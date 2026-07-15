#!/usr/bin/env bash
set -euo pipefail

# Migrate drywell's immich postgres (podman-compose systemd unit) to a new
# major version via dump/restore.
#
# Prereq: edit hosts/drywell/services/immich.nix first — bump the postgres
# image tag AND (for 18+) change the volume mount to
#   /services/immich/postgres:/var/lib/postgresql
# but do NOT rebuild; this script builds the new system up front (so a slow
# or failed build costs no downtime) and activates it after the data dump
# and dataset swap.
#
# Usage (on drywell): hosts/drywell/pg-major-upgrade.sh

repo_root=$(cd "$(dirname "$0")/../.." && pwd)

project=immich
unit=immich
pool=fast
dataset="${pool}/services/${project}/postgres"
nix_file="${repo_root}/hosts/drywell/services/${project}.nix"

# Working files are temporary and removed by the exit trap.
workdir=$(mktemp -d "/var/tmp/pg-upgrade-${project}-XXXXXX")
dump="${workdir}/dump.sql"

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

dataset_renamed=0
service_stopped=0

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

confirm() {
    local reply
    read -r -p "$1 [y/N] " reply
    [[ "$reply" =~ ^[Yy] ]] || { echo "Aborted." >&2; exit 1; }
}

die() { echo "ERROR: $*" >&2; exit 1; }

on_exit() {
    local code=$?
    if [ "$code" -ne 0 ] && [ "$dataset_renamed" -eq 1 ]; then
        cat >&2 <<-EOF

	The old dataset was already renamed. To roll back to pg${old_major}:
	  ${SUDO} systemctl stop ${unit}
	  ${SUDO} zfs destroy -r ${dataset}    # the (failed) new cluster
	  ${SUDO} zfs rename ${old_dataset} ${dataset}
	  ${SUDO} nix-env -p /nix/var/nix/profiles/system --set ${old_system}
	  ${SUDO} ${old_system}/bin/switch-to-configuration switch
	  ${SUDO} systemctl restart ${unit}
	Then revert ${nix_file} so a later rebuild doesn't re-deploy pg${new_major}.
	Pre-upgrade snapshot: ${dataset_snapshot:-<none>}
	EOF
    elif [ "$code" -ne 0 ] && [ "$service_stopped" -eq 1 ]; then
        cat >&2 <<-EOF

	No dataset or config changes were made. Bring the service back with:
	  ${SUDO} systemctl restart ${unit}
	EOF
    fi
    rm -rf "${workdir:-}"
}
trap on_exit EXIT

find_ctr() {
    $SUDO podman ps --format '{{.Names}}' | grep -E "^${project}[_-]$1" | head -1
}

# Run SQL in the postgres container, tuples-only.
# SQL must not contain double quotes, backslashes, or dollar signs.
pg_sql() {
    $SUDO podman exec "$pg_ctr" \
        sh -c "psql -U \"\${POSTGRES_USER:-postgres}\" -d \"${2:-postgres}\" -tAc \"$1\""
}

# db names, per-db table names, and extension versions — captured before and
# after so the diff shows exactly what the upgrade changed.
capture_meta() {
    local out=$1 db
    {
        echo "== databases =="
        pg_sql "select datname from pg_database where not datistemplate order by datname"
        for db in $(pg_sql "select datname from pg_database where not datistemplate order by datname"); do
            echo "== ${db}: tables =="
            pg_sql "select table_schema || '.' || table_name from information_schema.tables where table_schema not in ('pg_catalog','information_schema') order by 1" "$db"
            echo "== ${db}: extensions =="
            pg_sql "select extname, extversion from pg_extension order by extname" "$db"
        done
    } > "$out"
}

################################################################################
step "Preflight"

[ "$(hostname)" = "drywell" ] || die "this script must run on drywell"
[ -f "$nix_file" ] || die "$nix_file not found"

# Pinned for the rollback instructions: activating this exact path restores
# the pre-migration system no matter what happened to generations since.
old_system=$(readlink -f /run/current-system)

pg_ctr=$(find_ctr postgres) || true
[ -n "$pg_ctr" ] || die "no running ${project} postgres container found"
app_ctr=$(find_ctr "${project}([_-][0-9]+)?\$") || true
[ -n "$app_ctr" ] || die "no running ${project} app container found"

old_major=$(( $(pg_sql "show server_version_num") / 10000 ))
old_dataset="${dataset}-pg${old_major}"

live_image=$($SUDO podman inspect -f '{{.ImageName}}' "$pg_ctr")
nix_image=$(grep -o 'ghcr.io/immich-app/postgres:[^"]*' "$nix_file" | head -1)
[ -n "$nix_image" ] || die "no postgres image found in ${nix_file}"
[ "$live_image" != "$nix_image" ] \
    || die "image in ${nix_file} matches the running container — edit the nix config first"

new_tag=${nix_image#*:}
new_major=${new_tag%%[!0-9]*}
[ -n "$new_major" ] || die "cannot determine target major version from ${nix_image}"
[ "$new_major" != "$old_major" ] || die "target major (${new_major}) equals current major"
if [ "$new_major" -ge 18 ] && grep -q ":/var/lib/postgresql/data" "$nix_file"; then
    die "18+ images moved PGDATA: change the volume mount in ${nix_file} to /services/${project}/postgres:/var/lib/postgresql"
fi

zfs list "$dataset" > /dev/null || die "dataset ${dataset} not found"
! zfs list "$old_dataset" &> /dev/null || die "${old_dataset} already exists"
case "$(zfs get -H -o source mountpoint "$dataset")" in
    inherited*|default) ;;
    *) die "${dataset} has a locally-set mountpoint; 'zfs rename' would not move the mount" ;;
esac

mountpoint=$(zfs get -H -o value mountpoint "$dataset")
refquota=$(zfs get -H -o value refquota "$dataset")
dir_owner=$($SUDO stat -c '%u:%g' "$mountpoint")
dir_mode=$($SUDO stat -c '%a' "$mountpoint")

db_bytes=$(pg_sql "select sum(pg_database_size(datname)) from pg_database")
avail=$(df --output=avail -B1 "$workdir" | tail -1)
[ "$avail" -gt $(( db_bytes * 2 )) ] \
    || die "only ${avail} bytes free under ${workdir}; need 2x DB size ($(( db_bytes * 2 )))"

cat <<-EOF

	Project:      ${project} (systemd unit ${unit}, containers ${app_ctr} / ${pg_ctr})
	Upgrade:      pg${old_major} -> pg${new_major}
	Image:        ${live_image}
	           -> ${nix_image}
	Dataset:      ${dataset} (refquota ${refquota})
	              old data kept as ${old_dataset}
	DB size:      $(numfmt --to=iec "$db_bytes")
	Dump/logs:    ${workdir} (removed on exit)
	Rollback gen: ${old_system}

	The service is DOWN from dump until restore completes. The new system is
	built and the image pulled up front; only activation happens mid-flow.
	zrepl note: the rename breaks incremental continuity — both the renamed
	dataset and the fresh one appear as new datasets to zrepl.
	EOF
confirm "Proceed?"

capture_meta "${workdir}/meta.pre"

step "Building the new system (before any downtime)"
nix build "${repo_root}#nixosConfigurations.drywell.config.system.build.toplevel" \
    -o "${workdir}/system" --option fallback true
new_system=$(readlink -f "${workdir}/system")
echo "Built ${new_system}"

step "Pulling ${nix_image} (before downtime starts)"
$SUDO podman pull "$nix_image"

################################################################################
step "Stopping ${app_ctr} (postgres stays up for the dump)"

service_stopped=1
$SUDO podman stop "$app_ctr"

################################################################################
step "Dumping all databases to ${dump}"

$SUDO podman exec "$pg_ctr" \
    sh -c 'pg_dumpall --clean --if-exists --username="${POSTGRES_USER:-postgres}"' > "$dump"
tail -n5 "$dump" | grep -q "cluster dump complete" || die "dump looks incomplete (no trailer)"
echo "Dump complete: $(du -h "$dump" | cut -f1)"

################################################################################
step "Stopping ${unit}"

$SUDO systemctl stop "$unit"
for _ in $(seq 30); do
    [ -z "$($SUDO podman ps --format '{{.Names}}' | grep -E "^${project}[_-]" || true)" ] && break
    sleep 2
done

################################################################################
step "Swapping ZFS datasets"

# Timestamped: a rolled-back dataset keeps earlier attempts' snapshots, so a
# static name would collide on rerun.
dataset_snapshot="${dataset}@pre-pg${new_major}-upgrade-$(date +%Y%m%d-%H%M%S)"
confirm "Snapshot, rename ${dataset} -> ${old_dataset}, create fresh dataset?"
$SUDO zfs snapshot "$dataset_snapshot"
$SUDO zfs rename "$dataset" "$old_dataset"
dataset_renamed=1
if [ "$refquota" != "none" ] && [ "$refquota" != "-" ]; then
    $SUDO zfs create -o "refquota=${refquota}" "$dataset"
else
    $SUDO zfs create "$dataset"
fi
$SUDO chown "$dir_owner" "$mountpoint"
$SUDO chmod "$dir_mode" "$mountpoint"

################################################################################
step "Activating the new system (starts pg${new_major} on the fresh dataset)"

$SUDO nix-env -p /nix/var/nix/profiles/system --set "$new_system"
$SUDO "$new_system/bin/switch-to-configuration" switch
$SUDO systemctl start "$unit"

# Stop the app again as soon as it exists — it must not touch the database
# until the restore is done.
app_ctr=""
for _ in $(seq 60); do
    app_ctr=$(find_ctr "${project}([_-][0-9]+)?\$") || true
    [ -n "$app_ctr" ] && break
    sleep 2
done
[ -n "$app_ctr" ] || die "${project} app container did not appear after rebuild"
$SUDO podman stop "$app_ctr"

pg_ctr=$(find_ctr postgres) || true
[ -n "$pg_ctr" ] || die "postgres container did not appear after rebuild"
pg_ready=0
for _ in $(seq 60); do
    if $SUDO podman exec "$pg_ctr" \
        sh -c 'pg_isready -U "${POSTGRES_USER:-postgres}"' &> /dev/null; then
        pg_ready=1
        break
    fi
    sleep 2
done
[ "$pg_ready" -eq 1 ] || die "pg${new_major} did not become ready"

################################################################################
step "Restoring"

# search_path rewrite per immich's restore docs; harmless for other services.
# stderr also streams to the terminal: the workdir is deleted on exit, so the
# scrollback is the durable record of restore errors.
sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" "$dump" \
    | $SUDO podman exec -i "$pg_ctr" \
        sh -c 'psql --username="${POSTGRES_USER:-postgres}" --dbname=postgres' \
        > "${workdir}/restore.log" \
        2> >(tee "${workdir}/restore.err" >&2)

# Restoring a cluster dump into a fresh cluster always fails to drop/create
# the connected superuser role — anything else deserves eyes.
grep -E '^ERROR' "${workdir}/restore.err" \
    | grep -vE 'current (user|role) cannot be dropped|role "postgres" already exists' \
    > "${workdir}/restore.errors" || true
if [ -s "${workdir}/restore.errors" ]; then
    echo "Unexpected restore errors:"
    cat "${workdir}/restore.errors"
    confirm "Continue anyway?"
else
    echo "No unexpected restore errors."
fi

capture_meta "${workdir}/meta.post"
echo "Pre/post comparison (expect extension version bumps and extension-owned tables only; user tables must match):"
diff -u "${workdir}/meta.pre" "${workdir}/meta.post" || true
confirm "Does the comparison look right?"

echo "Rebuilding planner statistics..."
$SUDO podman exec "$pg_ctr" \
    sh -c 'vacuumdb --all --analyze-in-stages --username="${POSTGRES_USER:-postgres}"'

################################################################################
step "Restarting ${unit}"

$SUDO systemctl restart "$unit"
dataset_renamed=0
service_stopped=0

################################################################################
step "Done — follow-ups"

cat <<-EOF
	1. Verify immich.
	2. Commit the ${nix_file} change.
	3. After a soak period, release zrepl holds and destroy the old dataset:
	     zfs list -H -o name -t snapshot -r ${old_dataset} \\
	         | xargs -rn1 zfs holds -H | awk '{print \$2, \$1}' \\
	         | xargs -rn2 ${SUDO} zfs release
	     ${SUDO} zfs destroy -rv ${old_dataset}
	4. Rollback (before destroying): stop ${unit}, destroy ${dataset}, rename
	   ${old_dataset} back, revert the nix config, rebuild, restart ${unit}.
	EOF

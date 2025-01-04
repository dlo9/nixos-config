#!/bin/sh

set -e

usage() {
  echo "create-host-config <hostname> <admin username>"
}

hostname="$1"
admin="$2"

if [ -z "$hostname" ] || [ -z "$admin" ]; then
  usage
  exit 1
fi

if [ -z "$SOPS_AGE_KEY" ]; then
  echo "ERROR: SOPS_AGE_KEY must be set to the master key"
  exit 1
fi

repoDir="/etc/nixos"
hostDir="$repoDir/hosts/$hostname"
mkdir -p "$hostDir"

##########################
### Secrets Generation ###
##########################

# Change to temp dir for SSH key generation
tempDir="$(mktemp -d)"

ssh-keygen -N '' -t rsa -C "root@$hostname" -f "$tempDir/host_rsa" > /dev/null
sshHostRsaPrivate="$(cat "$tempDir/host_rsa")"
sshHostRsaPublic="$(cat "$tempDir/host_rsa.pub")"

ssh-keygen -N '' -t ed25519 -C "root@$hostname" -f "$tempDir/host_ed25519" > /dev/null
sshHostPrivate="$(cat "$tempDir/host_ed25519")"
sshHostPublic="$(cat "$tempDir/host_ed25519.pub")"

ssh-keygen -N '' -t ed25519 -C "$admin@$hostname" -f "$tempDir/admin_ed25519" > /dev/null
sshAdminPrivate="$(cat "$tempDir/admin_ed25519")"
sshAdminPublic="$(cat "$tempDir/admin_ed25519.pub")"

ageKey="$(age-keygen 2> /dev/null)"
ageKeyCreated="$(echo "$ageKey" | awk 'NR == 1 {print $3}')"
ageKeyPublic="$(echo "$ageKey" | awk 'NR == 2 {print $4}')"
ageKeyPrivate="$(echo "$ageKey" | awk 'NR == 3 {print $1}')"

# Cleanup
rm -rf "$tempDir"

###############
### Secrets ###
###############

# Add public age key to sops
creationRules="$(cat "$repoDir/.sops.yaml")"
printf "%s" "$creationRules" | awk "/Host root keys/ { inHostKeys=1 } inHostKeys && /^\$/ { print \"  - &$hostname $ageKeyPublic\"; inHostKeys=0 }  { print }" > "$repoDir/.sops.yaml"

# Add host secrets file to sops
cat << EOF >> "$repoDir/.sops.yaml"

  - path_regex: ^hosts/$hostname/secrets.yaml\$
    unencrypted_regex: ^(exports|enable|sopsNix)\$
    key_groups:
    - age:
      - *bitwarden
      - *$hostname
EOF

# Update shared keys
find "$repoDir" -name secrets.yaml -not -path "$repoDir/hosts/*" -exec sops updatekeys -y '{}' ';'

# Create host secrets
cat << EOF >> "$hostDir/secrets.yaml"
age-key:
  enable: false
  exports:
    created: "$ageKeyCreated"
    public: $ageKeyPublic
  contents: $ageKeyPrivate
host-ssh-key:
  enable: true
  sopsNix:
    path: /etc/ssh/ssh_host_ed25519_key
  exports:
    pub: $sshHostPublic
  contents: |
    $(echo "$sshHostPrivate" | sed '1b; s/^/      /')
$admin-ssh-key:
  enable: true
  sopsNix:
    path: /home/$admin/.ssh/id_ed25519
    owner: $admin
    group: users
  exports:
    pub: $sshAdminPublic
  contents: |
      $(echo "$sshAdminPrivate" | sed '1b; s/^/      /')
EOF

# Encrypt host secrets
sops -e -i "$hostDir/secrets.yaml"

###########################
### Hardware Generation ###
###########################

#git add -u
#git add "hosts/$hostname"
#git commit -m "Add host: $hostname"

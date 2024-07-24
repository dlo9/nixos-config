#!/usr/bin/env -S awk -f

BEGIN {
    # Taken from: https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/utils.nix
    # TODO: inject this dynamically
    split("/ /nix /nix/store /var /var/log /var/lib /var/lib/nixos /etc /usr", pathsNeededForBoot)
}

# Skip commented network interfaces
/# networking/ { next; }

# Detect a filesystem mount start
match($0, /fileSystems\."(.*)"/, matches) {
    currentFilesystem = matches[1];
}

# Store the filesystem mount
currentFilesystem != "" {
    # Detect a filesystem mount end
    if ($0 ~ /^$/) {
        currentFilesystem = "";
    } else {
        filesystemSpecs[currentFilesystem] = filesystemSpecs[currentFilesystem] "\n" $0;

        if (match($0, /fsType = "(.*)"/, matches)) {
            filesystemTypes[currentFilesystem] = matches[1];
        }
    }

    # Don't print the current line
    next;
}

# Last line
/^\}$/ {
    # Sort filesystems
    asorti(filesystemSpecs, filesystemsSorted);

    # Print filesystems
    for (i in filesystemsSorted) {
        shouldOutput = 0;

        # Only output paths needed for boot
        currentFilesystem = filesystemsSorted[i];
        for (j in pathsNeededForBoot) {
            bootPath = pathsNeededForBoot[j];
            if (currentFilesystem == bootPath) {
                shouldOutput = 1;
                break;
            }
        }

        if (shouldOutput) {
            print filesystemSpecs[currentFilesystem];
        }
    }
}

{ print; }

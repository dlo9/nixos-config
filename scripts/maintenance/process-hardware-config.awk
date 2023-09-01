#!/usr/bin/env -S awk -f

BEGIN {
    ignoredPaths[0] = "^/var/lib/kubernetes/pods/";
    ignoredPaths[1] = "^/var/lib/docker/overlay2/";

    ignoredFilesystemTypes[0] = "autofs";
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
        shouldOutput = 1;

        # Ignore configured paths
        currentFilesystem = filesystemsSorted[i];
        for (j in ignoredPaths) {
            ignoredPath = ignoredPaths[j];
            if (currentFilesystem ~ ignoredPath) {
                shouldOutput = 0;
                break;
            }
        }

        # Ignore configured filesystems
        currentFilesystemType = filesystemTypes[currentFilesystem];
        for (j in ignoredFilesystemTypes) {
            ignoredFilesystemType = ignoredFilesystemTypes[j];
            if (currentFilesystemType ~ ignoredFilesystemType) {
                shouldOutput = 0;
                break;
            }
        }

        if (shouldOutput) {
            print filesystemSpecs[currentFilesystem];
        }
    }
}

{ print; }

#!/usr/bin/env -S awk -f

# Skip commented network interfaces
/# networking/ { next; }

# Detect a fileSystem mount start
match($0, /fileSystems\."(.*)"/, matches) {
    currentFilesystem = matches[1];
}

# Store the fileSystem mount
currentFilesystem != "" {
    # Detect a fileSystem mount end
    if ($0 ~ /^$/) {
        currentFilesystem = ""
    } else {
        fileSystems[currentFilesystem] = fileSystems[currentFilesystem] "\n" $0;
    }

    # Don't print the empty line
    next;
}

# Last line
/^\}$/ {
    # Sort fileSystems
    asorti(fileSystems, fileSystemsSorted);

    # Print fileSystems
    for (i in fileSystemsSorted) {
        fileSystem = fileSystemsSorted[i];

        if (fileSystem ~ /^\/var\/lib\/kubernetes\/pods/) {
            # Pod mounts are managed by kubernetes
            continue;
        }

        print fileSystems[fileSystem];
    }
}

{ print }

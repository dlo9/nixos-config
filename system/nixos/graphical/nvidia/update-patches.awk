BEGIN {
    FS="[\"']"
    OFS=" "
}

$2 ~ /^[0-9]+\.[0-9]+(.[0-9]+)?$/ {
    version = $2

    if ($4 ~ /^s\//) {
        # Escape hex codes
        gsub("\\\\x", "\\\\\\\\x", $4)
        patches[version] = $4
    } else if ($4 ~ /\.so$/) {
        files[version] = $4
    }
}

END {
    asorti(patches, versions)

    print "{"
    for (i in versions) {
        version = versions[i]
        patch = patches[version]
        file = files[version]

        printf "  \"%s\" = { patch = \"%s\"; file = \"%s\"; };\n", version, patch, file
    }
    print "}"
}

#!/bin/sh

for regex in $(yq  '.creation_rules | map(.path_regex) | .[]' .sops.yaml | sed 's#^\^#^./#'); do
    find . -regextype posix-extended -regex "$regex" -exec sops updatekeys -y '{}' ';'
done

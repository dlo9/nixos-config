#!/bin/sh

for regex in $(yq  '.creation_rules | map(.path_regex) | .[]' .sops.yaml | sed 's#^\^#^./#'); do
    find . -regex "$regex" -exec sops updatekeys -y '{}' ';'
done
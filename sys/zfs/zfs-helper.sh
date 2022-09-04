#!/bin/sh

# In-memory keyfile so that unexpected shutdowns request passwords on next boot
# Directory must be a tmpfs mount started within initrd
keyFileMem="/run/zfs_keys"

# On-disk keyfile to persist keys across expected shutdowns
# EFI will be mounted to this directory
keyFileDisk="/run/efi/zfs_keys"

# Mount the filesystem used for persistence
mountPersist() {
  # Create mountpoint
  echo "Preparing EFI mount"
  mountDir="$(dirname "$keyFileDisk")"
  mkdir -p "$mountDir"

  # Mount EFI
  echo "Mounting EFI"
  mount -t vfat /dev/disk/by-label/EFI "$mountDir"
}

# Unmount the filesystem used for persistence
unmountPersist() {
  echo "Unmounting EFI"
  mountDir="$(dirname "$keyFileDisk")"
  umount "$mountDir"
  rm -r "$mountDir"
}

waitForPool() {
  echo "Waiting for pool to import"
  
  while [ "$(zpool list -H | wc -l)" -eq 0 ]; do
    sleep 1
  done
  
  echo "Pool imported"
}

# Prompt the user for the key to each encryption root and save them to in-memory keyfile
readKeysFromUser() {
  echo "Requesting dataset keys from user"

  # Create file
  truncate -s 0 "$keyFileMem"
  chmod 600 "$keyFileMem"

  for encRoot in $(zfs list -H -t filesystem -o encryptionroot,encryption,keyformat | awk '$2 != "off" && $3 == "passphrase" && !a[$1]++ { print $1; }'); do
    # Loop until the correct password is entered
    while true; do
      # Prompt for password
      read -s -r -p "Enter passphrase for '$encRoot': " key
      echo

      # Test key
      echo "$key" | zfs load-key -n "$encRoot" && break
    done

    # Add key to file
    printf '%s\t%s\n' "$encRoot" "$key" >> "$keyFileMem"
  done
}

# Load keys from in-memory keyfile and unlock ZFS datasets
unlockDatasets() {
  echo "Decrypting ZFS datasets"

  while read -r encRoot key; do
	echo "Decrypting $encRoot"
    echo "$key" | zfs load-key "$encRoot"
  done < "$keyFileMem"
}

# Move keys from memory to disk
saveKeys() {
  mountPersist

  if [ -e "$keyFileMem" ]; then
    echo "Persisting keyfile"
    mv "$keyFileMem" "$keyFileDisk"
  else
    echo "Keyfile not found, next boot will prompt user for keys"
  fi

  unmountPersist
}

# Move keys from disk to memory
# Returns true on successful load
loadSavedKeys() {
  mountPersist

  if [ -e "$keyFileDisk" ]; then
    echo "Persisted keyfile found, will attempt to decrypt pools from key file"
    # TODO: wipe
    mv "$keyFileDisk" "$keyFileMem"
    chmod 600 "$keyFileMem"
  else
    echo "Persisted keyfile missing, will prompt user for keys"
  fi

  unmountPersist
  test -f "$keyFileMem"
}

# Attempt to boot from on-disk keyfile, with no fallback to user prompt
onBoot() {
  waitForPool
  loadSavedKeys || return
  unlockDatasets

  # Load any other keys in the normal way, in case something went wrong
  # or keys are file-based
  echo "Loading any remaining keys"
  zfs load-key -a

  # Kill the existing prompt, which will trigger a load-key which should succeed
  echo "Informing init process of decrypted datasets"
  killall zfs
}

# Attempt to boot from on-disk keyfile, falling back to user prompt
onBootPrompt() {
  waitForPool
  loadSavedKeys || readKeysFromUser
  unlockDatasets

  # Load any other keys in the normal way, in case something went wrong
  # or keys are file-based
  echo "Loading any remaining keys"
  zfs load-key -a

  # Kill the existing prompt, which will trigger a load-key which should succeed
  echo "Informing init process of decrypted datasets"
  killall zfs
}

# Save in-memory keys from the current boot to disk, so that user input isn't necessary on the next boot.
# This won't happen on unexpected shutdowns
onShutdown() {
  saveKeys
}

version() {
  echo "0.1"
}

# Just call the specified function directly
$1

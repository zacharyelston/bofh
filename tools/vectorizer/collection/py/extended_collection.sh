#!/bin/bash
# Extended collection with content sampling and hashing

find "$1" -type f -print0 | xargs -0 -n 100 bash -c '
  for file in "$@"; do
    if [ -r "$file" ]; then
      hash=$(sha256sum "$file" | cut -d" " -f1)
      mime=$(file --mime-type -b "$file")
      first_bytes=$(head -c 1024 "$file" | xxd -p | tr -d "\n")
      echo "$file|$(stat -c "%s|%Y|%A" "$file")|$hash|$mime|$first_bytes"
    fi
  done
' bash

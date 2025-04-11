#!/bin/bash
# Performance-optimized collection with parallelization

find "$1" -type f -print0 | parallel -0 -j8 '
  stat -c "%n|%s|%Y|%A" {} 2>/dev/null
  if [ $? -eq 0 ] && [ -r {} ]; then
    echo -n "|"
    sha256sum {} | cut -d" " -f1
  fi
' > raw_data_parallel.txt

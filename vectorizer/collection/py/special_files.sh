#!/bin/bash
# Collection for special file types

# For binary files, collect entropy information
find "$1" -type f -name "*.bin" -o -name "*.exe" | while read file; do
    entropy=$(ent "$file" | grep "Entropy" | awk '{print $3}')
    echo "$file|$entropy" >> binary_entropy.txt
done

# For text files, collect language statistics
find "$1" -type f -name "*.txt" -o -name "*.md" | while read file; do
    lang=$(langdetect < "$file")
    lines=$(wc -l < "$file")
    echo "$file|$lang|$lines" >> text_stats.txt
done

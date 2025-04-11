#!/bin/bash
# extract_features.sh - Convert raw filesystem data to feature vectors

# Read from stdin or file provided as argument
input=${1:-/dev/stdin}

# Output header
echo "path,depth,size_log,age_days,user_r,user_w,user_x,group_r,group_w,group_x,other_r,other_w,other_x,is_hidden,filename_length,has_extension,entropy"

# Process each line
cat "$input" | while IFS='|' read -r path size modified permissions remainder; do
    # Extract path features
    depth=$(echo "$path" | tr -cd '/' | wc -c)
    filename=$(basename "$path")
    filename_length=${#filename}
    has_extension=$(echo "$filename" | grep -q "\." && echo "1" || echo "0")
    is_hidden=$(echo "$filename" | grep -q "^\." && echo "1" || echo "0")
    
    # Extract metadata features
    size_log=$(echo "l($size)/l(10)" | bc -l)
    current_time=$(date +%s)
    age_days=$(echo "($current_time - $modified) / 86400" | bc)
    
    # Extract permission features
    user_r=$(echo "$permissions" | grep -q "^.r" && echo "1" || echo "0")
    user_w=$(echo "$permissions" | grep -q "^..w" && echo "1" || echo "0")
    user_x=$(echo "$permissions" | grep -q "^...x" && echo "1" || echo "0")
    group_r=$(echo "$permissions" | grep -q "^....r" && echo "1" || echo "0")
    group_w=$(echo "$permissions" | grep -q "^.....w" && echo "1" || echo "0")
    group_x=$(echo "$permissions" | grep -q "^......x" && echo "1" || echo "0")
    other_r=$(echo "$permissions" | grep -q "^.......r" && echo "1" || echo "0")
    other_w=$(echo "$permissions" | grep -q "^........w" && echo "1" || echo "0")
    other_x=$(echo "$permissions" | grep -q "^.........x" && echo "1" || echo "0")
    
    # Calculate entropy if file content is available
    entropy="0"
    if [[ "$remainder" == *"|"* ]]; then
        hash=$(echo "$remainder" | cut -d'|' -f1)
        entropy=$(echo "scale=3; ${#hash} / 64" | bc)
    fi
    
    # Output feature vector
    echo "$path,$depth,$size_log,$age_days,$user_r,$user_w,$user_x,$group_r,$group_w,$group_x,$other_r,$other_w,$other_x,$is_hidden,$filename_length,$has_extension,$entropy"
done

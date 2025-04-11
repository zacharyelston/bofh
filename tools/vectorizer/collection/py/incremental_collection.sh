#!/bin/bash
# Incremental collection based on change times

# Only collect data for files modified after last scan
find "$1" -type f -newer last_scan_timestamp -exec stat -c "%n|%s|%Y|%A" {} \; > incremental_update.txt
touch last_scan_timestamp

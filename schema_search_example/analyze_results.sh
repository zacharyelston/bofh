#!/bin/bash
# analyze_results.sh - Script to analyze search results and generate app/table mapping
# Created by ModelContextProtocol

# Source the config file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../config.sh" ]; then
    source "$SCRIPT_DIR/../config.sh"
fi

# Set variables with defaults that can be overridden
TARGET_DIR="${1:-${DEFAULT_CODE_DIR:-/var/www/html}}"
OUTPUT_DIR="${2:-${DEFAULT_OUTPUT_DIR:-$SCRIPT_DIR/output}}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
FINAL_REPORT="$OUTPUT_DIR/apps_and_tables.txt"

echo "=====================================================================
Application and Table Mapping - MCP
=====================================================================
" > "$FINAL_REPORT"

# Check if the search results exist
if [ ! -f "$OUTPUT_DIR/tables_rg.txt" ]; then
  echo "Error: Search results not found. Please run search_with_ripgrep.sh first."
  exit 1
fi

echo "Analyzing directory structure to identify applications..." >> "$FINAL_REPORT"

# Extract application names based on directory structure
cat "$OUTPUT_DIR/tables_rg.txt" | xargs dirname | sort | uniq -c | sort -rn > "$OUTPUT_DIR/app_directories.txt"

echo "Found $(wc -l < "$OUTPUT_DIR/app_directories.txt") potential application directories" >> "$FINAL_REPORT"
echo "" >> "$FINAL_REPORT"

# Analyze each potential application directory
echo "Applications and their tables:" >> "$FINAL_REPORT"
echo "-------------------------------------------------------------------" >> "$FINAL_REPORT"

# We'll look at the top 10 directories with the most table files
cat "$OUTPUT_DIR/app_directories.txt" | head -10 | while read -r count dir; do
  app_name=$(basename "$dir")
  echo "Application: $app_name (Directory: $dir)" >> "$FINAL_REPORT"
  echo "Table files: $count" >> "$FINAL_REPORT"
  
  # Find table definitions in this app directory
  grep "$dir/" "$OUTPUT_DIR/tables_rg.txt" > "$OUTPUT_DIR/temp_app_tables.txt"
  
  echo "Sample tables:" >> "$FINAL_REPORT"
  cat "$OUTPUT_DIR/temp_app_tables.txt" | while read -r file; do
    # Extract table names from the file
    grep -n "CREATE TABLE" "$file" 2>/dev/null | head -5 | sed 's/^[0-9]*:/    Table: /' >> "$FINAL_REPORT"
  done
  
  echo "-------------------------------------------------------------------" >> "$FINAL_REPORT"
done

# Clean up temporary files
rm -f "$OUTPUT_DIR/temp_app_tables.txt"

echo "Analysis complete. Final report available at $FINAL_REPORT"

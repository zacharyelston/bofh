#!/bin/bash
# search_with_ripgrep.sh - Advanced schema search script
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

echo "=====================================================================
Advanced Schema Search Process - MCP
=====================================================================
" > "$OUTPUT_DIR/ripgrep_results.txt"

# Step 1: Find schema definitions using ripgrep
echo "Step 1: Searching for schema definitions..." >> "$OUTPUT_DIR/ripgrep_results.txt"
rg -l "CREATE SCHEMA|schema = |schema:|schema =" --type sql --type-add 'sql:*.{sql,ddl,hql,prisma}' "$TARGET_DIR" > "$OUTPUT_DIR/schemas_rg.txt" 2>/dev/null

echo "Found $(wc -l < "$OUTPUT_DIR/schemas_rg.txt") schema definition files" >> "$OUTPUT_DIR/ripgrep_results.txt"
echo "Sample schema files:" >> "$OUTPUT_DIR/ripgrep_results.txt"
cat "$OUTPUT_DIR/schemas_rg.txt" | head -5 >> "$OUTPUT_DIR/ripgrep_results.txt"
echo "" >> "$OUTPUT_DIR/ripgrep_results.txt"

# Step 2: Find table definitions
echo "Step 2: Searching for table definitions..." >> "$OUTPUT_DIR/ripgrep_results.txt"
rg -l "CREATE TABLE|Table |table:|@Table" --type sql --type-add 'sql:*.{sql,ddl,hql,prisma,java,kt,scala}' "$TARGET_DIR" > "$OUTPUT_DIR/tables_rg.txt" 2>/dev/null

echo "Found $(wc -l < "$OUTPUT_DIR/tables_rg.txt") table definition files" >> "$OUTPUT_DIR/ripgrep_results.txt"
echo "Sample table files:" >> "$OUTPUT_DIR/ripgrep_results.txt"
cat "$OUTPUT_DIR/tables_rg.txt" | head -5 >> "$OUTPUT_DIR/ripgrep_results.txt"
echo "" >> "$OUTPUT_DIR/ripgrep_results.txt"

# Step 3: Extract schema names
echo "Step 3: Extracting schema names..." >> "$OUTPUT_DIR/ripgrep_results.txt"
echo "Sample schema definitions:" >> "$OUTPUT_DIR/ripgrep_results.txt"

if [ -s "$OUTPUT_DIR/schemas_rg.txt" ]; then
  head -3 "$OUTPUT_DIR/schemas_rg.txt" | while read -r file; do
    echo "File: $file" >> "$OUTPUT_DIR/ripgrep_results.txt"
    rg "CREATE SCHEMA|schema = |schema:|schema =" -n --context 1 "$file" | head -5 >> "$OUTPUT_DIR/ripgrep_results.txt"
    echo "" >> "$OUTPUT_DIR/ripgrep_results.txt"
  done
fi

# Step 4: Extract table names and their associated schemas
echo "Step 4: Extracting table names and their schemas..." >> "$OUTPUT_DIR/ripgrep_results.txt"
echo "Sample table definitions with schema context:" >> "$OUTPUT_DIR/ripgrep_results.txt"

if [ -s "$OUTPUT_DIR/tables_rg.txt" ]; then
  head -3 "$OUTPUT_DIR/tables_rg.txt" | while read -r file; do
    echo "File: $file" >> "$OUTPUT_DIR/ripgrep_results.txt"
    rg "CREATE TABLE|Table |table:|@Table" -n --context 1 "$file" | head -5 >> "$OUTPUT_DIR/ripgrep_results.txt"
    echo "" >> "$OUTPUT_DIR/ripgrep_results.txt"
  done
fi

echo "Process completed. See advanced results in $OUTPUT_DIR/ripgrep_results.txt"

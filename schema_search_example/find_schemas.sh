#!/bin/bash
# find_schemas.sh - Script to find schema references and their tables
# Created by ModelContextProtocol (MCP)

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
Schema Search Process - MCP
=====================================================================
" > "$OUTPUT_DIR/search_results.txt"

# Approach 1: Find + Grep combination
echo "Approach 1: Find + Grep combination" >> "$OUTPUT_DIR/search_results.txt"
echo "Searching for schema references..." >> "$OUTPUT_DIR/search_results.txt"

find "$TARGET_DIR" -type f -not -path "*/node_modules/*" -not -path "*/\.*" -exec grep -l "schema" {} \; | head -20 > "$OUTPUT_DIR/schema_files_grep.txt"

echo "Found $(wc -l < "$OUTPUT_DIR/schema_files_grep.txt") files (limited to 20)" >> "$OUTPUT_DIR/search_results.txt"
echo "Sample files:" >> "$OUTPUT_DIR/search_results.txt"
cat "$OUTPUT_DIR/schema_files_grep.txt" | head -5 >> "$OUTPUT_DIR/search_results.txt"
echo "" >> "$OUTPUT_DIR/search_results.txt"

# Approach 2: Find focused on SQL files
echo "Approach 2: Find focused on SQL and related files" >> "$OUTPUT_DIR/search_results.txt"
echo "Searching for schema in SQL-related files..." >> "$OUTPUT_DIR/search_results.txt"

# Use extensions from config if available, otherwise use defaults
if [ -z "$SQL_EXTENSIONS" ]; then
    SQL_EXTENSIONS=("sql" "ddl" "hql" "prisma")
fi

# Build the find command with file extensions
FIND_EXPR=""
for ext in "${SQL_EXTENSIONS[@]}"; do
    if [ -z "$FIND_EXPR" ]; then
        FIND_EXPR="-name \"*.$ext\""
    else
        FIND_EXPR="$FIND_EXPR -o -name \"*.$ext\""
    fi
done

# Run the find command with the built expression
eval "find \"$TARGET_DIR\" -type f \( $FIND_EXPR \) -not -path \"*/node_modules/*\" -not -path \"*/\\.*\"" | \
  xargs grep -l "schema" 2>/dev/null > "$OUTPUT_DIR/schema_files_sql.txt"

echo "Found $(wc -l < "$OUTPUT_DIR/schema_files_sql.txt") SQL-related files" >> "$OUTPUT_DIR/search_results.txt"
echo "Sample files:" >> "$OUTPUT_DIR/search_results.txt"
cat "$OUTPUT_DIR/schema_files_sql.txt" | head -5 >> "$OUTPUT_DIR/search_results.txt"
echo "" >> "$OUTPUT_DIR/search_results.txt"

# Look for CREATE TABLE statements in the found files
echo "Looking for CREATE TABLE statements in identified files..." >> "$OUTPUT_DIR/search_results.txt"
if [ -s "$OUTPUT_DIR/schema_files_sql.txt" ]; then
    cat "$OUTPUT_DIR/schema_files_sql.txt" | xargs grep -l "CREATE TABLE" 2>/dev/null > "$OUTPUT_DIR/table_files.txt"
    echo "Found $(wc -l < "$OUTPUT_DIR/table_files.txt") files with CREATE TABLE statements" >> "$OUTPUT_DIR/search_results.txt"
else
    echo "No SQL-related files found with schema references" >> "$OUTPUT_DIR/search_results.txt"
    touch "$OUTPUT_DIR/table_files.txt"
fi
echo "" >> "$OUTPUT_DIR/search_results.txt"

# Extract table names from a sample file
if [ -s "$OUTPUT_DIR/table_files.txt" ]; then
    SAMPLE_FILE=$(head -1 "$OUTPUT_DIR/table_files.txt")
    echo "Sample table definitions from $SAMPLE_FILE:" >> "$OUTPUT_DIR/search_results.txt"
    grep -n "CREATE TABLE" "$SAMPLE_FILE" 2>/dev/null | head -5 >> "$OUTPUT_DIR/search_results.txt"
else
    echo "No files with CREATE TABLE statements found" >> "$OUTPUT_DIR/search_results.txt"
fi

echo "Process completed. See results in $OUTPUT_DIR/search_results.txt"

# If debug level is set and greater than 0, print more info
if [ ! -z "$DEBUG_LEVEL" ] && [ "$DEBUG_LEVEL" -gt 0 ]; then
    echo "Search completed with the following settings:"
    echo "Target directory: $TARGET_DIR"
    echo "Output directory: $OUTPUT_DIR"
    echo "SQL extensions searched: ${SQL_EXTENSIONS[*]}"
    echo "Number of schema files found: $(wc -l < "$OUTPUT_DIR/schema_files_grep.txt")"
    echo "Number of SQL files with schema references: $(wc -l < "$OUTPUT_DIR/schema_files_sql.txt")"
    echo "Number of files with CREATE TABLE statements: $(wc -l < "$OUTPUT_DIR/table_files.txt")"
fi

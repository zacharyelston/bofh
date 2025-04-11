#!/bin/bash
# search_hql_patterns.sh - Find schema and table patterns in HQL and similar files
# Created by ModelContextProtocol (MCP)

# Source the config file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../config.sh" ]; then
    source "$SCRIPT_DIR/../config.sh"
fi

# Set variables with defaults that can be overridden
TARGET_DIR="${1:-${DEFAULT_CODE_DIR:-/var/www/html}}"
OUTPUT_DIR="${2:-${DEFAULT_OUTPUT_DIR:-$SCRIPT_DIR/output}}"
RESULTS_FILE="$OUTPUT_DIR/hql_schema_report.md"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "# HQL Schema and Table Analysis" > "$RESULTS_FILE"
echo "Generated on $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Step 1: Find all HQL or SQL-like files that aren't .sql extension
echo "## Files Analyzed" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

find "$TARGET_DIR" -type f -not -path "*/node_modules/*" -not -path "*/\.*" -not -name "*.sql" | \
  xargs grep -l "SELECT\|FROM\|WHERE\|JOIN\|HAVING\|GROUP BY" 2>/dev/null | sort > "$OUTPUT_DIR/hql_files.txt"

echo "Found $(wc -l < "$OUTPUT_DIR/hql_files.txt") files with SQL-like queries" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Step 2: Extract schema and table patterns from these files
echo "## Schema and Table Patterns" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# FROM patterns
echo "### FROM Patterns" >> "$RESULTS_FILE"
echo "Tables referenced in FROM clauses:" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

cat "$OUTPUT_DIR/hql_files.txt" | xargs grep -h -o "FROM\s\+[a-zA-Z0-9_\.]\+" 2>/dev/null | \
  sed 's/FROM\s\+//' | sort | uniq -c | sort -nr | head -30 | \
  awk '{print "- " $2 " (" $1 " occurrences)"}' >> "$RESULTS_FILE"

echo "" >> "$RESULTS_FILE"

# JOIN patterns
echo "### JOIN Patterns" >> "$RESULTS_FILE"
echo "Tables referenced in JOIN clauses:" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

cat "$OUTPUT_DIR/hql_files.txt" | xargs grep -h -o "JOIN\s\+[a-zA-Z0-9_\.]\+" 2>/dev/null | \
  sed 's/JOIN\s\+//' | sort | uniq -c | sort -nr | head -30 | \
  awk '{print "- " $2 " (" $1 " occurrences)"}' >> "$RESULTS_FILE"

echo "" >> "$RESULTS_FILE"

# Step 3: Look for schema patterns
echo "## Schema References" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

cat "$OUTPUT_DIR/hql_files.txt" | xargs grep -h -o "[a-zA-Z0-9_]\+\.[a-zA-Z0-9_]\+" 2>/dev/null | \
  sort | uniq -c | sort -nr | head -50 | \
  awk -F. '{print $1}' | sort | uniq -c | sort -nr | \
  awk '{print "- " $2 " schema (" $1 " references)"}' >> "$RESULTS_FILE"

echo "" >> "$RESULTS_FILE"

# Step 4: Find sample queries for context
echo "## Sample Queries" >> "$RESULTS_FILE"
echo "Examples of queries found in the codebase:" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

cat "$OUTPUT_DIR/hql_files.txt" | head -3 | while read -r file; do
  echo "### File: $(basename "$file")" >> "$RESULTS_FILE"
  echo "From: $file" >> "$RESULTS_FILE"
  echo "" >> "$RESULTS_FILE"
  echo '```sql' >> "$RESULTS_FILE"
  grep -A 20 "SELECT\|select" "$file" | head -15 >> "$RESULTS_FILE"
  echo "..." >> "$RESULTS_FILE"
  echo '```' >> "$RESULTS_FILE"
  echo "" >> "$RESULTS_FILE"
done

# Step 5: Find possible data warehouse references
echo "## Cloud Data Warehouse References" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

echo "### Data Warehouse Type References" >> "$RESULTS_FILE"

for dw_type in "athena" "redshift" "snowflake" "bigquery"; do
  count=$(grep -l "$dw_type" "$OUTPUT_DIR/hql_files.txt" | wc -l)
  echo "Found $count files with $dw_type references" >> "$RESULTS_FILE"
done
echo "" >> "$RESULTS_FILE"

# Summary
echo "## Summary" >> "$RESULTS_FILE"
echo "This analysis identified SQL-like patterns in non-SQL files, which may represent Hive, Athena, or other data warehouse queries." >> "$RESULTS_FILE"
echo "These queries often reference schemas and tables that are not defined in traditional SQL migration files." >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "For a more comprehensive understanding of the data model, these references should be combined with the SQL schema analysis." >> "$RESULTS_FILE"

echo "HQL schema analysis completed. Results saved to $RESULTS_FILE"

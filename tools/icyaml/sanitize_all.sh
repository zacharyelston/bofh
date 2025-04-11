#!/bin/bash
# ICYAML Complete Sanitization Script
# Thoroughly removes ALL references to specific projects, paths, and usernames
# to ensure a completely clean repository

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🧹 ICYAML Complete Sanitizer"
echo "=========================="
echo "Thoroughly sanitizing ALL files to remove ALL project references..."

# Create a backup directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$SCRIPT_DIR/backups_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
echo "Created backup directory: $BACKUP_DIR"

# First, let's create backups of all files to be modified
echo "Creating backups of all files..."
find "$SCRIPT_DIR" -type f -not -path "$SCRIPT_DIR/backups*/*" | while read file; do
    if [ -f "$file" ]; then
        rel_path=${file#$SCRIPT_DIR/}
        mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
        cp "$file" "$BACKUP_DIR/$rel_path.bak"
    fi
done
echo "✅ Backups created"

# Function to thoroughly sanitize a file
sanitize_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Skip if file is in backup directory or is a binary file
    if [[ "$file" == *"/backups"* ]] || [[ ! -f "$file" ]]; then
        return
    fi
    
    # Check if file is binary (not a text file)
    if file "$file" | grep -q "binary"; then
        echo "Skipping binary file: $filename"
        return
    fi
    
    echo "Sanitizing: $filename"
    
    # Create a temporary file
    local temp_file="${file}.tmp"
    
    # PHASE 1: Replace all specific project references
    sed -e 's|SOURCE_DIR_PATH|SOURCE_DIR|g' \
        -e 's|SOURCE_DIR/|SOURCE_DIR/|g' \
        -e 's|/SOURCE_DIR|/SOURCE_DIR|g' \
        -e 's|SOURCE_DIR |SOURCE_DIR |g' \
        -e 's|SOURCE_DIR$|SOURCE_DIR|g' \
        -e 's|SOURCE_DIR"|SOURCE_DIR"|g' \
        -e 's|SOURCE_DIR:|SOURCE_DIR:|g' \
        -e 's|SOURCE_DIR-|SOURCE_DIR-|g' \
        -e 's|ordering-atlas|config-files|g' \
        -e 's|Ordering Atlas|Configuration Files|g' \
        -e "s|zacelston@ZEMBA|user@host|g" \
        -e "s|zacelston|username|g" \
        -e "s|ZEMBA|hostname|g" \
        "$file" > "$temp_file"
    
    # PHASE 2: Replace all absolute paths
    sed -i -e 's|/Users/[^/]*/CODE/[^/]*|$SOURCE_DIR|g' \
           -e 's|../../../CODE/[^/]*|$SOURCE_DIR|g' \
           -e 's|/Users/[^/]*/[^/]*/[^/]*/[^/]*|$SOURCE_DIR|g' \
           "$temp_file"
    
    # Replace specific filenames that include project name
    sed -i -e 's|analyze_yaml_|analyze_yaml_|g' \
           -e 's|catalog_yaml_|catalog_yaml_|g' \
           -e 's|query_yaml_|query_yaml_|g' \
           "$temp_file"
    
    # Additional replacement for script names that still have project names
    if [[ "$filename" == analyze_yaml_* ]]; then
        new_name="${file/analyze_yaml_/analyze_yaml_}"
        mv "$temp_file" "$new_name"
        echo "  Renamed to: $(basename "$new_name")"
    elif [[ "$filename" == catalog_yaml_* ]]; then
        new_name="${file/catalog_yaml_/catalog_yaml_}"
        mv "$temp_file" "$new_name"
        echo "  Renamed to: $(basename "$new_name")"
    elif [[ "$filename" == query_yaml_* ]]; then
        new_name="${file/query_yaml_/query_yaml_}"
        mv "$temp_file" "$new_name" 
        echo "  Renamed to: $(basename "$new_name")"
    else
        # Replace the original file
        mv "$temp_file" "$file"
    fi
}

# Sanitize all files
echo "Sanitizing all files..."
find "$SCRIPT_DIR" -type f -not -path "$SCRIPT_DIR/backups*/*" -not -path "$SCRIPT_DIR/sanitize*" | while read file; do
    sanitize_file "$file"
done

# Clean up the output directory
OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output"
if [ -d "$OUTPUT_PATH" ]; then
    echo "Removing output directory contents..."
    rm -rf "$OUTPUT_PATH"/*
    echo "✅ Cleaned output directory: $OUTPUT_PATH"
fi

# Remove temporary files
echo "Removing temporary files..."
find "$SCRIPT_DIR" -name "*.tmp" -delete

# Update any reference to old script names in other files
echo "Updating script references in remaining files..."
find "$SCRIPT_DIR" -type f -name "*.sh" -not -path "$SCRIPT_DIR/backups*/*" -not -path "$SCRIPT_DIR/sanitize*" | while read file; do
    sed -i -e 's|./analyze_yaml_|./analyze_yaml_|g' \
           -e 's|./catalog_yaml_|./catalog_yaml_|g' \
           -e 's|./query_yaml_|./query_yaml_|g' \
           "$file"
done

# Create a .gitignore file if it doesn't exist
GITIGNORE_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/.gitignore"
if [ ! -f "$GITIGNORE_PATH" ]; then
    echo "Creating .gitignore file..."
    cat > "$GITIGNORE_PATH" << EOF
# ICYAML generated files and backups
output/
backups*/
*.json
*_report.json
*_report.txt
*.yaml.tmp
*_fixed
*.bak
*.sanitized
*.tmp

# Editor and system files
.DS_Store
.idea/
.vscode/
*.swp
EOF
    echo "✅ Created .gitignore file at $GITIGNORE_PATH"
fi

echo "✅ Complete sanitization finished!"
echo ""
echo "Files have been thoroughly sanitized to remove ALL project references."
echo "The following changes were made:"
echo "  - Replaced ALL instances of project name with generic terms"
echo "  - Renamed script files to remove project references"
echo "  - Sanitized all paths and usernames"
echo "  - Updated script references in other files"
echo ""
echo "Original files have been backed up to: $BACKUP_DIR"
echo ""
echo "IMPORTANT: Review the sanitized files to ensure everything looks correct."
echo "Run the following command to verify no project references remain:"
echo ""
echo "  grep -r 'SOURCE_DIR' $SCRIPT_DIR --include='*.*' | grep -v 'sanitize'"
echo ""
echo "If there are issues, you can restore from the backups directory."

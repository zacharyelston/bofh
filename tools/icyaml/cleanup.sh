#!/bin/bash
# ICYAML Clean-up Script
# Removes all generated reports, output files, and other artifacts
# to ensure a clean repository before committing changes

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Output directory path
OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output"

echo "🧹 ICYAML Clean-up"
echo "=================="
echo "Cleaning up generated files and reports..."

# Create a .gitignore file if it doesn't exist
GITIGNORE_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/.gitignore"

if [ ! -f "$GITIGNORE_PATH" ]; then
    echo "Creating .gitignore file..."
    cat > "$GITIGNORE_PATH" << EOF
# ICYAML generated files
output/
*.json
*_report.json
*_report.txt
*.yaml.tmp
*_fixed
*.bak

# Editor and system files
.DS_Store
.idea/
.vscode/
*.swp
EOF
    echo "✅ Created .gitignore file at $GITIGNORE_PATH"
fi

# Clean up the output directory
if [ -d "$OUTPUT_PATH" ]; then
    echo "Removing output directory contents..."
    rm -rf "$OUTPUT_PATH"/*
    echo "✅ Cleaned output directory: $OUTPUT_PATH"
else
    echo "⚠️ Output directory not found: $OUTPUT_PATH"
fi

# Remove any temporary files in the tools directory
echo "Removing temporary files..."
find "$SCRIPT_DIR" -name "*.tmp" -delete
find "$SCRIPT_DIR" -name "*.bak" -delete
find "$SCRIPT_DIR" -name "*_fixed" -delete
find "$SCRIPT_DIR" -name "*.json" -delete

# Optional: Remove any Docker images that are no longer needed
# (uncomment if you want to clean Docker images too)
# echo "Cleaning up Docker images..."
# docker rmi icyaml:arm64 >/dev/null 2>&1 || true

echo "✅ Clean-up completed successfully!"
echo ""
echo "Your repository is now clean and ready for committing changes."
echo "Files removed:"
echo "  - All files in the output directory"
echo "  - Temporary and backup files"
echo "  - Fixed script versions"
echo "  - JSON report files"
echo ""
echo "Reminder: Always run this script before committing changes to the repository."

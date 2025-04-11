#!/bin/bash
# Install dependencies for ICYAML

echo "Installing ICYAML dependencies..."

# Check if pip is available
if command -v pip3 &> /dev/null; then
    PIP_CMD="pip3"
elif command -v pip &> /dev/null; then
    PIP_CMD="pip"
else
    echo "Error: pip not found. Please install Python and pip first."
    exit 1
fi

# Install PyYAML
echo "Installing PyYAML..."
$PIP_CMD install pyyaml

# Check if GraphViz is installed
if ! command -v dot &> /dev/null; then
    echo "GraphViz not found. This is optional but recommended for visualizations."
    echo "To install GraphViz:"
    echo "  On macOS: brew install graphviz"
    echo "  On Ubuntu: apt-get install graphviz"
    echo "  On Windows: Download from https://graphviz.org/download/"
fi

echo "Dependencies installed successfully!"
echo ""
echo "You can now run the ICYAML tools:"
echo "  ./find_outliers.sh --dir /path/to/yaml/files"
echo "  ./analyze_cfa_outliers.sh"
echo "  ./catalog_cfa_atlas.sh"

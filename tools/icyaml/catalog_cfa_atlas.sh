#!/bin/bash
# Script to catalog YAML trees in YAML configuration files directories

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="$PARENT_DIR/output"

# Auto-detect CFA path if not provided
if [ -z "$SOURCE_DIR" ]; then
    # Try to find it relative to the script directory
    if [ -d "$(dirname "$PARENT_DIR")/CODE/CFA" ]; then
        BASE_PATH="$(dirname "$PARENT_DIR")/CODE/$SOURCE_DIR"
    else
        # Fall back to a relative path
        BASE_PATH="$SOURCE_DIR/$SOURCE_DIR"
        echo "Warning: SOURCE_DIR not specified and couldn't be auto-detected."
        echo "Using relative path: $BASE_PATH"
    fi
else
    BASE_PATH="$SOURCE_DIR/$SOURCE_DIR"
fi

# Set output paths
JSON_OUTPUT="${OUTPUT_DIR}/atlas_catalog.json"
GRAPH_OUTPUT="${OUTPUT_DIR}/atlas_relationships.dot"
GRAPH_PNG="${OUTPUT_DIR}/atlas_relationships.png"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "ICYAML - \"I See YAML\""
echo "Cataloging YAML trees in ${BASE_PATH}..."

# Run the catalogger - using the enhanced version for better Kustomize support
python "${SCRIPT_DIR}/yaml_tree_catalogger_enhanced.py" "${BASE_PATH}" \
  --pattern "*" \
  --output "${JSON_OUTPUT}" \
  --graph "${GRAPH_OUTPUT}"

# Generate PNG if GraphViz is installed
if command -v dot &> /dev/null; then
    echo "Generating visualization..."
    dot -Tpng -o "${GRAPH_PNG}" "${GRAPH_OUTPUT}"
    echo "Visualization saved to ${GRAPH_PNG}"
    
    # Try to open the PNG file if possible
    if command -v open &> /dev/null; then
        echo "Opening visualization..."
        open "${GRAPH_PNG}"
    elif command -v xdg-open &> /dev/null; then
        echo "Opening visualization..."
        xdg-open "${GRAPH_PNG}"
    fi
else
    echo "GraphViz 'dot' command not found. Install GraphViz to generate visualizations."
    echo "On macOS: brew install graphviz"
    echo "On Ubuntu: apt-get install graphviz"
fi

echo "Catalog completed:"
echo "- JSON output: ${JSON_OUTPUT}"
echo "- Graph DOT file: ${GRAPH_OUTPUT}"
echo "- Graph PNG: ${GRAPH_PNG}"

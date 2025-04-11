#!/bin/bash
# Script to analyze YAML structure outliers in YAML configuration files directories using Docker

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set debugging flag (set to true to enable more verbose output)
DEBUG=${DEBUG:-false}

# Auto-detect SOURCE_DIR path if not provided
if [ -z "$SOURCE_DIR" ]; then
    # Try to find it relative to the script directory
    if [ -d "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/CODE/SOURCE_DIR" ]; then
        export SOURCE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/CODE/SOURCE_DIR"
    else
        # Fall back to a relative path
        export SOURCE_DIR="$SOURCE_DIR"
        echo "Warning: SOURCE_DIR not specified and couldn't be auto-detected."
        echo "Using relative path: $SOURCE_DIR"
        echo "Set SOURCE_DIR environment variable if needed."
    fi
fi

# Set output path if not provided
if [ -z "$OUTPUT_PATH" ]; then
    export OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output"
    mkdir -p "$OUTPUT_PATH"
fi

# Display message
echo "Analyzing YAML configuration files YAML structures for outliers using Docker..."
echo "Base path: $SOURCE_DIR"
echo "Output path: $OUTPUT_PATH"

# First ensure that Docker and Python are working
echo "Testing Docker container..."
"$SCRIPT_DIR/docker-run.sh" test

if [ $? -ne 0 ]; then
    echo "Error: Docker container test failed. Please fix Docker setup first."
    exit 1
fi

# Run the analyzer in Docker with DEBUG flag
export DEBUG=$DEBUG

# Run the analyzer in Docker
echo "Running analysis..."
"$SCRIPT_DIR/docker-run.sh" outliers \
    --dir /data/ENV/$SOURCE_DIR \
    --pattern "*" \
    --threshold 50 \
    --output /data/output/env_outliers.json

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to analyze YAML structures"
    echo "To get more debugging information, run:"
    echo "DEBUG=true $0"
    exit 1
fi

echo ""
echo "Analysis completed:"
echo "- JSON output: $OUTPUT_PATH/env_outliers.json"
echo ""
echo "Next steps:"
echo "1. Examine the outliers to identify patterns"
echo "2. Check if missing keys are intentional or errors"
echo "3. Use Docker to run queries for specific key values:"
echo "   ./docker-run.sh query --dir /data/ENV --query \"select name from metadata when kind is Deployment\""

#!/bin/bash
# A simplified Docker approach for ICYAML
# This script uses a simpler direct Docker run command rather than docker-compose

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    fi
fi

# Set output path if not provided
if [ -z "$OUTPUT_PATH" ]; then
    export OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output"
    mkdir -p "$OUTPUT_PATH"
fi

echo "Using paths:"
echo "  SOURCE_DIR: $SOURCE_DIR"
echo "  OUTPUT_PATH: $OUTPUT_PATH"

# Build a simple Docker image
echo "Building Docker image..."
docker build -t icyaml-simple "$SCRIPT_DIR"

# Run a test to see if Python works
echo "Testing Python in Docker..."
docker run --rm icyaml-simple python3 --version

# Now run the YAML outlier detection
echo "Running analysis..."
docker run --rm \
  -v "$SCRIPT_DIR:/app" \
  -v "$SOURCE_DIR:/data/ENV" \
  -v "$OUTPUT_PATH:/data/output" \
  icyaml-simple \
  python3 /app/yaml_outlier_detector.py \
    --dir /data/ENV/$SOURCE_DIR \
    --pattern "*" \
    --threshold 50 \
    --output /data/output/env_outliers.json

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Analysis failed"
    exit 1
fi

echo ""
echo "Analysis completed:"
echo "- JSON output: $OUTPUT_PATH/env_outliers.json"
echo ""
echo "Next steps:"
echo "1. Examine the outliers to identify patterns"
echo "2. Check if missing keys are intentional or errors"

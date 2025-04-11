#!/bin/bash
# Script to analyze parent path relationships in YAML files
# Part of the ICYAML toolkit

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for required SOURCE_DIR
if [ -z "$SOURCE_DIR" ]; then
    echo "ERROR: SOURCE_DIR environment variable not set."
    echo "Please set it to the directory containing your YAML files:"
    echo "  export SOURCE_DIR=/path/to/your/yaml/files"
    exit 1
fi

# Set output path if not provided
if [ -z "$OUTPUT_PATH" ]; then
    export OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output"
    mkdir -p "$OUTPUT_PATH"
fi

# Set default values
PATTERN="*"                 # Default file pattern
OUTPUT_FILE="yaml_parent_paths_report.json"  # Default output file

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    
    case $key in
        -p|--pattern)
            PATTERN="$2"
            shift
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./analyze_parent_paths.sh [options]"
            echo "Options:"
            echo "  -p, --pattern STR   File pattern to match (default: '*')"
            echo "  -o, --output FILE   Output file name (default: 'yaml_parent_paths_report.json')"
            exit 1
            ;;
    esac
done

# Display header
echo "🔍 ICYAML Parent Path Analyzer"
echo "============================"
echo "Source Directory: $SOURCE_DIR"
echo "File Pattern: $PATTERN"
echo "Output File: $OUTPUT_PATH/$OUTPUT_FILE"

# Run the analysis
echo "📊 Analyzing YAML path hierarchies..."

# Build Docker command to run the parent path analyzer
DOCKER_CMD="docker run --rm -v \"$SCRIPT_DIR:/app\" -v \"$SOURCE_DIR:/data/sourceDir\" -v \"$OUTPUT_PATH:/data/output\" icyaml:arm64 python3 /app/yaml_parent_path_analyzer.py --dir \"/data/sourceDir\" --pattern \"$PATTERN\" --output \"/data/output/$OUTPUT_FILE\""

# Execute the command
eval "$DOCKER_CMD"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "✅ Parent path analysis completed successfully!"
    echo "📊 Results saved to: $OUTPUT_PATH/$OUTPUT_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Review the report to understand the hierarchical structure of your YAML files"
    echo "2. Identify common parent paths that could be standardized"
    echo "3. Compare path structures across different types of resources"
else
    echo "❌ Parent path analysis failed"
    exit 1
fi

#!/bin/bash
# Script to analyze YAML consistency across files with detailed examples
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
OUTPUT_FILE="yaml_consistency_report.json"  # Default output file

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
            echo "Usage: ./analyze_consistency.sh [options]"
            echo "Options:"
            echo "  -p, --pattern STR   File pattern to match (default: '*')"
            echo "  -o, --output FILE   Output file name (default: 'yaml_consistency_report.json')"
            exit 1
            ;;
    esac
done

# Display header
echo "🔍 ICYAML Consistency Analyzer"
echo "============================="
echo "Source Directory: $SOURCE_DIR"
echo "File Pattern: $PATTERN"
echo "Output File: $OUTPUT_PATH/$OUTPUT_FILE"

# Run the analysis
echo "📊 Analyzing YAML consistency..."

# Build Docker command to run the consistency analyzer
DOCKER_CMD="docker run --rm -v \"$SCRIPT_DIR:/app\" -v \"$SOURCE_DIR:/data/sourceDir\" -v \"$OUTPUT_PATH:/data/output\" icyaml:arm64 python3 /app/yaml_consistency_analyzer.py --dir \"/data/sourceDir\" --pattern \"$PATTERN\" --output \"/data/output/$OUTPUT_FILE\""

# Execute the command
eval "$DOCKER_CMD"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "✅ Consistency analysis completed successfully!"
    echo "📊 Results saved to: $OUTPUT_PATH/$OUTPUT_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Review the detailed report for consistency issues"
    echo "2. Implement the recommended standardizations"
    echo "3. To focus on specific key patterns, use:"
    echo "   ./analyze_consistency.sh --pattern \"deployment-*\""
else
    echo "❌ Consistency analysis failed"
    exit 1
fi

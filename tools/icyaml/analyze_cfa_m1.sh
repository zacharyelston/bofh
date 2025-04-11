#!/bin/bash
# Script to analyze YAML structure outliers in CFA specifically for Apple Silicon Macs

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
SUBDIR="$SOURCE_DIR"  # Default subdirectory to analyze
PATTERN="*"                 # Default file pattern
THRESHOLD=50                # Default threshold percentage
OUTPUT_FILE="cfa_outliers.json"  # Default output file

# Display header
echo "🔍 ICYAML CFA Analyzer for Apple Silicon Macs"
echo "=============================================="
echo "Source Directory: $SOURCE_DIR"
echo "Subdirectory: $SUBDIR"
echo "Output Path: $OUTPUT_PATH"

# First run the platform-aware Docker setup test
"$SCRIPT_DIR/arm64_docker.sh" > /dev/null

# If the test was successful, run the outlier detection
if [ $? -eq 0 ]; then
    echo "🔍 Analyzing CFA YAML structures for outliers..."
    
    # Run the analysis
    "$SCRIPT_DIR/run_analysis.sh" \
        --source "$SOURCE_DIR" \
        --subdir "$SUBDIR" \
        --pattern "$PATTERN" \
        --threshold "$THRESHOLD" \
        --output "$OUTPUT_FILE"
    
    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "✅ Analysis completed successfully!"
        echo "📊 Results saved to: $OUTPUT_PATH/$OUTPUT_FILE"
        echo ""
        echo "Next steps:"
        echo "1. Examine the outliers to identify patterns"
        echo "2. Check if missing keys are intentional or errors"
        echo "3. Run queries to investigate specific patterns:"
        echo '   ./arm64_docker.sh query "select name from metadata when kind is Deployment"'
    else
        echo "❌ Analysis failed"
        exit 1
    fi
else
    echo "❌ Docker test failed. Cannot proceed with analysis."
    exit 1
fi
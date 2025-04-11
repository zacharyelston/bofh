#!/bin/bash
# Script to run YAML analysis on a specified source directory

# Set default values
SOURCE_DIR=""
SUBDIR=""
PATTERN="*.yaml"
THRESHOLD=50
OUTPUT_FILE="outliers.json"

# Display usage information
show_usage() {
    echo "Usage: ./run_analysis.sh [options]"
    echo ""
    echo "Options:"
    echo "  -s, --source DIR    Source directory containing YAML files (required)"
    echo "  -d, --subdir DIR    Subdirectory within the source to analyze (optional)"
    echo "  -p, --pattern STR   File pattern to match (default: '*.yaml')"
    echo "  -t, --threshold NUM Threshold percentage for common keys (default: 50)"
    echo "  -o, --output FILE   Output file for results (default: 'outliers.json')"
    echo "  -h, --help          Display this help message"
    echo ""
    echo "Example:"
    echo "  ./run_analysis.sh --source /path/to/yaml/files --subdir configs --pattern '*-config'"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    
    case $key in
        -s|--source)
            SOURCE_DIR="$2"
            shift
            shift
            ;;
        -d|--subdir)
            SUBDIR="$2"
            shift
            shift
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift
            shift
            ;;
        -t|--threshold)
            THRESHOLD="$2"
            shift
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check for required parameters
if [ -z "$SOURCE_DIR" ]; then
    echo "Error: Source directory is required"
    show_usage
    exit 1
fi

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Get absolute path to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set environment variable for the ARM64 Docker script
export SOURCE_DIR="$SOURCE_DIR"

# Run the analysis
if [ -z "$SUBDIR" ]; then
    # Run analysis on the root of the source directory
    "$SCRIPT_DIR/arm64_docker.sh" "" "$PATTERN" "$THRESHOLD" "$OUTPUT_FILE"
else
    # Run analysis on the specified subdirectory
    "$SCRIPT_DIR/arm64_docker.sh" "$SUBDIR" "$PATTERN" "$THRESHOLD" "$OUTPUT_FILE"
fi

# Display success message
if [ $? -eq 0 ]; then
    echo "✅ Analysis completed successfully!"
    
    # Display the output file path
    OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output/$OUTPUT_FILE"
    echo "📊 Results saved to: $OUTPUT_PATH"
fi

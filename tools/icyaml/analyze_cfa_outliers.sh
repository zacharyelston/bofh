#!/bin/bash
# Script to analyze YAML structure outliers in YAML configuration files directories

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
JSON_OUTPUT="${OUTPUT_DIR}/cfa_outliers.json"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Display the ASCII art logo
display_logo() {
    echo -e "\033[1;36m"
    echo "  _____  _______     __      _      __  __  _          ____        _   _ _               "
    echo " |_   _|/ ____\\ \\   / //\\   | |    |  \\/  || |        / __ \\      | | | (_)              "
    echo "   | | | |     \\ \\_/ //  \\  | |    | \\  / || |       | |  | |_   _| |_| |_  ___ _ __ ___ "
    echo "   | | | |      \\   // /\\ \\ | |    | |\\/| || |       | |  | | | | | __| | |/ _ \\ '__/ __|"
    echo "  _| |_| |____   | |/ ____ \\| |____| |  | || |____   | |__| | |_| | |_| | |  __/ |  \\__ \\"
    echo " |_____|\\_____|  |_/_/    \\_\\______|_|  |_||______|   \\____/ \\__,_|\\__|_|_|\\___|_|  |___/"
    echo -e "\033[0m"
    echo "  \"I see missing branches... outliers in the YAML trees...\""
    echo ""
}

# Parse command line arguments
parse_args() {
    THRESHOLD=50
    VERBOSE=""
    
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --threshold|-t)
                THRESHOLD="$2"
                shift 2
                ;;
            --verbose|-v)
                VERBOSE="--verbose"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: analyze_cfa_outliers.sh [--threshold N] [--verbose]"
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Display the logo
    display_logo
    
    # Parse command line arguments
    parse_args "$@"
    
    echo "Analyzing YAML configuration files YAML structures for outliers..."
    echo "Base path: ${BASE_PATH}"
    echo "Threshold: ${THRESHOLD}%"
    
    # Run the outlier detector - use python3 explicitly
    python3 "${SCRIPT_DIR}/yaml_outlier_detector.py" \
        --dir "${BASE_PATH}" \
        --pattern "*" \
        --threshold "${THRESHOLD}" \
        --output "${JSON_OUTPUT}" \
        ${VERBOSE}
    
    # Check if the command was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to analyze YAML structures"
        exit 1
    fi
    
    echo ""
    echo "Analysis completed:"
    echo "- JSON output: ${JSON_OUTPUT}"
    echo ""
    echo "Next steps:"
    echo "1. Examine the outliers to identify patterns"
    echo "2. Check if missing keys are intentional or errors"
    echo "3. Use 'icyaml query' to investigate specific key values"
    echo ""
    echo "To adjust the analysis threshold:"
    echo "  ./analyze_cfa_outliers.sh --threshold 75"
}

# Run the main function
main "$@"

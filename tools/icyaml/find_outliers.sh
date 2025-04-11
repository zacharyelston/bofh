#!/bin/bash
# ICYAML Outlier Detector - Find missing keys and structure outliers in YAML files

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="$PARENT_DIR/output"

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

# Display the usage information
display_usage() {
    echo "Usage: find_outliers.sh [options]"
    echo ""
    echo "Options:"
    echo "  --dir, -d         Directory containing YAML files to analyze (required)"
    echo "  --pattern, -p     File pattern to match (default: *)"
    echo "  --threshold, -t   Threshold percentage for common keys (default: 50)"
    echo "  --output, -o      Output file for results (JSON)"
    echo "  --verbose, -v     Enable verbose output"
    echo "  --help, -h        Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./find_outliers.sh --dir /path/to/yaml/files"
    echo "  ./find_outliers.sh --dir /path/to/yaml/files --threshold 75 --output results.json"
    echo "  ./find_outliers.sh --dir /path/to/kubernetes/manifests --pattern '*.yaml'"
    echo ""
}

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not found. Please install Python 3 and try again."
    echo "Alternatively, use the Docker version: ./docker-run.sh outliers"
    exit 1
fi

# Default output directory
mkdir -p "$OUTPUT_DIR"

# Run the outlier detector
run_outlier_detector() {
    # If no output file specified but we have a directory, use a default name
    if [[ "$*" != *"--output"* ]] && [[ "$*" != *"-o"* ]]; then
        if [[ "$*" == *"--dir"* ]] || [[ "$*" == *"-d"* ]]; then
            # Extract directory name for the default output filename
            dir_arg=$(echo "$*" | grep -oP '(?<=--dir )[^ ]+|(?<=-d )[^ ]+')
            dir_name=$(basename "$dir_arg")
            default_output="${OUTPUT_DIR}/${dir_name}_outliers.json"
            set -- "$@" "--output" "$default_output"
        fi
    fi
    
    python3 "${SCRIPT_DIR}/yaml_outlier_detector.py" "$@"
}

# Main function
main() {
    # Display the logo
    display_logo
    
    # Check if we have arguments
    if [ $# -eq 0 ]; then
        display_usage
        exit 0
    fi
    
    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        display_usage
        exit 0
    fi
    
    # Run the outlier detector
    run_outlier_detector "$@"
}

# Run the main function
main "$@"

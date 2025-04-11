#!/bin/bash
# Docker runner script for ICYAML tools

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Output directory is relative to the script directory
DEFAULT_OUTPUT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/output"

# Set debugging flag (set to true to enable more verbose output)
DEBUG=${DEBUG:-false}

# Display the ASCII art logo
display_logo() {
    echo -e "\033[1;36m"
    echo "  _____  _______     __      _      __  __  _       _____             _             "
    echo " |_   _|/ ____\\ \\   / //\\   | |    |  \\/  || |     |  __ \\           | |            "
    echo "   | | | |     \\ \\_/ //  \\  | |    | \\  / || |     | |  | | ___   ___| | _____ _ __ "
    echo "   | | | |      \\   // /\\ \\ | |    | |\\/| || |     | |  | |/ _ \\ / __| |/ / _ \\ '__|"
    echo "  _| |_| |____   | |/ ____ \\| |____| |  | || |____ | |__| | (_) | (__|   <  __/ |   "
    echo " |_____|\\_____|  |_/_/    \\_\\______|_|  |_||______|_____/ \\___/ \\___|_|\\_\\___|_|  "
    echo -e "\033[0m"
    echo "  \"I see YAML through containers... no dependency issues...\""
    echo ""
}

# Display the usage information
display_usage() {
    echo "Usage: docker-run.sh [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  build              Build the Docker image"
    echo "  scan               Run scan command with Docker"
    echo "  query              Run query command with Docker"
    echo "  outliers           Run outlier detection with Docker"
    echo "  analyze-ENV        Analyze YAML configuration files for outliers"
    echo "  catalog-ENV        Catalog YAML configuration files YAML files"
    echo "  shell              Start a shell in the container"
    echo "  test               Run tests to verify container functionality"
    echo "  help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./docker-run.sh build"
    echo "  ./docker-run.sh outliers --dir /data/ENV --threshold 50 --output /data/output/outliers.json"
    echo "  ./docker-run.sh analyze-ENV"
    echo "  ./docker-run.sh catalog-ENV"
    echo "  ./docker-run.sh query --dir /data/ENV --query \"select name from metadata when kind is Deployment\""
    echo "  ./docker-run.sh shell"
    echo "  ./docker-run.sh test"
    echo ""
    echo "Environment Variables:"
    echo "  SOURCE_DIR           Path to SOURCE_DIR code (default: auto-detected relative path)"
    echo "  OUTPUT_PATH        Path for output files (default: ../../../output relative to script)"
    echo "  DEBUG              Set to 'true' for more verbose debugging output"
    echo ""
}

# Build the Docker image
build_image() {
    echo "Building ICYAML Docker image..."
    
    # Use --no-cache to ensure a fresh build
    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Building with --no-cache for fresh build"
        docker-compose build --no-cache
    else
        docker-compose build
    fi
    
    # Verify the image was built
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image"
        exit 1
    fi
    
    echo "Docker image built successfully!"
}

# Run tests to verify container functionality
run_tests() {
    echo "Running tests to verify container functionality..."
    
    echo "Test 1: Check if Python is working"
    docker-compose run --rm icyaml python3 --version
    if [ $? -ne 0 ]; then
        echo "Error: Python is not working in the container"
        exit 1
    fi
    
    echo "Test 2: Check if YAML module is available"
    docker-compose run --rm icyaml python3 -c "import yaml; print('YAML module is working!')"
    if [ $? -ne 0 ]; then
        echo "Error: YAML module is not available in the container"
        exit 1
    fi
    
    echo "Test 3: Run test script"
    docker-compose run --rm icyaml python3 test_python.py
    if [ $? -ne 0 ]; then
        echo "Error: Test script failed"
        exit 1
    fi
    
    echo "All tests passed! Container is working properly."
}

# Run the Docker container with the specified command
run_container() {
    local command="$1"
    shift
    
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
    export OUTPUT_PATH="${OUTPUT_PATH:-$DEFAULT_OUTPUT_DIR}"
    
    # Make sure the output directory exists
    mkdir -p "$OUTPUT_PATH"
    
    echo "Using paths:"
    echo "  SOURCE_DIR: $SOURCE_DIR"
    echo "  OUTPUT_PATH: $OUTPUT_PATH"
    
    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Running command in container: $command $@"
        # Show Docker command that will be executed
        echo "DEBUG: docker-compose run --rm icyaml $command $@"
    fi
    
    # Run the container with the specified command
    docker-compose run --rm icyaml "$command" "$@"
    
    # Check if the command was successful
    local result=$?
    if [ $result -ne 0 ]; then
        echo "Error: Command failed with exit code $result"
        echo "Try running with DEBUG=true for more detailed output"
        if [ "$DEBUG" = "true" ]; then
            echo "DEBUG: Inspecting container state..."
            docker-compose run --rm icyaml ls -la /app
            docker-compose run --rm icyaml python3 --version || echo "Python not working!"
            docker-compose run --rm icyaml bash --version || echo "Bash not working!"
            echo "DEBUG: Environment variables:"
            docker-compose run --rm icyaml env
        fi
        exit $result
    fi
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
    
    # Parse the command
    command="$1"
    shift
    
    case "$command" in
        build)
            build_image
            ;;
        scan)
            run_container "python3" "yaml_tree_catalogger_enhanced.py" "$@"
            ;;
        query)
            run_container "python3" "yaml_query_engine.py" "$@"
            ;;
        outliers)
            run_container "python3" "yaml_outlier_detector.py" "$@"
            ;;
        analyze-ENV)
            run_container "bash" "analyze_yaml_outliers.sh" "$@"
            ;;
        catalog-ENV)
            run_container "bash" "catalog_yaml_atlas.sh" "$@"
            ;;
        shell)
            run_container "bash"
            ;;
        test)
            run_tests
            ;;
        help)
            display_usage
            ;;
        *)
            echo "Unknown command: $command"
            display_usage
            exit 1
            ;;
    esac
}

# Run the main function
main "$@"

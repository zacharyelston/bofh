#!/bin/bash
# Platform-aware Docker script for ICYAML
# Automatically detects Apple Silicon and configures Docker appropriately

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Auto-detect CFA path if not provided
if [ -z "$SOURCE_DIR" ]; then
    # Try to find it relative to the script directory
    if [ -d "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/CODE/CFA" ]; then
        export SOURCE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/CODE/CFA"
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

# Display info header
echo "🔍 ICYAML Platform-aware Docker Runner"
echo "======================================="

# Detect Apple Silicon
IS_APPLE_SILICON=false
if [ "$(uname)" == "Darwin" ]; then
    if [ "$(uname -m)" == "arm64" ]; then
        IS_APPLE_SILICON=true
        echo "📱 Detected Apple Silicon (M1/M2/M3 Mac)"
    else
        echo "🖥️ Detected Intel Mac"
    fi
else
    echo "💻 Detected non-Mac platform"
fi

# Build the Docker image with appropriate platform flag
echo "🔨 Building Docker image for your platform..."

if [ "$IS_APPLE_SILICON" = true ]; then
    # For Apple Silicon, we need to explicitly specify platform
    echo "   Using --platform=linux/arm64 for Apple Silicon compatibility"
    docker build --platform=linux/arm64 -t icyaml:platform-aware "$SCRIPT_DIR"
else
    # For Intel/AMD systems, we use the default platform
    docker build -t icyaml:platform-aware "$SCRIPT_DIR"
fi

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to build Docker image"
    exit 1
fi

echo "✅ Docker image built successfully!"

# Display usage information
display_usage() {
    echo "Usage: platform_docker.sh [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  test               Run a quick test to verify Docker functionality"
    echo "  outliers           Analyze YAML files for outliers"
    echo "  query              Run SQL-like queries on YAML files"
    echo "  scan               Scan and catalog YAML structures"
    echo "  shell              Open a shell in the container"
    echo "  help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./platform_docker.sh test"
    echo "  ./platform_docker.sh outliers --dir /data/cfa/$SOURCE_DIR --output /data/output/results.json"
    echo "  ./platform_docker.sh query --dir /data/cfa --query \"select name from metadata when kind is Deployment\""
    echo ""
}

# Run a test to verify Docker is working correctly
run_test() {
    echo "🧪 Running test to verify Docker functionality..."
    
    if [ "$IS_APPLE_SILICON" = true ]; then
        # Modified to use sh -c to execute python command through shell
        docker run --platform=linux/arm64 --rm icyaml:platform-aware sh -c "python3 --version"
    else
        docker run --rm icyaml:platform-aware sh -c "python3 --version"
    fi
    
    if [ $? -ne 0 ]; then
        echo "❌ Error: Python is not working in the container"
        exit 1
    fi
    
    echo "🧪 Testing YAML module..."
    if [ "$IS_APPLE_SILICON" = true ]; then
        # Modified to use sh -c to execute python command through shell
        docker run --platform=linux/arm64 --rm icyaml:platform-aware sh -c "python3 -c \"import yaml; print('YAML module is working!')\""
    else
        docker run --rm icyaml:platform-aware sh -c "python3 -c \"import yaml; print('YAML module is working!')\""
    fi
    
    if [ $? -ne 0 ]; then
        echo "❌ Error: YAML module is not available in the container"
        exit 1
    fi
    
    echo "✅ All tests passed! Container is working properly."
}

# Run a Docker command with platform awareness
run_docker_command() {
    local command="$1"
    shift
    
    echo "🚀 Running command: $command $@"
    
    if [ "$IS_APPLE_SILICON" = true ]; then
        # For Apple Silicon, include platform flag and use sh -c
        docker run --platform=linux/arm64 --rm \
            -v "$SCRIPT_DIR:/app" \
            -v "$SOURCE_DIR:/data/cfa" \
            -v "$OUTPUT_PATH:/data/output" \
            icyaml:platform-aware \
            sh -c "$command $@"
    else
        # For other platforms, run without platform flag
        docker run --rm \
            -v "$SCRIPT_DIR:/app" \
            -v "$SOURCE_DIR:/data/cfa" \
            -v "$OUTPUT_PATH:/data/output" \
            icyaml:platform-aware \
            sh -c "$command $@"
    fi
    
    # Check if the command was successful
    if [ $? -ne 0 ]; then
        echo "❌ Error: Command failed"
        exit 1
    fi
    
    echo "✅ Command completed successfully"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    display_usage
    exit 0
fi

# Process command
command="$1"
shift

case "$command" in
    test)
        run_test
        ;;
    outliers)
        run_docker_command "python3 /app/yaml_outlier_detector.py" "$@"
        ;;
    query)
        run_docker_command "python3 /app/yaml_query_engine.py" "$@"
        ;;
    scan)
        run_docker_command "python3 /app/yaml_tree_catalogger_enhanced.py" "$@"
        ;;
    shell)
        echo "🐚 Opening shell in container..."
        if [ "$IS_APPLE_SILICON" = true ]; then
            docker run --platform=linux/arm64 -it --rm \
                -v "$SCRIPT_DIR:/app" \
                -v "$SOURCE_DIR:/data/cfa" \
                -v "$OUTPUT_PATH:/data/output" \
                icyaml:platform-aware
        else
            docker run -it --rm \
                -v "$SCRIPT_DIR:/app" \
                -v "$SOURCE_DIR:/data/cfa" \
                -v "$OUTPUT_PATH:/data/output" \
                icyaml:platform-aware
        fi
        ;;
    help)
        display_usage
        ;;
    *)
        echo "❌ Unknown command: $command"
        display_usage
        exit 1
        ;;
esac

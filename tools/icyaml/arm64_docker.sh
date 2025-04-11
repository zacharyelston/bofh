#!/bin/bash
# ARM64-specific Docker script for ICYAML with configurable source directory

# Do not exit on any error immediately for better diagnostics
set +e

# Enable debug output
DEBUG=true

# Function for debug logging
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1"
    fi
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default paths
OUTPUT_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/output"
mkdir -p "$OUTPUT_PATH"

# Check for required SOURCE_DIR
if [ -z "$SOURCE_DIR" ]; then
    echo "ERROR: SOURCE_DIR environment variable not set."
    echo "Please set it to the directory containing your YAML files."
    echo "Example: export SOURCE_DIR=/path/to/your/yaml/files"
    exit 1
fi

echo "🔍 ICYAML ARM64 Docker Runner (M1/M2/M3 Mac)"
echo "=============================================="
echo "Source Directory: $SOURCE_DIR"
echo "Output Path: $OUTPUT_PATH"

# Build the Docker image
echo "🔨 Building Docker image for ARM64..."
debug_log "Running docker build command: docker build -f \"$SCRIPT_DIR/Dockerfile.arm64\" -t icyaml:arm64 \"$SCRIPT_DIR\""
docker build -f "$SCRIPT_DIR/Dockerfile.arm64" -t icyaml:arm64 "$SCRIPT_DIR"
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to build Docker image"
    exit 1
fi
echo "✅ Docker image built successfully!"

# Verify docker image details
debug_log "Checking docker image details:"
docker images icyaml:arm64

# Function to run a test
run_test() {
    echo "🧪 Testing Python in ARM64 container..."
    
    # Try running with platform flag first
    debug_log "Attempt 1: Running with platform flag"
    debug_log "Command: docker run --platform=linux/arm64 --rm icyaml:arm64 python3 --version"
    docker run --platform=linux/arm64 --rm icyaml:arm64 python3 --version
    PYTHON_TEST_RESULT=$?
    debug_log "Exit code: $PYTHON_TEST_RESULT"
    
    if [ $PYTHON_TEST_RESULT -ne 0 ]; then
        echo "❌ Warning: Python test with platform flag failed with exit code $PYTHON_TEST_RESULT"
        echo "Trying without platform flag..."
        
        # Try without platform flag
        debug_log "Attempt 2: Running without platform flag"
        debug_log "Command: docker run --rm icyaml:arm64 python3 --version"
        docker run --rm icyaml:arm64 python3 --version
        PYTHON_TEST_RESULT=$?
        debug_log "Exit code: $PYTHON_TEST_RESULT"
        
        if [ $PYTHON_TEST_RESULT -ne 0 ]; then
            echo "❌ Error: Python test without platform flag also failed with exit code $PYTHON_TEST_RESULT"
            echo "Trying with shell command..."
            
            # Try with shell command
            debug_log "Attempt 3: Running with shell command"
            debug_log "Command: docker run --rm icyaml:arm64 /bin/sh -c \"python3 --version\""
            docker run --rm icyaml:arm64 /bin/sh -c "python3 --version"
            PYTHON_TEST_RESULT=$?
            debug_log "Exit code: $PYTHON_TEST_RESULT"
            
            if [ $PYTHON_TEST_RESULT -ne 0 ]; then
                echo "❌ Error: All Python tests failed"
                
                # Try with bash instead of sh
                debug_log "Attempt 4: Running with bash command"
                debug_log "Command: docker run --rm icyaml:arm64 /bin/bash -c \"python3 --version\""
                docker run --rm icyaml:arm64 /bin/bash -c "python3 --version" 
                PYTHON_TEST_RESULT=$?
                debug_log "Exit code: $PYTHON_TEST_RESULT"
                
                if [ $PYTHON_TEST_RESULT -ne 0 ]; then
                    echo "❌ Error: All Python tests failed"
                    
                    # Final attempt: run ls to see what's in the container
                    debug_log "Final attempt: Running ls to see what's inside"
                    debug_log "Command: docker run --rm icyaml:arm64 ls -la /usr/local/bin/"
                    docker run --rm icyaml:arm64 ls -la /usr/local/bin/
                    LS_RESULT=$?
                    debug_log "Exit code: $LS_RESULT"
                    
                    # Check python symlinks
                    debug_log "Checking python symlinks"
                    debug_log "Command: docker run --rm icyaml:arm64 ls -la /usr/bin/python*"
                    docker run --rm icyaml:arm64 ls -la /usr/bin/python*
                    LS_SYMLINKS_RESULT=$?
                    debug_log "Exit code: $LS_SYMLINKS_RESULT"
                    
                    return 1
                else
                    echo "✅ Python test with bash command succeeded"
                    USE_BASH=true
                    USE_SHELL=true
                fi
            else
                echo "✅ Python test with shell command succeeded"
                USE_SHELL=true
            fi
        fi
    fi
    
    echo "🧪 Testing YAML module..."
    
    if [ "$USE_BASH" = true ]; then
        # Use bash command
        debug_log "Using bash for YAML test"
        debug_log "Command: docker run --rm icyaml:arm64 /bin/bash -c \"python3 -c \\\"import yaml; print('YAML module is working!')\\\"\""
        docker run --rm icyaml:arm64 /bin/bash -c "python3 -c \"import yaml; print('YAML module is working!')\""
    elif [ "$USE_SHELL" = true ]; then
        # Use shell command
        debug_log "Using shell for YAML test"
        debug_log "Command: docker run --rm icyaml:arm64 /bin/sh -c \"python3 -c \\\"import yaml; print('YAML module is working!')\\\"\""
        docker run --rm icyaml:arm64 /bin/sh -c "python3 -c \"import yaml; print('YAML module is working!')\""
    else
        # Try direct command
        debug_log "Using direct command for YAML test"
        debug_log "Command: docker run --rm icyaml:arm64 python3 -c \"import yaml; print('YAML module is working!')\""
        docker run --rm icyaml:arm64 python3 -c "import yaml; print('YAML module is working!')"
    fi
    
    YAML_TEST_RESULT=$?
    debug_log "YAML test exit code: $YAML_TEST_RESULT"
    
    if [ $YAML_TEST_RESULT -ne 0 ]; then
        echo "❌ Error: YAML module test failed with exit code $YAML_TEST_RESULT"
        return 1
    fi
    
    echo "✅ Docker container is working properly!"
    return 0
}

# Function to run outlier detection
run_outlier_detection() {
    local source_subdir="$1"
    local pattern="$2"
    local threshold="$3"
    local output_file="$4"
    
    if [ -z "$source_subdir" ]; then
        source_subdir="."  # Default to root of source directory
    fi
    
    if [ -z "$pattern" ]; then
        pattern="*.yaml"  # Default to all YAML files
    fi
    
    if [ -z "$threshold" ]; then
        threshold="50"  # Default threshold
    fi
    
    if [ -z "$output_file" ]; then
        output_file="outliers.json"  # Default output file
    fi
    
    echo "🧪 Running outlier detection on YAML structures..."
    echo "Source subdirectory: /data/sourceDir/$source_subdir"
    echo "Pattern: $pattern"
    echo "Threshold: $threshold"
    echo "Output file: /data/output/$output_file"
    
    # Check if source directory exists and is accessible
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "❌ Error: Source directory $SOURCE_DIR does not exist or is not accessible"
        return 1
    fi
    
    # Check if output directory exists and is writable
    if [ ! -d "$OUTPUT_PATH" ] || [ ! -w "$OUTPUT_PATH" ]; then
        echo "❌ Error: Output directory $OUTPUT_PATH does not exist or is not writable"
        return 1
    fi
    
    # Show files in source directory
    echo "Files in source directory:"
    ls -la "$SOURCE_DIR"
    
    # Construct the command based on test results
    DOCKER_CMD="docker run --rm"
    if [ "$USE_PLATFORM_FLAG" = true ]; then
        DOCKER_CMD="$DOCKER_CMD --platform=linux/arm64"
    fi
    
    DOCKER_CMD="$DOCKER_CMD -v \"$SCRIPT_DIR:/app\" -v \"$SOURCE_DIR:/data/sourceDir\" -v \"$OUTPUT_PATH:/data/output\" icyaml:arm64"
    
    if [ "$USE_BASH" = true ]; then
        debug_log "Using bash for outlier detection"
        DOCKER_CMD="$DOCKER_CMD /bin/bash -c \"python3 /app/yaml_outlier_detector.py --dir \\\"/data/sourceDir/$source_subdir\\\" --pattern \\\"$pattern\\\" --threshold \\\"$threshold\\\" --output \\\"/data/output/$output_file\\\"\""
    elif [ "$USE_SHELL" = true ]; then
        debug_log "Using shell for outlier detection"
        DOCKER_CMD="$DOCKER_CMD /bin/sh -c \"python3 /app/yaml_outlier_detector.py --dir \\\"/data/sourceDir/$source_subdir\\\" --pattern \\\"$pattern\\\" --threshold \\\"$threshold\\\" --output \\\"/data/output/$output_file\\\"\""
    else
        debug_log "Using direct command for outlier detection"
        DOCKER_CMD="$DOCKER_CMD python3 /app/yaml_outlier_detector.py --dir \"/data/sourceDir/$source_subdir\" --pattern \"$pattern\" --threshold \"$threshold\" --output \"/data/output/$output_file\""
    fi
    
    debug_log "Running command: $DOCKER_CMD"
    eval "$DOCKER_CMD"
    
    return $?
}

# Run the test
debug_log "Starting Docker container test"
run_test
TEST_RESULT=$?
debug_log "Test result: $TEST_RESULT"

if [ $TEST_RESULT -ne 0 ]; then
    echo "❌ Docker test failed. Cannot proceed with analysis."
    exit 1
fi

# Check if we have a subdirectory specified
if [ $# -ge 1 ]; then
    SOURCE_SUBDIR="$1"
    PATTERN="${2:-*.yaml}"
    THRESHOLD="${3:-50}"
    OUTPUT_FILE="${4:-outliers.json}"
    
    run_outlier_detection "$SOURCE_SUBDIR" "$PATTERN" "$THRESHOLD" "$OUTPUT_FILE"
else
    # If no arguments provided, run with defaults
    run_outlier_detection "" "*.yaml" "50" "outliers.json"
fi

ANALYSIS_RESULT=$?
debug_log "Analysis result: $ANALYSIS_RESULT"

# Check if successful
if [ $ANALYSIS_RESULT -eq 0 ]; then
    echo "✅ Analysis completed successfully!"
    echo "📊 Results saved to: $OUTPUT_PATH/outliers.json"
    echo ""
    echo "Next steps:"
    echo "1. Examine the outliers to identify patterns"
    echo "2. Check if missing keys are intentional or errors"
    echo "3. Run queries to investigate specific patterns:"
    echo '   ./arm64_docker.sh query "select name from metadata when kind is Deployment"'
    exit 0
else
    echo "❌ Analysis failed with exit code $ANALYSIS_RESULT"
    exit 1
fi
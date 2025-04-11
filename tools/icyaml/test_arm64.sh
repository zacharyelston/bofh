#!/bin/bash
# Test script for ARM64 Docker containers

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🧪 Testing ARM64 Docker container for Apple Silicon..."

# Build the ARM64-specific Docker image
echo "Building ARM64 Docker image..."
docker build -f "$SCRIPT_DIR/Dockerfile.arm64" -t icyaml:arm64test "$SCRIPT_DIR"

# Run a simple test
echo "Testing Python in the ARM64 container..."
docker run --rm icyaml:arm64test python3 --version

echo "If you see the Python version above, the test was successful!"

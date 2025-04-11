#!/bin/bash
# Test script for Docker container

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Testing Docker container..."

# First, build a fresh Docker image
echo "Building fresh Docker image..."
"$SCRIPT_DIR/docker-run.sh" build

echo "Running a simple Python command..."
docker-compose run --rm icyaml python3 -c "print('Python is working!')"

echo "Testing YAML module..."
docker-compose run --rm icyaml python3 -c "import yaml; print('YAML module is working!')"

echo "Testing shell access..."
docker-compose run --rm icyaml ls -la /app

echo "Test complete!"

#!/bin/bash
# analyze-directory.sh - A helper script for DISKVOYEUR
# Usage: ./analyze-directory.sh /path/to/directory

# Check if directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/directory"
  echo "This script will analyze the specified directory using DISKVOYEUR"
  exit 1
fi

# Get absolute path of the directory
TARGET_DIR=$(cd "$1" 2>/dev/null && pwd)

if [ -z "$TARGET_DIR" ]; then
  echo "Error: Directory '$1' does not exist or is not accessible"
  exit 1
fi

echo "Preparing to analyze directory: $TARGET_DIR"

# Create directories for input/output
mkdir -p ./data/input ./data/output

# Create a tarball of the target directory
echo "Creating tarball of the directory..."
cd "$TARGET_DIR" && tar -cf - . | tee ../target_directory.tar | tar -xf - -C "$(cd ..)/data/input"

# Run DISKVOYEUR analysis
echo "Running DISKVOYEUR analysis..."
docker-compose up diskvoyeur

# Run visualization
echo "Generating visualizations..."
docker-compose up diskvoyeur-viz

echo "Analysis complete!"
echo "Results are available in ./data/output"
echo "Open ./data/output/index.html in a web browser to view the visualizations"

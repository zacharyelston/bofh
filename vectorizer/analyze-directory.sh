#!/bin/bash
# analyze-directory.sh - A helper script for DISKVOYEUR
# Usage: ./analyze-directory.sh /path/to/directory

# Set strict error handling
set -e

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
  echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to print warning messages
print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to print error messages
print_error() {
  echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to clean up on exit
cleanup() {
  print_status "Cleaning up..."
  # Stop any running containers
  docker-compose down >/dev/null 2>&1 || true
  docker network rm diskvoyeur-network >/dev/null 2>&1 || true
}

# Register the cleanup function
trap cleanup EXIT

# Check if directory argument is provided
if [ -z "$1" ]; then
  print_error "Usage: $0 /path/to/directory"
  print_status "This script will analyze the specified directory using DISKVOYEUR"
  exit 1
fi

# Get absolute path of the directory
TARGET_DIR=$(cd "$1" 2>/dev/null && pwd)

if [ -z "$TARGET_DIR" ]; then
  print_error "Directory '$1' does not exist or is not accessible"
  exit 1
fi

# Get the script directory for absolute paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create log directory
mkdir -p "$SCRIPT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$SCRIPT_DIR/logs/run_${TIMESTAMP}.log"

# Start logging
print_status "DISKVOYEUR Analysis Run - $(date)"
print_status "Target directory: $TARGET_DIR"
print_status "Script directory: $SCRIPT_DIR"
print_status "----------------------------------------"

print_status "Preparing to analyze directory: $TARGET_DIR"

# Create directories for input/output with absolute paths
mkdir -p "$SCRIPT_DIR/data/input" "$SCRIPT_DIR/data/output"

# Clear input directory first to avoid mixing data
print_status "Clearing input directory..."
rm -rf "$SCRIPT_DIR/data/input"/*

# Create a tarball of the target directory and extract it to the input directory
print_status "Copying files to input directory..."
cd "$TARGET_DIR"
tar -cf - . | (cd "$SCRIPT_DIR/data/input" && tar -xf -) 2>&1 | tee -a "$LOG_FILE" || {
  print_error "Failed to copy files to input directory"
  exit 1
}

# Return to script directory for docker-compose
cd "$SCRIPT_DIR"

# Check if Docker is running
print_status "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running or not properly configured."
  print_error "Please start Docker Desktop and try again."
  exit 1
fi

# Ensure the Docker network exists
print_status "Setting up Docker network..."
docker network create diskvoyeur-network >/dev/null 2>&1 || true

# Force rebuild Docker images
print_status "Rebuilding Docker images..."
docker-compose build --no-cache diskvoyeur 2>&1 | tee -a "$LOG_FILE" || {
  print_error "Failed to build Docker images"
  exit 1
}

# Run DISKVOYEUR analysis with Docker
print_status "Running DISKVOYEUR analysis..."
docker-compose down -v 2>&1 | tee -a "$LOG_FILE" # Stop any running containers and remove volumes

# Remove any existing containers to prevent the ContainerConfig issue
docker rm -f diskvoyeur_analyzer diskvoyeur_visualizer 2>/dev/null || true

# Try running with different approach if force-recreate causes issues
docker-compose up diskvoyeur 2>&1 | tee -a "$LOG_FILE" || {
  print_warning "Standard docker-compose failed, trying alternative approach..."
  # Alternative approach: run the container directly
  docker run --rm \
    --name diskvoyeur_analyzer \
    -v "$SCRIPT_DIR/data/input:/data/input" \
    -v "$SCRIPT_DIR/data/output:/data/output" \
    -v "$SCRIPT_DIR/logs:/logs" \
    -e PYTHONPATH=/app \
    --network diskvoyeur-network \
    vectorizer_diskvoyeur analyze 2>&1 | tee -a "$LOG_FILE" || {
      print_error "Failed to run analysis container"
      exit 1
    }
}

# Check if analysis was successful by looking for the results file
if [ ! -f "$SCRIPT_DIR/data/output/analysis_results.json" ]; then
  print_warning "Analysis may have failed. Results file not found."
  print_warning "Check the logs for errors."
  
  # Check Docker logs for more details
  print_status "Checking Docker logs for more details..."
  docker logs diskvoyeur_analyzer 2>&1 | tee -a "$LOG_FILE"
else
  print_success "Analysis completed successfully!"
  
  # Run visualization
  print_status "Generating visualizations..."
  docker-compose build --no-cache diskvoyeur-viz 2>&1 | tee -a "$LOG_FILE" || {
    print_warning "Failed to build visualization Docker image"
  }
  
  # Remove any existing visualization container to prevent the ContainerConfig issue
  docker rm -f diskvoyeur_visualizer 2>/dev/null || true
  
  docker-compose up diskvoyeur-viz 2>&1 | tee -a "$LOG_FILE" || {
    print_warning "Standard docker-compose failed for visualization, trying alternative approach..."
    # Alternative approach: run the container directly
    docker run --rm \
      --name diskvoyeur_visualizer \
      -v "$SCRIPT_DIR/data/input:/data/input" \
      -v "$SCRIPT_DIR/data/output:/data/output" \
      -v "$SCRIPT_DIR/logs:/logs" \
      -e PYTHONPATH=/app \
      --network diskvoyeur-network \
      vectorizer_diskvoyeur-viz visualize 2>&1 | tee -a "$LOG_FILE" || {
        print_warning "Failed to run visualization container"
      }
  }
  
  if [ -f "$SCRIPT_DIR/data/output/index.html" ]; then
    print_success "Visualizations generated successfully!"
  else
    print_warning "Visualization generation may have failed. Check the logs for errors."
    docker logs diskvoyeur_visualizer 2>&1 | tee -a "$LOG_FILE"
  fi
fi

print_success "Analysis complete!"
print_status "Results are available in ./data/output"
print_status "Logs are available in ./logs"
print_status "Open ./data/output/index.html in a web browser to view the visualizations"

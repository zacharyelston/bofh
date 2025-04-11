#!/bin/bash
# Test Runner for BOFH Toolkit
# This script runs all test suites for the BOFH toolkit

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to print warning messages
print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to print error messages
print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOFH_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

print_status "Running BOFH test suite..."
print_status "BOFH root directory: $BOFH_ROOT"

# Check if unit test directory exists
if [ ! -d "$SCRIPT_DIR/unit" ]; then
  print_warning "Unit test directory not found. Creating empty directory."
  mkdir -p "$SCRIPT_DIR/unit"
fi

# Check if there are any test files
TEST_FILES=$(find "$SCRIPT_DIR" -name "*_test.sh" -o -name "test_*.sh" -o -name "*_test.py" -o -name "test_*.py")
if [ -z "$TEST_FILES" ]; then
  print_warning "No test files found. Test suite is still under development."
  print_warning "This is a placeholder for future test implementation."
  exit 0
fi

# Run shell-based tests
print_status "Running shell-based tests..."
for test in $(find "$SCRIPT_DIR" -name "*_test.sh" -o -name "test_*.sh"); do
  print_status "Running test: $test"
  bash "$test"
done

# Run Python-based tests
print_status "Running Python-based tests..."
for test in $(find "$SCRIPT_DIR" -name "*_test.py" -o -name "test_*.py"); do
  print_status "Running test: $test"
  python3 "$test"
done

print_success "All tests completed."

#!/bin/bash
# BOFH Test Runner

# Set strict error handling
set -e

# Get the test directory
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOFH_ROOT="$( cd "$TEST_DIR/.." && pwd )"

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

# Function to print warning messages
print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to print error messages
print_error() {
  echo -e "${RED}[FAIL]${NC} $1"
}

# Function to run all tests in a directory
run_tests_in_dir() {
  local test_dir="$1"
  local test_count=0
  local pass_count=0
  
  print_status "Running tests in $test_dir"
  
  # Find all test scripts
  for test_script in $(find "$test_dir" -name "test_*.sh" -type f); do
    print_status "Running test: $test_script"
    
    # Run the test
    if bash "$test_script"; then
      print_success "Test passed: $test_script"
      ((pass_count++))
    else
      print_error "Test failed: $test_script"
    fi
    
    ((test_count++))
  done
  
  print_status "Completed $test_count tests in $test_dir. $pass_count passed."
  
  return 0
}

# Run unit tests
run_tests_in_dir "$TEST_DIR/unit"

# Run integration tests
run_tests_in_dir "$TEST_DIR/integration"

print_status "All tests completed"

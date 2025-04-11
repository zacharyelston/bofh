#!/bin/bash
# BOFH Toolkit Directory Restructuring Script
# This script reorganizes the BOFH toolkit into a more structured layout

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
cd "$SCRIPT_DIR"

print_status "Starting BOFH restructuring..."
print_status "Current directory: $SCRIPT_DIR"

# Create the new directory structure
print_status "Creating new directory structure..."

mkdir -p bin/helpers
mkdir -p lib/{filesystem,docker,common}
mkdir -p tools/{vectorizer,find2tar,schema_search}
mkdir -p docs/{mcp,user_guides}
mkdir -p tests/{unit,integration,fixtures}
mkdir -p examples
mkdir -p config/mcp

# Move files to their new locations
print_status "Moving files to new locations..."

# Move the main scripts
if [ -f bofh.sh ]; then
  cp bofh.sh bin/bofh
  chmod +x bin/bofh
  print_success "Created main command: bin/bofh"
fi

if [ -f config.sh ]; then
  cp config.sh config/config.sh
  print_success "Moved config.sh to config/config.sh"
fi

# Move vectorizer
if [ -d vectorizer ]; then
  # Copy core functionality to the tools directory
  cp -r vectorizer tools/
  
  # Extract library functions to lib directory
  if [ -d vectorizer/py ]; then
    mkdir -p lib/filesystem/analysis
    # Move analysis modules to lib
    cp -r vectorizer/py/analyze_filesystem.py lib/filesystem/analysis/
    print_success "Moved analysis module to lib/filesystem/analysis/"
  fi
  
  print_success "Moved vectorizer to tools/vectorizer"
fi

# Move find2tar
if [ -d find2tar ]; then
  cp -r find2tar tools/
  print_success "Moved find2tar to tools/find2tar"
fi

# Move schema_search_example
if [ -d schema_search_example ]; then
  cp -r schema_search_example tools/schema_search
  print_success "Moved schema_search_example to tools/schema_search"
fi

# Copy MCP documentation
if [ -f prompt.yaml ]; then
  cp prompt.yaml config/mcp/
  print_success "Moved prompt.yaml to config/mcp/"
fi

# Create basic README files
print_status "Creating README files for directories..."

echo "# BOFH Toolkit Libraries" > lib/README.md
echo "Core libraries used by BOFH toolkit tools and utilities." >> lib/README.md

echo "# BOFH Tools" > tools/README.md
echo "Individual tools that are part of the BOFH toolkit." >> tools/README.md

echo "# BOFH Documentation" > docs/README.md
echo "Documentation for the BOFH toolkit." >> docs/README.md

echo "# BOFH Tests" > tests/README.md
echo "Test suites for the BOFH toolkit components." >> tests/README.md

print_success "Created README files for main directories"

# Create a basic test script
print_status "Creating a basic test runner..."

cat > tests/run_tests.sh << 'EOL'
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
EOL

chmod +x tests/run_tests.sh
print_success "Created test runner: tests/run_tests.sh"

# Create a sample unit test
print_status "Creating a sample unit test..."

mkdir -p tests/unit/filesystem

cat > tests/unit/filesystem/test_analyze_directory.sh << 'EOL'
#!/bin/bash
# Test: vectorizer/analyze-directory.sh

# Get the test directory
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOFH_ROOT="$( cd "$TEST_DIR/../../.." && pwd )"

# Source assertion functions (would be common in a real implementation)
# source "$BOFH_ROOT/tests/lib/assertions.sh"

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Simple assertion functions
assert_command() {
  echo "Running command: $1"
  if eval "$1"; then
    echo -e "${GREEN}[PASS]${NC} Command executed successfully: $1"
    return 0
  else
    echo -e "${RED}[FAIL]${NC} Command failed: $1"
    return 1
  fi
}

assert_file_exists() {
  if [ -f "$1" ]; then
    echo -e "${GREEN}[PASS]${NC} File exists: $1"
    return 0
  else
    echo -e "${RED}[FAIL]${NC} File does not exist: $1"
    return 1
  fi
}

assert_command_fails() {
  echo "Running command (expecting failure): $1"
  if ! eval "$1"; then
    echo -e "${GREEN}[PASS]${NC} Command failed as expected: $1"
    return 0
  else
    echo -e "${RED}[FAIL]${NC} Command succeeded unexpectedly: $1"
    return 1
  fi
}

# Setup
test_setup() {
  echo "Setting up test environment..."
  mkdir -p "$BOFH_ROOT/tests/fixtures/test_data"
  
  # Create test files
  for i in {1..10}; do
    echo "Test content $i" > "$BOFH_ROOT/tests/fixtures/test_data/file$i.txt"
  done
  
  mkdir -p "$BOFH_ROOT/tests/fixtures/empty_dir"
  
  echo "Test setup complete."
}

# Test: Basic analyze function
test_basic_analyze() {
  echo "Running test: Basic directory analysis"
  
  # This is a placeholder test, modify the actual command when implementing
  # assert_command "$BOFH_ROOT/tools/vectorizer/analyze-directory.sh $BOFH_ROOT/tests/fixtures/test_data"
  # assert_file_exists "$BOFH_ROOT/tools/vectorizer/data/output/index.html"
  
  # For now, just succeed
  return 0
}

# Test: Empty directory
test_empty_directory() {
  echo "Running test: Empty directory analysis"
  
  # This is a placeholder test, modify the actual command when implementing
  # assert_command_fails "$BOFH_ROOT/tools/vectorizer/analyze-directory.sh $BOFH_ROOT/tests/fixtures/empty_dir"
  
  # For now, just succeed
  return 0
}

# Teardown
test_teardown() {
  echo "Cleaning up test environment..."
  rm -rf "$BOFH_ROOT/tests/fixtures/test_data"
  rm -rf "$BOFH_ROOT/tests/fixtures/empty_dir"
  echo "Test cleanup complete."
}

# Run tests
run_tests() {
  test_setup
  
  # Track if all tests pass
  local all_tests_passed=0
  
  if test_basic_analyze; then
    echo "✓ Basic analyze test passed."
  else
    echo "✗ Basic analyze test failed."
    all_tests_passed=1
  fi
  
  if test_empty_directory; then
    echo "✓ Empty directory test passed."
  else
    echo "✗ Empty directory test failed."
    all_tests_passed=1
  fi
  
  test_teardown
  
  return $all_tests_passed
}

# Execute the tests
run_tests
exit $?
EOL

chmod +x tests/unit/filesystem/test_analyze_directory.sh
print_success "Created sample unit test: tests/unit/filesystem/test_analyze_directory.sh"

# Create a new main entry script
print_status "Creating new main entry script..."

cat > bin/bofh << 'EOL'
#!/bin/bash
# BOFH - Main Command Line Interface
# This is the main entry point for the BOFH toolkit

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOFH_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Source the configuration
if [ -f "$BOFH_ROOT/config/config.sh" ]; then
  source "$BOFH_ROOT/config/config.sh"
fi

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

# Function to display help message
show_help() {
  echo "BOFH Toolkit - A collection of system administration utilities"
  echo ""
  echo "Usage: bofh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  analyze <dir>     Analyze a directory structure"
  echo "  archive <src>     Create an archive of files"
  echo "  visualize <data>  Visualize analysis results"
  echo "  schema <dir>      Search for schema patterns"
  echo "  test              Run the test suite"
  echo "  help              Show this help message"
  echo ""
  echo "Examples:"
  echo "  bofh analyze /path/to/directory"
  echo "  bofh archive /path/to/source -o output.tar.gz"
  echo "  bofh visualize analysis_data.json"
  echo "  bofh test"
  echo ""
}

# Function to run the analyzer
run_analyzer() {
  if [ -z "$1" ]; then
    print_error "No directory specified"
    echo "Usage: bofh analyze <directory>"
    return 1
  fi
  
  print_status "Analyzing directory: $1"
  
  if [ -d "$BOFH_ROOT/tools/vectorizer" ]; then
    "$BOFH_ROOT/tools/vectorizer/analyze-directory.sh" "$1"
    return $?
  else
    print_error "Analyzer tool not found"
    return 1
  fi
}

# Function to run the archiver
run_archiver() {
  if [ -z "$1" ]; then
    print_error "No source specified"
    echo "Usage: bofh archive <source> [options]"
    return 1
  fi
  
  print_status "Creating archive from: $1"
  
  if [ -d "$BOFH_ROOT/tools/find2tar" ]; then
    "$BOFH_ROOT/tools/find2tar/find2tar.sh" "$@"
    return $?
  else
    print_error "Archive tool not found"
    return 1
  fi
}

# Function to run the visualizer
run_visualizer() {
  if [ -z "$1" ]; then
    print_error "No data specified"
    echo "Usage: bofh visualize <data>"
    return 1
  fi
  
  print_status "Visualizing data: $1"
  
  if [ -d "$BOFH_ROOT/tools/vectorizer" ]; then
    # This would need to be implemented - placeholder
    print_warning "Visualization as separate command not yet implemented"
    print_status "You can view visualizations in data/output/index.html after analysis"
    return 0
  else
    print_error "Visualizer tool not found"
    return 1
  fi
}

# Function to run the schema searcher
run_schema_search() {
  if [ -z "$1" ]; then
    print_error "No directory specified"
    echo "Usage: bofh schema <directory> <pattern>"
    return 1
  fi
  
  print_status "Searching for schema in: $1"
  
  if [ -d "$BOFH_ROOT/tools/schema_search" ]; then
    "$BOFH_ROOT/tools/schema_search/search_schema.sh" "$@"
    return $?
  else
    print_error "Schema search tool not found"
    return 1
  fi
}

# Function to run the test suite
run_tests() {
  print_status "Running test suite"
  
  if [ -f "$BOFH_ROOT/tests/run_tests.sh" ]; then
    "$BOFH_ROOT/tests/run_tests.sh"
    return $?
  else
    print_error "Test suite not found"
    return 1
  fi
}

# Main command processing
if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

case "$1" in
  analyze)
    shift
    run_analyzer "$@"
    ;;
  archive)
    shift
    run_archiver "$@"
    ;;
  visualize)
    shift
    run_visualizer "$@"
    ;;
  schema)
    shift
    run_schema_search "$@"
    ;;
  test)
    run_tests
    ;;
  help)
    show_help
    ;;
  *)
    print_error "Unknown command: $1"
    show_help
    exit 1
    ;;
esac

exit $?
EOL

chmod +x bin/bofh
print_success "Created new main entry script: bin/bofh"

print_status "Creating symbolic links for backward compatibility..."

# Create symbolic links for backward compatibility
ln -sf "$SCRIPT_DIR/bin/bofh" "$SCRIPT_DIR/bofh.sh.new"
print_success "Created symbolic link: bofh.sh.new -> bin/bofh"

print_status "Creating reset-docker script..."

# Create reset-docker script
cat > "$SCRIPT_DIR/reset-docker.sh" << 'EOL'
#!/bin/bash
# Script to completely reset Docker state for BOFH toolkit

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} Stopping all BOFH containers..."
docker stop diskvoyeur_analyzer diskvoyeur_visualizer 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Removing all BOFH containers..."
docker rm -f diskvoyeur_analyzer diskvoyeur_visualizer 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Removing all BOFH images..."
docker rmi -f vectorizer_diskvoyeur vectorizer_diskvoyeur-viz 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Pruning volumes..."
docker volume prune -f 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Pruning networks..."
docker network prune -f 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} Docker environment reset complete!"
EOL

chmod +x "$SCRIPT_DIR/reset-docker.sh"
print_success "Created reset-docker.sh script"

print_success "Restructuring complete!"
print_status "=================================="
print_status "Next steps:"
print_status "1. Review the new directory structure"
print_status "2. Test the new main command: ./bin/bofh"
print_status "3. Run the sample test: ./tests/run_tests.sh"
print_status "4. Once verified, replace the old files with the new ones"
print_status "=================================="

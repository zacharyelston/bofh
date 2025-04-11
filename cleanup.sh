#!/bin/bash
# BOFH Repository Cleanup Script
# This script performs various cleanup operations on the BOFH repository

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

print_status "Starting BOFH repository cleanup..."
print_status "Working in directory: $SCRIPT_DIR"
print_status "----------------------------------------"

# Step 1: Remove duplicate files
print_status "Removing duplicate files..."
rm -f "$SCRIPT_DIR/tools/vectorizer/analyze-directory.sh.new"
rm -f "$SCRIPT_DIR/tools/vectorizer/Dockerfile.new"
print_success "Duplicate files removed."

# Step 2: Standardize tool scripts
print_status "Creating missing directories according to README structure..."
mkdir -p "$SCRIPT_DIR/lib/filesystem/analysis"
mkdir -p "$SCRIPT_DIR/config/mcp"
mkdir -p "$SCRIPT_DIR/tests/unit"
print_success "Directory structure updated."

# Step 3: Fix find2tar script references 
print_status "Fixing script references in main script..."
# Find the reference to find2tar.sh which should be mcp_directory_scanner.sh
sed -i.bak 's/find2tar.sh/mcp_directory_scanner.sh/g' "$SCRIPT_DIR/bin/bofh"
print_success "Script references fixed."

# Step 4: Move prompt.yaml to the correct location
print_status "Moving prompt.yaml to the correct location..."
if [ -f "$SCRIPT_DIR/prompt.yaml" ]; then
  mkdir -p "$SCRIPT_DIR/config/mcp"
  cp "$SCRIPT_DIR/prompt.yaml" "$SCRIPT_DIR/config/mcp/prompt.yaml"
fi
print_success "Prompt file structure standardized."

# Step 5: Create missing run_tests.sh
print_status "Creating test runner script..."
mkdir -p "$SCRIPT_DIR/tests"
cat > "$SCRIPT_DIR/tests/run_tests.sh" << 'EOL'
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
EOL
chmod +x "$SCRIPT_DIR/tests/run_tests.sh"
print_success "Test runner script created."

# Step 6: Update README to document reset-docker.sh
print_status "Updating README to document reset-docker.sh..."
cat >> "$SCRIPT_DIR/README.md" << 'EOL'

## Docker Reset

If you encounter ContainerConfig errors or other Docker-related issues, you can reset the Docker environment with:

```bash
./reset-docker.sh
```

This script will:
1. Stop all BOFH containers
2. Remove all BOFH containers
3. Remove all BOFH images
4. Prune volumes
5. Prune networks

This provides a clean state to rebuild the Docker environment.
EOL
print_success "README updated with Docker reset documentation."

# Step 7: Create a requirements.txt file
print_status "Creating requirements.txt file..."
cat > "$SCRIPT_DIR/requirements.txt" << 'EOL'
# BOFH Toolkit Python Dependencies

# Core data analysis
numpy>=1.20.0
pandas>=1.3.0
scikit-learn>=1.0.0

# Visualization 
matplotlib>=3.4.0
seaborn>=0.11.0
plotly>=5.0.0

# Network analysis
networkx>=2.6.0
python-louvain>=0.16
umap-learn>=0.5.0
EOL
print_success "Requirements file created."

# Final summary
print_success "BOFH repository cleanup completed successfully!"
print_status "The following actions were performed:"
print_status "- Removed duplicate files"
print_status "- Updated directory structure to match README"
print_status "- Fixed script references"
print_status "- Standardized configuration file locations"
print_status "- Created test runner script"
print_status "- Updated documentation for reset-docker.sh"
print_status "- Created requirements.txt file"
print_status "----------------------------------------"
print_status "You may want to review the TODO.md file to prioritize remaining tasks."
print_status "To run the test suite (once implemented), use: ./tests/run_tests.sh"
print_status "To reset the Docker environment, use: ./reset-docker.sh"

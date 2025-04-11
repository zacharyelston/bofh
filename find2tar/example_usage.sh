#!/bin/bash

# MCP Directory Processing Tools - Example Usage
# This script demonstrates the various tools for directory and archive processing

echo "==============================================="
echo "MCP Directory Processing Tools - Examples"
echo "ModelContextProtocol Directory Handling Examples"
echo "==============================================="

# Set up example directory structure
setup_examples() {
    echo "Setting up example directories and files..."
    
    # Create example directory structure
    mkdir -p example/dir1/subdir1
    mkdir -p example/dir2/subdir2
    
    # Create example files
    echo "Example content 1" > example/file1.txt
    echo "Example content 2" > example/dir1/file2.txt
    echo "Example content 3" > example/dir1/subdir1/file3.txt
    echo "Example content 4" > example/dir2/file4.txt
    echo "Example content 5" > example/dir2/subdir2/file5.txt
    
    # Create example JavaScript file
    cat > example/script.js << 'EOF'
function hello() {
    console.log("Hello, world!");
}
hello();
EOF
    
    # Create example tar archive
    tar -cf example/archive.tar example/
    
    # Create example tar.gz archive
    tar -czf example/archive.tar.gz example/
    
    echo "Example setup complete."
    echo ""
}

# Example 1: Using directory_tree_reader.js
example_1() {
    echo "Example 1: Using directory_tree_reader.js"
    echo "----------------------------------------"
    
    echo "Reading directory structure (text output):"
    node directory_tree_reader.js example/
    
    echo ""
    echo "Reading directory structure (JSON output):"
    node directory_tree_reader.js example/ --json
    
    echo ""
    echo "Reading directory structure with max depth:"
    node directory_tree_reader.js example/ --max-depth=1
    
    echo ""
}

# Example 2: Using tar_parser.js
example_2() {
    echo "Example 2: Using tar_parser.js"
    echo "-----------------------------"
    
    echo "Listing tar archive contents:"
    node tar_parser.js example/archive.tar
    
    echo ""
    echo "Listing tar archive contents (JSON output):"
    node tar_parser.js example/archive.tar --json
    
    echo ""
    echo "Extracting specific files from tar archive:"
    node tar_parser.js example/archive.tar --extract=script.js
    
    echo ""
}

# Example 3: Using mcp_directory_scanner.sh
example_3() {
    echo "Example 3: Using mcp_directory_scanner.sh"
    echo "---------------------------------------"
    
    echo "Scanning directory structure:"
    ./mcp_directory_scanner.sh example/
    
    echo ""
    echo "Scanning directory with statistics:"
    ./mcp_directory_scanner.sh --stats example/
    
    echo ""
    echo "Processing tar archive:"
    ./mcp_directory_scanner.sh example/archive.tar.gz
    
    echo ""
    echo "Extracting specific files from archive:"
    ./mcp_directory_scanner.sh --extract=.txt example/archive.tar.gz
    
    echo ""
    echo "Filtering by file type:"
    ./mcp_directory_scanner.sh --type=js example/
    
    echo ""
}

# Example 4: Performance comparison
example_4() {
    echo "Example 4: Performance comparison"
    echo "-------------------------------"
    
    echo "Timing directory scan with find (baseline):"
    time find example/ -type f | wc -l
    
    echo ""
    echo "Timing directory scan with directory_tree_reader.js:"
    time node directory_tree_reader.js example/ > /dev/null
    
    echo ""
    echo "Timing directory scan with mcp_directory_scanner.sh:"
    time ./mcp_directory_scanner.sh example/ > /dev/null
    
    echo ""
}

# Example 5: Error handling and validation
example_5() {
    echo "Example 5: Error handling and validation"
    echo "-------------------------------------"
    
    echo "Attempting to process non-existent directory:"
    ./mcp_directory_scanner.sh non_existent_directory/
    
    echo ""
    echo "Attempting to process non-existent archive:"
    node tar_parser.js non_existent_archive.tar
    
    echo ""
    echo "Processing invalid file as archive:"
    node tar_parser.js example/file1.txt
    
    echo ""
}

# Main execution
echo "Preparing examples..."
setup_examples

# Make scripts executable
chmod +x mcp_directory_scanner.sh

# Run examples
echo "Running examples..."
example_1
example_2
example_3
example_4
example_5

echo "Examples completed."
#!/bin/bash

# MCP Batch Processing System - Example Setup
# This script creates a sample project structure and demonstrates
# the usage of the MCP batch processing tools.

echo "======================================================"
echo "MCP Batch Processing System - Example Setup"
echo "ModelContextProtocol File Batch Processing Demonstration"
echo "======================================================"

# Create example project structure
setup_example_project() {
  echo "Setting up example project structure..."
  
  # Create directories
  mkdir -p example_project
  mkdir -p example_project/src
  mkdir -p example_project/docs
  mkdir -p example_project/tests
  mkdir -p example_project/data
  mkdir -p example_project/config
  mkdir -p example_project/node_modules  # This will be excluded
  mkdir -p example_project/.git          # This will be excluded
  
  # Create example files with different timestamps
  
  # Recent files (will be included)
  echo "Creating recent files..."
  
  # Main code files
  cat > example_project/src/main.js << EOF
/**
 * MCP Test Project - Main Module
 */
const config = require('../config/config.json');

function initialize() {
  console.log('Initializing application with config:', config);
  return true;
}

function processData(data) {
  // Process the data
  return data.map(item => item * 2);
}

module.exports = {
  initialize,
  processData
};
EOF

  cat > example_project/src/utils.js << EOF
/**
 * MCP Test Project - Utility Functions
 */
function formatDate(date) {
  return date.toISOString().split('T')[0];
}

function generateId() {
  return Math.random().toString(36).substring(2, 15);
}

module.exports = {
  formatDate,
  generateId
};
EOF

  # Documentation file
  cat > example_project/docs/README.md << EOF
# MCP Test Project

This is a sample project used to demonstrate the MCP batch processing system.

## Features

- Collects recently modified files
- Packages them into a single archive
- Processes them as a unified stream

## Usage

See the main documentation for details.
EOF

  # Configuration file
  cat > example_project/config/config.json << EOF
{
  "name": "mcp-test-project",
  "version": "1.0.0",
  "settings": {
    "maxItems": 100,
    "timeout": 30000,
    "debug": true
  }
}
EOF

  # Data file
  cat > example_project/data/sample.csv << EOF
id,name,value
1,Alpha,10.5
2,Beta,20.3
3,Gamma,15.7
4,Delta,8.2
5,Epsilon,12.1
EOF

  # Test file
  cat > example_project/tests/main.test.js << EOF
/**
 * MCP Test Project - Tests
 */
const main = require('../src/main');
const utils = require('../src/utils');

describe('Main module', () => {
  test('initialize returns true', () => {
    expect(main.initialize()).toBe(true);
  });
  
  test('processData doubles values', () => {
    const input = [1, 2, 3];
    const expected = [2, 4, 6];
    expect(main.processData(input)).toEqual(expected);
  });
});
EOF

  # Create older files (modified timestamps will be adjusted)
  echo "Creating older files (will be excluded by default)..."
  
  cat > example_project/HISTORY.md << EOF
# Version History

## v1.0.0 - Initial Release
- Basic functionality
- Config system
- Data processing

## v0.9.0 - Beta
- Feature testing
- Bug fixes
EOF

  cat > example_project/docs/ARCHITECTURE.md << EOF
# System Architecture

This document describes the high-level architecture of the system.

## Components
- Main module
- Utility functions
- Configuration
- Data processing
EOF

  # Set older files to have older timestamps
  touch -d "10 days ago" example_project/HISTORY.md
  touch -d "7 days ago" example_project/docs/ARCHITECTURE.md
  
  # Create a node_modules file (should be excluded)
  cat > example_project/node_modules/package.json << EOF
{
  "name": "excluded-package",
  "private": true
}
EOF

  # Create a git file (should be excluded)
  mkdir -p example_project/.git/refs
  touch example_project/.git/HEAD
  
  echo "Example project setup complete."
}

# Demo for the shell script implementation
demo_shell_script() {
  echo ""
  echo "======================================================"
  echo "DEMO: Shell Script Implementation (mcp_batch_processor.sh)"
  echo "======================================================"
  
  # Make script executable
  chmod +x mcp_batch_processor.sh
  
  echo "1. Collecting files modified in the last 3 days..."
  ./mcp_batch_processor.sh -d example_project -m 3 -v collect
  
  echo ""
  echo "2. Reading the collected files..."
  ./mcp_batch_processor.sh read | head -n 30
  
  echo "..."
  echo "(Output truncated for brevity)"
  echo ""
  
  echo "3. Collecting only JavaScript files..."
  ./mcp_batch_processor.sh -d example_project -p "*.js" -v collect
  
  echo ""
  echo "4. Reading the JavaScript files in JSON format..."
  ./mcp_batch_processor.sh -f json read | head -n 20
  
  echo "..."
  echo "(Output truncated for brevity)"
}

# Demo for the Node.js implementation
demo_nodejs() {
  echo ""
  echo "======================================================"
  echo "DEMO: Node.js Implementation (mcp_file_collector.js)"
  echo "======================================================"
  
  # Make script executable
  chmod +x mcp_file_collector.js
  
  echo "1. Collecting files modified in the last 5 days..."
  node mcp_file_collector.js --dir example_project --mtime 5 --verbose --collect
  
  echo ""
  echo "2. Reading the collected files..."
  node mcp_file_collector.js --read | head -n 30
  
  echo "..."
  echo "(Output truncated for brevity)"
  echo ""
  
  echo "3. Collecting only markdown files..."
  node mcp_file_collector.js --dir example_project --include "*.md" --verbose --collect
  
  echo ""
  echo "4. Reading the markdown files..."
  node mcp_file_collector.js --read | head -n 30
  
  echo "..."
  echo "(Output truncated for brevity)"
}

# Demo for the Python implementation
demo_python() {
  echo ""
  echo "======================================================"
  echo "DEMO: Python Implementation (mcp_collector.py)"
  echo "======================================================"
  
  # Make script executable
  chmod +x mcp_collector.py
  
  echo "1. Collecting files modified in the last 2 days..."
  python3 mcp_collector.py -d example_project -m 2 -v collect
  
  echo ""
  echo "2. Reading the collected files..."
  python3 mcp_collector.py read | head -n 30
  
  echo "..."
  echo "(Output truncated for brevity)"
  echo ""
  
  echo "3. Collecting specific file types (JSON and CSV)..."
  python3 mcp_collector.py -d example_project -p "*.json" -p "*.csv" -v collect
  
  echo ""
  echo "4. Reading the collected files in JSON format..."
  python3 mcp_collector.py read -f json | head -n 20
  
  echo "..."
  echo "(Output truncated for brevity)"
}

# AI integration example
demo_ai_integration() {
  echo ""
  echo "======================================================"
  echo "DEMO: AI Integration Example"
  echo "======================================================"
  
  # Create a simple AI integration script
  cat > ai_integration.py << EOF
#!/usr/bin/env python3

"""
MCP Batch Processing - AI Integration Example
This script demonstrates how to integrate the MCP Collector with an AI system.
"""

import json
import subprocess
import sys

def collect_recent_changes():
    """Collect recent changes using the MCP Collector."""
    print("Collecting recent changes...")
    
    # Use subprocess to call the MCP Collector
    try:
        subprocess.run(["python3", "mcp_collector.py", 
                        "-d", "example_project",
                        "-m", "2",  # Last 2 days
                        "-v", "collect"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error collecting changes: {e}")
        sys.exit(1)
    
    print("Collection complete.")

def read_changes():
    """Read the collected changes in JSON format."""
    print("Reading collected changes...")
    
    try:
        result = subprocess.run(["python3", "mcp_collector.py", "read", "-f", "json"],
                                capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error reading changes: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        sys.exit(1)

def analyze_changes(changes):
    """Analyze the changes and produce a report."""
    print("Analyzing changes...")
    
    if not changes or 'files' not in changes:
        print("No changes to analyze.")
        return
    
    # Count files by type
    file_types = {}
    for file in changes['files']:
        file_type = file['type']
        if file_type not in file_types:
            file_types[file_type] = 0
        file_types[file_type] += 1
    
    # Identify the most common file type
    most_common_type = max(file_types.items(), key=lambda x: x[1])
    
    # Count lines of code (for text files only)
    total_lines = 0
    code_files = []
    
    for file in changes['files']:
        if file.get('encoding') == 'utf-8' and file['content']:
            lines = file['content'].count('\\n') + 1
            total_lines += lines
            
            if file['type'] in ['text/javascript', 'application/javascript', 'text/x-python']:
                code_files.append({
                    'path': file['path'],
                    'lines': lines
                })
    
    # Sort code files by line count (descending)
    code_files.sort(key=lambda x: x['lines'], reverse=True)
    
    # Generate report
    report = {
        'summary': {
            'total_files': len(changes['files']),
            'total_lines': total_lines,
            'file_types': file_types,
            'most_common_type': most_common_type[0],
            'most_common_count': most_common_type[1]
        },
        'code_files': code_files[:5]  # Top 5 code files by line count
    }
    
    return report

def main():
    """Main function."""
    collect_recent_changes()
    changes = read_changes()
    report = analyze_changes(changes)
    
    print("\nAI Analysis Report:")
    print(json.dumps(report, indent=2))
    
    # In a real application, you would send this to an AI system
    print("\nIn a real application, this data would be sent to an AI system")
    print("for advanced analysis and insights.")

if __name__ == "__main__":
    main()
EOF

  chmod +x ai_integration.py
  
  echo "Running AI integration example..."
  python3 ai_integration.py
}

# Main execution
echo "Starting MCP Batch Processing demonstrations..."

# Set up example project
setup_example_project

# Run demos
demo_shell_script
demo_nodejs
demo_python
demo_ai_integration

echo ""
echo "======================================================"
echo "All demonstrations completed."
echo "The example project and tools are available in the current directory."
echo "======================================================"
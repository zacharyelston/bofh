#!/usr/bin/env node

/**
 * ModelContextProtocol (MCP) Directory Tree Reader
 * 
 * This script efficiently reads a directory structure recursively
 * and outputs the structure as JSON or in a more human-readable format.
 * 
 * Usage: 
 *   node directory_tree_reader.js <directory_path> [--json] [--max-depth=N]
 */

const fs = require('fs');
const path = require('path');
const util = require('util');

// Convert callback-based fs functions to promise-based
const readdir = util.promisify(fs.readdir);
const stat = util.promisify(fs.stat);

// Parse command line arguments
const args = process.argv.slice(2);
const directoryPath = args[0] || '.';
const jsonOutput = args.includes('--json');
const maxDepthArg = args.find(arg => arg.startsWith('--max-depth='));
const maxDepth = maxDepthArg ? parseInt(maxDepthArg.split('=')[1], 10) : Infinity;

// Validate arguments
if (!directoryPath) {
  console.error('Error: Directory path is required');
  process.exit(1);
}

// Main function
async function scanDirectory(dirPath, depth = 0) {
  try {
    // Check if we've reached max depth
    if (depth > maxDepth) {
      return { name: path.basename(dirPath), type: 'directory', truncated: true };
    }
    
    const entries = await readdir(dirPath, { withFileTypes: true });
    const result = {
      name: path.basename(dirPath),
      type: 'directory',
      children: []
    };
    
    // Process all entries in parallel for speed
    const processPromises = entries.map(async (entry) => {
      const entryPath = path.join(dirPath, entry.name);
      
      if (entry.isDirectory()) {
        return scanDirectory(entryPath, depth + 1);
      } else {
        try {
          const stats = await stat(entryPath);
          return {
            name: entry.name,
            type: 'file',
            size: stats.size,
            lastModified: stats.mtime
          };
        } catch (err) {
          return {
            name: entry.name,
            type: 'file',
            error: err.message
          };
        }
      }
    });
    
    // Wait for all entries to be processed
    const children = await Promise.all(processPromises);
    result.children = children;
    
    return result;
  } catch (err) {
    console.error(`Error scanning directory ${dirPath}: ${err.message}`);
    return {
      name: path.basename(dirPath),
      type: 'directory',
      error: err.message
    };
  }
}

// Output formatting function
function formatOutput(tree, indent = 0) {
  const indentStr = '  '.repeat(indent);
  
  if (tree.type === 'directory') {
    console.log(`${indentStr}[DIR] ${tree.name}${tree.truncated ? ' (truncated)' : ''}`);
    
    if (tree.children && !tree.truncated) {
      tree.children.forEach(child => {
        formatOutput(child, indent + 1);
      });
    }
  } else {
    console.log(`${indentStr}[FILE] ${tree.name} (${tree.size} bytes)`);
  }
}

// Main execution
(async () => {
  console.log(`Scanning directory: ${directoryPath}`);
  console.time('Directory scan completed in');
  
  try {
    const tree = await scanDirectory(directoryPath);
    
    if (jsonOutput) {
      console.log(JSON.stringify(tree, null, 2));
    } else {
      formatOutput(tree);
    }
    
    console.timeEnd('Directory scan completed in');
  } catch (err) {
    console.error(`Failed to scan directory: ${err.message}`);
    process.exit(1);
  }
})();
#!/usr/bin/env node

/**
 * ModelContextProtocol (MCP) Tar Parser
 * 
 * This script efficiently parses a tar file and lists its contents
 * without fully extracting the archive.
 * 
 * Usage: 
 *   node tar_parser.js <tarfile_path> [--extract=<file_pattern>] [--json]
 */

const fs = require('fs');
const tar = require('tar');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const tarFilePath = args[0];
const jsonOutput = args.includes('--json');
const extractArg = args.find(arg => arg.startsWith('--extract='));
const extractPattern = extractArg ? extractArg.split('=')[1] : null;

// Validate arguments
if (!tarFilePath) {
  console.error('Error: Tar file path is required');
  process.exit(1);
}

// Check if tar module is installed
try {
  require.resolve('tar');
} catch (err) {
  console.error('Error: The "tar" module is required but not installed');
  console.error('Please install it using: npm install tar');
  process.exit(1);
}

// Main function to list tar contents
async function listTarContents(tarPath) {
  const entries = [];
  const extractedFiles = [];

  try {
    console.time('Tar parsing completed in');
    
    await new Promise((resolve, reject) => {
      const stream = fs.createReadStream(tarPath)
        .pipe(new tar.Parse());
      
      stream.on('entry', (entry) => {
        const info = {
          name: entry.path,
          type: entry.type, // 'file', 'directory', 'symlink', etc.
          size: entry.size,
          mode: entry.mode.toString(8),
          mtime: entry.mtime
        };
        
        entries.push(info);
        
        // Extract files matching the pattern if specified
        if (extractPattern && entry.path.includes(extractPattern) && entry.type === 'file') {
          const outputPath = path.join(process.cwd(), 'extracted', entry.path);
          const outputDir = path.dirname(outputPath);
          
          // Create output directory if it doesn't exist
          if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
          }
          
          // Extract the file
          entry.pipe(fs.createWriteStream(outputPath));
          extractedFiles.push(entry.path);
        } else {
          // Drain the entry if not extracting
          entry.resume();
        }
      });
      
      stream.on('error', reject);
      stream.on('end', resolve);
    });
    
    console.timeEnd('Tar parsing completed in');
    
    // Output results
    if (jsonOutput) {
      console.log(JSON.stringify({
        totalEntries: entries.length,
        entries: entries,
        extractedFiles: extractedFiles
      }, null, 2));
    } else {
      console.log(`\nTotal entries: ${entries.length}`);
      
      // Group entries by directory for better visualization
      const dirMap = {};
      
      entries.forEach(entry => {
        const dir = path.dirname(entry.name);
        if (!dirMap[dir]) {
          dirMap[dir] = [];
        }
        dirMap[dir].push(entry);
      });
      
      // Print directory structure
      Object.keys(dirMap).sort().forEach(dir => {
        console.log(`\n[DIR] ${dir}`);
        dirMap[dir].forEach(entry => {
          if (path.dirname(entry.name) === dir) {
            console.log(`  [${entry.type.toUpperCase()}] ${path.basename(entry.name)} (${entry.size} bytes)`);
          }
        });
      });
      
      // Print extracted files
      if (extractedFiles.length > 0) {
        console.log('\nExtracted files:');
        extractedFiles.forEach(file => {
          console.log(`  - ${file}`);
        });
      }
    }
    
  } catch (err) {
    console.error(`Error parsing tar file: ${err.message}`);
    process.exit(1);
  }
}

// Main execution
if (fs.existsSync(tarFilePath)) {
  listTarContents(tarFilePath);
} else {
  console.error(`Error: File not found: ${tarFilePath}`);
  process.exit(1);
}
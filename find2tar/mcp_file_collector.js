#!/usr/bin/env node

/**
 * ModelContextProtocol File Collector
 * 
 * A tool that finds recent or relevant files, packages them into a single archive,
 * and provides unified streaming access to all contents.
 * 
 * This follows MCP principles:
 * - Process is key and provides security through repetition
 * - One task at a time with validation
 * - Slow and careful processing to minimize errors
 */

const fs = require('fs');
const path = require('path');
const util = require('util');
const { spawn, execSync } = require('child_process');
const stream = require('stream');
const readline = require('readline');

// Promisify fs functions
const readdir = util.promisify(fs.readdir);
const stat = util.promisify(fs.stat);
const mkdir = util.promisify(fs.mkdir);
const writeFile = util.promisify(fs.writeFile);

// Command line argument parsing
const args = process.argv.slice(2);
const options = {
  searchDir: '.',
  outputDir: './mcp_output',
  archiveName: 'collected_files.tar',
  mtime: 1, // Default to 1 day
  excludeDirs: ['.git', 'node_modules', 'dist', 'build', 'target'],
  includePatterns: [],
  excludePatterns: [],
  maxSize: 1024 * 1024 * 100, // 100MB default max archive size
  verbose: false,
  mode: 'collect', // collect or read
  format: 'text', // text or json output format
};

// Parse arguments
for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  
  if (arg === '--dir' || arg === '-d') {
    options.searchDir = args[++i];
  } else if (arg === '--output' || arg === '-o') {
    options.outputDir = args[++i];
  } else if (arg === '--archive' || arg === '-a') {
    options.archiveName = args[++i];
  } else if (arg === '--mtime' || arg === '-m') {
    options.mtime = parseInt(args[++i], 10);
  } else if (arg === '--exclude-dir' || arg === '-xd') {
    options.excludeDirs.push(args[++i]);
  } else if (arg === '--include' || arg === '-i') {
    options.includePatterns.push(args[++i]);
  } else if (arg === '--exclude' || arg === '-x') {
    options.excludePatterns.push(args[++i]);
  } else if (arg === '--max-size') {
    options.maxSize = parseSize(args[++i]);
  } else if (arg === '--verbose' || arg === '-v') {
    options.verbose = true;
  } else if (arg === '--read' || arg === '-r') {
    options.mode = 'read';
  } else if (arg === '--collect' || arg === '-c') {
    options.mode = 'collect';
  } else if (arg === '--json' || arg === '-j') {
    options.format = 'json';
  } else if (arg === '--help' || arg === '-h') {
    printHelp();
    process.exit(0);
  }
}

// Full archive path
const archivePath = path.join(options.outputDir, options.archiveName);

// Parse human-readable size
function parseSize(sizeStr) {
  const units = {
    'B': 1,
    'K': 1024,
    'M': 1024 * 1024,
    'G': 1024 * 1024 * 1024,
  };
  
  const match = sizeStr.match(/^(\d+)([BKMG])?$/i);
  if (!match) {
    throw new Error(`Invalid size format: ${sizeStr}. Use format like 100M, 1G, etc.`);
  }
  
  const size = parseInt(match[1], 10);
  const unit = (match[2] || 'B').toUpperCase();
  
  return size * units[unit];
}

// Print help information
function printHelp() {
  console.log(`
ModelContextProtocol File Collector

Usage: node mcp_file_collector.js [options]

Modes:
  --collect, -c          Find and collect files (default)
  --read, -r             Read previously collected archive

Options:
  --dir, -d <path>       Directory to search in (default: current directory)
  --output, -o <path>    Output directory for archive (default: ./mcp_output)
  --archive, -a <n>   Archive name (default: collected_files.tar)
  --mtime, -m <days>     Find files modified in the last N days (default: 1)
  --exclude-dir, -xd <dir> Directory pattern to exclude (can be used multiple times)
  --include, -i <pattern> File pattern to include (can be used multiple times)
  --exclude, -x <pattern> File pattern to exclude (can be used multiple times)
  --max-size <size>      Maximum archive size (e.g., 100M, 1G)
  --verbose, -v          Enable verbose logging
  --json, -j             Output in JSON format
  --help, -h             Show this help

Examples:
  # Collect files modified in the last 2 days
  node mcp_file_collector.js --mtime 2
  
  # Collect only JavaScript and JSON files
  node mcp_file_collector.js --include "*.js" --include "*.json"
  
  # Read previously collected archive
  node mcp_file_collector.js --read
  
  # Collect files and output in JSON format
  node mcp_file_collector.js --collect --json
`);
}

// Create necessary directories
async function ensureDirectories() {
  try {
    if (!fs.existsSync(options.outputDir)) {
      await mkdir(options.outputDir, { recursive: true });
      log(`Created output directory: ${options.outputDir}`);
    }
  } catch (err) {
    console.error(`Error creating directories: ${err.message}`);
    process.exit(1);
  }
}

// Log helper function that respects verbose flag
function log(message) {
  if (options.verbose) {
    console.log(`[MCP] ${message}`);
  }
}

// Validate a file against our filters
function isFileValid(filePath, stats) {
  // Check modification time
  const fileAgeDays = (Date.now() - stats.mtime) / (1000 * 60 * 60 * 24);
  if (fileAgeDays > options.mtime) {
    return false;
  }
  
  // Check file path against exclude directories
  for (const dir of options.excludeDirs) {
    if (filePath.includes(`/${dir}/`) || filePath.startsWith(`${dir}/`)) {
      return false;
    }
  }
  
  // Check file against exclude patterns
  for (const pattern of options.excludePatterns) {
    if (minimatch(filePath, pattern)) {
      return false;
    }
  }
  
  // If we have include patterns, at least one must match
  if (options.includePatterns.length > 0) {
    let included = false;
    for (const pattern of options.includePatterns) {
      if (minimatch(filePath, pattern)) {
        included = true;
        break;
      }
    }
    if (!included) {
      return false;
    }
  }
  
  return true;
}

// Simple minimatch-like pattern matching
function minimatch(filePath, pattern) {
  // Convert glob pattern to RegExp
  const regexPattern = pattern
    .replace(/\./g, '\\.')
    .replace(/\*/g, '.*')
    .replace(/\?/g, '.');
  
  const regex = new RegExp(`^${regexPattern}$`);
  return regex.test(path.basename(filePath));
}

// Find files matching our criteria
async function findFiles(dir, fileList = []) {
  try {
    const entries = await readdir(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory()) {
        // Skip excluded directories
        if (options.excludeDirs.includes(entry.name)) {
          log(`Skipping excluded directory: ${fullPath}`);
          continue;
        }
        
        // Recursively scan subdirectories
        await findFiles(fullPath, fileList);
      } else if (entry.isFile()) {
        // Get file stats
        const stats = await stat(fullPath);
        
        // Check if file matches our criteria
        if (isFileValid(fullPath, stats)) {
          fileList.push({
            path: fullPath,
            size: stats.size,
            mtime: stats.mtime
          });
          log(`Found matching file: ${fullPath} (${stats.size} bytes)`);
        }
      }
    }
    
    return fileList;
  } catch (err) {
    console.error(`Error scanning directory ${dir}: ${err.message}`);
    return fileList;
  }
}

// Create the tar archive
async function createArchive(files) {
  try {
    // Write file list for tar to use
    const fileListPath = path.join(options.outputDir, 'file_list.txt');
    await writeFile(fileListPath, files.map(f => f.path).join('\n'));
    
    log(`Creating archive with ${files.length} files...`);
    
    // Use tar command to create archive
    const tarCommand = `tar -cf "${archivePath}" -T "${fileListPath}"`;
    execSync(tarCommand, { stdio: options.verbose ? 'inherit' : 'ignore' });
    
    // Get archive info
    const archiveStats = await stat(archivePath);
    log(`Archive created: ${archivePath} (${archiveStats.size} bytes)`);
    
    // Write metadata file
    const metadataPath = path.join(options.outputDir, 'metadata.json');
    const metadata = {
      createdAt: new Date().toISOString(),
      options: options,
      files: files,
      archiveSize: archiveStats.size,
      fileCount: files.length
    };
    
    await writeFile(metadataPath, JSON.stringify(metadata, null, 2));
    log(`Metadata written to: ${metadataPath}`);
    
    return { archivePath, metadataPath };
  } catch (err) {
    console.error(`Error creating archive: ${err.message}`);
    process.exit(1);
  }
}

// Read and stream the archive contents
async function readArchive() {
  try {
    if (!fs.existsSync(archivePath)) {
      console.error(`Archive not found: ${archivePath}`);
      process.exit(1);
    }
    
    log(`Reading archive: ${archivePath}`);
    
    // Get archive metadata if available
    const metadataPath = path.join(options.outputDir, 'metadata.json');
    let metadata = null;
    
    if (fs.existsSync(metadataPath)) {
      metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
      log(`Found metadata: ${metadata.fileCount} files, created on ${metadata.createdAt}`);
    }
    
    // Use tar to extract and stream file contents
    console.log('MCP File Collector - Archive Contents');
    console.log('===============================================================');
    
    const tar = spawn('tar', ['-xOf', archivePath]);
    
    // Set up tar to output file contents
    const rl = readline.createInterface({
      input: tar.stdout,
      crlfDelay: Infinity
    });
    
    let currentFileName = '';
    let currentFileContent = [];
    let outputFiles = [];
    
    // Handle each line of output
    for await (const line of rl) {
      // Detect file boundaries (this is a simplified approach)
      if (line.startsWith('=== ') && line.endsWith(' ===')) {
        // If we have a file in progress, save it
        if (currentFileName) {
          outputFiles.push({
            name: currentFileName,
            content: currentFileContent.join('\n')
          });
          
          if (options.format === 'text') {
            console.log(`\n=============== ${currentFileName} ===============`);
            console.log(currentFileContent.join('\n'));
            console.log('===============================================================\n');
          }
        }
        
        // Start new file
        currentFileName = line.replace(/^=== /, '').replace(/ ===$/, '');
        currentFileContent = [];
      } else {
        // Add line to current file
        currentFileContent.push(line);
      }
    }
    
    // Handle the last file
    if (currentFileName) {
      outputFiles.push({
        name: currentFileName,
        content: currentFileContent.join('\n')
      });
      
      if (options.format === 'text') {
        console.log(`\n=============== ${currentFileName} ===============`);
        console.log(currentFileContent.join('\n'));
        console.log('===============================================================\n');
      }
    }
    
    // Output JSON if requested
    if (options.format === 'json') {
      console.log(JSON.stringify({
        metadata: metadata,
        files: outputFiles
      }, null, 2));
    }
    
    console.log(`\nFinished reading ${outputFiles.length} files from archive.`);
  } catch (err) {
    console.error(`Error reading archive: ${err.message}`);
    process.exit(1);
  }
}

// Main function
async function main() {
  try {
    // Ensure output directory exists
    await ensureDirectories();
    
    if (options.mode === 'collect') {
      log(`Starting file collection in ${options.searchDir}`);
      log(`Looking for files modified in the last ${options.mtime} days`);
      
      // Find matching files
      const files = await findFiles(options.searchDir);
      
      if (files.length === 0) {
        console.log('No matching files found.');
        process.exit(0);
      }
      
      // Sort files by modification time (newest first)
      files.sort((a, b) => b.mtime - a.mtime);
      
      // Create tar archive with all files
      await createArchive(files);
      
      // Summary output
      console.log(`\nMCP File Collector - Summary`);
      console.log(`===============================================================`);
      console.log(`Total files collected: ${files.length}`);
      console.log(`Archive location: ${archivePath}`);
      console.log(`To read this archive: node mcp_file_collector.js --read`);
      console.log(`===============================================================`);
    } else if (options.mode === 'read') {
      await readArchive();
    }
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
}

// Start the program
main();
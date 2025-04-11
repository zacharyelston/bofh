# Find2Tar Directory Tools
## ModelContextProtocol (MCP) Directory and Archive Management

Find2Tar is a collection of advanced tools for directory scanning and archive manipulation that extend the capabilities of standard Unix utilities like `find` and `tar`. These tools provide more efficient and flexible ways to work with file systems and archives.

## Available Tools

### 1. `mcp_directory_scanner.sh`

A powerful directory scanner with advanced filtering options, JSON output, and detailed statistics.

**Usage:**
```bash
./mcp_directory_scanner.sh [options] <directory or archive>

Options:
  -j, --json                Output in JSON format
  -d, --max-depth=N         Maximum directory depth to scan
  -e, --extract=PATTERN     Extract files matching pattern from archives
  -t, --type=TYPE           Process specific file types only (e.g., 'js,md,txt')
  -s, --stats               Show detailed statistics
  -h, --help                Show this help
```

### 2. `directory_tree_reader.js`

A JavaScript-based directory structure analyzer that provides fast traversal and flexible output formats.

**Usage:**
```bash
node directory_tree_reader.js [options] <directory>

Options:
  --json                    Output in JSON format
  --max-depth=N             Maximum directory depth to scan
  --include-hidden          Include hidden files and directories
```

### 3. `tar_parser.js`

A tool for working with TAR archives with support for extraction, listing, and JSON output.

**Usage:**
```bash
node tar_parser.js [options] <archive>

Options:
  --json                    Output in JSON format
  --extract=PATTERN         Extract files matching pattern
  --stats                   Show archive statistics
```

### 4. `mcp_batch_processor.sh`

Process files in batches across directories with customizable actions.

**Usage:**
```bash
./mcp_batch_processor.sh [options] <directory>

Options:
  --batch-size=N            Number of files to process in each batch
  --action=ACTION           Action to perform on each file
  --recursive               Process directories recursively
```

### 5. `mcp_collector.py`

A Python script for collecting and organizing files based on patterns or metadata.

**Usage:**
```bash
python mcp_collector.py [options] <source> <destination>

Options:
  --pattern=PATTERN         File pattern to match
  --organize-by=METHOD      Organization method (date, type, size)
  --maintain-structure      Maintain source directory structure
```

## Example Usage

The `example_usage.sh` script demonstrates various use cases for these tools:

```bash
./example_usage.sh
```

This will show examples of:
1. Directory scanning and statistics
2. Archive listing and extraction
3. File filtering by type
4. Performance comparisons
5. Error handling and validation

## Getting Started

1. Make the scripts executable:
   ```bash
   chmod +x mcp_directory_scanner.sh mcp_batch_processor.sh example_usage.sh
   ```

2. Set up an example environment:
   ```bash
   ./example_setup.sh
   ```

3. Try the example usage script:
   ```bash
   ./example_usage.sh
   ```

4. Use the tools for your own directories and archives:
   ```bash
   ./mcp_directory_scanner.sh --stats /path/to/your/directory
   ```

## Integration with BOFH

These tools are fully integrated with the BOFH system and can be used alongside other BOFH utilities. They share the same configuration system and can be invoked through the main BOFH interface.

## Performance Considerations

- The JavaScript tools are optimized for large directory structures
- For very large archives, consider using extraction patterns to avoid memory issues
- Statistics generation can be resource-intensive on large directories

## Future Enhancements

Planned improvements include:
- Support for more archive formats
- Parallel processing capabilities
- Directory synchronization features
- Content-based search within archives
- Metadata extraction and indexing

## Special Acknowledgments

These tools were created under the ModelContextProtocol (MCP) approach, focusing on process and planning over implementation.

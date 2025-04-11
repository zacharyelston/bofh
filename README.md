# BOFH - Bastard Operator From Hell
## Unix Sysadmin mcpServer

BOFH is a Unix system administration tool that harnesses the power of traditional Unix toolchains in magical ways, embracing the spirit of the original Bastard Operator From Hell character - pragmatic, efficient, and occasionally terrifying in its capabilities.

## Philosophy

The BOFH tool operates on these core principles:

1. **Unix Philosophy**: Small, focused tools that do one thing well and can be chained together
2. **ModelContextProtocol (MCP)**: Process and planning over implementation, with documentation and repeatability
3. **Magical Toolchains**: Combining standard Unix tools in unexpected and powerful ways
4. **Efficiency Over Elegance**: Getting the job done, sometimes in ways that make you question your sanity

## Example Use Cases

The BOFH toolset contains examples for various system administration tasks:

1. **Schema Searching** (`/schema_search_example/`): Tools for digging through codebases to find database schemas and table structures
2. **Find2Tar Directory Tools** (`/find2tar/`): Advanced directory scanning and archive manipulation tools that extend standard Unix find/tar capabilities
3. More examples to come as the toolset evolves

## Tool Highlights

### Schema Search

A collection of tools for finding and analyzing database schemas in codebases. Includes scripts for:
- Identifying schema definitions in SQL files
- Mapping relationships between tables
- Finding SQL patterns in non-SQL files
- Generating comprehensive documentation of database structures

### Find2Tar Directory Tools

A powerful extension of standard Unix utilities for efficient file system operations:
- **mcp_directory_scanner.sh**: Advanced directory scanner with JSON output and statistics
- **tar_parser.js**: Flexible TAR archive manipulation tool
- **directory_tree_reader.js**: Fast directory structure analyzer
- **mcp_batch_processor.sh**: Process files in batches across directories
- **mcp_collector.py**: Collect and organize files based on patterns

## Potential Future Direction

The relationship between BOFH and AI LLMs may be symbiotic:

1. **BOFH → LLM**: BOFH can generate structured data and initial analyses that LLMs can then interpret and expand upon
2. **LLM → BOFH**: LLMs can generate BOFH-style scripts and approaches tailored to specific problems
3. **Hybrid Operations**: Tasks that require both raw Unix power and natural language understanding

## Usage Patterns

BOFH tools typically follow these patterns:

1. Execute a search or analysis operation (using grep, awk, sed, find, etc.)
2. Generate structured output (JSON, CSV, or markdown reports)
3. Provide tools for further analysis or processing of that output
4. Document the approach for repeatability and adaptation

## Getting Started

Browse the example directories to see BOFH in action. Each example contains:

- README explaining the purpose and approach
- Command-line tools (typically shell scripts and occasionally Python/JavaScript)
- Sample outputs or expected results
- Documentation on when and how to use the tools

### Quick Start with Find2Tar

```bash
# Scan a directory and generate statistics
./find2tar/mcp_directory_scanner.sh --stats /path/to/directory

# Process a tar archive
./find2tar/mcp_directory_scanner.sh /path/to/archive.tar.gz

# Extract specific files from an archive
./find2tar/mcp_directory_scanner.sh --extract=.txt /path/to/archive.tar.gz

# Generate JSON output for further processing
./find2tar/mcp_directory_scanner.sh --json /path/to/directory
```

## Configuration

Most BOFH tools can be configured via:
1. The global configuration file (`config.sh`)
2. Command-line arguments
3. Environment variables

## Warning

In the true spirit of BOFH, these tools are powerful and should be wielded with caution. Always review scripts before executing them, especially if they modify system files or databases.

Remember: With great power comes absolutely no responsibility whatsoever.

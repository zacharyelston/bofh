# MCP YAML Tree Catalogger

## Overview

The MCP YAML Tree Catalogger is a tool that follows the ModelContextProtocol (MCP) pattern for searching YAML trees in filesystem structures and building relationship catalogs. It's particularly useful for analyzing Kubernetes/Kustomize applications and their dependencies.

## Features

- Recursively search directories matching a specified pattern
- Find and parse YAML files to extract key information
- Extract service names and application titles
- Identify Kustomize resources and their relationships
- Generate relationship visualizations
- Export results to JSON for further processing
- Follow MCP pattern for consistent usage

## MCP Command Structure

The tool follows the ModelContextProtocol (MCP) format:

```
[MCP]
Command: bofh.filesystem.yaml_catalog
Parameters:
  directory: /path/to/search
  pattern: *-atlas
  output_json: /path/to/output.json
  output_graph: /path/to/output.dot
  output_dir: /path/to/output/directory
[/MCP]
```

## Parameters

- `directory`: Base path to search (required)
- `pattern`: Directory name pattern to match (default: `*-atlas`)
- `output_json`: Path for JSON output file (optional)
- `output_graph`: Path for GraphViz DOT output file (optional)
- `output_dir`: Directory for output files (optional)

## Usage Examples

### Search a specific directory with default pattern

```
[MCP]
Command: bofh.filesystem.yaml_catalog
Parameters:
  directory: $SOURCE_DIR/$SOURCE_DIR
[/MCP]
```

### Specify a custom pattern and output directory

```
[MCP]
Command: bofh.filesystem.yaml_catalog
Parameters:
  directory: $SOURCE_DIR
  pattern: *-kustomize
  output_dir: /Users/zacelston/AlZacAI/bofh/results
[/MCP]
```

### Specify exact output file paths

```
[MCP]
Command: bofh.filesystem.yaml_catalog
Parameters:
  directory: $SOURCE_DIR/$SOURCE_DIR
  output_json: /Users/zacelston/AlZacAI/bofh/results/my-catalog.json
  output_graph: /Users/zacelston/AlZacAI/bofh/results/my-graph.dot
[/MCP]
```

## Command Line Usage

The tool can also be used directly from the command line:

```bash
./mcp_yaml_catalogger.sh /path/to/search --pattern=*-atlas --output-dir=/path/to/output
```

## Implementation Details

The MCP YAML Catalogger is a bash script wrapper around the Python-based YAML Tree Catalogger. It handles:

1. Parsing MCP-formatted commands
2. Validating inputs
3. Creating output directories
4. Running the YAML Tree Catalogger
5. Generating visualizations if GraphViz is installed

## Best Practices (Following MCP)

- Work on one task at a time - first identify directories, then analyze YAML files
- Validate each step works before moving to the next task
- Use specific patterns to focus your search
- Document any issues encountered
- Review results before proceeding with any further actions

## Dependencies

- Python 3.6+
- PyYAML
- GraphViz (optional, for visualization)

## Integration with Other MCP Tools

The MCP YAML Catalogger can be integrated with other tools in the BOFH toolkit:

- Use with `bofh.filesystem.analyze` to perform deeper analysis
- Combine with `bofh.filesystem.find` to pre-filter directories
- Pipeline output to `bofh.filesystem.archive` to archive specific YAML files

## Error Handling

The tool provides detailed error messages and validates inputs before execution. Common errors include:

- Non-existent directories
- Invalid patterns
- Permission issues
- Missing dependencies

## References

This tool follows the ModelContextProtocol (MCP) as defined in `/Users/zacelston/AlZacAI/bofh/prompt.yaml`.

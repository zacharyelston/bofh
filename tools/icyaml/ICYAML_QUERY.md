# ICYAML Query: SQL-like querying for YAML structures

## Overview

ICYAML Query extends the ICYAML toolkit with SQL-like querying capabilities for YAML structures. This powerful tool allows you to extract specific relationships and associations from complex YAML files, particularly focused on Kubernetes manifests and Kustomize configurations.

## Features

- Query YAML files using SQL-like syntax
- Extract specific key-value pairs based on conditions
- Traverse parent-child relationships
- Report customized associations
- Export results in various formats (JSON, YAML, text)
- Preserves hierarchical structure
- MCP (ModelContextProtocol) compatible

## Query Syntax

```
select <KeyB> from <KeyB> node when [parent] <KeyA> is <ValueA> and report <KeyB:ValueB> <KeyA:ValueA>
```

The query syntax is inspired by SQL but tailored for hierarchical YAML structures:

- `select <Key>`: Specifies the key whose value you want to extract
- `from <Key> node`: Defines the context of the search
- `when [parent] <Key> is <Value>`: Sets conditions to filter results
  - The optional `parent` keyword indicates a parent-child relationship
- `and report <Key:Value>`: Specifies the key-value pairs to include in the results

## Examples

### Find Deployments and Their Names

```
select name from metadata when kind is Deployment and report name:name kind:kind
```

### Find Container Images and Their Deployment Contexts

```
select image from containers when kind is Deployment and report image:image name:name
```

### Find Service-to-Deployment Connections

```
select app from selector when metadata is metadata and report app:app
```

### Find Specific Configuration Values

```
select port from spec when parent service is web and report port:port service:service
```

## Command Line Usage

The ICYAML Query tool can be used directly from the command line:

```bash
./icyaml_query --dir /path/to/yaml/files --query "select name from metadata when kind is Deployment"
```

```bash
./icyaml query --dir /path/to/yaml/files --query "select port from spec when name is web" --output results.json --format json
```

```bash
./query_yaml_atlas.sh deployments
```

## MCP Protocol Usage

The tool follows the ModelContextProtocol (MCP) pattern and can be used with MCP commands:

```
[MCP]
Command: bofh.filesystem.yaml_query
Parameters:
  directory: /path/to/yaml/files
  query: "select name from metadata when kind is Deployment and report name:name kind:kind"
  output: /path/to/output.json
  format: json
[/MCP]
```

You can use the MCP wrapper script:

```bash
./mcp_yaml_query.sh "[MCP] Command: bofh.filesystem.yaml_query ..."
```

## Integration with ICYAML Suite

The query functionality is fully integrated with the rest of the ICYAML suite:

1. **Map the Structure**: Use `icyaml scan-enhanced` to discover and catalog YAML files
2. **Query Relationships**: Use `icyaml query` to extract specific relationships
3. **Visualize Results**: Export results to JSON and create custom visualizations

## Use Cases

### Kubernetes Resource Analysis

- Find all Deployments in a cluster
- Extract service-to-deployment connections
- Identify resource requirements
- List all container images

### Configuration Management

- Find specific configuration values
- Extract environment variables
- Identify resource interdependencies

### Dependency Analysis

- Find GitHub repository dependencies
- Map service dependencies
- Extract version information

## Best Practices

1. **Start Simple**: Begin with basic queries and gradually build more complex ones
2. **Narrow Your Focus**: Use directory patterns to limit the scope of your search
3. **Extract Specific Data**: Only request the key-value pairs you need
4. **Create Reusable Queries**: Save common queries for future use
5. **Combine with Visualization**: Export query results and create custom visualizations

## Requirements

- Python 3.6+
- PyYAML

## References

This tool is part of the ICYAML suite following the ModelContextProtocol (MCP) as defined in `prompt.yaml`.

---

> "I see key-value relationships... they don't know they're associated."
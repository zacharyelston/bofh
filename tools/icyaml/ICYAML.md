# ICYAML: "I See YAML" - YAML Structure Visualization Tool

![ICYAML Logo](https://via.placeholder.com/400x100?text=ICYAML)

> "I see YAML trees... walking around like regular files. They don't know they're structured data."

## Overview

ICYAML ("I See YAML") is a suite of tools for searching filesystem structures, discovering YAML files, and visualizing their relationships. The name is inspired by the famous line from "The Sixth Sense" - but instead of seeing dead people, this tool sees structured/serialized data that others might miss.

## Features

- Recursively search directories for YAML files
- Extract structure and relationships between Kubernetes resources
- Special handling for Kustomize configurations
- Identify dependencies between services
- Extract service names, application titles, and other metadata
- Visualize relationships through GraphViz diagrams
- Export detailed catalogs to JSON for further analysis
- MCP (ModelContextProtocol) compatible execution

## Tools Included

### Core Tools
- `yaml_tree_catalogger.py` - Basic YAML file discovery and cataloging
- `yaml_tree_catalogger_enhanced.py` - Advanced version with Kustomize awareness

### MCP Wrappers
- `mcp_yaml_catalogger.sh` - MCP-compatible wrapper for the basic tool
- `mcp_yaml_catalogger_enhanced.sh` - MCP-compatible wrapper for the enhanced tool

### Example Scripts
- `catalog_cfa_atlas.sh` - Ready-to-use script for the YAML configuration files repository
- `catalog_cfa_example.md` - Concrete example for using ICYAML with the CFA repository

## Usage Examples

### Basic Scanning

```
[MCP]
Command: bofh.filesystem.yaml_catalog
Parameters:
  directory: /path/to/kubernetes/project
  pattern: *-atlas
  output_dir: /path/to/output
[/MCP]
```

### Enhanced Scanning with Kustomize Awareness

```
[MCP]
Command: bofh.filesystem.yaml_catalog_enhanced
Parameters:
  directory: /path/to/kubernetes/project
  pattern: *
  output_json: /path/to/output.json
  output_graph: /path/to/output.dot
[/MCP]
```

## Visual Output

ICYAML generates GraphViz DOT files that can be converted to visual diagrams showing:

- Service dependencies
- Kustomize bases and overlays
- GitHub repository relationships
- Patch file applications
- Application architecture

## Philosophy

Like the protagonist in "The Sixth Sense" who sees what others cannot, ICYAML reveals the hidden structures and connections in your YAML files. It helps you understand the complex relationships between Kubernetes resources that might otherwise be difficult to visualize.

By building a comprehensive catalog of these connections, ICYAML helps you:

1. Document your infrastructure
2. Identify dependencies between services
3. Track configuration changes
4. Visualize your application architecture
5. Ensure consistency across deployments

## Integration with BOFH Toolkit

ICYAML follows the ModelContextProtocol (MCP) and integrates seamlessly with other tools in the BOFH toolkit:

- Use with `bofh.filesystem.analyze` for deeper analysis
- Combine with `bofh.filesystem.find` for pre-filtering directories
- Pipeline output to `bofh.filesystem.archive` to archive specific YAML files

## Requirements

- Python 3.6+
- PyYAML
- GraphViz (optional, for visualization)

## References

Developed as part of the BOFH toolkit following the ModelContextProtocol (MCP) as defined in `/Users/zacelston/AlZacAI/bofh/prompt.yaml`.

---

> "They only see what they want to see. They don't know they're YAML."
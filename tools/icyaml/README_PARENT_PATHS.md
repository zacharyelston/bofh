# YAML Parent Path Analyzer

## Overview

The YAML Parent Path Analyzer is a specialized tool for examining the hierarchical structure of YAML configuration files. It identifies parent-child relationships between keys, helping you understand the overall organization and patterns in your configuration files.

This tool helps you:
- Visualize the hierarchical structure of YAML keys
- Identify common parent paths across files
- Find inconsistencies in path hierarchies
- Understand the organization of different resource types
- Discover path patterns that could be standardized

## Quick Start

```bash
# Set your source directory
export SOURCE_DIR=/path/to/your/yaml/files

# Run the parent path analyzer
./analyze_parent_paths.sh

# Analyze with a specific file pattern
./analyze_parent_paths.sh --pattern "deployment-*"

# Specify a custom output file
./analyze_parent_paths.sh --output "path_structure.json"
```

## Understanding the Report

The parent path analyzer generates a comprehensive report that includes:

### 1. Summary Statistics
- Total files analyzed
- Resource types found (Deployment, Service, etc.)
- Total unique paths found
- Count of root paths (top-level keys)
- Count of leaf paths (keys with no children)

### 2. Root Paths
A list of all top-level keys found in your YAML files, with:
- Percentage of files containing each root path
- Number of direct and indirect children

### 3. Common Parent Paths
Parent paths that appear in at least 50% of files, showing:
- Percentage of files containing each parent path
- Example direct children
- Prevalence of each child path

### 4. Path Patterns
Common patterns in path structures, organized by categories:
- Container-related paths
- Metadata-related paths
- Spec-related paths

### 5. Hierarchical Structure Example
A detailed hierarchical view of a common path, showing:
- Parent-child relationships
- Prevalence of each path in the hierarchy
- Multiple levels of nesting

## Example Output

```
=== YAML Parent Path Analysis Report ===

Total files analyzed: 33
Resource types found: 4
  - Deployment: 18 file(s)
  - Service: 9 file(s)
  - CronJob: 4 file(s)
  - ConfigMap: 2 file(s)
Unique paths found: 142
Root paths: 4
Leaf paths: 87

=== Root Paths ===

  - apiVersion: 100% of files (33/33)
    Children: 0 direct, 0 total
  - kind: 100% of files (33/33)
    Children: 0 direct, 0 total
  - metadata: 100% of files (33/33)
    Children: 3 direct, 9 total
  - spec: 97% of files (32/33)
    Children: 6 direct, 124 total

=== Common Parent Paths (50%+ of files) ===

  - metadata: 100% of files (33/33)
    Example children:
      * name: 100% of files
      * namespace: 97% of files
      * labels: 82% of files
  - spec: 97% of files (32/33)
    Example children:
      * template: 67% of files
      * selector: 52% of files
      * ports: 27% of files
  - spec.template: 67% of files (22/33)
    Example children:
      * metadata: 67% of files
      * spec: 67% of files
  - spec.template.spec: 67% of files (22/33)
    Example children:
      * containers: 67% of files
      * volumes: 42% of files
      * serviceAccountName: 24% of files

=== Path Patterns ===

  Containers Paths: 12 paths
    Examples:
      * spec.template.spec.containers: 67% of files
      * spec.template.spec.containers[0]: 67% of files
      * spec.template.spec.containers[0].name: 67% of files
      ... and 9 more paths
  
  Metadata Paths: 9 paths
    Examples:
      * metadata: 100% of files
      * metadata.name: 100% of files
      * metadata.namespace: 97% of files
      ... and 6 more paths

=== Example Hierarchical Structure for 'spec' ===

  spec: 97% of files (32/33)
    template: 67% of files (22/33)
      metadata: 67% of files (22/33)
        labels: 67% of files (22/33)
        annotations: 15% of files (5/33)
        name: 12% of files (4/33)
      spec: 67% of files (22/33)
        containers: 67% of files (22/33)
        volumes: 42% of files (14/33)
        serviceAccountName: 24% of files (8/33)
    selector: 52% of files (17/33)
      matchLabels: 52% of files (17/33)
```

## How to Interpret Results

The analyzer shows you the hierarchical structure of paths across your YAML files:

1. **Root Paths**: These are top-level keys that begin the hierarchy
   - Example: `apiVersion`, `kind`, `metadata`, `spec`

2. **Common Parent Paths**: These paths appear in many files and have child paths
   - Example: `spec.template.spec` is a common parent with children like `containers`

3. **Path Patterns**: These show common categories of paths
   - Examples: container-related, metadata-related, etc.

4. **Hierarchical Structure**: This visualizes the nesting of keys with their prevalence
   - Shows parent-child relationships with the percentage of files containing each path

## Use Cases

### Understanding Resource Structure

```bash
# Analyze structure of deployment resources
export SOURCE_DIR=/path/to/k8s/manifests
./analyze_parent_paths.sh --pattern "deployment*"
```

This helps you understand:
- The common structure of deployment resources
- Required vs. optional paths
- Patterns in path usage

### Standardizing Config Hierarchies

```bash
# Compare configurations across environments
export SOURCE_DIR=/path/to/prod
./analyze_parent_paths.sh --output "prod_paths.json"

export SOURCE_DIR=/path/to/staging
./analyze_parent_paths.sh --output "staging_paths.json"
```

Use this to:
- Identify structural differences between environments
- Find missing paths in one environment that exist in another
- Create standardized templates with consistent paths

### Hierarchical Documentation

The hierarchical view helps create documentation for complex YAML structures:
- Shows the nesting of configuration options
- Indicates which paths are commonly used together
- Makes it easier to understand the overall structure

## Tips for Effective Analysis

1. **Focus on specific resource types**: Use the pattern option to analyze similar resources
   ```bash
   ./analyze_parent_paths.sh --pattern "deployment-*"
   ```

2. **Look at the hierarchical example**: It provides a visual representation of the nesting structure

3. **Pay attention to prevalence**: Paths with low prevalence might indicate optional configurations

4. **Identify structural patterns**: Root paths and common parents reveal the fundamental structure of your files

## Integration with Other ICYAML Tools

This analyzer works well with other ICYAML tools:

```bash
# First analyze the parent path structure
./analyze_parent_paths.sh

# Then run the consistency analyzer to find missing keys
./analyze_consistency.sh

# Finally query specific paths of interest
./arm64_docker.sh query "select containers from spec.template.spec"
```

The combination of these tools provides a comprehensive view of your YAML configuration files, from structure to content.

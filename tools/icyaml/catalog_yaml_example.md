# YAML Tree Catalogger Use Case: YAML configuration files

This document provides a concrete example of using the YAML Tree Catalogger tools to analyze the Kubernetes/Kustomize applications in the YAML configuration files repository.

## Overview

The YAML configuration files repository contains multiple microservices deployed using Kustomize. The structure typically includes:

- A directory for each microservice (e.g., `spine-partner-service`)
- Kustomization files (`kustomization.yaml`)
- Resource files in a `resources/` directory
- Patch files in a `patches/` directory
- References to GitHub repositories for base configurations

## Step 1: Basic Catalog with Standard Tool

First, let's use the standard YAML Tree Catalogger to scan the repository:

```bash
# Use the MCP protocol format
[MCP]
Command: bofh.filesystem.yaml_catalog
Parameters:
  directory: $SOURCE_DIR/$SOURCE_DIR
  pattern: *
  output_dir: /Users/zacelston/AlZacAI/bofh/output
[/MCP]
```

This will:
1. Scan all directories in the $SOURCE_DIR repository
2. Identify YAML files and extract service names and app titles
3. Generate a summary of connections
4. Export results to JSON and GraphViz dot files

## Step 2: Enhanced Catalog with Kustomize Awareness

For a more detailed analysis with Kustomize awareness, use the enhanced version:

```bash
# Use the MCP protocol format
[MCP]
Command: bofh.filesystem.yaml_catalog_enhanced
Parameters:
  directory: $SOURCE_DIR/$SOURCE_DIR
  pattern: *
  output_dir: /Users/zacelston/AlZacAI/bofh/output
[/MCP]
```

This enhanced version will:
1. Scan all directories in the $SOURCE_DIR repository
2. Specifically identify Kustomization files
3. Extract GitHub dependencies from Kustomize resources
4. Identify patch files and their relationships
5. Generate a comprehensive view of the service architecture
6. Export results with more detailed relationship information

## Step 3: Analyze a Specific Service

To focus on a particular service:

```bash
# Use the MCP protocol format
[MCP]
Command: bofh.filesystem.yaml_catalog_enhanced
Parameters:
  directory: $SOURCE_DIR/$SOURCE_DIR/us-east-1/spine-partner-service
  pattern: *
  output_json: /Users/zacelston/AlZacAI/bofh/output/spine-partner-service.json
  output_graph: /Users/zacelston/AlZacAI/bofh/output/spine-partner-service.dot
[/MCP]
```

## Step 4: Generate Visualization

After running the catalog, generate a visualization using GraphViz:

```bash
dot -Tpng -o /Users/zacelston/AlZacAI/bofh/output/spine-partner-service.png /Users/zacelston/AlZacAI/bofh/output/spine-partner-service.dot
```

## Example Output Structure

The JSON output will have a structure similar to:

```json
{
  "spine-partner-service": {
    "path": "$SOURCE_DIR/$SOURCE_DIR/us-east-1/spine-partner-service",
    "services": [],
    "kustomizations": [
      {
        "type": "kustomization",
        "file": "$SOURCE_DIR/$SOURCE_DIR/us-east-1/spine-partner-service/kustomization.yaml",
        "resources": [
          {
            "type": "local",
            "path": "resources/serviceaccount.yaml"
          }
        ],
        "bases": [
          {
            "type": "github",
            "url": "https://github.com/envcorp/scdh-k8s-bases/k8s/spine-partner-service?ref=v2.11",
            "repo": "envcorp/scdh-k8s-bases",
            "path": "k8s/spine-partner-service",
            "ref": "v2.11"
          }
        ],
        "patches": [
          {
            "path": "patches/deployment.yaml"
          },
          {
            "path": "patches/service.yaml"
          }
        ],
        "images": [
          {
            "name": "ENV-docker.jfrog.io/scdh-spine-partner-service",
            "newTag": "v1.4.6"
          }
        ],
        "namePrefix": "spine-partner-service-",
        "namespace": "sc-ordering"
      }
    ],
    "kubernetes_resources": [...],
    "relationships": [...],
    "github_dependencies": [...]
  }
}
```

## Analyzing Output

The output can be used to:

1. **Visualize Service Architecture**: The generated GraphViz graph shows the connections between services and their dependencies.

2. **Identify External Dependencies**: The GitHub dependencies section shows which external repositories are used for base configurations.

3. **Verify Configuration Consistency**: Check that all services follow the expected pattern and identify any outliers.

4. **Track Version Dependencies**: See which versions of base repositories and Docker images are being used.

5. **Document Deployment Structure**: Use the output as documentation for the deployment infrastructure.

## Integration with Other BOFH Tools

This catalog can be integrated with other tools in the BOFH toolkit:

```bash
# Analyze the catalog output
[MCP]
Command: bofh.filesystem.analyze
Parameters:
  directory: /Users/zacelston/AlZacAI/bofh/output
  output: /Users/zacelston/AlZacAI/bofh/analysis
[/MCP]
```

## Following MCP Best Practices

When using these tools, remember to:

1. Work on one task at a time
2. Validate each step before moving to the next
3. Document any issues encountered
4. Focus on specific tasks rather than trying to analyze everything at once
5. Ask if additional tasks are needed before starting them

# ICYAML Docker Usage Guide

## Overview

This guide explains how to use the ICYAML tools with Docker, eliminating dependency issues and ensuring consistent execution across different environments.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. **Build the Docker image**:
   ```bash
   ./docker-run.sh build
   ```

2. **Analyze YAML configuration files for outliers**:
   ```bash
   ./analyze_yaml_outliers_docker.sh
   ```

3. **Run other commands**:
   ```bash
   ./docker-run.sh outliers --dir /data/ENV --threshold 50 --output /data/output/outliers.json
   ./docker-run.sh query --dir /data/ENV --query "select name from metadata when kind is Deployment"
   ```

## Docker Commands

The `docker-run.sh` script provides an easy way to run ICYAML tools in Docker:

- **Build the Docker image**:
  ```bash
  ./docker-run.sh build
  ```

- **Run outlier detection**:
  ```bash
  ./docker-run.sh outliers --dir /data/ENV --threshold 50 --output /data/output/outliers.json
  ```

- **Run YAML query engine**:
  ```bash
  ./docker-run.sh query --dir /data/ENV --query "select name from metadata when kind is Deployment"
  ```

- **Run YAML tree catalogger**:
  ```bash
  ./docker-run.sh scan --dir /data/ENV --pattern "*" --output /data/output/catalog.json --graph /data/output/relationships.dot
  ```

- **Analyze YAML configuration files**:
  ```bash
  ./docker-run.sh analyze-ENV
  ```

- **Catalog YAML configuration files**:
  ```bash
  ./docker-run.sh catalog-ENV
  ```

- **Open a shell in the container**:
  ```bash
  ./docker-run.sh shell
  ```

## Path Mapping

The Docker setup maps local paths to container paths:

- Local SOURCE_DIR path → `/data/ENV` in container
- Local output path → `/data/output` in container
- ICYAML scripts (current directory) → `/app` in container

When providing paths in your commands, use the container paths.

## Environment Variables

You can customize the path mapping by setting environment variables:

```bash
export SOURCE_DIR=/path/to/your/ENV
export OUTPUT_PATH=/path/to/your/output
./docker-run.sh analyze-ENV
```

## Common Use Cases

### Find missing keys in YAML structures

```bash
./docker-run.sh outliers --dir /data/ENV/$SOURCE_DIR --threshold 50 --output /data/output/outliers.json
```

### Query for specific values

```bash
./docker-run.sh query --dir /data/ENV --query "select name from metadata when kind is Deployment and report name:name kind:kind" --output /data/output/query_results.json
```

### Catalog YAML structures

```bash
./docker-run.sh scan --dir /data/ENV --pattern "*" --output /data/output/catalog.json
```

## Troubleshooting

If you encounter problems:

1. Make sure Docker and Docker Compose are installed and running
2. Verify the paths in the environment variables
3. Check that the required directories exist
4. Build a fresh image with `./docker-run.sh build`
5. Try running a simpler command like `./docker-run.sh shell` to debug

## Benefits of the Docker Approach

- Eliminates dependency issues
- Ensures consistent execution across environments
- Simplifies setup (no need to install Python packages)
- Isolates the tools from your system
- Makes it easy to share with others

Happy YAML analyzing!

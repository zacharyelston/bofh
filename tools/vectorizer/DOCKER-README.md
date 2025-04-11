# DISKVOYEUR - Docker-Based Filesystem Analysis

This is a Docker-based implementation of DISKVOYEUR, making it easier to analyze any filesystem without installing dependencies on your host system.

## Quick Start

The simplest way to analyze a directory is using the helper script:

```bash
# Make the script executable
chmod +x ./analyze-directory.sh

# Analyze a directory
./analyze-directory.sh /path/to/directory
```

This will:
1. Create a tarball of the target directory
2. Extract it into the Docker container's input directory
3. Run the DISKVOYEUR analysis
4. Generate interactive visualizations
5. Output results to `./data/output`

## Manual Usage

If you prefer more control, you can use Docker Compose directly:

```bash
# Create input/output directories
mkdir -p ./data/input ./data/output

# Copy files to analyze into the input directory
cp -r /path/to/analyze/* ./data/input/

# Run the analysis
docker-compose up diskvoyeur

# Generate visualizations
docker-compose up diskvoyeur-viz
```

## Viewing Results

Results are stored in the `./data/output` directory. Open `./data/output/index.html` in a web browser to view interactive visualizations.

Key visualizations include:
- Interactive file scatter plot showing relationships
- Timeline of file modifications
- Treemap showing file sizes and types
- Anomaly details and visualizations
- Static charts showing clusters and patterns

## Advanced Usage

### Custom Analysis

You can modify the analysis parameters by editing the `docker-compose.yml` file:

```yaml
services:
  diskvoyeur:
    environment:
      - ANOMALY_THRESHOLD=0.03  # Modify anomaly sensitivity (lower = more anomalies)
      - CLUSTER_COUNT=8         # Number of clusters to find
      - DUPLICATE_THRESHOLD=0.97  # Similarity threshold for duplicates (higher = stricter)
```

### Running Inside a Docker Container

To analyze a directory inside an existing Docker container:

```bash
# From the host, copy the DISKVOYEUR directory into the container
docker cp ./vectorizer container_name:/app/diskvoyeur

# Enter the container
docker exec -it container_name /bin/bash

# Inside the container, run DISKVOYEUR
cd /app/diskvoyeur
./analyze-directory.sh /path/to/analyze
```

## Features

- **No Host Dependencies**: All dependencies are contained within Docker
- **Interactive Visualizations**: HTML-based visualizations for exploring results
- **Anomaly Detection**: Find unusual files that don't fit patterns
- **Clustering**: Group similar files automatically
- **Duplicate Detection**: Find exact and near-duplicate files
- **Timeline Analysis**: View file changes over time

## Technical Details

The Docker setup includes:
- Python 3.9 with scientific libraries
- DISKVOYEUR analysis modules
- Visualization tools using Matplotlib and Plotly
- Custom analysis scripts

## Example Outputs

### Anomaly Detection

```
Detected 15 anomalous files (5.0% of total)

Top 10 anomalous files:
1. /data/input/config/secrets.yaml
2. /data/input/logs/error_2023-05-01.log
3. /data/input/src/main.py.bak
4. /data/input/data/.hidden_file
5. /data/input/bin/core_dump
```

### Duplicate Files

```
Found 3 duplicate groups:

Group 1:
  - /data/input/docs/report.pdf
  - /data/input/backup/docs/report.pdf

Group 2:
  - /data/input/src/utils.py
  - /data/input/src/backup/utils.py
  - /data/input/src/old/utils.py
```

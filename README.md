# BOFH Toolkit

## Overview

The BOFH (Bastard Operator From Hell) Toolkit is a collection of system administration and Docker management utilities designed to simplify common tasks like filesystem analysis, data visualization, and Docker container management.

## Key Features

- **Filesystem Analysis**: Analyze directory structures and generate insights
- **Data Visualization**: Create visual representations of analyzed data
- **Docker Management**: Simplified Docker container and image management
- **Archive Creation**: Create and manage archive files for backups and transfers
- **ModelContextProtocol (MCP)**: Structured protocol for toolkit interaction

## Components

The toolkit is organized into several key components:

- **vectorizer**: Analyzes and visualizes directory structures
- **find2tar**: Extracts and archives specific files and directories
- **schema_search_example**: Sample implementation for searching file schemas
- **bofh.sh**: Main entry point script for the toolkit

## Requirements

### System Requirements

- macOS (tested on latest version)
- Docker Desktop
- Python 3.9+
- Git

### Python Dependencies

- numpy
- pandas
- scikit-learn
- matplotlib
- seaborn
- plotly
- networkx
- python-louvain
- umap-learn

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/AlZacAI/bofh.git
   cd bofh
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Ensure Docker Desktop is running:
   ```bash
   docker info
   ```

## Usage

### Analyze a Directory

```bash
./vectorizer/analyze-directory.sh /path/to/directory
```

### Create an Archive from Search Results

```bash
./find2tar/find2tar.sh /path/to/search -name "*.txt" -o output.tar.gz
```

### Run a Schema Search

```bash
./schema_search_example/search_schema.sh /path/to/data pattern
```

### Using the MCP Interface

The toolkit implements the ModelContextProtocol (MCP) for structured interaction:

```
[MCP]
Command: bofh.filesystem.analyze
Parameters:
  directory: /path/to/target
  output: /path/to/output
[/MCP]
```

See `prompt.yaml` for detailed MCP documentation.

## Directory Structure

```
bofh/
├── bofh.sh                # Main entry script
├── config.sh              # Global configuration
├── prompt.yaml            # MCP documentation
├── vectorizer/            # Directory analysis and visualization
├── find2tar/              # File search and archive utilities
└── schema_search_example/ # Schema search examples
```

## Testing

Run the test suite:

```bash
./run_tests.sh
```

## Troubleshooting

Common issues:

1. **Docker not running**: Ensure Docker Desktop is started
2. **Permission denied**: Run with appropriate permissions 
3. **ContainerConfig error**: Clean Docker resources with `./reset-docker.sh`

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

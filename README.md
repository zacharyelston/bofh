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
- **schema_search**: Sample implementation for searching file schemas
- **bin/bofh**: Main entry point script for the toolkit

## Directory Structure

The BOFH toolkit uses the following directory structure:

```
/Users/zacelston/AlZacAI/bofh/
├── bin/                        # Entry point scripts
│   └── bofh                    # Main command
├── config/                     # Configuration files
│   └── mcp/                    # MCP configuration
│       └── prompt.yaml         # MCP protocol definition
├── lib/                        # Core library functions
│   └── filesystem/             # Filesystem utilities
│       └── analysis/           # Analysis functions
├── tools/                      # Individual tools
│   ├── vectorizer/             # Directory analysis tool
│   ├── find2tar/               # Search and archive tool
│   └── schema_search/          # Schema search tool
├── tests/                      # Test suites
│   ├── unit/                   # Unit tests
│   └── run_tests.sh            # Test runner
├── README.md                   # This file
├── TODO.md                     # Todo list
├── prompt.yaml                 # MCP documentation
└── test_plan.md                # Testing plan
```

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
   git clone https://github.com/yourusername/bofh.git
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

### Using the Main Command

The main `bofh` command provides a unified interface to all toolkit functions:

```bash
./bin/bofh <command> [options]
```

### Analyze a Directory

```bash
./bin/bofh analyze /path/to/directory
```

or directly:

```bash
./tools/vectorizer/analyze-directory.sh /path/to/directory
```

### Find and Archive Files

```bash
./bin/bofh archive /path/to/search -o output.tar.gz
```

or directly:

```bash
./tools/find2tar/mcp_directory_scanner.sh /path/to/search
```

### Run a Schema Search

```bash
./bin/bofh schema /path/to/data pattern
```

or directly:

```bash
./tools/schema_search/find_schemas.sh /path/to/data pattern
```

### Find All Files in the Project

The toolkit leverages standard Unix utilities enhanced with additional functionality:

```bash
find /Users/zacelston/AlZacAI/bofh -type f -not -path '*/\.*'
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

## Testing

Run the test suite:

```bash
./tests/run_tests.sh
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

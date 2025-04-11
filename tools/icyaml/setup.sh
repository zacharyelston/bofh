#!/bin/bash
# Setup script for ICYAML

echo "Setting up ICYAML (I See YAML)..."

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$(dirname "$0")/icyaml_main"
chmod +x "$(dirname "$0")/icyaml_query"
chmod +x "$(dirname "$0")/catalog_yaml_atlas.sh"
chmod +x "$(dirname "$0")/query_yaml_atlas.sh"
chmod +x "$(dirname "$0")/find_outliers.sh"
chmod +x "$(dirname "$0")/analyze_yaml_outliers.sh"
chmod +x "$(dirname "$0")/mcp_yaml_catalogger.sh"
chmod +x "$(dirname "$0")/mcp_yaml_catalogger_enhanced.sh"
chmod +x "$(dirname "$0")/mcp_yaml_query.sh"

# Create symlinks in parent directory
echo "Creating symlinks in tools directory..."
ln -sf "$(dirname "$0")/icyaml_main" "$(dirname "$0")/../icyaml"
ln -sf "$(dirname "$0")/icyaml_query" "$(dirname "$0")/../icyaml_query"
ln -sf "$(dirname "$0")/find_outliers.sh" "$(dirname "$0")/../icyaml_outliers"

# Create output directory
echo "Creating output directory..."
mkdir -p "/Users/zacelston/AlZacAI/bofh/output"

# Create symbolic link for main executable
echo "Creating main executable symlink..."
ln -sf "$(dirname "$0")/icyaml_main" "$(dirname "$0")/icyaml"

echo "Setup complete!"
echo ""
echo "Usage:"
echo "  ./icyaml help                        # Show help"
echo "  ./icyaml scan -d /path/to/dir        # Basic scan"
echo "  ./icyaml scan-enhanced -d /path/to/dir # Enhanced scan"
echo "  ./icyaml query -d /path/to/dir -q \"query\" # SQL-like query"
echo ""
echo "Finding outliers and structure differences:"
echo "  ./find_outliers.sh --dir /path/to/dir  # Find missing keys and structure outliers"
echo "  ./analyze_yaml_outliers.sh             # Analyze YAML configuration files for outliers"
echo ""
echo "Ready-to-use scripts:"
echo "  ./catalog_yaml_atlas.sh               # Scan YAML configuration files"
echo "  ./query_yaml_atlas.sh deployments     # Find deployments in YAML configuration files"
echo "  ./query_yaml_atlas.sh custom \"query\"  # Custom query on YAML configuration files"
echo ""
echo "MCP Protocol Usage:"
echo "  ./mcp_yaml_catalogger.sh \"[MCP] Command: bofh.filesystem.yaml_catalog ...\""
echo "  ./mcp_yaml_query.sh \"[MCP] Command: bofh.filesystem.yaml_query ...\""
echo ""
echo "Note: You may need to install dependencies:"
echo "  pip install pyyaml"
echo "  brew install graphviz    # For macOS"
echo "  apt install graphviz     # For Ubuntu"

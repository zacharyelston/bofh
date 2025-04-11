#!/bin/bash
# Setup script for ICYAML Docker

echo "Setting up ICYAML Docker..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="$PARENT_DIR/output"

# Make Docker scripts executable
echo "Making Docker scripts executable..."
chmod +x "$SCRIPT_DIR/docker-run.sh"
chmod +x "$SCRIPT_DIR/analyze_yaml_outliers_docker.sh"

# Create output directory
echo "Creating output directory..."
mkdir -p "$OUTPUT_DIR"

# Create Docker aliases
echo "Creating Docker aliases..."
cat > "$SCRIPT_DIR/icyaml_docker_aliases.sh" << 'EOF'
# ICYAML Docker aliases
alias icyaml-docker="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/docker-run.sh"
alias icyaml-build="icyaml-docker build"
alias icyaml-outliers="icyaml-docker outliers"
alias icyaml-query="icyaml-docker query"
alias icyaml-scan="icyaml-docker scan"
alias icyaml-analyze-ENV="icyaml-docker analyze-ENV"
alias icyaml-catalog-ENV="icyaml-docker catalog-ENV"
alias icyaml-shell="icyaml-docker shell"
EOF

echo "Removing existing Docker image (if any)..."
docker-compose down
docker rmi icyaml:latest 2>/dev/null || true

echo "Building Docker image..."
"$SCRIPT_DIR/docker-run.sh" build

echo "Setup complete!"
echo ""
echo "To use ICYAML with Docker:"
echo ""
echo "1. Run analysis with Docker:"
echo "   ./docker-run.sh outliers --dir /data/ENV --threshold 50"
echo "   ./analyze_yaml_outliers_docker.sh"
echo ""
echo "2. (Optional) Source the aliases for easier usage:"
echo "   source $SCRIPT_DIR/icyaml_docker_aliases.sh"
echo ""
echo "   Then you can use:"
echo "   icyaml-outliers --dir /data/ENV"
echo "   icyaml-query --dir /data/ENV --query \"select name from metadata when kind is Deployment\""
echo "   icyaml-analyze-ENV"
echo ""
echo "For more information, see README_DOCKER.md"

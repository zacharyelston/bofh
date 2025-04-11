#!/bin/bash
# Script to completely reset Docker state for BOFH toolkit

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} Stopping all BOFH containers..."
docker stop diskvoyeur_analyzer diskvoyeur_visualizer 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Removing all BOFH containers..."
docker rm -f diskvoyeur_analyzer diskvoyeur_visualizer 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Removing all BOFH images..."
docker rmi -f vectorizer_diskvoyeur vectorizer_diskvoyeur-viz 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Pruning volumes..."
docker volume prune -f 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Pruning networks..."
docker network prune -f 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} Docker environment reset complete!"

#!/bin/bash
# BOFH Configuration File
# Contains all configurable parameters for the BOFH tool suite

# Base directory where BOFH is installed
BOFH_HOME="${BOFH_HOME:-$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")}"

# Default directories for searches (can be overridden via command line)
DEFAULT_CODE_DIR="${DEFAULT_CODE_DIR:-/var/www/html}"
DEFAULT_OUTPUT_DIR="${DEFAULT_OUTPUT_DIR:-$BOFH_HOME/output}"

# Schema search configuration
SCHEMA_SEARCH_EXAMPLE_DIR="$BOFH_HOME/schema_search_example"

# Database types to search for
DB_TYPES=(
  "postgres"
  "mysql"
  "oracle"
  "mssql"
  "sqlite"
  "dynamodb"
  "redshift"
  "athena"
)

# File extensions to search
SQL_EXTENSIONS=(
  "sql"
  "ddl"
  "hql"
  "prisma"
)

# BOFH excuse file (uncomment to use file instead of hardcoded excuses)
# EXCUSE_FILE="$BOFH_HOME/data/excuses.txt"

# Debug level (0=none, 1=basic, 2=verbose)
DEBUG_LEVEL=1

# Colorize output (0=off, 1=on)
USE_COLORS=1

# Backup settings
BACKUP_DIR="$BOFH_HOME/backups"
MAX_BACKUPS=5

# Default user to blame for system issues
DEFAULT_VICTIM="dev-team"

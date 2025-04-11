#!/bin/bash

# ModelContextProtocol Batch Processor
# This tool implements an MCP-compliant process for:
# 1. Finding relevant files (by time, pattern, etc.)
# 2. Packaging them into a single archive
# 3. Reading the entire package as a single stream with file metadata
#
# Following MCP principles:
# - Process over implementation
# - Security through repetition
# - One thing at a time with validation
# - Careful, deliberate execution

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
SEARCH_DIR="."
OUTPUT_DIR="./mcp_output"
ARCHIVE_NAME="mcp_batch.tar"
TMP_DIR="/tmp/mcp_tmp"
MTIME=1
FILE_PATTERN="*"
EXCLUDE_PATTERN=""
EXCLUDE_DIRS=".git node_modules dist build tmp"
VERBOSE=0
MODE="collect"
FORMAT="text"
MAX_FILES=5000
MAX_SIZE="100M"

# Function for MCP-compliant logging
mcp_log() {
  local level=$1
  local message=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  if [ "$level" = "INFO" ] && [ $VERBOSE -eq 1 ]; then
    echo -e "${GREEN}[$timestamp] [MCP-INFO] $message${NC}"
  elif [ "$level" = "WARN" ]; then
    echo -e "${YELLOW}[$timestamp] [MCP-WARN] $message${NC}"
  elif [ "$level" = "ERROR" ]; then
    echo -e "${RED}[$timestamp] [MCP-ERROR] $message${NC}" >&2
  elif [ "$level" = "DEBUG" ] && [ $VERBOSE -eq 1 ]; then
    echo -e "${BLUE}[$timestamp] [MCP-DEBUG] $message${NC}"
  elif [ "$level" = "STEP" ]; then
    echo -e "${GREEN}[$timestamp] [MCP-STEP] $message${NC}"
  fi
}

# Print usage information
show_usage() {
  cat << EOF
ModelContextProtocol Batch Processor

USAGE:
  ./mcp_batch_processor.sh [OPTIONS] COMMAND

COMMANDS:
  collect              Find and package files
  read                 Read and stream packaged files
  
OPTIONS:
  -d, --dir DIR        Directory to search (default: current directory)
  -o, --output DIR     Output directory (default: ./mcp_output)
  -a, --archive NAME   Archive name (default: mcp_batch.tar)
  -m, --mtime DAYS     Find files modified in last N days (default: 1)
  -p, --pattern PAT    File pattern to include (default: *)
  -e, --exclude PAT    File pattern to exclude
  -E, --exclude-dir D  Directory to exclude (can be used multiple times)
  -f, --format FMT     Output format: text|json (default: text)
  -n, --max-files N    Maximum number of files to process (default: 5000)
  -s, --max-size SIZE  Maximum total size (default: 100M)
  -v, --verbose        Enable verbose logging
  -h, --help           Show this help message

EXAMPLES:
  # Collect all files modified in the last 2 days
  ./mcp_batch_processor.sh -m 2 collect
  
  # Collect only JavaScript files
  ./mcp_batch_processor.sh -p "*.js" collect
  
  # Read and stream the collected archive
  ./mcp_batch_processor.sh read
  
  # Exclude temporary files and output in JSON format
  ./mcp_batch_processor.sh -e "*.tmp" -f json collect
  
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      SEARCH_DIR="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -a|--archive)
      ARCHIVE_NAME="$2"
      shift 2
      ;;
    -m|--mtime)
      MTIME="$2"
      shift 2
      ;;
    -p|--pattern)
      FILE_PATTERN="$2"
      shift 2
      ;;
    -e|--exclude)
      EXCLUDE_PATTERN="$2"
      shift 2
      ;;
    -E|--exclude-dir)
      EXCLUDE_DIRS="$EXCLUDE_DIRS $2"
      shift 2
      ;;
    -f|--format)
      FORMAT="$2"
      shift 2
      ;;
    -n|--max-files)
      MAX_FILES="$2"
      shift 2
      ;;
    -s|--max-size)
      MAX_SIZE="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    collect)
      MODE="collect"
      shift
      ;;
    read)
      MODE="read"
      shift
      ;;
    *)
      mcp_log "ERROR" "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Full archive path
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"
METADATA_PATH="$OUTPUT_DIR/metadata.json"
FILE_LIST_PATH="$OUTPUT_DIR/file_list.txt"

# Function to check dependencies
check_dependencies() {
  mcp_log "STEP" "Checking dependencies"
  
  local missing=0
  for cmd in find tar jq; do
    if ! command -v $cmd &> /dev/null; then
      mcp_log "ERROR" "Required command not found: $cmd"
      ((missing++))
    fi
  done
  
  if [ $missing -gt 0 ]; then
    mcp_log "ERROR" "Missing $missing required dependencies. Please install them and try again."
    exit 1
  fi
  
  mcp_log "INFO" "All dependencies satisfied"
}

# Function to create necessary directories
create_directories() {
  mcp_log "STEP" "Creating necessary directories"
  
  # Create output directory if it doesn't exist
  if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    mcp_log "INFO" "Created output directory: $OUTPUT_DIR"
  fi
  
  # Create temporary directory
  if [ ! -d "$TMP_DIR" ]; then
    mkdir -p "$TMP_DIR"
    mcp_log "INFO" "Created temporary directory: $TMP_DIR"
  fi
}

# Function to find files based on criteria
find_files() {
  mcp_log "STEP" "Finding files modified in the last $MTIME days"
  
  # Build the find command with all options
  local find_cmd="find \"$SEARCH_DIR\" -type f -mtime -$MTIME"
  
  # Add pattern if specified
  if [ "$FILE_PATTERN" != "*" ]; then
    find_cmd="$find_cmd -name \"$FILE_PATTERN\""
  fi
  
  # Add exclude pattern if specified
  if [ -n "$EXCLUDE_PATTERN" ]; then
    find_cmd="$find_cmd -not -name \"$EXCLUDE_PATTERN\""
  fi
  
  # Add exclude directories
  for dir in $EXCLUDE_DIRS; do
    find_cmd="$find_cmd -not -path \"*/$dir/*\""
  done
  
  mcp_log "DEBUG" "Find command: $find_cmd"
  
  # Run the find command and save results to file list
  eval $find_cmd > "$FILE_LIST_PATH"
  
  # Count files found
  local file_count=$(wc -l < "$FILE_LIST_PATH")
  
  if [ $file_count -eq 0 ]; then
    mcp_log "WARN" "No matching files found"
    exit 0
  fi
  
  # Check if we exceed max files
  if [ $file_count -gt $MAX_FILES ]; then
    mcp_log "WARN" "Found $file_count files, but max is set to $MAX_FILES"
    mcp_log "INFO" "Keeping only the $MAX_FILES most recently modified files"
    
    # Sort by modification time (newest first) and keep only MAX_FILES
    find "$SEARCH_DIR" -type f -mtime -$MTIME -printf "%T@ %p\n" | 
      sort -nr | 
      head -n $MAX_FILES | 
      cut -d' ' -f2- > "$FILE_LIST_PATH.tmp"
    
    mv "$FILE_LIST_PATH.tmp" "$FILE_LIST_PATH"
    file_count=$MAX_FILES
  fi
  
  mcp_log "INFO" "Found $file_count files matching criteria"
  
  # Calculate total size
  local total_size=0
  while IFS= read -r file; do
    if [ -f "$file" ]; then
      file_size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
      total_size=$((total_size + file_size))
    fi
  done < "$FILE_LIST_PATH"
  
  # Convert MAX_SIZE to bytes
  local max_size_bytes=$(echo $MAX_SIZE | numfmt --from=iec 2>/dev/null || echo $MAX_SIZE)
  
  if [ $total_size -gt $max_size_bytes ]; then
    mcp_log "WARN" "Total size ($total_size bytes) exceeds maximum ($MAX_SIZE)"
    mcp_log "INFO" "Will truncate file list to fit size limit"
    
    # Sort by size (smallest first) to maximize file count
    local new_total=0
    local new_list="$FILE_LIST_PATH.tmp"
    > "$new_list"
    
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        file_size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
        if [ $((new_total + file_size)) -le $max_size_bytes ]; then
          echo "$file" >> "$new_list"
          new_total=$((new_total + file_size))
        fi
      fi
    done < <(find "$SEARCH_DIR" -type f -mtime -$MTIME -printf "%s %p\n" | sort -n | cut -d' ' -f2-)
    
    mv "$new_list" "$FILE_LIST_PATH"
    file_count=$(wc -l < "$FILE_LIST_PATH")
    mcp_log "INFO" "Reduced to $file_count files with total size of $new_total bytes"
  fi
  
  return $file_count
}

# Function to create metadata JSON
create_metadata() {
  mcp_log "STEP" "Creating metadata"
  
  local file_count=$1
  local total_size=0
  local files_json="["
  local first=1
  
  while IFS= read -r file; do
    if [ -f "$file" ]; then
      local file_size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
      local file_mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
      local file_type=$(file -b --mime-type "$file")
      
      # Convert mtime to ISO format
      local mtime_iso=$(date -d @$file_mtime "+%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -r $file_mtime "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
      
      # Add comma if not first item
      if [ $first -eq 0 ]; then
        files_json="$files_json,"
      else
        first=0
      fi
      
      # JSON for this file
      files_json="$files_json
      {
        \"path\": \"$file\",
        \"size\": $file_size,
        \"modified\": \"$mtime_iso\",
        \"type\": \"$file_type\"
      }"
      
      total_size=$((total_size + file_size))
    fi
  done < "$FILE_LIST_PATH"
  
  files_json="$files_json
  ]"
  
  # Create full metadata JSON
  cat > "$METADATA_PATH" << EOF
{
  "created": "$(date "+%Y-%m-%dT%H:%M:%S")",
  "search_directory": "$SEARCH_DIR",
  "modified_days": $MTIME,
  "file_pattern": "$FILE_PATTERN",
  "exclude_pattern": "$EXCLUDE_PATTERN",
  "file_count": $file_count,
  "total_size": $total_size,
  "files": $files_json
}
EOF
  
  mcp_log "INFO" "Metadata written to $METADATA_PATH"
}

# Function to create the archive
create_archive() {
  mcp_log "STEP" "Creating archive"
  
  if [ ! -f "$FILE_LIST_PATH" ]; then
    mcp_log "ERROR" "File list not found: $FILE_LIST_PATH"
    exit 1
  fi
  
  mcp_log "INFO" "Creating archive at $ARCHIVE_PATH"
  
  # Create tar archive from file list
  tar -cf "$ARCHIVE_PATH" -T "$FILE_LIST_PATH"
  
  if [ $? -eq 0 ]; then
    local archive_size=$(stat -c %s "$ARCHIVE_PATH" 2>/dev/null || stat -f %z "$ARCHIVE_PATH" 2>/dev/null)
    local human_size=$(echo $archive_size | numfmt --to=iec 2>/dev/null || echo "$archive_size bytes")
    mcp_log "INFO" "Archive created successfully: $ARCHIVE_PATH ($human_size)"
  else
    mcp_log "ERROR" "Failed to create archive"
    exit 1
  fi
}

# Function to read file contents from archive and stream with metadata
read_archive() {
  mcp_log "STEP" "Reading archive"
  
  if [ ! -f "$ARCHIVE_PATH" ]; then
    mcp_log "ERROR" "Archive not found: $ARCHIVE_PATH"
    exit 1
  fi
  
  # Check if metadata exists
  if [ -f "$METADATA_PATH" ]; then
    mcp_log "INFO" "Using metadata from $METADATA_PATH"
    local file_count=$(jq '.file_count' "$METADATA_PATH")
    local total_size=$(jq '.total_size' "$METADATA_PATH")
    local human_size=$(echo $total_size | numfmt --to=iec 2>/dev/null || echo "$total_size bytes")
    
    mcp_log "INFO" "Archive contains $file_count files with total size $human_size"
  else
    mcp_log "WARN" "Metadata file not found. Limited information available."
  fi
  
  # Create temporary extraction directory
  local extract_dir="$TMP_DIR/mcp_extract_$$"
  mkdir -p "$extract_dir"
  
  # Extract archive to temporary directory
  mcp_log "INFO" "Extracting archive to temporary location"
  tar -xf "$ARCHIVE_PATH" -C "$extract_dir"
  
  if [ $? -ne 0 ]; then
    mcp_log "ERROR" "Failed to extract archive"
    rm -rf "$extract_dir"
    exit 1
  fi
  
  # Process extracted files
  mcp_log "STEP" "Processing files"
  
  # Initialize JSON output if format is json
  if [ "$FORMAT" = "json" ]; then
    echo "{"
    echo "  \"metadata\": $(cat "$METADATA_PATH" 2>/dev/null || echo "null"),"
    echo "  \"files\": ["
  else
    echo "====== MCP BATCH PROCESSOR - FILE CONTENTS ======"
    echo "Archive: $ARCHIVE_PATH"
    echo "======================================================"
  fi
  
  # Find all files in extraction directory
  local file_count=0
  local first=1
  
  while IFS= read -r file; do
    local rel_path="${file#$extract_dir/}"
    
    if [ -f "$file" ]; then
      ((file_count++))
      
      if [ "$FORMAT" = "json" ]; then
        # Add comma separator if not first item
        if [ $first -eq 0 ]; then
          echo ","
        else
          first=0
        fi
        
        # Start file JSON object
        echo -n "    {"
        echo -n "\"path\": \"$rel_path\", "
        
        # Get file stats
        local file_size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
        local file_type=$(file -b --mime-type "$file")
        
        echo -n "\"size\": $file_size, "
        echo -n "\"type\": \"$file_type\", "
        
        # Encode file content as base64 to handle binary files
        if [[ "$file_type" == text/* || "$file_type" == application/json || "$file_type" == application/javascript ]]; then
          echo -n "\"content\": "
          content=$(cat "$file" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g')
          echo -n "\"$content\""
        else
          echo -n "\"encoding\": \"base64\", "
          echo -n "\"content\": \""
          base64 "$file" | tr -d '\n'
          echo -n "\""
        fi
        
        echo -n "}"
      else
        # Text format output
        echo ""
        echo "====== FILE: $rel_path ======"
        echo "Size: $file_size bytes"
        echo "Type: $file_type"
        echo "------------------------------------------------------"
        
        # Output file content based on type
        if [[ "$file_type" == text/* || "$file_type" == application/json || "$file_type" == application/javascript ]]; then
          cat "$file"
        else
          echo "[Binary file - content not displayed]"
        fi
        echo "------------------------------------------------------"
      fi
    fi
  done < <(find "$extract_dir" -type f | sort)
  
  # Finalize JSON output if format is json
  if [ "$FORMAT" = "json" ]; then
    echo ""
    echo "  ]"
    echo "}"
  else
    echo ""
    echo "====== END OF FILE CONTENTS ($file_count files) ======"
  fi
  
  # Clean up temporary directory
  mcp_log "INFO" "Cleaning up temporary files"
  rm -rf "$extract_dir"
}

# Main function for collect mode
collect_files() {
  mcp_log "STEP" "Starting file collection"
  
  # Find files meeting our criteria
  find_files
  file_count=$?
  
  if [ $file_count -eq 0 ]; then
    mcp_log "WARN" "No files found matching criteria"
    exit 0
  fi
  
  # Create metadata
  create_metadata $file_count
  
  # Create the archive
  create_archive
  
  mcp_log "STEP" "File collection complete"
  echo ""
  echo "ModelContextProtocol Batch Processor - Summary"
  echo "==========================================================="
  echo "Files collected: $file_count"
  echo "Archive: $ARCHIVE_PATH"
  echo "Metadata: $METADATA_PATH"
  echo ""
  echo "To read this archive: ./mcp_batch_processor.sh read"
  echo "==========================================================="
}

# Main execution
check_dependencies
create_directories

if [ "$MODE" = "collect" ]; then
  collect_files
elif [ "$MODE" = "read" ]; then
  read_archive
else
  mcp_log "ERROR" "Invalid mode: $MODE"
  show_usage
  exit 1
fi

exit 0
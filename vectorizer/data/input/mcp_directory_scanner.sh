#!/bin/bash

# MCP Directory Scanner - ModelContextProtocol Directory Processing
# This script provides efficient directory scanning and archive handling
# Version: 1.0
# Author: ProjectManager

# Print banner
echo "========================================="
echo "MCP Directory Scanner"
echo "ModelContextProtocol Directory Processing"
echo "========================================="

# Function to show usage
show_usage() {
    echo "Usage: $0 [options] <directory or archive>"
    echo ""
    echo "Options:"
    echo "  -j, --json                Output in JSON format"
    echo "  -d, --max-depth=N         Maximum directory depth to scan"
    echo "  -e, --extract=PATTERN     Extract files matching pattern from archives"
    echo "  -t, --type=TYPE           Process specific file types only (e.g., 'js,md,txt')"
    echo "  -s, --stats               Show detailed statistics"
    echo "  -h, --help                Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/directory     Scan a directory"
    echo "  $0 archive.tar.gz         List contents of a tar.gz archive"
    echo "  $0 --extract=*.json archive.tar.gz   Extract JSON files from archive"
    exit 1
}

# Function to check dependencies
check_deps() {
    local missing=0
    
    for cmd in find stat tar gzip bzip2 xz jq; do
        if ! command -v $cmd &> /dev/null; then
            echo "Warning: $cmd not found. Some features may not work."
            ((missing++))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        echo "$missing dependencies missing. Continue? (y/n)"
        read -r response
        if [[ "$response" != "y" ]]; then
            echo "Exiting."
            exit 1
        fi
    fi
}

# Function to detect input type
detect_input_type() {
    if [ ! -e "$1" ]; then
        echo "Error: '$1' does not exist."
        exit 1
    elif [ -d "$1" ]; then
        echo "directory"
    elif [[ "$1" == *.tar ]]; then
        echo "tar"
    elif [[ "$1" == *.tar.gz || "$1" == *.tgz ]]; then
        echo "tar.gz"
    elif [[ "$1" == *.tar.bz2 || "$1" == *.tbz2 ]]; then
        echo "tar.bz2"
    elif [[ "$1" == *.tar.xz ]]; then
        echo "tar.xz"
    elif [[ "$1" == *.zip ]]; then
        echo "zip"
    else
        echo "unknown"
    fi
}

# Function to scan directory
scan_directory() {
    local dir="$1"
    local max_depth="$2"
    local file_type="$3"
    local json="$4"
    local stats="$5"
    
    local depth_arg=""
    if [ -n "$max_depth" ]; then
        depth_arg="-maxdepth $max_depth"
    fi
    
    local type_arg=""
    if [ -n "$file_type" ]; then
        IFS=',' read -ra types <<< "$file_type"
        type_arg="-type f "
        for t in "${types[@]}"; do
            type_arg+=" -name \"*.$t\" -o"
        done
        type_arg=${type_arg:0:-3}  # Remove trailing " -o"
    fi
    
    echo "Scanning directory: $dir"
    echo "Start time: $(date)"
    
    if [ "$json" = true ]; then
        # JSON output
        if [ -n "$type_arg" ]; then
            find "$dir" $depth_arg $type_arg -printf '{"path":"%p","type":"%y","size":%s,"modified":"%TF %TT"}\n' | jq -s '.'
        else
            find "$dir" $depth_arg -printf '{"path":"%p","type":"%y","size":%s,"modified":"%TF %TT"}\n' | jq -s '.'
        fi
    else
        # Human-readable output
        if [ -n "$type_arg" ]; then
            find "$dir" $depth_arg $type_arg -printf "[%y] %p (%s bytes, mod: %TF %TT)\n"
        else
            find "$dir" $depth_arg -printf "[%y] %p (%s bytes, mod: %TF %TT)\n"
        fi
    fi
    
    echo "End time: $(date)"
    
    # Show statistics if requested
    if [ "$stats" = true ]; then
        echo -e "\nDirectory Statistics:"
        echo "Total directories: $(find "$dir" $depth_arg -type d | wc -l)"
        echo "Total files: $(find "$dir" $depth_arg -type f | wc -l)"
        echo "Total size: $(du -sh "$dir" | cut -f1)"
        
        if [ -n "$file_type" ]; then
            echo -e "\nFile type distribution:"
            find "$dir" $depth_arg -type f -exec basename {} \; | grep -o "\.[^\.]*$" | sort | uniq -c | sort -rn
        fi
    fi
}

# Function to process a tar archive
process_tar() {
    local archive="$1"
    local extract_pattern="$2"
    local json="$3"
    local cmd="tar"
    
    echo "Processing archive: $archive"
    echo "Archive type: $(detect_input_type "$archive")"
    echo "Start time: $(date)"
    
    case "$(detect_input_type "$archive")" in
        tar)     cmd="tar tf" ;;
        tar.gz)  cmd="tar tzf" ;;
        tar.bz2) cmd="tar tjf" ;;
        tar.xz)  cmd="tar tJf" ;;
        zip)     cmd="unzip -l" ;;
        *)
            echo "Error: Unsupported archive format."
            exit 1
            ;;
    esac
    
    if [ -n "$extract_pattern" ]; then
        echo "Extracting files matching: $extract_pattern"
        
        # Create extraction directory
        extract_dir="./extracted_$(basename "$archive" | tr '.' '_')"
        mkdir -p "$extract_dir"
        
        case "$(detect_input_type "$archive")" in
            tar)     tar xf "$archive" -C "$extract_dir" --wildcards "*$extract_pattern*" ;;
            tar.gz)  tar xzf "$archive" -C "$extract_dir" --wildcards "*$extract_pattern*" ;;
            tar.bz2) tar xjf "$archive" -C "$extract_dir" --wildcards "*$extract_pattern*" ;;
            tar.xz)  tar xJf "$archive" -C "$extract_dir" --wildcards "*$extract_pattern*" ;;
            zip)     unzip -j "$archive" "*$extract_pattern*" -d "$extract_dir" ;;
        esac
        
        echo "Extracted files saved to: $extract_dir"
    fi
    
    # List archive contents
    if [ "$json" = true ]; then
        # JSON output - parse the listing into JSON format
        case "$(detect_input_type "$archive")" in
            tar|tar.gz|tar.bz2|tar.xz)
                $cmd "$archive" | awk '{print "{\"path\":\"" $0 "\"}"}' | jq -s '.'
                ;;
            zip)
                unzip -l "$archive" | tail -n +4 | head -n -2 | awk '{$1=""; $2=""; $3=""; print "{\"path\":\"" substr($0,4) "\"}"}' | jq -s '.'
                ;;
        esac
    else
        # Human-readable output
        $cmd "$archive"
    fi
    
    echo "End time: $(date)"
}

# Parse arguments
JSON=false
MAX_DEPTH=""
EXTRACT_PATTERN=""
FILE_TYPE=""
STATS=false
INPUT_PATH=""

while (( "$#" )); do
  case "$1" in
    -j|--json)
      JSON=true
      shift
      ;;
    -d|--max-depth*)
      if [[ "$1" == *=* ]]; then
        MAX_DEPTH="${1#*=}"
      else
        MAX_DEPTH="$2"
        shift
      fi
      shift
      ;;
    -e|--extract*)
      if [[ "$1" == *=* ]]; then
        EXTRACT_PATTERN="${1#*=}"
      else
        EXTRACT_PATTERN="$2"
        shift
      fi
      shift
      ;;
    -t|--type*)
      if [[ "$1" == *=* ]]; then
        FILE_TYPE="${1#*=}"
      else
        FILE_TYPE="$2"
        shift
      fi
      shift
      ;;
    -s|--stats)
      STATS=true
      shift
      ;;
    -h|--help)
      show_usage
      ;;
    -*|--*=)
      echo "Error: Unsupported option $1"
      show_usage
      ;;
    *)
      INPUT_PATH="$1"
      shift
      ;;
  esac
done

# Check if input path was provided
if [ -z "$INPUT_PATH" ]; then
    echo "Error: No input directory or archive specified."
    show_usage
fi

# Check dependencies
check_deps

# Process input based on type
INPUT_TYPE=$(detect_input_type "$INPUT_PATH")

case "$INPUT_TYPE" in
    directory)
        scan_directory "$INPUT_PATH" "$MAX_DEPTH" "$FILE_TYPE" "$JSON" "$STATS"
        ;;
    tar|tar.gz|tar.bz2|tar.xz|zip)
        process_tar "$INPUT_PATH" "$EXTRACT_PATTERN" "$JSON"
        ;;
    unknown)
        echo "Error: '$INPUT_PATH' is not a recognized directory or archive format."
        exit 1
        ;;
esac

echo "Process completed successfully."
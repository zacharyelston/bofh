#!/bin/bash
# DISKVOYEUR - Multi-Dimensional Filesystem Analysis
# Created by ModelContextProtocol (MCP)

VERSION="0.1.0"

# Determine script location for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
OUTPUT_DIR="$SCRIPT_DIR/output"
DEFAULT_DB="$OUTPUT_DIR/vectors.db"
DEBUG_LEVEL=1
USE_COLORS=1

# Text formatting - only if colors are enabled
if [ "$USE_COLORS" -eq 1 ]; then
    bold=$(tput bold)
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    yellow=$(tput setaf 3)
    blue=$(tput setaf 4)
    magenta=$(tput setaf 5)
    cyan=$(tput setaf 6)
    reset=$(tput sgr0)
else
    bold=""
    red=""
    green=""
    yellow=""
    blue=""
    magenta=""
    cyan=""
    reset=""
fi

# Print the banner
function print_banner() {
    clear
    echo "${bold}${cyan}"
    echo "╔╦╗╦╔═╗╦╔═  ╦  ╦╔═╗╦ ╦╔═╗╦ ╦╦═╗"
    echo " ║║║╚═╗╠╩╗  ╚╗╔╝║ ║╚╦╝║╣ ║ ║╠╦╝"
    echo "═╩╝╩╚═╝╩ ╩   ╚╝ ╚═╝ ╩ ╚═╝╚═╝╩╚═"
    echo "${reset}"
    echo "${bold}${green}Multi-Dimensional Filesystem Analysis${reset} - v$VERSION"
    echo "${cyan}ModelContextProtocol (MCP)${reset}"
    echo ""
}

# Debug logging
function log_debug() {
    if [ "$DEBUG_LEVEL" -ge "$1" ]; then
        echo "${blue}[DEBUG:$1]${reset} $2"
    fi
}

# Show help information
function show_help() {
    echo "${bold}${cyan}DISKVOYEUR - Multi-Dimensional Filesystem Analysis${reset}"
    echo ""
    echo "${yellow}Usage:${reset}"
    echo "  diskvoyeur.sh [command] [options]"
    echo ""
    echo "${yellow}Available commands:${reset}"
    echo "  ${bold}analyze${reset}     Analyze a filesystem to create vector representation"
    echo "              Options: --dir=PATH, --output=PATH, --depth=N, --sample=N"
    echo "  ${bold}explore${reset}     Explore a previously generated vector database"
    echo "              Options: --db=PATH, --mode=(cluster|anomaly|duplicate)"
    echo "  ${bold}visualize${reset}   Create visualizations from vector data"
    echo "              Options: --db=PATH, --type=(scatter|heatmap|timeline|graph)"
    echo "  ${bold}help${reset}        Show this help information"
    echo ""
    echo "${yellow}Examples:${reset}"
    echo "  diskvoyeur.sh analyze --dir=/home/user/projects"
    echo "  diskvoyeur.sh explore --db=vectors.db --mode=cluster"
    echo "  diskvoyeur.sh visualize --db=vectors.db --type=scatter"
    echo ""
    echo "${yellow}For more information, see the README.md file.${reset}"
}

# Parse command line options
function parse_options() {
    for arg in "$@"; do
        case "$arg" in
            --dir=*)
                TARGET_DIR="${arg#*=}"
                log_debug 2 "Set target dir to $TARGET_DIR"
                ;;
            --output=*)
                OUTPUT_PATH="${arg#*=}"
                log_debug 2 "Set output path to $OUTPUT_PATH"
                ;;
            --db=*)
                DB_PATH="${arg#*=}"
                log_debug 2 "Set database path to $DB_PATH"
                ;;
            --depth=*)
                MAX_DEPTH="${arg#*=}"
                log_debug 2 "Set max depth to $MAX_DEPTH"
                ;;
            --sample=*)
                SAMPLE_SIZE="${arg#*=}"
                log_debug 2 "Set sample size to $SAMPLE_SIZE"
                ;;
            --mode=*)
                EXPLORE_MODE="${arg#*=}"
                log_debug 2 "Set explore mode to $EXPLORE_MODE"
                ;;
            --type=*)
                VIZ_TYPE="${arg#*=}"
                log_debug 2 "Set visualization type to $VIZ_TYPE"
                ;;
            --debug=*)
                DEBUG_LEVEL="${arg#*=}"
                log_debug 1 "Set debug level to $DEBUG_LEVEL"
                ;;
        esac
    done
}

# Ensure output directory exists
function ensure_output_dir() {
    local dir="${1:-$OUTPUT_DIR}"
    log_debug 1 "Ensuring output directory exists: $dir"
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_debug 1 "Created output directory: $dir"
    fi
}

# Check for required dependencies
function check_dependencies() {
    log_debug 1 "Checking dependencies..."
    
    local missing=0
    
    # Basic Unix tools
    for cmd in find stat grep awk sed sort uniq wc head tail; do
        if ! command -v $cmd &> /dev/null; then
            echo "${red}Error: $cmd not found. This tool is required for basic operation.${reset}"
            ((missing++))
        fi
    done
    
    # Python packages
    if command -v python3 &> /dev/null; then
        for pkg in numpy pandas sklearn matplotlib seaborn; do
            if ! python3 -c "import $pkg" &> /dev/null; then
                echo "${yellow}Warning: Python package $pkg not found. Some functionality may be limited.${reset}"
            fi
        done
    else
        echo "${yellow}Warning: Python not found. Advanced analysis and visualization will be limited.${reset}"
    fi
    
    # Database tools
    if ! command -v sqlite3 &> /dev/null; then
        echo "${yellow}Warning: sqlite3 not found. Vector storage will use CSV files instead.${reset}"
    fi
    
    if [ $missing -gt 0 ]; then
        echo "${red}$missing required dependencies missing. Cannot continue.${reset}"
        exit 1
    fi
    
    log_debug 1 "Dependency check completed."
}

# Analyze filesystem and create vector representation
function analyze_filesystem() {
    # Set default directory if not specified
    TARGET_DIR="${TARGET_DIR:-/tmp}"
    OUTPUT_PATH="${OUTPUT_PATH:-$DEFAULT_DB}"
    MAX_DEPTH="${MAX_DEPTH:-10}"
    SAMPLE_SIZE="${SAMPLE_SIZE:-1000}"
    
    ensure_output_dir "$OUTPUT_DIR"
    
    echo "${yellow}DISKVOYEUR Filesystem Analysis${reset}"
    echo "${cyan}Analyzing directory: ${bold}$TARGET_DIR${reset}"
    echo "${cyan}Maximum depth: ${bold}$MAX_DEPTH${reset}"
    echo "${cyan}Sample size: ${bold}$SAMPLE_SIZE${reset}"
    echo "${cyan}Output will be saved to: ${bold}$OUTPUT_PATH${reset}"
    echo ""
    
    if [ ! -d "$TARGET_DIR" ]; then
        echo "${red}Error: Directory not found: $TARGET_DIR${reset}"
        exit 1
    fi
    
    # Create intermediate files
    RAW_METADATA="$OUTPUT_DIR/raw_metadata.txt"
    FEATURE_VECTORS="$OUTPUT_DIR/feature_vectors.csv"
    
    echo "${bold}Step 1: Collecting filesystem metadata...${reset}"
    # Use find to collect metadata (limit by sample size and depth)
    find "$TARGET_DIR" -type f -maxdepth "$MAX_DEPTH" | head -n "$SAMPLE_SIZE" | xargs -n 100 stat -c "%n|%s|%Y|%a|%F|%u|%g|%h|%X|%Z" 2>/dev/null > "$RAW_METADATA"
    
    echo "Collected metadata for $(wc -l < "$RAW_METADATA") files."
    echo ""
    
    echo "${bold}Step 2: Extracting features...${reset}"
    # Extract features using awk
    echo "path,depth,size_log,age_days,user_r,user_w,user_x,group_r,group_w,group_x,other_r,other_w,other_x,is_hidden,filename_length,has_extension" > "$FEATURE_VECTORS"
    
    awk -F'|' '{
        # Path features
        path = $1;
        depth = gsub("/", "/", path);
        filename = path;
        gsub(".*/", "", filename);
        filename_length = length(filename);
        has_extension = (index(filename, ".") > 0) ? 1 : 0;
        is_hidden = (substr(filename, 1, 1) == ".") ? 1 : 0;
        
        # Metadata features
        size = $2;
        size_log = log(size > 0 ? size : 1);
        modified = $3;
        current_time = systime();
        age_days = (current_time - modified) / 86400;
        
        # Permission features (octal to binary)
        perm = $4;
        user_r = (and(perm, 400) > 0) ? 1 : 0;
        user_w = (and(perm, 200) > 0) ? 1 : 0;
        user_x = (and(perm, 100) > 0) ? 1 : 0;
        group_r = (and(perm, 40) > 0) ? 1 : 0;
        group_w = (and(perm, 20) > 0) ? 1 : 0;
        group_x = (and(perm, 10) > 0) ? 1 : 0;
        other_r = (and(perm, 4) > 0) ? 1 : 0;
        other_w = (and(perm, 2) > 0) ? 1 : 0;
        other_x = (and(perm, 1) > 0) ? 1 : 0;
        
        # Output feature vector
        printf("%s,%d,%.2f,%.2f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", 
               path, depth, size_log, age_days, 
               user_r, user_w, user_x, 
               group_r, group_w, group_x, 
               other_r, other_w, other_x, 
               is_hidden, filename_length, has_extension);
    }' "$RAW_METADATA" >> "$FEATURE_VECTORS"
    
    echo "Extracted features for $(( $(wc -l < "$FEATURE_VECTORS") - 1 )) files."
    echo ""
    
    echo "${bold}Step 3: Creating vector database...${reset}"
    if command -v sqlite3 &> /dev/null; then
        # Create SQLite database
        echo "CREATE TABLE IF NOT EXISTS files (
            path TEXT PRIMARY KEY,
            depth INTEGER,
            size_log REAL,
            age_days REAL,
            user_r INTEGER,
            user_w INTEGER,
            user_x INTEGER,
            group_r INTEGER,
            group_w INTEGER,
            group_x INTEGER,
            other_r INTEGER,
            other_w INTEGER,
            other_x INTEGER,
            is_hidden INTEGER,
            filename_length INTEGER,
            has_extension INTEGER
        );" | sqlite3 "$OUTPUT_PATH"
        
        # Import CSV data
        echo ".mode csv
        .import '$FEATURE_VECTORS' files
        DELETE FROM files WHERE path = 'path';
        CREATE INDEX IF NOT EXISTS idx_path ON files(path);
        CREATE INDEX IF NOT EXISTS idx_size ON files(size_log);
        CREATE INDEX IF NOT EXISTS idx_age ON files(age_days);" | sqlite3 "$OUTPUT_PATH"
        
        echo "Created vector database: $OUTPUT_PATH"
    else
        # Just use the CSV file
        cp "$FEATURE_VECTORS" "$OUTPUT_PATH"
        echo "Created vector CSV file: $OUTPUT_PATH"
    fi
    
    echo ""
    echo "${green}Analysis completed successfully.${reset}"
    echo ""
    echo "To explore the vectors: ./diskvoyeur.sh explore --db=$OUTPUT_PATH"
    echo "To visualize the vectors: ./diskvoyeur.sh visualize --db=$OUTPUT_PATH"
}

# Explore vector database
function explore_vectors() {
    DB_PATH="${DB_PATH:-$DEFAULT_DB}"
    EXPLORE_MODE="${EXPLORE_MODE:-cluster}"
    
    echo "${yellow}DISKVOYEUR Vector Explorer${reset}"
    echo "${cyan}Database: ${bold}$DB_PATH${reset}"
    echo "${cyan}Mode: ${bold}$EXPLORE_MODE${reset}"
    echo ""
    
    if [ ! -f "$DB_PATH" ]; then
        echo "${red}Error: Database file not found: $DB_PATH${reset}"
        exit 1
    fi
    
    # Check if it's an SQLite database or CSV
    if file "$DB_PATH" | grep -q "SQLite"; then
        DB_TYPE="sqlite"
        # Count records
        RECORD_COUNT=$(echo "SELECT COUNT(*) FROM files;" | sqlite3 "$DB_PATH")
        echo "Found $RECORD_COUNT files in SQLite database."
    else
        DB_TYPE="csv"
        # Count records (subtract header)
        RECORD_COUNT=$(( $(wc -l < "$DB_PATH") - 1 ))
        echo "Found $RECORD_COUNT files in CSV database."
    fi
    
    echo ""
    
    case "$EXPLORE_MODE" in
        cluster)
            echo "${bold}Clustering files by similarity...${reset}"
            
            # If Python with sklearn is available, use KMeans clustering
            if command -v python3 &> /dev/null && python3 -c "import sklearn" &> /dev/null; then
                echo "Using KMeans clustering..."
                
                if [ "$DB_TYPE" = "sqlite" ]; then
                    # Export to temporary CSV for Python
                    echo ".mode csv
                    .headers on
                    .output $OUTPUT_DIR/temp_vectors.csv
                    SELECT * FROM files;" | sqlite3 "$DB_PATH"
                    TEMP_FILE="$OUTPUT_DIR/temp_vectors.csv"
                else
                    TEMP_FILE="$DB_PATH"
                fi
                
                # Run clustering
                python3 -c "
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
import os

# Load data
df = pd.read_csv('$TEMP_FILE')
paths = df['path'].values
X = df.drop('path', axis=1).values

# Determine optimal number of clusters (max 20)
n_clusters = min(20, len(X) // 10 + 1)

# Run clustering
kmeans = KMeans(n_clusters=n_clusters, random_state=42)
labels = kmeans.fit_predict(X)

# Group files by cluster
clusters = {}
for i, label in enumerate(labels):
    if label not in clusters:
        clusters[label] = []
    clusters[label].append(paths[i])

# Output results
for label, files in clusters.items():
    print(f'Cluster {label} ({len(files)} files):')
    
    # Group by directory
    dir_counts = {}
    for file in files:
        dirname = os.path.dirname(file)
        if dirname not in dir_counts:
            dir_counts[dirname] = 0
        dir_counts[dirname] += 1
    
    # Get most common directories
    top_dirs = sorted(dir_counts.items(), key=lambda x: x[1], reverse=True)[:3]
    for dirname, count in top_dirs:
        print(f'  {dirname}: {count} files')
    
    # Get most common extensions
    exts = [os.path.splitext(file)[1] for file in files if os.path.splitext(file)[1]]
    if exts:
        ext_counts = {}
        for ext in exts:
            if ext not in ext_counts:
                ext_counts[ext] = 0
            ext_counts[ext] += 1
        
        top_exts = sorted(ext_counts.items(), key=lambda x: x[1], reverse=True)[:3]
        print(f'  Common extensions: {[ext for ext, _ in top_exts]}')
    
    # Get example files
    print(f'  Examples:')
    for file in files[:3]:
        print(f'   - {file}')
    
    print()
"
                # Clean up
                if [ "$DB_TYPE" = "sqlite" ]; then
                    rm "$TEMP_FILE"
                fi
            else
                # Use a simpler approach with awk
                echo "Python with scikit-learn not available. Using simple clustering..."
                
                if [ "$DB_TYPE" = "sqlite" ]; then
                    echo ".mode csv
                    .headers on
                    .output $OUTPUT_DIR/temp_vectors.csv
                    SELECT * FROM files;" | sqlite3 "$DB_PATH"
                    TEMP_FILE="$OUTPUT_DIR/temp_vectors.csv"
                else
                    TEMP_FILE="$DB_PATH"
                fi
                
                # Group by depth and extension
                awk -F, 'NR>1 {
                    # Extract features
                    path = $1;
                    depth = $2;
                    
                    # Get extension
                    ext = "";
                    if (match(path, /\.[^\/\.]+$/)) {
                        ext = substr(path, RSTART, RLENGTH);
                    }
                    
                    # Create cluster key
                    key = depth ":" ext;
                    
                    # Add to cluster
                    clusters[key]++;
                    if (cluster_files[key] == "") {
                        cluster_files[key] = path;
                    } else {
                        cluster_files[key] = cluster_files[key] "," path;
                    }
                }
                END {
                    print "Simple clustering by depth and extension:";
                    print "";
                    
                    # Output clusters
                    n = 0;
                    PROCINFO["sorted_in"] = "@val_num_desc";
                    for (key in clusters) {
                        n++;
                        if (n > 20) break;  # Limit to 20 clusters
                        
                        split(key, parts, ":");
                        depth = parts[1];
                        ext = parts[2];
                        
                        print "Cluster " n " (Depth: " depth ", Extension: " ext ", Files: " clusters[key] "):";
                        
                        # Print example files
                        split(cluster_files[key], files, ",");
                        for (i=1; i<=3 && i<=length(files); i++) {
                            print "  - " files[i];
                        }
                        print "";
                    }
                }' "$TEMP_FILE"
                
                # Clean up
                if [ "$DB_TYPE" = "sqlite" ]; then
                    rm "$TEMP_FILE"
                fi
            fi
            ;;
            
        anomaly)
            echo "${bold}Detecting anomalous files...${reset}"
            
            # If Python with sklearn is available, use Isolation Forest
            if command -v python3 &> /dev/null && python3 -c "import sklearn" &> /dev/null; then
                echo "Using Isolation Forest anomaly detection..."
                
                if [ "$DB_TYPE" = "sqlite" ]; then
                    # Export to temporary CSV for Python
                    echo ".mode csv
                    .headers on
                    .output $OUTPUT_DIR/temp_vectors.csv
                    SELECT * FROM files;" | sqlite3 "$DB_PATH"
                    TEMP_FILE="$OUTPUT_DIR/temp_vectors.csv"
                else
                    TEMP_FILE="$DB_PATH"
                fi
                
                # Run anomaly detection
                python3 -c "
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
import os

# Load data
df = pd.read_csv('$TEMP_FILE')
paths = df['path'].values
X = df.drop('path', axis=1).values

# Detect anomalies
contamination = min(0.05, 10.0 / len(X))  # At most 5% or 10 files
detector = IsolationForest(contamination=contamination, random_state=42)
labels = detector.fit_predict(X)

# Find anomalies
anomalies = [paths[i] for i, label in enumerate(labels) if label == -1]

print(f'Found {len(anomalies)} anomalous files:')
print()

for path in anomalies:
    # Get file info
    size = os.path.getsize(path) if os.path.exists(path) else 'unknown'
    mtime = os.path.getmtime(path) if os.path.exists(path) else 'unknown'
    
    # Extract extension
    ext = os.path.splitext(path)[1]
    
    # Find what's unusual (based on original features)
    file_row = df[df['path'] == path].iloc[0]
    
    unusual_features = []
    
    # Check size
    if file_row['size_log'] > df['size_log'].mean() + 2*df['size_log'].std():
        unusual_features.append('unusually large')
    elif file_row['size_log'] < df['size_log'].mean() - 2*df['size_log'].std():
        unusual_features.append('unusually small')
    
    # Check age
    if file_row['age_days'] > df['age_days'].mean() + 2*df['age_days'].std():
        unusual_features.append('very old')
    elif file_row['age_days'] < df['age_days'].mean() - 2*df['age_days'].std():
        unusual_features.append('very recent')
    
    # Check permissions
    if file_row['other_w'] == 1:
        unusual_features.append('world-writable')
    
    if not unusual_features:
        unusual_features.append('unusual combination of features')
    
    print(f'File: {path}')
    print(f'Size: {size} bytes')
    print(f'Unusual because: {", ".join(unusual_features)}')
    print()
"
                # Clean up
                if [ "$DB_TYPE" = "sqlite" ]; then
                    rm "$TEMP_FILE"
                fi
            else
                # Use a simpler approach with awk
                echo "Python with scikit-learn not available. Using simple anomaly detection..."
                
                if [ "$DB_TYPE" = "sqlite" ]; then
                    echo ".mode csv
                    .headers on
                    .output $OUTPUT_DIR/temp_vectors.csv
                    SELECT * FROM files;" | sqlite3 "$DB_PATH"
                    TEMP_FILE="$OUTPUT_DIR/temp_vectors.csv"
                else
                    TEMP_FILE="$DB_PATH"
                fi
                
                # Find files with unusual characteristics
                awk -F, 'NR==1 {
                    for (i=1; i<=NF; i++) {
                        header[i] = $i;
                    }
                }
                NR>1 {
                    path = $1;
                    
                    # Get unusual features
                    for (i=2; i<=NF; i++) {
                        features[header[i]] = $i;
                    }
                    
                    unusual = 0;
                    reasons = "";
                    
                    # Check for world-writable
                    if (features["other_w"] == 1) {
                        unusual = 1;
                        reasons = reasons "world-writable ";
                    }
                    
                    # Check for hidden but executable
                    if (features["is_hidden"] == 1 && features["user_x"] == 1) {
                        unusual = 1;
                        reasons = reasons "hidden-executable ";
                    }
                    
                    # Very large files
                    if (features["size_log"] > 20) {  # ~400MB+
                        unusual = 1;
                        reasons = reasons "very-large ";
                    }
                    
                    if (unusual) {
                        print "Anomalous file: " path;
                        print "Reasons: " reasons;
                        print "";
                    }
                }' "$TEMP_FILE"
                
                # Clean up
                if [ "$DB_TYPE" = "sqlite" ]; then
                    rm "$TEMP_FILE"
                fi
            fi
            ;;
            
        duplicate)
            echo "${bold}Finding potential duplicate files...${reset}"
            
            # This is a simplistic approach; real deduplication would use content hashing
            
            if [ "$DB_TYPE" = "sqlite" ]; then
                echo "Finding files with identical sizes..."
                echo "
                SELECT f1.path, f2.path, f1.size_log
                FROM files f1
                JOIN files f2 ON f1.size_log = f2.size_log
                WHERE f1.path < f2.path
                  AND f1.filename_length = f2.filename_length
                  AND f1.has_extension = f2.has_extension
                ORDER BY f1.size_log DESC
                LIMIT 20;
                " | sqlite3 -csv "$DB_PATH" | awk -F, '{
                    print "Potential duplicates (same size):";
                    print "  " $1;
                    print "  " $2;
                    print "";
                }'
            else
                echo "Finding files with identical sizes..."
                awk -F, 'NR==1 {
                    for (i=1; i<=NF; i++) {
                        header[i] = $i;
                    }
                }
                NR>1 {
                    path = $1;
                    for (i=2; i<=NF; i++) {
                        if (header[i] == "size_log") {
                            size_log = $i;
                        } else if (header[i] == "filename_length") {
                            filename_length = $i;
                        } else if (header[i] == "has_extension") {
                            has_extension = $i;
                        }
                    }
                    
                    # Create a key for potential duplicates
                    key = size_log ":" filename_length ":" has_extension;
                    
                    if (size_groups[key] == "") {
                        size_groups[key] = path;
                    } else {
                        size_groups[key] = size_groups[key] "," path;
                    }
                }
                END {
                    # Output potential duplicates
                    for (key in size_groups) {
                        split(size_groups[key], paths, ",");
                        if (length(paths) > 1) {
                            print "Potential duplicates (same size):";
                            for (i in paths) {
                                print "  " paths[i];
                            }
                            print "";
                        }
                    }
                }' "$DB_PATH" | head -n 50
            fi
            
            echo ""
            echo "${yellow}Note: For more accurate duplicate detection, use a content-based approach:${reset}"
            echo "  find /path -type f -exec sha256sum {} \; | sort | uniq -w64 -d"
            ;;
            
        *)
            echo "${red}Error: Unknown exploration mode: $EXPLORE_MODE${reset}"
            echo "Available modes: cluster, anomaly, duplicate"
            exit 1
            ;;
    esac
}

# Visualize vector data
function visualize_vectors() {
    DB_PATH="${DB_PATH:-$DEFAULT_DB}"
    VIZ_TYPE="${VIZ_TYPE:-scatter}"
    OUTPUT_IMAGE="$OUTPUT_DIR/viz_${VIZ_TYPE}.png"
    
    ensure_output_dir "$OUTPUT_DIR"
    
    echo "${yellow}DISKVOYEUR Vector Visualization${reset}"
    echo "${cyan}Database: ${bold}$DB_PATH${reset}"
    echo "${cyan}Visualization type: ${bold}$VIZ_TYPE${reset}"
    echo "${cyan}Output image: ${bold}$OUTPUT_IMAGE${reset}"
    echo ""
    
    if [ ! -f "$DB_PATH" ]; then
        echo "${red}Error: Database file not found: $DB_PATH${reset}"
        exit 1
    fi
    
    # Check if Python with matplotlib is available
    if ! command -v python3 &> /dev/null || ! python3 -c "import matplotlib.pyplot" &> /dev/null; then
        echo "${red}Error: Python with matplotlib is required for visualization.${reset}"
        exit 1
    fi
    
    # Check if it's an SQLite database or CSV
    if file "$DB_PATH" | grep -q "SQLite"; then
        DB_TYPE="sqlite"
        # Export to temporary CSV for Python
        echo ".mode csv
        .headers on
        .output $OUTPUT_DIR/temp_vectors.csv
        SELECT * FROM files;" | sqlite3 "$DB_PATH"
        TEMP_FILE="$OUTPUT_DIR/temp_vectors.csv"
    else
        DB_TYPE="csv"
        TEMP_FILE="$DB_PATH"
    fi
    
    case "$VIZ_TYPE" in
        scatter)
            echo "${bold}Creating scatter plot visualization...${reset}"
            
            python3 -c "
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import os

# Load data
df = pd.read_csv('$TEMP_FILE')
if len(df) < 2:
    print('Not enough data points for visualization')
    exit(1)

# Extract features
X = df.drop('path', axis=1).values
paths = df['path'].values

# Reduce to 2D using PCA
pca = PCA(n_components=2)
X_2d = pca.fit_transform(X)

# Get file extensions for coloring
extensions = [os.path.splitext(path)[1] if os.path.splitext(path)[1] else 'none' for path in paths]

# Limit to top 10 extensions
ext_counts = {}
for ext in extensions:
    if ext not in ext_counts:
        ext_counts[ext] = 0
    ext_counts[ext] += 1

top_exts = sorted(ext_counts.items(), key=lambda x: x[1], reverse=True)[:10]
top_ext_set = set([ext for ext, _ in top_exts])
colors = plt.cm.tab10(np.linspace(0, 1, len(top_ext_set)))
ext_to_color = {ext: colors[i] for i, ext in enumerate(top_ext_set)}

# Create plot
plt.figure(figsize=(12, 10))

# Plot each extension group
for ext in top_ext_set:
    mask = [e == ext for e in extensions]
    plt.scatter(X_2d[mask, 0], X_2d[mask, 1], 
                color=ext_to_color[ext], label=ext,
                alpha=0.7, s=50)

# Add other category for remaining extensions
other_mask = [ext not in top_ext_set for ext in extensions]
if any(other_mask):
    plt.scatter(X_2d[other_mask, 0], X_2d[other_mask, 1], 
                color='gray', label='other',
                alpha=0.5, s=30)

plt.title('Filesystem Vector Space (PCA projection)')
plt.legend(title='File Extension')
plt.grid(True, alpha=0.3)
plt.savefig('$OUTPUT_IMAGE', dpi=300, bbox_inches='tight')
print(f'Saved scatter plot to $OUTPUT_IMAGE')
"
            ;;
            
        timeline)
            echo "${bold}Creating timeline visualization...${reset}"
            
            python3 -c "
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import os

# Load data
df = pd.read_csv('$TEMP_FILE')

# Extract age_days and convert to dates
current_time = datetime.now()
dates = [current_time - timedelta(days=float(age)) for age in df['age_days']]
df['date'] = dates

# Group by day and count files
df['day'] = [date.date() for date in df['date']]
daily_counts = df.groupby('day').size()

# Get extension distribution
extensions = [os.path.splitext(path)[1] if os.path.splitext(path)[1] else 'none' for path in df['path']]
df['ext'] = extensions
ext_counts = df.groupby('ext').size().sort_values(ascending=False)

# Create timeline plot
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))

# Activity over time
ax1.bar(daily_counts.index, daily_counts.values, alpha=0.7, color='#1f77b4')
ax1.set_title('File Activity Timeline')
ax1.set_ylabel('Number of Files')
ax1.grid(True, alpha=0.3)
plt.setp(ax1.get_xticklabels(), rotation=45, ha='right')

# Show only top N extensions to avoid cluttering
top_n = min(10, len(ext_counts))
top_exts = ext_counts.head(top_n)
ax2.bar(top_exts.index, top_exts.values, alpha=0.7, color='#ff7f0e')
ax2.set_title(f'Top {top_n} File Extensions')
ax2.set_ylabel('Number of Files')
ax2.grid(True, alpha=0.3)
plt.setp(ax2.get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
plt.savefig('$OUTPUT_IMAGE', dpi=300, bbox_inches='tight')
print(f'Saved timeline to $OUTPUT_IMAGE')
"
            ;;
            
        heatmap)
            echo "${bold}Creating heatmap visualization...${reset}"
            
            python3 -c "
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Load data
df = pd.read_csv('$TEMP_FILE')
if len(df) < 2:
    print('Not enough data points for visualization')
    exit(1)

# Create correlation matrix of features
feature_cols = [col for col in df.columns if col != 'path']
corr_matrix = df[feature_cols].corr()

# Create heatmap
plt.figure(figsize=(12, 10))
sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', fmt='.2f')
plt.title('Feature Correlation Heatmap')
plt.tight_layout()
plt.savefig('$OUTPUT_IMAGE', dpi=300, bbox_inches='tight')
print(f'Saved heatmap to $OUTPUT_IMAGE')
"
            ;;
            
        graph)
            echo "${bold}Creating graph visualization...${reset}"
            
            python3 -c "
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import networkx as nx
import os

# Load data
df = pd.read_csv('$TEMP_FILE')
if len(df) < 2:
    print('Not enough data points for visualization')
    exit(1)

# Create directory structure graph
G = nx.DiGraph()

# Add nodes and edges for directory structure
for path in df['path']:
    parts = path.split('/')
    
    # Skip empty parts and handle absolute/relative paths
    if parts[0] == '':
        parts = parts[1:]
    
    # Process directory hierarchy
    current_path = ''
    for i, part in enumerate(parts):
        if not part:
            continue
            
        # Build the path incrementally
        if current_path:
            parent = current_path
            current_path = current_path + '/' + part
        else:
            parent = '/'
            current_path = '/' + part
        
        # Add node if it doesn't exist
        if not G.has_node(current_path):
            # Add file/directory attribute
            is_file = (i == len(parts) - 1)
            G.add_node(current_path, 
                      type='file' if is_file else 'dir',
                      name=part,
                      depth=i+1)
        
        # Add edge from parent to child
        if parent != current_path:  # Avoid self-loops
            G.add_edge(parent, current_path)

# Limit graph size for visualization
if len(G.nodes) > 100:
    # Keep top-level directories and some sample files
    depths = nx.get_node_attributes(G, 'depth')
    types = nx.get_node_attributes(G, 'type')
    nodes_to_keep = [node for node, depth in depths.items() if depth <= 3]
    nodes_to_keep += [node for node, type in types.items() 
                     if type == 'file' and node not in nodes_to_keep][:50]
    
    G = G.subgraph(nodes_to_keep)

# Set node colors based on type
colors = []
for node in G.nodes:
    if G.nodes[node]['type'] == 'file':
        # Color by extension
        ext = os.path.splitext(node)[1]
        if ext in ['.txt', '.md', '.csv', '.json']:
            colors.append('#1f77b4')  # Text files
        elif ext in ['.jpg', '.png', '.gif']:
            colors.append('#ff7f0e')  # Images
        elif ext in ['.py', '.js', '.sh']:
            colors.append('#2ca02c')  # Code
        else:
            colors.append('#d62728')  # Other files
    else:
        # Directories
        colors.append('#9467bd')

# Create layout
pos = nx.spring_layout(G, seed=42)

# Create plot
plt.figure(figsize=(15, 12))
nx.draw_networkx(G, pos,
                node_color=colors,
                node_size=[100 if G.nodes[node]['type'] == 'dir' else 50 
                          for node in G.nodes],
                with_labels=False,
                arrows=False,
                alpha=0.7,
                width=0.5)

# Add legend
plt.scatter([], [], c='#9467bd', label='Directory')
plt.scatter([], [], c='#1f77b4', label='Text Files')
plt.scatter([], [], c='#ff7f0e', label='Images')
plt.scatter([], [], c='#2ca02c', label='Code')
plt.scatter([], [], c='#d62728', label='Other Files')
plt.legend()

# Add labels for important nodes
labels = {}
for node in G.nodes:
    if G.nodes[node]['depth'] <= 2:
        labels[node] = G.nodes[node]['name']
nx.draw_networkx_labels(G, pos, labels=labels, font_size=8)

plt.title('Filesystem Directory Structure')
plt.axis('off')
plt.tight_layout()
plt.savefig('$OUTPUT_IMAGE', dpi=300, bbox_inches='tight')
print(f'Saved graph to $OUTPUT_IMAGE')
"
            ;;
            
        *)
            echo "${red}Error: Unknown visualization type: $VIZ_TYPE${reset}"
            echo "Available types: scatter, timeline, heatmap, graph"
            exit 1
            ;;
    esac
    
    # Clean up temporary file
    if [ "$DB_TYPE" = "sqlite" ]; then
        rm "$TEMP_FILE"
    fi
    
    echo ""
    echo "${green}Visualization completed successfully.${reset}"
    echo "The visualization has been saved to: $OUTPUT_IMAGE"
}

# Main function
function main() {
    # Parse command line options first
    parse_options "$@"
    
    print_banner
    
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # Check dependencies
    check_dependencies
    
    case "$1" in
        analyze)
            shift
            analyze_filesystem
            ;;
        explore)
            shift
            explore_vectors
            ;;
        visualize)
            shift
            visualize_vectors
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "${red}Error: Unknown command '$1'${reset}"
            show_help
            exit 1
            ;;
    esac
}

# Run the main function
main "$@"

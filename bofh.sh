#!/bin/bash
# BOFH - Bastard Operator From Hell
# A unix-sys-admin mcpServer that uses unix toolchains in magical ways
# Created by ModelContextProtocol (MCP)

VERSION="0.1.0"

# Determine script location for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "Error: Configuration file not found. Creating default config."
    cat > "$SCRIPT_DIR/config.sh" << EOF
#!/bin/bash
# BOFH Configuration File - Default settings
BOFH_HOME="$SCRIPT_DIR"
DEFAULT_CODE_DIR="/var/www/html"
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/output"
SCHEMA_SEARCH_EXAMPLE_DIR="$SCRIPT_DIR/schema_search_example"
DEBUG_LEVEL=1
USE_COLORS=1
EOF
    source "$SCRIPT_DIR/config.sh"
fi

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

# BOFH random excuse generator
EXCUSES=(
    "Quantum fluctuations in the space-time continuum"
    "The system's running too fast for your puny mortal comprehension"
    "Temporary gravitational anomaly"
    "The CPU decided to take an early retirement"
    "Bug in the RAID array's motivational subsystem"
    "Your karma is just terrible today"
    "Cosmic rays from Jupiter's alignment with Mars"
    "Incompatible telepathic interface with the AI"
    "The cable is perfectly fine, must be your hardware"
    "Someone deployed to production on a Friday afternoon"
    "It's been working fine for me all day"
)

# Print the BOFH banner
function print_banner() {
    clear
    echo "${bold}${red}"
    echo "██████╗  ██████╗ ███████╗██╗  ██╗"
    echo "██╔══██╗██╔═══██╗██╔════╝██║  ██║"
    echo "██████╔╝██║   ██║█████╗  ███████║"
    echo "██╔══██╗██║   ██║██╔══╝  ██╔══██║"
    echo "██████╔╝╚██████╔╝██║     ██║  ██║"
    echo "╚═════╝  ╚═════╝ ╚═╝     ╚═╝  ╚═╝"
    echo "${reset}"
    echo "${bold}${green}Bastard Operator From Hell${reset} - v$VERSION"
    echo "${cyan}Unix toolchains, evolved.${reset}"
    echo ""
}

# Generate a random BOFH excuse
function random_excuse() {
    # Check if we have an excuse file defined and use that if available
    if [ ! -z ${EXCUSE_FILE+x} ] && [ -f "$EXCUSE_FILE" ]; then
        local count=$(wc -l < "$EXCUSE_FILE")
        local line=$((RANDOM % count + 1))
        sed -n "${line}p" "$EXCUSE_FILE"
    else
        local idx=$((RANDOM % ${#EXCUSES[@]}))
        echo "${EXCUSES[$idx]}"
    fi
}

# Debug logging
function log_debug() {
    if [ "$DEBUG_LEVEL" -ge "$1" ]; then
        echo "${blue}[DEBUG:$1]${reset} $2"
    fi
}

# Show help information
function show_help() {
    echo "${bold}${cyan}BOFH - Unix System Administration mcpServer${reset}"
    echo ""
    echo "${yellow}Usage:${reset}"
    echo "  bofh.sh [command] [options]"
    echo ""
    echo "${yellow}Available commands:${reset}"
    echo "  ${bold}schema-search${reset}    Search for database schemas in codebases"
    echo "                  Options: --dir=PATH, --output=PATH"
    echo "  ${bold}find-offenders${reset}   Identify resource-hogging processes"
    echo "  ${bold}blame-user${reset}       Generate a plausible excuse for system issues"
    echo "                  Options: --user=USERNAME"
    echo "  ${bold}wizard${reset}           Invoke the MCP wizard for complex operations"
    echo "  ${bold}config${reset}           View or edit configuration settings"
    echo "  ${bold}help${reset}             Show this help information"
    echo ""
    echo "${yellow}Examples:${reset}"
    echo "  bofh.sh schema-search --dir=/path/to/codebase"
    echo "  bofh.sh blame-user --user=marketing-dept"
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
                OUTPUT_DIR="${arg#*=}"
                log_debug 2 "Set output dir to $OUTPUT_DIR"
                ;;
            --user=*)
                TARGET_USER="${arg#*=}"
                log_debug 2 "Set target user to $TARGET_USER"
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
    local dir="${1:-$DEFAULT_OUTPUT_DIR}"
    log_debug 1 "Ensuring output directory exists: $dir"
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_debug 1 "Created output directory: $dir"
    fi
}

# Launch the schema search tools
function schema_search() {
    # Set default directory if not specified
    TARGET_DIR="${TARGET_DIR:-$DEFAULT_CODE_DIR}"
    OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
    
    ensure_output_dir "$OUTPUT_DIR"
    
    echo "${yellow}BOFH Schema Search Utility${reset}"
    echo "${cyan}Searching for schemas in: ${bold}$TARGET_DIR${reset}"
    echo "${cyan}Output will be saved to: ${bold}$OUTPUT_DIR${reset}"
    echo ""
    
    if [ ! -d "$TARGET_DIR" ]; then
        echo "${red}Error: Directory not found. Using example instead.${reset}"
        echo ""
        TARGET_DIR="$SCHEMA_SEARCH_EXAMPLE_DIR"
    fi
    
    echo "${bold}Available Tools:${reset}"
    echo "1. Generate high-level app/table report"
    echo "2. Search for explicit schema and table definitions"
    echo "3. Run deep analysis of schemas and relationships"
    echo "4. Search for SQL-like patterns in non-SQL files"
    echo "5. Exit"
    echo ""
    
    read -p "Select an option (1-5): " option
    echo ""
    
    case $option in
        1)
            echo "${green}Running high-level schema analysis...${reset}"
            echo "This would normally run the app report generator"
            echo "See ${bold}$SCHEMA_SEARCH_EXAMPLE_DIR/apps_tables_report.md${reset} for example output"
            # Replace with actual command:
            # "$SCHEMA_SEARCH_EXAMPLE_DIR/generate_report.sh" "$TARGET_DIR" "$OUTPUT_DIR"
            ;;
        2)
            echo "${green}Searching for schema definitions...${reset}"
            echo "This would normally run find_schema_tables.sh"
            echo "See ${bold}$SCHEMA_SEARCH_EXAMPLE_DIR/find_schema_tables.sh${reset} for the script"
            # Replace with actual command:
            # "$SCHEMA_SEARCH_EXAMPLE_DIR/find_schema_tables.sh" "$TARGET_DIR" "$OUTPUT_DIR"
            ;;
        3)
            echo "${green}Running deep schema analysis...${reset}"
            echo "This would normally run analyze_schemas.py"
            echo "See ${bold}$SCHEMA_SEARCH_EXAMPLE_DIR/analyze_schemas.py${reset} for the script"
            # Replace with actual command:
            # python3 "$SCHEMA_SEARCH_EXAMPLE_DIR/analyze_schemas.py" "$TARGET_DIR" "$OUTPUT_DIR"
            ;;
        4)
            echo "${green}Searching for SQL patterns in non-SQL files...${reset}"
            echo "This would normally run search_hql_patterns.sh"
            echo "See ${bold}$SCHEMA_SEARCH_EXAMPLE_DIR/search_hql_patterns.sh${reset} for the script"
            # Replace with actual command:
            # "$SCHEMA_SEARCH_EXAMPLE_DIR/search_hql_patterns.sh" "$TARGET_DIR" "$OUTPUT_DIR"
            ;;
        5)
            echo "Exiting schema search utility"
            return
            ;;
        *)
            echo "${red}Invalid option. Please try again.${reset}"
            schema_search
            ;;
    esac
}

# Find resource hogs
function find_offenders() {
    echo "${yellow}BOFH Resource Offender Detector${reset}"
    echo "${cyan}Checking system resource usage...${reset}"
    echo ""
    
    # This would normally run actual system commands
    echo "${bold}Top CPU consumers:${reset}"
    echo "1. user123      34.2%    Browser (27 tabs)"
    echo "2. $DEFAULT_VICTIM     28.7%    IDE"
    echo "3. jenkins      12.5%    Continuous build"
    echo ""
    
    echo "${bold}Top memory hogs:${reset}"
    echo "1. user456      8.2GB    Docker containers"
    echo "2. analytics    6.5GB    Data processing job"
    echo "3. $DEFAULT_VICTIM     4.3GB    Electron apps"
    echo ""
    
    echo "${bold}BOFH Assessment:${reset}"
    echo "${red}Primary offender:${reset} $DEFAULT_VICTIM"
    echo "${green}Recommended action:${reset} Selective response throttling and mysterious latency injection"
}

# Generate a blame excuse
function blame_user() {
    TARGET_USER="${TARGET_USER:-$DEFAULT_VICTIM}"
    
    echo "${yellow}BOFH Blame Assignment Utility${reset}"
    echo "${cyan}Generating plausible excuse for system issues...${reset}"
    echo ""
    
    echo "${bold}System Issue:${reset} Unexplained service degradation"
    echo "${bold}Blamed User:${reset} $TARGET_USER"
    echo "${bold}Official Explanation:${reset} $(random_excuse)"
    echo ""
    echo "${green}This excuse has been automatically added to the ticket response template.${reset}"
}

# MCP Wizard for complex operations
function mcp_wizard() {
    echo "${yellow}BOFH MCP Wizard${reset}"
    echo "${cyan}Complexity through simplicity, chaos through order${reset}"
    echo ""
    
    echo "The MCP Wizard would guide you through complex system administration tasks,"
    echo "combining Unix tools in unexpected ways to solve problems efficiently."
    echo ""
    
    echo "${bold}Example wizard operations:${reset}"
    echo "- System health assessment"
    echo "- Configuration management"
    echo "- Database maintenance"
    echo "- Log analysis and anomaly detection"
    echo "- Performance tuning"
    echo ""
    
    echo "${magenta}The wizard remains under development. Its power is too great for this version.${reset}"
}

# View or edit configuration
function manage_config() {
    echo "${yellow}BOFH Configuration Manager${reset}"
    echo "${cyan}Current configuration settings:${reset}"
    echo ""
    
    echo "${bold}BOFH_HOME:${reset} $BOFH_HOME"
    echo "${bold}DEFAULT_CODE_DIR:${reset} $DEFAULT_CODE_DIR"
    echo "${bold}DEFAULT_OUTPUT_DIR:${reset} $DEFAULT_OUTPUT_DIR"
    echo "${bold}DEBUG_LEVEL:${reset} $DEBUG_LEVEL"
    echo "${bold}USE_COLORS:${reset} $USE_COLORS"
    echo ""
    
    echo "To edit configuration, use a text editor to modify:"
    echo "${bold}$SCRIPT_DIR/config.sh${reset}"
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
    
    case "$1" in
        schema-search)
            shift
            schema_search
            ;;
        find-offenders)
            find_offenders
            ;;
        blame-user)
            shift
            blame_user
            ;;
        wizard)
            mcp_wizard
            ;;
        config)
            manage_config
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

#!/usr/bin/env python3
# analyze_schemas.py - A more sophisticated analysis of schemas and tables
# Created by ModelContextProtocol (MCP)

import os
import re
import sys
import configparser
import argparse
from collections import defaultdict
import json

def load_config():
    """Load configuration from config file if available"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(os.path.dirname(script_dir), 'config.ini')
    
    # Default configuration
    config = {
        'target_dir': '/var/www/html',
        'output_dir': os.path.join(script_dir, 'output'),
        'debug_level': 1
    }
    
    # Try to load from config.ini if it exists
    if os.path.exists(config_path):
        try:
            cfg = configparser.ConfigParser()
            cfg.read(config_path)
            if 'schema_search' in cfg:
                for key in config:
                    if key in cfg['schema_search']:
                        config[key] = cfg['schema_search'][key]
        except Exception as e:
            print(f"Warning: Could not parse config file: {e}", file=sys.stderr)
    
    return config

def parse_arguments():
    """Parse command line arguments"""
    config = load_config()
    
    parser = argparse.ArgumentParser(description='Analyze database schemas in code repositories')
    parser.add_argument('--target-dir', '-t', default=config['target_dir'],
                        help='Target directory to search for SQL files')
    parser.add_argument('--output-dir', '-o', default=config['output_dir'],
                        help='Directory where output files will be written')
    parser.add_argument('--debug', '-d', type=int, default=int(config['debug_level']),
                        help='Debug level (0=none, 1=basic, 2=verbose)')
    
    return parser.parse_args()

# Patterns to search for
schema_pattern = re.compile(r'CREATE\s+SCHEMA\s+(IF\s+NOT\s+EXISTS\s+)?([a-zA-Z0-9_]+)', re.IGNORECASE)
table_pattern = re.compile(r'CREATE\s+TABLE\s+(IF\s+NOT\s+EXISTS\s+)?(([a-zA-Z0-9_]+)\.)?([a-zA-Z0-9_]+)', re.IGNORECASE)
column_pattern = re.compile(r'^\s*([a-zA-Z0-9_]+)\s+(.*?),?$', re.MULTILINE)
fk_pattern = re.compile(r'FOREIGN\s+KEY.*?REFERENCES\s+([a-zA-Z0-9_\.]+)', re.IGNORECASE)
join_pattern = re.compile(r'JOIN\s+([a-zA-Z0-9_\.]+)', re.IGNORECASE)
app_dir_pattern = re.compile(r'/([^/]+)/', re.IGNORECASE)

def find_sql_files(directory):
    """Find all SQL files in the given directory (recursively)"""
    sql_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.sql') and 'node_modules' not in root:
                sql_files.append(os.path.join(root, file))
    return sql_files

def extract_app_name(file_path):
    """Extract the app name from the file path"""
    path_parts = file_path.split(os.sep)
    # Try to find a component that looks like an app name
    for idx, part in enumerate(path_parts):
        if part in ['api', 'service', 'app', 'module', 'application'] and idx > 0:
            return path_parts[idx-1]
    
    # Fallback: use the directory name
    return os.path.basename(os.path.dirname(file_path))

def analyze_sql_files(sql_files, debug_level=1):
    """Analyze SQL files to extract schema and table information"""
    schemas = {}  # Schema -> app mapping
    tables = {}   # Table -> {schema, app, columns, references}
    apps = defaultdict(set)  # App -> set of tables
    
    for file_path in sql_files:
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            
            # Extract app name
            app_name = extract_app_name(file_path)
            
            # Find schemas
            for match in schema_pattern.finditer(content):
                schema_name = match.group(2)
                if schema_name not in schemas:
                    schemas[schema_name] = [app_name]
                elif app_name not in schemas[schema_name]:
                    schemas[schema_name].append(app_name)
            
            # Find tables
            for match in table_pattern.finditer(content):
                schema_name = match.group(3) or 'public'  # Default to public if no schema specified
                table_name = match.group(4)
                
                # Initialize table if it doesn't exist
                if table_name not in tables:
                    tables[table_name] = {
                        'schema': schema_name,
                        'apps': [app_name],
                        'columns': [],
                        'references': set(),
                        'joined_with': set()
                    }
                else:
                    # Update table information if already exists
                    if app_name not in tables[table_name]['apps']:
                        tables[table_name]['apps'].append(app_name)
                
                # Add to app -> tables mapping
                apps[app_name].add(table_name)
                
                # Try to extract columns (simplistic approach)
                table_def = content[match.end():].split(';')[0]
                for col_match in column_pattern.finditer(table_def):
                    col_name = col_match.group(1)
                    if col_name not in tables[table_name]['columns'] and col_name != 'PRIMARY' and col_name != 'UNIQUE':
                        tables[table_name]['columns'].append(col_name)
            
            # Find foreign key references
            for match in fk_pattern.finditer(content):
                reference = match.group(1)
                if '.' in reference:
                    schema, ref_table = reference.split('.')
                else:
                    schema, ref_table = 'public', reference
                
                # Try to associate with a table in the content
                for table_name in tables:
                    if table_name in content[:match.start()]:
                        tables[table_name]['references'].add(ref_table)
                        break
            
            # Find join patterns
            for match in join_pattern.finditer(content):
                joined_table = match.group(1)
                if '.' in joined_table:
                    joined_table = joined_table.split('.')[1]
                
                # Try to associate with a table in the content
                # This is simplistic and might not always be accurate
                for table_name in tables:
                    if f"FROM {table_name}" in content[:match.start()] or f"from {table_name}" in content[:match.start()]:
                        tables[table_name]['joined_with'].add(joined_table)
                        break
        
        except (UnicodeDecodeError, IOError) as e:
            if debug_level > 0:
                print(f"Error processing {file_path}: {e}", file=sys.stderr)
    
    # Convert sets to lists for JSON serialization
    for table in tables:
        tables[table]['references'] = list(tables[table]['references'])
        tables[table]['joined_with'] = list(tables[table]['joined_with'])
    
    return {
        'schemas': schemas,
        'tables': tables,
        'apps': {app: list(tables) for app, tables in apps.items()}
    }

def generate_markdown_report(data, output_file):
    """Generate a Markdown report from the analyzed data"""
    with open(output_file, 'w') as f:
        f.write("# Schema Analysis Report\n")
        f.write("## ModelContextProtocol (MCP)\n\n")
        
        # Schemas
        f.write("## Schemas Identified\n\n")
        for schema, apps in data['schemas'].items():
            f.write(f"- **{schema}**: Used by {', '.join(apps)}\n")
        f.write("\n")
        
        # Apps
        f.write("## Applications and Their Tables\n\n")
        for app, tables in data['apps'].items():
            if app == 'unknown' or not tables:
                continue
            f.write(f"### {app}\n\n")
            for table in sorted(tables):
                schema = data['tables'][table]['schema']
                f.write(f"- **{schema}.{table}**\n")
                
                # If columns are available
                if data['tables'][table]['columns']:
                    f.write("  - Columns: ")
                    for i, col in enumerate(data['tables'][table]['columns'][:5]):  # Show only first 5 columns
                        if i > 0:
                            f.write(", ")
                        f.write(f"`{col}`")
                    if len(data['tables'][table]['columns']) > 5:
                        f.write(f", ... ({len(data['tables'][table]['columns']) - 5} more)")
                    f.write("\n")
                
                # If references are available
                if data['tables'][table]['references']:
                    f.write("  - References: ")
                    for i, ref in enumerate(data['tables'][table]['references'][:3]):  # Show only first 3 references
                        if i > 0:
                            f.write(", ")
                        f.write(f"`{ref}`")
                    if len(data['tables'][table]['references']) > 3:
                        f.write(f", ... ({len(data['tables'][table]['references']) - 3} more)")
                    f.write("\n")
            f.write("\n")
        
        # Table Relationships
        f.write("## Major Table Relationships\n\n")
        for table, info in data['tables'].items():
            if not info['references'] and not info['joined_with']:
                continue
            
            f.write(f"### {info['schema']}.{table}\n\n")
            
            if info['references']:
                f.write("References to:\n")
                for ref in info['references']:
                    f.write(f"- {ref}\n")
                f.write("\n")
            
            if info['joined_with']:
                f.write("Joined with:\n")
                for join in info['joined_with']:
                    f.write(f"- {join}\n")
                f.write("\n")
        
        # Summary
        f.write("## Summary\n\n")
        f.write(f"This analysis identified {len(data['schemas'])} schemas, {len(data['tables'])} tables, and {len(data['apps'])} applications.\n\n")
        f.write("For a more detailed view, refer to the schema_data.json file.\n")

def main():
    """Main function"""
    args = parse_arguments()
    debug_level = args.debug
    
    if debug_level > 0:
        print("Starting schema analysis...")
    
    # Create output directory if it doesn't exist
    os.makedirs(args.output_dir, exist_ok=True)
    
    markdown_output = os.path.join(args.output_dir, "schema_analysis_report.md")
    json_output = os.path.join(args.output_dir, "schema_data.json")
    
    # Find all SQL files
    if debug_level > 0:
        print(f"Finding SQL files in {args.target_dir}...")
    sql_files = find_sql_files(args.target_dir)
    if debug_level > 0:
        print(f"Found {len(sql_files)} SQL files")
    
    # Analyze the files
    if debug_level > 0:
        print("Analyzing files...")
    data = analyze_sql_files(sql_files, debug_level)
    
    # Write data to JSON
    if debug_level > 0:
        print(f"Writing JSON data to {json_output}")
    with open(json_output, 'w') as f:
        json.dump(data, f, indent=2)
    
    # Generate Markdown report
    if debug_level > 0:
        print(f"Generating Markdown report to {markdown_output}")
    generate_markdown_report(data, markdown_output)
    
    if debug_level > 0:
        print("Analysis completed successfully!")

if __name__ == "__main__":
    main()

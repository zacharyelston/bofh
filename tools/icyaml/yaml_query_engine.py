#!/usr/bin/env python3
import os
import sys
import yaml
import json
import re
from pathlib import Path
from typing import Dict, List, Any, Optional, Set, Tuple, Union

class YamlQueryEngine:
    """Query engine for YAML structures with SQL-like syntax."""
    
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.yaml_data = {}
        self.query_results = []
    
    def load_yaml(self, yaml_file_path: str) -> bool:
        """Load a YAML file into the query engine."""
        try:
            with open(yaml_file_path, 'r') as f:
                data = yaml.safe_load(f)
                file_id = os.path.basename(yaml_file_path)
                self.yaml_data[file_id] = {
                    'path': yaml_file_path,
                    'data': data
                }
            return True
        except Exception as e:
            if self.verbose:
                print(f"Error loading YAML file {yaml_file_path}: {e}")
            return False
    
    def load_directory(self, directory_path: str, pattern: str = "*.yaml") -> int:
        """Load all YAML files in a directory into the query engine."""
        loaded_count = 0
        path = Path(directory_path)
        
        # Find all YAML files
        yaml_files = []
        for ext in [".yaml", ".yml"]:
            if pattern == "*":
                yaml_files.extend(path.glob(f"**/*{ext}"))
            else:
                yaml_files.extend(path.glob(f"**/{pattern}{ext}"))
        
        # Load each file
        for yaml_file in yaml_files:
            if self.load_yaml(str(yaml_file)):
                loaded_count += 1
        
        return loaded_count
    
    def _extract_path_value(self, data: Dict, path: List[str]) -> Any:
        """Extract a value from a nested dictionary using a path list."""
        current = data
        for key in path:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                return None
        return current
    
    def _find_all_keys(self, data: Dict, target_key: str, path: List[str] = None) -> List[Dict]:
        """Find all occurrences of a key in a nested dictionary."""
        if path is None:
            path = []
        
        results = []
        
        if isinstance(data, dict):
            # Check if the current dict has the target key
            if target_key in data:
                results.append({
                    'path': path + [target_key],
                    'value': data[target_key]
                })
            
            # Recurse into all dictionary values
            for k, v in data.items():
                sub_results = self._find_all_keys(v, target_key, path + [k])
                results.extend(sub_results)
        
        elif isinstance(data, list):
            # Recurse into lists
            for i, item in enumerate(data):
                sub_results = self._find_all_keys(item, target_key, path + [str(i)])
                results.extend(sub_results)
        
        return results
    
    def _find_key_value_pairs(self, data: Dict, conditions: List[Dict], 
                             path: List[str] = None, current_matches: Dict = None) -> List[Dict]:
        """
        Find all key-value pairs that match the conditions.
        
        Args:
            data: Dictionary to search
            conditions: List of condition dictionaries with keys 'key', 'value', and 'operator'
            path: Current path in the nested structure
            current_matches: Current matches found for tracking
            
        Returns:
            List of matches, each match is a dict with 'matches' containing all matched key-value pairs
        """
        if path is None:
            path = []
        
        if current_matches is None:
            current_matches = {cond['key']: None for cond in conditions}
        
        results = []
        
        # Check if we're in a dictionary
        if isinstance(data, dict):
            # Check if any condition keys are in this dictionary
            new_matches = current_matches.copy()
            new_paths = {}
            
            for cond in conditions:
                key = cond['key']
                if key in data:
                    value = data[key]
                    operator = cond.get('operator', '==')
                    
                    # Check if the value matches the condition
                    if operator == '==' and value == cond['value']:
                        new_matches[key] = value
                        new_paths[key] = path + [key]
                    elif operator == '!=' and value != cond['value']:
                        new_matches[key] = value
                        new_paths[key] = path + [key]
                    elif operator == 'contains' and cond['value'] in value:
                        new_matches[key] = value
                        new_paths[key] = path + [key]
                    elif operator == 'startswith' and str(value).startswith(cond['value']):
                        new_matches[key] = value
                        new_paths[key] = path + [key]
                    elif operator == 'endswith' and str(value).endswith(cond['value']):
                        new_matches[key] = value
                        new_paths[key] = path + [key]
            
            # Check if all condition keys have been matched
            if all(new_matches.values()):
                # Extract any additional requested keys
                additional_keys = {}
                additional_paths = {}
                
                for extract_key in [c.get('extract_key') for c in conditions if 'extract_key' in c]:
                    if extract_key in data:
                        additional_keys[extract_key] = data[extract_key]
                        additional_paths[extract_key] = path + [extract_key]
                
                results.append({
                    'matches': new_matches,
                    'match_paths': new_paths,
                    'additional': additional_keys,
                    'additional_paths': additional_paths,
                    'context': path
                })
            
            # Recurse into all dictionary values
            for k, v in data.items():
                sub_results = self._find_key_value_pairs(v, conditions, path + [k], current_matches)
                results.extend(sub_results)
        
        elif isinstance(data, list):
            # Recurse into lists
            for i, item in enumerate(data):
                sub_results = self._find_key_value_pairs(item, conditions, path + [str(i)], current_matches)
                results.extend(sub_results)
        
        return results
    
    def _parse_query(self, query: str) -> Dict:
        """Parse a SQL-like query into components."""
        # Basic query pattern:
        # select <KeyB> from <KeyB> node when parent <KeyA> is <ValueA> and report <KeyB:ValueB> <KeyA:ValueA>
        
        # Extract the SELECT part
        select_match = re.search(r'select\s+(\S+)\s+from', query, re.IGNORECASE)
        select_key = select_match.group(1) if select_match else None
        
        # Extract the FROM part
        from_match = re.search(r'from\s+(\S+)\s+node', query, re.IGNORECASE)
        from_key = from_match.group(1) if from_match else None
        
        # Extract the WHEN conditions
        when_conditions = []
        when_pattern = r'when\s+(?:parent\s+)?(\S+)\s+is\s+(\S+)'
        when_matches = re.findall(when_pattern, query, re.IGNORECASE)
        
        for key, value in when_matches:
            # Check if there's a parent relationship specified
            is_parent = 'parent' in query.lower().split(key)[0].split()[-2:]
            
            when_conditions.append({
                'key': key,
                'value': value,
                'operator': '==',
                'is_parent': is_parent
            })
        
        # Extract the REPORT part
        report_keys = []
        report_match = re.search(r'report\s+(.*?)(?:$|\s+and\s+)', query, re.IGNORECASE)
        
        if report_match:
            report_str = report_match.group(1)
            # Extract key:value pairs
            for pair in report_str.split():
                if ':' in pair:
                    key, value = pair.split(':', 1)
                    report_keys.append({
                        'key': key,
                        'value': value if value != 'ValueB' else None  # Handle template values
                    })
        
        return {
            'select': select_key,
            'from': from_key,
            'conditions': when_conditions,
            'report': report_keys
        }
    
    def _execute_parsed_query(self, parsed_query: Dict) -> List[Dict]:
        """Execute a parsed query against the loaded YAML data."""
        results = []
        
        # Process each YAML file
        for file_id, file_info in self.yaml_data.items():
            data = file_info['data']
            
            # Build conditions from the parsed query
            conditions = []
            for cond in parsed_query['conditions']:
                condition = {
                    'key': cond['key'],
                    'value': cond['value'],
                    'operator': cond['operator']
                }
                
                # Handle the case where the select key is different from condition keys
                if parsed_query['select'] and parsed_query['select'] != cond['key']:
                    condition['extract_key'] = parsed_query['select']
                
                conditions.append(condition)
            
            # Find matching structures
            matches = self._find_key_value_pairs(data, conditions)
            
            # Process each match
            for match in matches:
                # Prepare the result structure
                result = {
                    'file': file_id,
                    'path': file_info['path'],
                    'matches': {},
                    'context': match['context']
                }
                
                # Include all matched key-value pairs
                for key, value in match['matches'].items():
                    result['matches'][key] = value
                
                # Include additional requested keys
                for key, value in match.get('additional', {}).items():
                    result['matches'][key] = value
                
                results.append(result)
        
        return results
    
    def execute_query(self, query: str) -> List[Dict]:
        """Execute a SQL-like query against the loaded YAML data."""
        parsed_query = self._parse_query(query)
        results = self._execute_parsed_query(parsed_query)
        self.query_results = results
        return results
    
    def format_results(self, format_type: str = 'text') -> str:
        """Format the query results in the specified format."""
        if not self.query_results:
            return "No results found."
        
        if format_type == 'json':
            return json.dumps(self.query_results, indent=2)
        
        elif format_type == 'yaml':
            return yaml.dump(self.query_results, default_flow_style=False)
        
        elif format_type == 'text':
            output = []
            output.append(f"Found {len(self.query_results)} matches:")
            
            for i, result in enumerate(self.query_results, 1):
                output.append(f"\nMatch {i}:")
                output.append(f"  File: {result['file']} ({result['path']})")
                output.append(f"  Context: /{'/'.join(result['context'])}")
                output.append("  Matches:")
                
                for key, value in result['matches'].items():
                    output.append(f"    {key}: {value}")
            
            return "\n".join(output)
        
        else:
            return f"Unsupported format: {format_type}"
    
    def save_results(self, output_file: str, format_type: str = None) -> bool:
        """Save the query results to a file."""
        if not self.query_results:
            return False
        
        # Determine format from file extension if not specified
        if format_type is None:
            if output_file.endswith('.json'):
                format_type = 'json'
            elif output_file.endswith('.yaml') or output_file.endswith('.yml'):
                format_type = 'yaml'
            else:
                format_type = 'text'
        
        # Format the results
        output = self.format_results(format_type)
        
        # Write to file
        try:
            with open(output_file, 'w') as f:
                f.write(output)
            return True
        except Exception as e:
            if self.verbose:
                print(f"Error saving results to {output_file}: {e}")
            return False


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Query YAML files with SQL-like syntax")
    parser.add_argument('--dir', '-d', help="Directory containing YAML files")
    parser.add_argument('--file', '-f', help="Single YAML file to query")
    parser.add_argument('--pattern', '-p', default="*", help="File pattern to match (default: *)")
    parser.add_argument('--query', '-q', help="SQL-like query to execute")
    parser.add_argument('--output', '-o', help="Output file for results")
    parser.add_argument('--format', choices=['json', 'yaml', 'text'], default='text', help="Output format")
    parser.add_argument('--verbose', '-v', action='store_true', help="Enable verbose output")
    
    args = parser.parse_args()
    
    # Create query engine
    engine = YamlQueryEngine(verbose=args.verbose)
    
    # Load YAML data
    if args.file:
        if not engine.load_yaml(args.file):
            print(f"Error: Failed to load YAML file: {args.file}")
            return 1
    elif args.dir:
        count = engine.load_directory(args.dir, args.pattern)
        if count == 0:
            print(f"Error: No YAML files found in {args.dir} with pattern {args.pattern}")
            return 1
        print(f"Loaded {count} YAML files")
    else:
        print("Error: Either --dir or --file must be specified")
        return 1
    
    # Execute query
    if args.query:
        results = engine.execute_query(args.query)
        output = engine.format_results(args.format)
        
        if args.output:
            if engine.save_results(args.output, args.format):
                print(f"Results saved to {args.output}")
            else:
                print(f"Error: Failed to save results to {args.output}")
                return 1
        else:
            print(output)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

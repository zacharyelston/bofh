#!/usr/bin/env python3
"""
YAML Parent Path Analyzer

This tool analyzes YAML files to identify hierarchical parent-child relationships
between keys, helping to understand the structure and organization of YAML configurations.
"""

import os
import sys
import yaml
import json
import glob
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple
from collections import defaultdict


class YamlParentPathAnalyzer:
    """Tool for analyzing parent-child path relationships in YAML files"""
    
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.yaml_files = []
        self.total_files = 0
        self.all_paths = set()
        self.parent_paths = defaultdict(set)
        self.child_paths = defaultdict(set)
        self.path_occurrences = defaultdict(int)
        self.file_types = defaultdict(int)
        self.path_examples = defaultdict(list)
        
        # Define keys to ignore (optional)
        self.ignore_patterns = [
            'env',
            'environment',
            'value',
            'values',
            'data'
        ]
    
    def should_ignore_key(self, key):
        """Check if a key should be ignored based on patterns"""
        return any(pattern in key.lower() for pattern in self.ignore_patterns)
    
    def load_files(self, directory: str, pattern: str = "*.ya?ml") -> int:
        """Load all YAML files in the directory and analyze path relationships"""
        if self.verbose:
            print(f"Searching for YAML files in {directory} with pattern {pattern}")
        
        paths = []
        for ext in ['.yaml', '.yml']:
            if pattern == "*":
                search_pattern = f"**/*{ext}"
            else:
                search_pattern = f"**/{pattern}{ext}"
            paths.extend(Path(directory).glob(search_pattern))
        
        self.yaml_files = [str(p) for p in paths]
        self.total_files = len(self.yaml_files)
        
        if self.verbose:
            print(f"Found {self.total_files} YAML files to analyze")
        
        # Process each file
        for file_path in self.yaml_files:
            try:
                with open(file_path, 'r') as f:
                    try:
                        data = yaml.safe_load(f)
                        if data is None:  # Skip empty files
                            continue
                        
                        # Store metadata about this file type
                        kind = data.get('kind', 'Unknown')
                        self.file_types[kind] += 1
                        
                        # Extract all key paths
                        file_paths = set()
                        self._extract_key_paths(data, file_paths)
                        
                        # Filter out paths that should be ignored
                        file_paths = {p for p in file_paths if not self.should_ignore_key(p)}
                        
                        # Update global path statistics
                        for path in file_paths:
                            self.all_paths.add(path)
                            self.path_occurrences[path] += 1
                            
                            # Store an example of this path (up to 2 per path)
                            if path not in self.path_examples or len(self.path_examples[path]) < 2:
                                if len(self.path_examples[path]) < 2:
                                    self.path_examples[path].append(file_path)
                        
                        # Analyze parent-child relationships
                        self._analyze_parent_child_relationships(file_paths)
                        
                    except yaml.YAMLError as e:
                        if self.verbose:
                            print(f"Error parsing YAML in {file_path}: {e}")
            except Exception as e:
                if self.verbose:
                    print(f"Error reading file {file_path}: {e}")
        
        return self.total_files
    
    def _extract_key_paths(self, data, paths, prefix=""):
        """Recursively extract all key paths from a nested structure"""
        if isinstance(data, dict):
            for k, v in data.items():
                new_path = f"{prefix}.{k}" if prefix else k
                paths.add(new_path)
                self._extract_key_paths(v, paths, new_path)
        elif isinstance(data, list):
            for i, item in enumerate(data):
                # For arrays, we'll use [0] notation for the first item to generalize the pattern
                if i == 0:
                    new_path = f"{prefix}[0]"
                    self._extract_key_paths(item, paths, new_path)
    
    def _analyze_parent_child_relationships(self, paths):
        """Identify parent-child relationships between paths"""
        for path in paths:
            # Find all parent paths
            segments = path.split('.')
            for i in range(1, len(segments)):
                parent = '.'.join(segments[:i])
                child = '.'.join(segments[:i+1])
                
                # Skip array index notation in parent paths
                if '[' in parent:
                    continue
                
                self.parent_paths[child].add(parent)
                self.child_paths[parent].add(child)
    
    def get_path_statistics(self):
        """Get statistics for all paths with usage percentages"""
        result = {}
        for path in self.all_paths:
            count = self.path_occurrences[path]
            percentage = round((count / self.total_files) * 100) if self.total_files > 0 else 0
            
            # Count direct children
            direct_children = {child for child in self.child_paths[path] 
                             if len(child.split('.')) == len(path.split('.')) + 1}
            
            result[path] = {
                'count': count,
                'percentage': percentage,
                'parents': list(self.parent_paths.get(path, [])),
                'direct_children_count': len(direct_children),
                'all_children_count': len(self.child_paths.get(path, [])),
                'examples': self.path_examples.get(path, [])[:2]  # Limit to 2 examples
            }
        
        return result
    
    def get_root_paths(self):
        """Get all root paths (those without parents)"""
        return {path for path in self.all_paths if not self.parent_paths.get(path)}
    
    def get_leaf_paths(self):
        """Get all leaf paths (those without children)"""
        return {path for path in self.all_paths if not self.child_paths.get(path)}
    
    def get_common_parent_paths(self, threshold_percentage=50):
        """Get parent paths that appear in at least threshold_percentage of files"""
        return {path: self.path_occurrences[path] for path in self.all_paths
                if self.path_occurrences[path] >= (self.total_files * threshold_percentage / 100)
                and self.child_paths.get(path)}
    
    def generate_path_tree(self):
        """Generate a hierarchical tree of paths"""
        root_paths = self.get_root_paths()
        tree = {}
        
        for root in sorted(root_paths):
            tree[root] = self._build_subtree(root)
        
        return tree
    
    def _build_subtree(self, parent):
        """Recursively build a subtree for a parent path"""
        direct_children = {child for child in self.child_paths.get(parent, set()) 
                         if len(child.split('.')) == len(parent.split('.')) + 1
                         or (parent.endswith('[0]') and 
                             len(child.split('.')) == len(parent.split('.')) + 1)}
        
        if not direct_children:
            return {
                'occurrence': self.path_occurrences[parent],
                'percentage': round((self.path_occurrences[parent] / self.total_files) * 100)
            }
        
        subtree = {
            'occurrence': self.path_occurrences[parent],
            'percentage': round((self.path_occurrences[parent] / self.total_files) * 100),
            'children': {}
        }
        
        for child in sorted(direct_children):
            subtree['children'][child] = self._build_subtree(child)
        
        return subtree
    
    def generate_report(self):
        """Generate a comprehensive path analysis report"""
        stats = self.get_path_statistics()
        tree = self.generate_path_tree()
        root_paths = list(self.get_root_paths())
        leaf_paths = list(self.get_leaf_paths())
        
        # Sort paths by occurrence for better readability
        sorted_stats = dict(sorted(stats.items(), 
                                  key=lambda x: x[1]['percentage'], 
                                  reverse=True))
        
        # Identify patterns in path structure
        path_patterns = self._identify_path_patterns()
        
        report = {
            'summary': {
                'total_files': self.total_files,
                'resource_types': dict(self.file_types),
                'total_unique_paths': len(self.all_paths),
                'root_paths_count': len(root_paths),
                'leaf_paths_count': len(leaf_paths)
            },
            'path_statistics': sorted_stats,
            'path_tree': tree,
            'root_paths': root_paths,
            'common_parent_paths': self.get_common_parent_paths(50),
            'path_patterns': path_patterns
        }
        
        return report
    
    def _identify_path_patterns(self):
        """Identify common patterns in path structure"""
        patterns = {}
        
        # Look for container patterns
        container_paths = {path for path in self.all_paths 
                          if 'container' in path.lower()}
        if container_paths:
            patterns['containers'] = {
                'count': len(container_paths),
                'paths': sorted(list(container_paths))
            }
        
        # Look for metadata patterns
        metadata_paths = {path for path in self.all_paths 
                         if 'metadata' in path.lower()}
        if metadata_paths:
            patterns['metadata'] = {
                'count': len(metadata_paths),
                'paths': sorted(list(metadata_paths))
            }
        
        # Look for spec patterns
        spec_paths = {path for path in self.all_paths 
                     if 'spec' in path.lower()}
        if spec_paths:
            patterns['spec'] = {
                'count': len(spec_paths),
                'paths': sorted(list(spec_paths))
            }
        
        return patterns
    
    def print_report_summary(self, report):
        """Print a human-readable summary of the path analysis report"""
        print("\n=== YAML Parent Path Analysis Report ===\n")
        
        # Summary
        print(f"Total files analyzed: {report['summary']['total_files']}")
        print(f"Resource types found: {len(report['summary']['resource_types'])}")
        for k, v in report['summary']['resource_types'].items():
            print(f"  - {k}: {v} file(s)")
        print(f"Unique paths found: {report['summary']['total_unique_paths']}")
        print(f"Root paths: {report['summary']['root_paths_count']}")
        print(f"Leaf paths: {report['summary']['leaf_paths_count']}")
        
        # Root paths
        print("\n=== Root Paths ===\n")
        for path in sorted(report['root_paths'])[:10]:  # Show top 10
            stats = report['path_statistics'][path]
            print(f"  - {path}: {stats['percentage']}% of files ({stats['count']}/{report['summary']['total_files']})")
            if stats['direct_children_count'] > 0:
                print(f"    Children: {stats['direct_children_count']} direct, {stats['all_children_count']} total")
        
        if len(report['root_paths']) > 10:
            print(f"  ... and {len(report['root_paths']) - 10} more root paths")
        
        # Common parent paths
        print("\n=== Common Parent Paths (50%+ of files) ===\n")
        common_parents = report['common_parent_paths']
        for path, count in sorted(common_parents.items(), key=lambda x: x[1], reverse=True)[:10]:
            percentage = round((count / report['summary']['total_files']) * 100)
            print(f"  - {path}: {percentage}% of files ({count}/{report['summary']['total_files']})")
            
            # Show example children
            direct_children = {child for child in self.child_paths.get(path, set()) 
                             if len(child.split('.')) == len(path.split('.')) + 1}
            if direct_children:
                print(f"    Example children:")
                for child in sorted(list(direct_children))[:3]:
                    child_count = self.path_occurrences[child]
                    child_percentage = round((child_count / report['summary']['total_files']) * 100)
                    print(f"      * {child.split('.')[-1]}: {child_percentage}% of files")
                
                if len(direct_children) > 3:
                    print(f"      ... and {len(direct_children) - 3} more children")
        
        if len(common_parents) > 10:
            print(f"  ... and {len(common_parents) - 10} more common parent paths")
        
        # Path patterns
        if report['path_patterns']:
            print("\n=== Path Patterns ===\n")
            for pattern_name, pattern_data in report['path_patterns'].items():
                print(f"  {pattern_name.capitalize()} Paths: {pattern_data['count']} paths")
                print(f"    Examples:")
                for path in pattern_data['paths'][:3]:
                    path_count = self.path_occurrences[path]
                    path_percentage = round((path_count / report['summary']['total_files']) * 100)
                    print(f"      * {path}: {path_percentage}% of files")
                
                if len(pattern_data['paths']) > 3:
                    print(f"      ... and {len(pattern_data['paths']) - 3} more paths")
        
        # Example of hierarchical structure for a common path
        if common_parents:
            most_common_parent = max(common_parents.items(), key=lambda x: x[1])[0]
            print(f"\n=== Example Hierarchical Structure for '{most_common_parent}' ===\n")
            self._print_path_hierarchy(most_common_parent, report['path_tree'], "  ")
    
    def _print_path_hierarchy(self, path, tree, indent=""):
        """Print a hierarchical view of a path and its children"""
        # Find the path in the tree
        path_parts = path.split('.')
        current_tree = tree
        current_path = ""
        
        # Navigate to the correct location in the tree
        for part in path_parts:
            if not current_path:
                current_path = part
            else:
                current_path = f"{current_path}.{part}"
            
            if current_path in current_tree:
                current_tree = current_tree[current_path]
                break
            elif 'children' in current_tree and current_path in current_tree['children']:
                current_tree = current_tree['children'][current_path]
            else:
                # Try to find path with [0]
                array_path = f"{current_path}[0]"
                if array_path in current_tree.get('children', {}):
                    current_path = array_path
                    current_tree = current_tree['children'][array_path]
                else:
                    print(f"{indent}Path {path} not found in tree")
                    return
        
        # Print the path and its occurrence
        if isinstance(current_tree, dict) and 'occurrence' in current_tree:
            print(f"{indent}{path.split('.')[-1]}: {current_tree['percentage']}% of files ({current_tree['occurrence']}/{self.total_files})")
            
            # Print children
            if 'children' in current_tree and current_tree['children']:
                child_indent = indent + "  "
                for child_path, child_tree in sorted(current_tree['children'].items()):
                    child_name = child_path.split('.')[-1]
                    print(f"{child_indent}{child_name}: {child_tree['percentage']}% of files ({child_tree['occurrence']}/{self.total_files})")
                    
                    # Print grandchildren (one level deeper)
                    if 'children' in child_tree and child_tree['children']:
                        grandchild_indent = child_indent + "  "
                        for grandchild_path, grandchild_tree in sorted(child_tree['children'].items())[:3]:
                            grandchild_name = grandchild_path.split('.')[-1]
                            print(f"{grandchild_indent}{grandchild_name}: {grandchild_tree['percentage']}% of files ({grandchild_tree['occurrence']}/{self.total_files})")
                        
                        if len(child_tree['children']) > 3:
                            print(f"{grandchild_indent}... and {len(child_tree['children']) - 3} more paths")


def main():
    parser = argparse.ArgumentParser(description="Analyze parent-child relationships in YAML paths")
    parser.add_argument('--dir', '-d', required=True, help="Directory containing YAML files")
    parser.add_argument('--pattern', '-p', default="*", help="File pattern to match (default: *)")
    parser.add_argument('--output', '-o', help="Output file for JSON report")
    parser.add_argument('--verbose', '-v', action='store_true', help="Enable verbose output")
    
    args = parser.parse_args()
    
    analyzer = YamlParentPathAnalyzer(verbose=args.verbose)
    analyzer.load_files(args.dir, args.pattern)
    
    # Generate and print the report
    report = analyzer.generate_report()
    analyzer.print_report_summary(report)
    
    # Save to JSON if output file specified
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"\nDetailed report saved to {args.output}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
YAML Consistency Analyzer

This tool analyzes YAML files across a directory structure to identify inconsistencies
in key usage, provides clear examples, and generates actionable recommendations.
It focuses on highlighting patterns of missing fields and inconsistent configurations.
"""

import os
import sys
import yaml
import json
import glob
import argparse
from pathlib import Path
from typing import Dict, List, Any, Tuple, Set
from collections import defaultdict, Counter
from pprint import pprint


class YamlConsistencyAnalyzer:
    """Tool for analyzing consistency patterns across YAML files"""
    
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.yaml_files = []
        self.key_stats = defaultdict(int)
        self.file_keys = {}
        self.total_files = 0
        self.file_types = defaultdict(int)
        self.kind_key_stats = defaultdict(lambda: defaultdict(int))
        self.examples = defaultdict(dict)
        
        # Define keys to ignore (environment variables and similar)
        self.ignore_patterns = [
            'env',
            'environment',
            'spec.template.spec.containers[0].env',
            'spec.containers[0].env',
            'spec.jobTemplate.spec.template.spec.containers[0].env',
            'spec.template.spec.containers[0].envFrom',
            'spec.containers[0].envFrom',
            'spec.jobTemplate.spec.template.spec.containers[0].envFrom',
            'value',
            'values',
            'data'
        ]
    
    def should_ignore_key(self, key):
        """Check if a key should be ignored based on patterns"""
        return any(pattern in key.lower() for pattern in self.ignore_patterns)
    
    def load_files(self, directory: str, pattern: str = "*.ya?ml") -> int:
        """Load all YAML files in the directory and calculate key statistics"""
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
                        file_keys = set()
                        self._extract_key_paths(data, file_keys)
                        
                        # Filter out keys that should be ignored
                        file_keys = {k for k in file_keys if not self.should_ignore_key(k)}
                        
                        self.file_keys[file_path] = file_keys
                        
                        # Update global key statistics
                        for key in file_keys:
                            self.key_stats[key] += 1
                            
                            # Update stats by kind
                            self.kind_key_stats[kind][key] += 1
                        
                        # Store example for each key
                        for key in file_keys:
                            if key not in self.examples or len(self.examples[key].get('with_key', [])) < 2:
                                # Get the value for this key to use as an example
                                value = self._get_value_for_key(data, key.split('.'))
                                if value is not None:
                                    if 'with_key' not in self.examples[key]:
                                        self.examples[key]['with_key'] = []
                                    if len(self.examples[key]['with_key']) < 2:  # Store up to 2 examples
                                        self.examples[key]['with_key'].append({
                                            'file': file_path,
                                            'value': value
                                        })
                        
                    except yaml.YAMLError as e:
                        if self.verbose:
                            print(f"Error parsing YAML in {file_path}: {e}")
            except Exception as e:
                if self.verbose:
                    print(f"Error reading file {file_path}: {e}")
        
        # Find examples of files missing common keys
        self._find_missing_examples()
        
        return self.total_files
    
    def _extract_key_paths(self, data, keys, prefix=""):
        """Recursively extract all key paths from a nested structure"""
        if isinstance(data, dict):
            for k, v in data.items():
                new_key = f"{prefix}.{k}" if prefix else k
                keys.add(new_key)
                self._extract_key_paths(v, keys, new_key)
        elif isinstance(data, list):
            for i, item in enumerate(data):
                # For arrays, we'll use [0] notation for the first item to generalize the pattern
                # rather than creating separate entries for each array index
                if i == 0:
                    new_key = f"{prefix}[0]"
                    self._extract_key_paths(item, keys, new_key)
    
    def _get_value_for_key(self, data, key_parts):
        """Get the value at the specified key path, handling nested structures"""
        current = data
        list_indices = []
        
        for i, part in enumerate(key_parts):
            if part.endswith(']') and '[' in part:
                # Handle array notation like containers[0]
                base_name, idx_str = part.split('[')
                idx = int(idx_str.rstrip(']'))
                
                if isinstance(current, dict) and base_name in current:
                    current = current[base_name]
                    if isinstance(current, list) and len(current) > idx:
                        current = current[idx]
                    else:
                        return None
                else:
                    return None
            elif isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return None
        
        # Truncate long values for readability
        if isinstance(current, str) and len(current) > 50:
            return current[:50] + "..."
        return current

    def _find_missing_examples(self):
        """Find examples of files missing common keys"""
        # Focus on keys that appear in at least 20% of files but not all files
        threshold = max(1, int(self.total_files * 0.2))
        common_keys = {k for k, count in self.key_stats.items() 
                      if count >= threshold and count < self.total_files}
        
        for key in common_keys:
            # Find files missing this key
            missing_files = [f for f in self.file_keys if key not in self.file_keys[f]]
            if missing_files:
                if 'without_key' not in self.examples[key]:
                    self.examples[key]['without_key'] = []
                
                # Store up to 2 examples of files missing this key
                for file in missing_files[:2]:
                    self.examples[key]['without_key'].append({'file': file})
                    if len(self.examples[key]['without_key']) >= 2:
                        break
    
    def get_key_statistics(self) -> Dict:
        """Get statistics for all keys with rounded whole percentages"""
        result = {}
        for key, count in self.key_stats.items():
            # Calculate percentage and round to nearest whole number
            percentage = round((count / self.total_files) * 100) if self.total_files > 0 else 0
            result[key] = {
                'count': count,
                'percentage': percentage
            }
        
        return result
    
    def get_low_usage_keys(self, threshold_percentage: float = 30.0) -> Dict:
        """Get keys with usage percentage below the threshold"""
        stats = self.get_key_statistics()
        return {k: v for k, v in stats.items() 
                if v['percentage'] < threshold_percentage 
                and v['percentage'] > 0}
    
    def get_inconsistent_keys(self, min_percentage: float = 30.0, max_percentage: float = 95.0) -> Dict:
        """Get keys that show inconsistent usage (neither very common nor very rare)"""
        stats = self.get_key_statistics()
        return {k: v for k, v in stats.items() 
                if min_percentage <= v['percentage'] <= max_percentage
                and v['count'] >= 2}  # At least present in 2 files
    
    def generate_recommendations(self, inconsistent_keys: Dict) -> List[Dict]:
        """Generate actionable recommendations based on inconsistent keys"""
        recommendations = []
        
        # Focus on security-related keys
        security_keys = {k: v for k, v in inconsistent_keys.items() 
                        if 'security' in k.lower()}
        if security_keys:
            recommendations.append({
                'category': 'Security',
                'title': 'Security Context Inconsistencies',
                'description': 'Security context configurations are inconsistently applied across files',
                'keys': security_keys,
                'recommendation': 'Standardize security context settings across all containers'
            })
        
        # Focus on label-related keys
        label_keys = {k: v for k, v in inconsistent_keys.items() 
                    if 'label' in k.lower() or 'annotation' in k.lower()}
        if label_keys:
            recommendations.append({
                'category': 'Metadata',
                'title': 'Inconsistent Labels and Annotations',
                'description': 'Labels and annotations are not consistently applied',
                'keys': label_keys,
                'recommendation': 'Establish a standard set of labels and annotations for all resources'
            })
        
        # Focus on resource-related keys
        resource_keys = {k: v for k, v in inconsistent_keys.items() 
                        if 'resource' in k.lower() or 'limit' in k.lower() or 'request' in k.lower()}
        if resource_keys:
            recommendations.append({
                'category': 'Resources',
                'title': 'Resource Requirements Inconsistencies',
                'description': 'Resource requests and limits are not consistently defined',
                'keys': resource_keys,
                'recommendation': 'Define standard resource configurations for different service tiers'
            })
        
        # Add generic recommendation for other inconsistent keys
        other_keys = {k: v for k, v in inconsistent_keys.items() 
                    if k not in [key for rec in recommendations for key in rec.get('keys', {})]}
        if other_keys:
            top_10_keys = dict(sorted(other_keys.items(), 
                                      key=lambda x: x[1]['percentage'])[:10])
            recommendations.append({
                'category': 'General',
                'title': 'Other Configuration Inconsistencies',
                'description': 'Various configuration options are inconsistently applied',
                'keys': top_10_keys,
                'recommendation': 'Review configuration standards for consistency'
            })
        
        return recommendations
    
    def generate_report(self):
        """Generate a comprehensive analysis report"""
        stats = self.get_key_statistics()
        inconsistent_keys = self.get_inconsistent_keys(min_percentage=10.0, max_percentage=90.0)
        recommendations = self.generate_recommendations(inconsistent_keys)
        
        # Sort keys by usage percentage for better readability
        sorted_stats = dict(sorted(stats.items(), 
                                  key=lambda x: x[1]['percentage'], 
                                  reverse=True))
        
        report = {
            'summary': {
                'total_files': self.total_files,
                'resource_types': dict(self.file_types),
                'total_unique_keys': len(stats),
                'ignored_patterns': self.ignore_patterns
            },
            'key_statistics': sorted_stats,
            'inconsistent_keys': inconsistent_keys,
            'recommendations': recommendations,
            'examples': self.examples
        }
        
        return report
    
    def print_report_summary(self, report):
        """Print a human-readable summary of the analysis report"""
        print("\n=== YAML Consistency Analysis Report ===\n")
        
        # Summary
        print(f"Total files analyzed: {report['summary']['total_files']}")
        print(f"Resource types found: {len(report['summary']['resource_types'])}")
        for k, v in report['summary']['resource_types'].items():
            print(f"  - {k}: {v} file(s)")
        print(f"Unique key paths found: {report['summary']['total_unique_keys']}")
        print("\nIgnored key patterns:")
        for pattern in report['summary']['ignored_patterns']:
            print(f"  - {pattern}")
        
        # Inconsistency highlights
        print("\n=== Key Inconsistency Highlights ===\n")
        for rec in report['recommendations']:
            print(f"Category: {rec['category']}")
            print(f"Issue: {rec['title']}")
            print(f"Description: {rec['description']}")
            print("\nInconsistent keys:")
            for k, v in rec['keys'].items():
                print(f"  - {k}: {v['percentage']}% of files ({v['count']}/{report['summary']['total_files']})")
                
                # Show examples with the key
                if k in report['examples'] and 'with_key' in report['examples'][k]:
                    print(f"    Examples with this key:")
                    for example in report['examples'][k]['with_key'][:2]:
                        file_name = os.path.basename(example['file'])
                        print(f"      * {file_name}: {example['value']}")
                
                # Show examples without the key
                if k in report['examples'] and 'without_key' in report['examples'][k]:
                    print(f"    Examples missing this key:")
                    for example in report['examples'][k]['without_key'][:2]:
                        file_name = os.path.basename(example['file'])
                        print(f"      * {file_name}")
            
            print(f"\nRecommendation: {rec['recommendation']}")
            print("\n" + "-" * 50 + "\n")
        
        # Give a summary of the most common and least common keys
        most_common = list(report['key_statistics'].items())[:5]
        least_common = list(report['key_statistics'].items())[-5:]
        
        print("\n=== Most Common Keys ===\n")
        for k, v in most_common:
            print(f"  - {k}: {v['percentage']}% of files")
        
        print("\n=== Least Common Keys ===\n")
        for k, v in least_common:
            print(f"  - {k}: {v['percentage']}% of files")


def main():
    parser = argparse.ArgumentParser(description="Analyze YAML consistency across files")
    parser.add_argument('--dir', '-d', required=True, help="Directory containing YAML files")
    parser.add_argument('--pattern', '-p', default="*", help="File pattern to match (default: *)")
    parser.add_argument('--output', '-o', help="Output file for JSON report")
    parser.add_argument('--verbose', '-v', action='store_true', help="Enable verbose output")
    
    args = parser.parse_args()
    
    analyzer = YamlConsistencyAnalyzer(verbose=args.verbose)
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

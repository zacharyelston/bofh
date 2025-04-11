#!/usr/bin/env python3
import os
import sys
import yaml
import json
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional, Set, Counter
from collections import defaultdict

class YamlOutlierDetector:
    """Tool to analyze YAML files across directories and find outliers/missing keys."""
    
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.yaml_data = {}
        self.key_paths = defaultdict(set)
        self.directory_keys = defaultdict(set)
        self.common_keys = set()
        self.outliers = {}
    
    def load_yaml(self, yaml_file_path: str) -> bool:
        """Load a YAML file and extract its keys."""
        try:
            with open(yaml_file_path, 'r') as f:
                data = yaml.safe_load(f)
                
                # Skip empty files
                if data is None:
                    if self.verbose:
                        print(f"Skipping empty file: {yaml_file_path}")
                    return False
                
                file_id = os.path.basename(yaml_file_path)
                dir_name = os.path.dirname(yaml_file_path)
                
                # Store the file data
                self.yaml_data[yaml_file_path] = {
                    'path': yaml_file_path,
                    'directory': dir_name,
                    'data': data
                }
                
                # Extract all keys and their paths
                key_paths = set()
                self._extract_key_paths(data, key_paths)
                
                # Add to directory keys
                self.directory_keys[dir_name].update(key_paths)
                
                # Add all key paths to global set
                for key_path in key_paths:
                    self.key_paths[dir_name].add(key_path)
                
                if self.verbose:
                    print(f"Loaded {yaml_file_path}, found {len(key_paths)} unique key paths")
                
                return True
        except Exception as e:
            if self.verbose:
                print(f"Error loading YAML file {yaml_file_path}: {e}")
            return False
    
    def _extract_key_paths(self, data, key_paths, current_path=""):
        """Recursively extract all key paths from a nested YAML structure."""
        if isinstance(data, dict):
            for key, value in data.items():
                new_path = f"{current_path}.{key}" if current_path else key
                key_paths.add(new_path)
                self._extract_key_paths(value, key_paths, new_path)
        elif isinstance(data, list):
            for i, item in enumerate(data):
                new_path = f"{current_path}[{i}]"
                self._extract_key_paths(item, key_paths, new_path)
    
    def load_directory(self, directory_path: str, pattern: str = "*.yaml") -> int:
        """Load all YAML files in a directory into the analyzer."""
        loaded_count = 0
        path = Path(directory_path)
        
        # Find all YAML files
        yaml_files = []
        for ext in [".yaml", ".yml"]:
            if pattern == "*":
                yaml_files.extend(path.glob(f"**/*{ext}"))
            else:
                yaml_files.extend(path.glob(f"**/{pattern}{ext}"))
        
        if self.verbose:
            print(f"Found {len(yaml_files)} YAML files in {directory_path}")
        
        # Load each file
        for yaml_file in yaml_files:
            if self.load_yaml(str(yaml_file)):
                loaded_count += 1
        
        return loaded_count
    
    def analyze_common_keys(self, threshold_percentage=50):
        """Find keys that are common across directories based on a threshold percentage."""
        if not self.directory_keys:
            print("No data loaded. Please load YAML files first.")
            return
        
        # Count occurrence of each key across directories
        key_counts = defaultdict(int)
        all_dirs = list(self.directory_keys.keys())
        
        for dir_name, keys in self.key_paths.items():
            for key in keys:
                key_counts[key] += 1
        
        # Calculate threshold count
        threshold_count = max(1, int(len(all_dirs) * threshold_percentage / 100))
        
        # Find common keys based on threshold
        self.common_keys = {key for key, count in key_counts.items() if count >= threshold_count}
        
        if self.verbose:
            print(f"Found {len(self.common_keys)} common keys across directories (threshold: {threshold_percentage}%)")
    
    def find_outliers(self):
        """Find directories with missing common keys."""
        self.outliers = {}
        
        for dir_name, keys in self.key_paths.items():
            missing_keys = self.common_keys - keys
            if missing_keys:
                self.outliers[dir_name] = sorted(missing_keys)
        
        if self.verbose:
            print(f"Found {len(self.outliers)} directories with missing common keys")
    
    def get_key_statistics(self):
        """Get statistics about key usage across directories."""
        stats = {
            "total_directories": len(self.directory_keys),
            "total_unique_keys": sum(len(keys) for keys in self.key_paths.values()),
            "common_keys_count": len(self.common_keys),
            "outlier_directories_count": len(self.outliers),
            "key_frequency": {},
            "top_keys": [],
            "least_common_keys": []
        }
        
        # Calculate key frequency
        key_counts = defaultdict(int)
        for dir_name, keys in self.key_paths.items():
            for key in keys:
                key_counts[key] += 1
        
        # Convert to percentage
        total_dirs = len(self.directory_keys)
        if total_dirs > 0:
            for key, count in key_counts.items():
                stats["key_frequency"][key] = (count / total_dirs) * 100
        
        # Get top keys by frequency
        if key_counts:
            sorted_keys = sorted(key_counts.items(), key=lambda x: x[1], reverse=True)
            stats["top_keys"] = sorted_keys[:20]  # Top 20 most common keys
            stats["least_common_keys"] = sorted_keys[-20:]  # 20 least common keys
        
        return stats
    
    def analyze_and_find_outliers(self, threshold_percentage=50):
        """Run the complete analysis process."""
        self.analyze_common_keys(threshold_percentage)
        self.find_outliers()
        
        return {
            "common_keys": sorted(self.common_keys),
            "outliers": self.outliers,
            "statistics": self.get_key_statistics()
        }
    
    def print_results(self, results=None):
        """Print the analysis results in a readable format."""
        if results is None:
            results = {
                "common_keys": sorted(self.common_keys),
                "outliers": self.outliers,
                "statistics": self.get_key_statistics()
            }
        
        print("\n===== YAML Structure Analysis Results =====\n")
        
        stats = results["statistics"]
        print(f"Total directories analyzed: {stats['total_directories']}")
        print(f"Total unique keys found: {stats['total_unique_keys']}")
        print(f"Common keys (threshold: {50}%): {len(results['common_keys'])}")
        print(f"Directories with missing keys: {len(results['outliers'])}")
        
        print("\n----- Top 10 Most Common Keys -----")
        for key, count in stats["top_keys"][:10]:
            print(f"  {key}: {count} directories ({stats['key_frequency'][key]:.1f}%)")
        
        print("\n----- Directories Missing Common Keys -----")
        for dir_name, missing_keys in results["outliers"].items():
            dir_basename = os.path.basename(dir_name)
            print(f"\n  Directory: {dir_basename}")
            print(f"  Missing {len(missing_keys)} common keys:")
            for key in sorted(missing_keys)[:10]:  # Show first 10 missing keys
                print(f"    - {key}")
            if len(missing_keys) > 10:
                print(f"    ... and {len(missing_keys) - 10} more")
    
    def export_results(self, output_file, results=None):
        """Export the analysis results to a JSON file."""
        if results is None:
            results = {
                "common_keys": sorted(self.common_keys),
                "outliers": self.outliers,
                "statistics": self.get_key_statistics()
            }
        
        try:
            with open(output_file, 'w') as f:
                json.dump(results, f, indent=2)
            
            if self.verbose:
                print(f"Results exported to {output_file}")
            
            return True
        except Exception as e:
            print(f"Error exporting results: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(description="Analyze YAML files across directories and find outliers/missing keys")
    parser.add_argument('--dir', '-d', required=True, help="Directory containing YAML files to analyze")
    parser.add_argument('--pattern', '-p', default="*", help="File pattern to match (default: *)")
    parser.add_argument('--threshold', '-t', type=int, default=50, help="Threshold percentage for common keys (default: 50)")
    parser.add_argument('--output', '-o', help="Output file for results (JSON)")
    parser.add_argument('--verbose', '-v', action='store_true', help="Enable verbose output")
    
    args = parser.parse_args()
    
    detector = YamlOutlierDetector(verbose=args.verbose)
    count = detector.load_directory(args.dir, args.pattern)
    
    if count == 0:
        print(f"Error: No YAML files found in {args.dir} with pattern {args.pattern}")
        return 1
    
    print(f"Analyzing {count} YAML files...")
    results = detector.analyze_and_find_outliers(args.threshold)
    
    detector.print_results(results)
    
    if args.output:
        detector.export_results(args.output, results)
        print(f"\nResults exported to {args.output}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

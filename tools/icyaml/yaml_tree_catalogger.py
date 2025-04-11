#!/usr/bin/env python3
import os
import sys
import yaml
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional


class YamlTreeCatalogger:
    """Tool to search filesystem for YAML trees and build connection summaries."""
    
    def __init__(self, base_paths: List[str], dir_pattern: str = "*"):
        self.base_paths = [Path(p) for p in base_paths]
        self.dir_pattern = dir_pattern
        self.catalog = {}
        
    def find_matching_directories(self) -> List[Path]:
        """Find all directories matching the pattern."""
        matching_dirs = []
        for base_path in self.base_paths:
            if not base_path.exists():
                print(f"Warning: Path {base_path} does not exist")
                continue
                
            for path in base_path.glob(f"**/{self.dir_pattern}"):
                if path.is_dir():
                    matching_dirs.append(path)
        
        return matching_dirs
    
    def find_yaml_files(self, directory: Path) -> List[Path]:
        """Find all YAML files in a directory and its subdirectories."""
        yaml_files = []
        for extension in ["*.yaml", "*.yml"]:
            yaml_files.extend(directory.glob(f"**/{extension}"))
        return yaml_files
    
    def parse_yaml_file(self, file_path: Path) -> Optional[Dict]:
        """Parse a YAML file and return its contents."""
        try:
            with open(file_path, 'r') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Error parsing {file_path}: {e}")
            return None
    
    def extract_service_info(self, yaml_data: Dict, file_path: Path) -> Dict:
        """Extract service name and app title from YAML data."""
        service_name = None
        app_title = None
        
        # Extract service name - could be in different locations based on YAML structure
        if yaml_data and isinstance(yaml_data, dict):
            # Try finding service name
            if 'service' in yaml_data and isinstance(yaml_data['service'], dict):
                service_name = yaml_data['service'].get('name')
            elif 'metadata' in yaml_data and isinstance(yaml_data['metadata'], dict):
                service_name = yaml_data['metadata'].get('name')
            
            # Try finding app title
            if 'app' in yaml_data and isinstance(yaml_data['app'], dict):
                app_title = yaml_data['app'].get('title')
            elif 'metadata' in yaml_data and isinstance(yaml_data['metadata'], dict):
                if 'labels' in yaml_data['metadata'] and isinstance(yaml_data['metadata']['labels'], dict):
                    app_title = yaml_data['metadata']['labels'].get('app.kubernetes.io/name')
            
            # Try Kustomize-specific patterns
            if 'resources' in yaml_data or 'bases' in yaml_data:
                return {
                    'type': 'kustomization',
                    'file': str(file_path),
                    'resources': yaml_data.get('resources', []),
                    'bases': yaml_data.get('bases', [])
                }
        
        return {
            'service_name': service_name,
            'app_title': app_title,
            'file': str(file_path)
        }
    
    def build_catalog(self):
        """Build catalog of YAML trees and their relationships."""
        matching_dirs = self.find_matching_directories()
        print(f"Found {len(matching_dirs)} matching directories")
        
        for directory in matching_dirs:
            dir_name = directory.name
            self.catalog[dir_name] = {
                'path': str(directory),
                'services': [],
                'relationships': []
            }
            
            yaml_files = self.find_yaml_files(directory)
            print(f"Found {len(yaml_files)} YAML files in {dir_name}")
            
            kustomizations = []
            services = []
            
            for yaml_file in yaml_files:
                yaml_data = self.parse_yaml_file(yaml_file)
                if not yaml_data:
                    continue
                
                info = self.extract_service_info(yaml_data, yaml_file)
                
                if info.get('type') == 'kustomization':
                    kustomizations.append(info)
                elif info.get('service_name') or info.get('app_title'):
                    services.append(info)
                    self.catalog[dir_name]['services'].append(info)
            
            # Build relationships from kustomizations
            for kust in kustomizations:
                bases = kust.get('bases', [])
                resources = kust.get('resources', [])
                
                for base in bases:
                    self.catalog[dir_name]['relationships'].append({
                        'type': 'kustomize_base',
                        'from': str(kust['file']),
                        'to': base
                    })
                
                for resource in resources:
                    self.catalog[dir_name]['relationships'].append({
                        'type': 'kustomize_resource',
                        'from': str(kust['file']),
                        'to': resource
                    })
    
    def print_summary(self):
        """Print a summary of the catalog."""
        print("\nYAML Tree Catalog Summary:")
        print("=========================")
        
        for dir_name, info in self.catalog.items():
            print(f"\nDirectory: {dir_name}")
            print(f"Path: {info['path']}")
            
            services = info['services']
            if services:
                print("\nServices:")
                for service in services:
                    svc_name = service.get('service_name', 'N/A')
                    app_title = service.get('app_title', 'N/A')
                    print(f"  - Service: {svc_name}, App: {app_title}")
            
            relationships = info['relationships']
            if relationships:
                print("\nRelationships:")
                for rel in relationships:
                    rel_type = rel.get('type', 'unknown')
                    from_file = os.path.basename(rel.get('from', ''))
                    to_file = rel.get('to', '')
                    print(f"  - {rel_type}: {from_file} → {to_file}")
    
    def export_json(self, output_file: str):
        """Export the catalog to a JSON file."""
        import json
        with open(output_file, 'w') as f:
            json.dump(self.catalog, f, indent=2)
        print(f"\nCatalog exported to {output_file}")
    
    def export_graphviz(self, output_file: str):
        """Export the relationships as a GraphViz DOT file for visualization."""
        try:
            with open(output_file, 'w') as f:
                f.write("digraph YAML_Relationships {\n")
                f.write("  rankdir=LR;\n")
                f.write("  node [shape=box, style=filled, fillcolor=lightblue];\n\n")
                
                # Create nodes for services
                for dir_name, info in self.catalog.items():
                    f.write(f"  subgraph cluster_{dir_name.replace('-', '_')} {{\n")
                    f.write(f"    label=\"{dir_name}\";\n")
                    f.write("    style=filled;\n")
                    f.write("    color=lightgrey;\n")
                    
                    # Add services as nodes
                    for i, service in enumerate(info['services']):
                        svc_name = service.get('service_name', f'unknown_service_{i}')
                        app_title = service.get('app_title', 'N/A')
                        node_id = f"{dir_name}_{svc_name}".replace('-', '_')
                        
                        if svc_name != 'N/A':
                            f.write(f"    {node_id} [label=\"{svc_name}\\nApp: {app_title}\"];\n")
                    
                    f.write("  }\n\n")
                
                # Create edges for relationships
                for dir_name, info in self.catalog.items():
                    for rel in info['relationships']:
                        rel_type = rel.get('type', 'unknown')
                        from_file = os.path.basename(rel.get('from', ''))
                        to_file = rel.get('to', '')
                        
                        from_id = f"{from_file}".replace('.', '_').replace('-', '_')
                        to_id = f"{to_file}".replace('.', '_').replace('-', '_').replace('/', '_')
                        
                        f.write(f"  {from_id} -> {to_id} [label=\"{rel_type}\"];\n")
                
                f.write("}\n")
                
            print(f"\nGraph exported to {output_file}")
            print("To generate a visualization, run: dot -Tpng -o relationships.png {output_file}")
        except Exception as e:
            print(f"Error exporting GraphViz file: {e}")


def main():
    parser = argparse.ArgumentParser(description='Search filesystem for YAML trees and build connection summaries')
    parser.add_argument('paths', nargs='+', help='Base paths to search')
    parser.add_argument('--pattern', default='*', help='Directory name pattern to match (default: *)')
    parser.add_argument('--output', '-o', help='Output JSON file (optional)')
    parser.add_argument('--graph', '-g', help='Output GraphViz DOT file (optional)')
    
    args = parser.parse_args()
    
    catalogger = YamlTreeCatalogger(args.paths, args.pattern)
    print(f"Searching for YAML files in directories matching '{args.pattern}'...")
    catalogger.build_catalog()
    catalogger.print_summary()
    
    if args.output:
        catalogger.export_json(args.output)
        
    if args.graph:
        catalogger.export_graphviz(args.graph)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
import os
import sys
import yaml
import json
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional, Set, Tuple


class KustomizationAnalyzer:
    """Class for analyzing Kustomize structures."""
    
    def __init__(self):
        self.github_bases = {}
        self.local_bases = {}
    
    def analyze_kustomization(self, file_path: Path, yaml_data: Dict) -> Dict:
        """Analyze a kustomization.yaml file."""
        result = {
            'type': 'kustomization',
            'file': str(file_path),
            'resources': [],
            'bases': [],
            'patches': [],
            'images': [],
            'namePrefix': yaml_data.get('namePrefix', ''),
            'namespace': yaml_data.get('namespace', '')
        }
        
        # Extract resources
        resources = yaml_data.get('resources', [])
        for resource in resources:
            if isinstance(resource, str):
                if resource.startswith('http'):
                    # GitHub resource
                    github_info = self._parse_github_url(resource)
                    result['bases'].append({
                        'type': 'github',
                        'url': resource,
                        'repo': github_info.get('repo', ''),
                        'path': github_info.get('path', ''),
                        'ref': github_info.get('ref', '')
                    })
                else:
                    # Local resource
                    result['resources'].append({
                        'type': 'local',
                        'path': resource
                    })
        
        # Extract patches
        patches = yaml_data.get('patchesStrategicMerge', [])
        for patch in patches:
            if isinstance(patch, str):
                result['patches'].append({
                    'path': patch
                })
        
        # Extract images
        images = yaml_data.get('images', [])
        for image in images:
            if isinstance(image, dict):
                result['images'].append({
                    'name': image.get('name', ''),
                    'newTag': image.get('newTag', '')
                })
        
        return result
    
    def _parse_github_url(self, url: str) -> Dict:
        """Parse GitHub URL to extract components."""
        result = {
            'repo': '',
            'path': '',
            'ref': ''
        }
        
        if '?ref=' in url:
            url_parts = url.split('?ref=')
            result['ref'] = url_parts[1]
            url = url_parts[0]
        
        if 'github.com/' in url:
            url_parts = url.split('github.com/')
            if len(url_parts) > 1:
                path_parts = url_parts[1].split('/', 2)
                if len(path_parts) >= 2:
                    result['repo'] = f"{path_parts[0]}/{path_parts[1]}"
                if len(path_parts) >= 3:
                    result['path'] = path_parts[2]
        
        return result


class YamlTreeCatalogger:
    """Tool to search filesystem for YAML trees and build connection summaries."""
    
    def __init__(self, base_paths: List[str], dir_pattern: str = "*-atlas"):
        self.base_paths = [Path(p) for p in base_paths]
        self.dir_pattern = dir_pattern
        self.catalog = {}
        self.kustomize_analyzer = KustomizationAnalyzer()
        
    def find_matching_directories(self) -> List[Path]:
        """Find all directories matching the pattern."""
        matching_dirs = []
        for base_path in self.base_paths:
            if not base_path.exists():
                print(f"Warning: Path {base_path} does not exist")
                continue
                
            if self.dir_pattern == "*":
                # Match all directories
                matching_dirs.append(base_path)
                for path in base_path.glob("**/"):
                    if path.is_dir():
                        matching_dirs.append(path)
            else:
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
        # Check if this is a kustomization file
        if file_path.name == "kustomization.yaml" or (yaml_data and 'apiVersion' in yaml_data and 'kind' in yaml_data and yaml_data['kind'] == 'Kustomization'):
            return self.kustomize_analyzer.analyze_kustomization(file_path, yaml_data)
        
        # Extract Kubernetes metadata
        service_name = None
        app_title = None
        kind = None
        
        if yaml_data and isinstance(yaml_data, dict):
            # Extract kind and metadata
            kind = yaml_data.get('kind')
            
            if 'metadata' in yaml_data and isinstance(yaml_data['metadata'], dict):
                service_name = yaml_data['metadata'].get('name')
                
                # Extract app title from labels
                if 'labels' in yaml_data['metadata'] and isinstance(yaml_data['metadata']['labels'], dict):
                    app_title = yaml_data['metadata']['labels'].get('app') or \
                                yaml_data['metadata']['labels'].get('app.kubernetes.io/name')
            
            # Extract from service
            if 'service' in yaml_data and isinstance(yaml_data['service'], dict):
                service_name = service_name or yaml_data['service'].get('name')
            
            # Extract from app
            if 'app' in yaml_data and isinstance(yaml_data['app'], dict):
                app_title = app_title or yaml_data['app'].get('title')
        
        return {
            'kind': kind,
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
                'kustomizations': [],
                'kubernetes_resources': [],
                'relationships': [],
                'github_dependencies': []
            }
            
            yaml_files = self.find_yaml_files(directory)
            print(f"Found {len(yaml_files)} YAML files in {dir_name}")
            
            for yaml_file in yaml_files:
                yaml_data = self.parse_yaml_file(yaml_file)
                if not yaml_data:
                    continue
                
                info = self.extract_service_info(yaml_data, yaml_file)
                
                if info.get('type') == 'kustomization':
                    self.catalog[dir_name]['kustomizations'].append(info)
                    
                    # Add GitHub dependencies
                    for base in info.get('bases', []):
                        if base.get('type') == 'github':
                            self.catalog[dir_name]['github_dependencies'].append({
                                'from': info.get('file'),
                                'repo': base.get('repo'),
                                'path': base.get('path'),
                                'ref': base.get('ref')
                            })
                    
                    # Add resource relationships
                    for resource in info.get('resources', []):
                        if resource.get('type') == 'local':
                            resource_path = resource.get('path')
                            if resource_path:
                                self.catalog[dir_name]['relationships'].append({
                                    'type': 'resource',
                                    'from': info.get('file'),
                                    'to': resource_path
                                })
                    
                    # Add patch relationships
                    for patch in info.get('patches', []):
                        patch_path = patch.get('path')
                        if patch_path:
                            self.catalog[dir_name]['relationships'].append({
                                'type': 'patch',
                                'from': info.get('file'),
                                'to': patch_path
                            })
                            
                elif info.get('kind') and info.get('service_name'):
                    # Kubernetes resource
                    self.catalog[dir_name]['kubernetes_resources'].append(info)
                    
                elif info.get('service_name') or info.get('app_title'):
                    # Generic service
                    self.catalog[dir_name]['services'].append(info)
    
    def print_summary(self):
        """Print a summary of the catalog."""
        print("\nYAML Tree Catalog Summary:")
        print("=========================")
        
        for dir_name, info in self.catalog.items():
            print(f"\nDirectory: {dir_name}")
            print(f"Path: {info['path']}")
            
            kustomizations = info['kustomizations']
            if kustomizations:
                print("\nKustomizations:")
                for kust in kustomizations:
                    file_path = os.path.basename(kust.get('file', ''))
                    namespace = kust.get('namespace', 'N/A')
                    name_prefix = kust.get('namePrefix', 'N/A')
                    print(f"  - File: {file_path}")
                    print(f"    Namespace: {namespace}")
                    print(f"    NamePrefix: {name_prefix}")
            
            k8s_resources = info['kubernetes_resources']
            if k8s_resources:
                print("\nKubernetes Resources:")
                for resource in k8s_resources:
                    kind = resource.get('kind', 'N/A')
                    name = resource.get('service_name', 'N/A')
                    app = resource.get('app_title', 'N/A')
                    print(f"  - {kind}: {name} (App: {app})")
            
            services = info['services']
            if services:
                print("\nServices:")
                for service in services:
                    svc_name = service.get('service_name', 'N/A')
                    app_title = service.get('app_title', 'N/A')
                    print(f"  - Service: {svc_name}, App: {app_title}")
            
            github_deps = info['github_dependencies']
            if github_deps:
                print("\nGitHub Dependencies:")
                for dep in github_deps:
                    repo = dep.get('repo', 'N/A')
                    ref = dep.get('ref', 'N/A')
                    path = dep.get('path', 'N/A')
                    print(f"  - Repo: {repo}, Ref: {ref}")
                    print(f"    Path: {path}")
            
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
                
                # Create clusters for directories
                for dir_name, info in self.catalog.items():
                    dir_id = f"cluster_{dir_name.replace('-', '_').replace('.', '_')}"
                    f.write(f"  subgraph {dir_id} {{\n")
                    f.write(f"    label=\"{dir_name}\";\n")
                    f.write("    style=filled;\n")
                    f.write("    color=lightgrey;\n")
                    
                    # Add kustomizations as nodes
                    for kust in info['kustomizations']:
                        file_path = kust.get('file', '')
                        if file_path:
                            node_id = self._path_to_node_id(file_path)
                            namespace = kust.get('namespace', '')
                            name_prefix = kust.get('namePrefix', '')
                            label = f"Kustomization\\nNamespace: {namespace}\\nPrefix: {name_prefix}"
                            f.write(f"    {node_id} [label=\"{label}\", shape=folder, fillcolor=lightyellow];\n")
                    
                    # Add Kubernetes resources as nodes
                    for resource in info['kubernetes_resources']:
                        file_path = resource.get('file', '')
                        if file_path:
                            node_id = self._path_to_node_id(file_path)
                            kind = resource.get('kind', '')
                            name = resource.get('service_name', '')
                            label = f"{kind}\\n{name}"
                            f.write(f"    {node_id} [label=\"{label}\", fillcolor=lightgreen];\n")
                    
                    # Add services as nodes
                    for service in info['services']:
                        file_path = service.get('file', '')
                        if file_path:
                            node_id = self._path_to_node_id(file_path)
                            name = service.get('service_name', 'N/A')
                            app = service.get('app_title', 'N/A')
                            label = f"Service: {name}\\nApp: {app}"
                            f.write(f"    {node_id} [label=\"{label}\"];\n")
                    
                    f.write("  }\n\n")
                
                # Create GitHub dependency nodes
                github_repos = set()
                for dir_name, info in self.catalog.items():
                    for dep in info['github_dependencies']:
                        repo = dep.get('repo', '')
                        ref = dep.get('ref', '')
                        if repo:
                            repo_id = f"github_{repo.replace('/', '_').replace('-', '_').replace('.', '_')}"
                            github_repos.add((repo_id, repo, ref))
                
                if github_repos:
                    f.write("  subgraph cluster_github {\n")
                    f.write("    label=\"GitHub Dependencies\";\n")
                    f.write("    style=filled;\n")
                    f.write("    color=lightblue;\n")
                    
                    for repo_id, repo, ref in github_repos:
                        label = f"{repo}\\nRef: {ref}"
                        f.write(f"    {repo_id} [label=\"{label}\", shape=component, fillcolor=pink];\n")
                    
                    f.write("  }\n\n")
                
                # Create edges for relationships
                for dir_name, info in self.catalog.items():
                    # GitHub dependencies
                    for dep in info['github_dependencies']:
                        from_file = dep.get('from', '')
                        repo = dep.get('repo', '')
                        if from_file and repo:
                            from_id = self._path_to_node_id(from_file)
                            repo_id = f"github_{repo.replace('/', '_').replace('-', '_').replace('.', '_')}"
                            f.write(f"  {from_id} -> {repo_id} [label=\"depends on\", color=red];\n")
                    
                    # Local relationships
                    for rel in info['relationships']:
                        rel_type = rel.get('type', '')
                        from_file = rel.get('from', '')
                        to_path = rel.get('to', '')
                        
                        if from_file and to_path:
                            from_id = self._path_to_node_id(from_file)
                            
                            # Construct the full path for the target
                            from_dir = os.path.dirname(from_file)
                            to_file = os.path.join(from_dir, to_path)
                            to_id = self._path_to_node_id(to_file)
                            
                            color = "blue" if rel_type == "resource" else "green"
                            f.write(f"  {from_id} -> {to_id} [label=\"{rel_type}\", color={color}];\n")
                
                f.write("}\n")
                
            print(f"\nGraph exported to {output_file}")
            print(f"To generate a visualization, run: dot -Tpng -o relationships.png {output_file}")
        except Exception as e:
            print(f"Error exporting GraphViz file: {e}")
    
    def _path_to_node_id(self, path: str) -> str:
        """Convert a file path to a valid node ID."""
        return f"node_{hash(path) % 100000000}".replace('-', '_')


def main():
    parser = argparse.ArgumentParser(description='Search filesystem for YAML trees and build connection summaries')
    parser.add_argument('paths', nargs='+', help='Base paths to search')
    parser.add_argument('--pattern', default='*-atlas', help='Directory name pattern to match (default: *-atlas)')
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

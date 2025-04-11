#!/usr/bin/env python3

"""
MCP Collector - ModelContextProtocol Batch Processing Tool

This tool finds recent files based on specified criteria, packages them into
a single archive, and provides a unified reading mechanism to stream all files
with metadata to an AI system.

Following MCP principles:
- Process over implementation
- Security through repetition
- One thing at a time with validation
- Careful, deliberate execution
"""

import os
import sys
import subprocess
import json
import tarfile
import tempfile
import logging
import argparse
from datetime import datetime, timedelta
import fnmatch
import re
import base64
import mimetypes
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [MCP-%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger('mcp_collector')

class MCPCollector:
    """ModelContextProtocol file collection and processing tool."""
    
    def __init__(self, options=None):
        """Initialize the collector with options."""
        self.options = {
            'search_dir': '.',
            'output_dir': './mcp_output',
            'archive_name': 'mcp_batch.tar',
            'mtime': 1,  # days
            'file_pattern': '*',
            'exclude_pattern': None,
            'exclude_dirs': ['.git', 'node_modules', 'dist', 'build', 'tmp'],
            'max_files': 5000,
            'max_size': 100 * 1024 * 1024,  # 100MB
            'format': 'text',
            'verbose': False
        }
        
        if options:
            self.options.update(options)
            
        # Set up paths
        self.archive_path = os.path.join(self.options['output_dir'], self.options['archive_name'])
        self.metadata_path = os.path.join(self.options['output_dir'], 'metadata.json')
        self.file_list_path = os.path.join(self.options['output_dir'], 'file_list.txt')
        
        # Configure logging level
        if self.options['verbose']:
            logger.setLevel(logging.DEBUG)
        
        # Ensure output directory exists
        self._ensure_directories()
    
    def _ensure_directories(self):
        """Create necessary directories if they don't exist."""
        logger.debug("Ensuring directories exist")
        
        if not os.path.exists(self.options['output_dir']):
            os.makedirs(self.options['output_dir'])
            logger.info(f"Created output directory: {self.options['output_dir']}")
    
    def _is_file_valid(self, file_path):
        """Check if file matches our criteria."""
        try:
            # Check if file exists and is a regular file
            if not os.path.isfile(file_path):
                return False
            
            # Check modification time
            file_stat = os.stat(file_path)
            file_mtime = datetime.fromtimestamp(file_stat.st_mtime)
            age_limit = datetime.now() - timedelta(days=self.options['mtime'])
            if file_mtime < age_limit:
                return False
            
            # Check excluded directories
            for excluded_dir in self.options['exclude_dirs']:
                if excluded_dir in file_path.split(os.sep):
                    return False
            
            # Check file pattern
            if not fnmatch.fnmatch(os.path.basename(file_path), self.options['file_pattern']):
                return False
                
            # Check exclude pattern
            if self.options['exclude_pattern'] and fnmatch.fnmatch(
                os.path.basename(file_path), self.options['exclude_pattern']):
                return False
            
            return True
        except Exception as e:
            logger.warning(f"Error checking file {file_path}: {str(e)}")
            return False
    
    def find_files(self):
        """Find files matching our criteria."""
        logger.info(f"Finding files modified in the last {self.options['mtime']} days")
        
        matching_files = []
        start_time = time.time()
        
        # Walk through directory tree
        for root, dirs, files in os.walk(self.options['search_dir']):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if d not in self.options['exclude_dirs']]
            
            for filename in files:
                file_path = os.path.join(root, filename)
                if self._is_file_valid(file_path):
                    try:
                        file_stat = os.stat(file_path)
                        matching_files.append({
                            'path': file_path,
                            'size': file_stat.st_size,
                            'mtime': file_stat.st_mtime
                        })
                        logger.debug(f"Found matching file: {file_path}")
                    except Exception as e:
                        logger.warning(f"Error processing file {file_path}: {str(e)}")
        
        # Sort by modification time (newest first)
        matching_files.sort(key=lambda x: x['mtime'], reverse=True)
        
        logger.info(f"Found {len(matching_files)} matching files in {time.time() - start_time:.2f} seconds")
        
        # Apply limits
        if len(matching_files) > self.options['max_files']:
            logger.warning(f"Limiting to {self.options['max_files']} files (from {len(matching_files)})")
            matching_files = matching_files[:self.options['max_files']]
        
        # Check total size
        total_size = sum(f['size'] for f in matching_files)
        if total_size > self.options['max_size']:
            logger.warning(f"Total size ({total_size} bytes) exceeds maximum ({self.options['max_size']} bytes)")
            
            # Sort by size (smallest first)
            size_sorted = sorted(matching_files, key=lambda x: x['size'])
            
            # Keep adding files until we hit the size limit
            new_files = []
            current_size = 0
            for file in size_sorted:
                if current_size + file['size'] <= self.options['max_size']:
                    new_files.append(file)
                    current_size += file['size']
            
            logger.info(f"Reduced to {len(new_files)} files with total size of {current_size} bytes")
            matching_files = new_files
            
            # Sort back by modification time
            matching_files.sort(key=lambda x: x['mtime'], reverse=True)
        
        # Write file list
        with open(self.file_list_path, 'w') as f:
            for file in matching_files:
                f.write(f"{file['path']}\n")
        
        return matching_files
    
    def create_metadata(self, files):
        """Create metadata file for the collection."""
        logger.info("Creating metadata")
        
        metadata = {
            'created': datetime.now().isoformat(),
            'search_directory': self.options['search_dir'],
            'modified_days': self.options['mtime'],
            'file_pattern': self.options['file_pattern'],
            'exclude_pattern': self.options['exclude_pattern'],
            'file_count': len(files),
            'total_size': sum(f['size'] for f in files),
            'files': []
        }
        
        # Add file details
        for file in files:
            try:
                mime_type, _ = mimetypes.guess_type(file['path'])
                metadata['files'].append({
                    'path': file['path'],
                    'size': file['size'],
                    'modified': datetime.fromtimestamp(file['mtime']).isoformat(),
                    'type': mime_type or 'application/octet-stream'
                })
            except Exception as e:
                logger.warning(f"Error adding metadata for {file['path']}: {str(e)}")
        
        # Write metadata file
        with open(self.metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info(f"Metadata written to {self.metadata_path}")
        return metadata
    
    def create_archive(self, files):
        """Create tar archive from file list."""
        logger.info(f"Creating archive: {self.archive_path}")
        
        start_time = time.time()
        
        with tarfile.open(self.archive_path, 'w') as tar:
            for file in files:
                try:
                    tar.add(file['path'])
                    logger.debug(f"Added to archive: {file['path']}")
                except Exception as e:
                    logger.warning(f"Error adding {file['path']} to archive: {str(e)}")
        
        # Get archive size
        archive_size = os.path.getsize(self.archive_path)
        logger.info(f"Archive created: {self.archive_path} ({archive_size} bytes) in {time.time() - start_time:.2f} seconds")
        
        return self.archive_path
    
    def collect(self):
        """Find and collect files into an archive."""
        logger.info("Starting file collection")
        
        # Find files
        files = self.find_files()
        
        if not files:
            logger.warning("No matching files found")
            return None
        
        # Create metadata
        metadata = self.create_metadata(files)
        
        # Create archive
        archive_path = self.create_archive(files)
        
        logger.info("File collection complete")
        
        return {
            'archive_path': archive_path,
            'metadata_path': self.metadata_path,
            'file_count': len(files),
            'total_size': sum(f['size'] for f in files)
        }
    
    def read_archive(self):
        """Read archive and stream all file contents with metadata."""
        logger.info(f"Reading archive: {self.archive_path}")
        
        if not os.path.exists(self.archive_path):
            logger.error(f"Archive not found: {self.archive_path}")
            return None
        
        # Load metadata if available
        metadata = None
        if os.path.exists(self.metadata_path):
            try:
                with open(self.metadata_path, 'r') as f:
                    metadata = json.load(f)
                logger.info(f"Loaded metadata: {metadata['file_count']} files, {metadata['total_size']} bytes")
            except Exception as e:
                logger.warning(f"Error loading metadata: {str(e)}")
        
        # Create temporary directory for extraction
        with tempfile.TemporaryDirectory() as temp_dir:
            logger.debug(f"Created temporary directory: {temp_dir}")
            
            # Extract archive
            logger.info("Extracting archive")
            with tarfile.open(self.archive_path, 'r') as tar:
                tar.extractall(path=temp_dir)
            
            # Process all files
            logger.info("Processing files")
            
            # Collect file data
            files_data = []
            
            for root, dirs, files in os.walk(temp_dir):
                for filename in files:
                    file_path = os.path.join(root, filename)
                    rel_path = os.path.relpath(file_path, temp_dir)
                    
                    try:
                        # Get file stats
                        file_stat = os.stat(file_path)
                        mime_type, _ = mimetypes.guess_type(file_path)
                        mime_type = mime_type or 'application/octet-stream'
                        
                        # Read file content
                        with open(file_path, 'rb') as f:
                            content = f.read()
                        
                        # Convert to string for text files, base64 for binary
                        if mime_type.startswith('text/') or mime_type in ['application/json', 'application/javascript']:
                            try:
                                content = content.decode('utf-8')
                                encoding = 'utf-8'
                            except UnicodeDecodeError:
                                content = base64.b64encode(content).decode('ascii')
                                encoding = 'base64'
                        else:
                            content = base64.b64encode(content).decode('ascii')
                            encoding = 'base64'
                        
                        # Add file data
                        files_data.append({
                            'path': rel_path,
                            'size': file_stat.st_size,
                            'type': mime_type,
                            'content': content,
                            'encoding': encoding
                        })
                        
                        logger.debug(f"Processed file: {rel_path} ({file_stat.st_size} bytes)")
                    except Exception as e:
                        logger.warning(f"Error processing file {rel_path}: {str(e)}")
            
            # Sort files by path
            files_data.sort(key=lambda x: x['path'])
            
            # Output
            if self.options['format'] == 'json':
                # JSON output
                output = {
                    'metadata': metadata,
                    'files': files_data
                }
                return output
            else:
                # Text output
                output = []
                output.append("====== MCP BATCH PROCESSOR - FILE CONTENTS ======")
                output.append(f"Archive: {self.archive_path}")
                output.append("======================================================")
                
                for file in files_data:
                    output.append("")
                    output.append(f"====== FILE: {file['path']} ======")
                    output.append(f"Size: {file['size']} bytes")
                    output.append(f"Type: {file['type']}")
                    output.append("------------------------------------------------------")
                    
                    if file['encoding'] == 'utf-8':
                        output.append(file['content'])
                    else:
                        output.append("[Binary file - content not displayed]")
                    
                    output.append("------------------------------------------------------")
                
                output.append("")
                output.append(f"====== END OF FILE CONTENTS ({len(files_data)} files) ======")
                
                return "\n".join(output)

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='MCP Collector - ModelContextProtocol Batch Processing Tool')
    
    # Commands
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Collect command
    collect_parser = subparsers.add_parser('collect', help='Find and package files')
    collect_parser.add_argument('-d', '--dir', dest='search_dir', default='.',
                               help='Directory to search (default: current directory)')
    collect_parser.add_argument('-o', '--output', dest='output_dir', default='./mcp_output',
                               help='Output directory (default: ./mcp_output)')
    collect_parser.add_argument('-a', '--archive', dest='archive_name', default='mcp_batch.tar',
                               help='Archive name (default: mcp_batch.tar)')
    collect_parser.add_argument('-m', '--mtime', type=int, default=1,
                               help='Find files modified in last N days (default: 1)')
    collect_parser.add_argument('-p', '--pattern', dest='file_pattern', default='*',
                               help='File pattern to include (default: *)')
    collect_parser.add_argument('-e', '--exclude', dest='exclude_pattern',
                               help='File pattern to exclude')
    collect_parser.add_argument('-E', '--exclude-dir', dest='exclude_dirs', action='append',
                               help='Directory to exclude (can be used multiple times)')
    collect_parser.add_argument('-n', '--max-files', type=int, default=5000,
                               help='Maximum number of files to process (default: 5000)')
    collect_parser.add_argument('-s', '--max-size', type=str, default='100M',
                               help='Maximum total size (default: 100M)')
    collect_parser.add_argument('-f', '--format', choices=['text', 'json'], default='text',
                               help='Output format (default: text)')
    collect_parser.add_argument('-v', '--verbose', action='store_true',
                               help='Enable verbose logging')
    
    # Read command
    read_parser = subparsers.add_parser('read', help='Read and stream packaged files')
    read_parser.add_argument('-o', '--output', dest='output_dir', default='./mcp_output',
                            help='Output directory containing archive (default: ./mcp_output)')
    read_parser.add_argument('-a', '--archive', dest='archive_name', default='mcp_batch.tar',
                            help='Archive name (default: mcp_batch.tar)')
    read_parser.add_argument('-f', '--format', choices=['text', 'json'], default='text',
                            help='Output format (default: text)')
    read_parser.add_argument('-v', '--verbose', action='store_true',
                            help='Enable verbose logging')
    
    args = parser.parse_args()
    
    # Convert arguments to options dict
    options = vars(args)
    
    # Convert max_size string to bytes
    if 'max_size' in options and options['max_size']:
        size_str = options['max_size']
        if size_str.endswith('K'):
            options['max_size'] = int(size_str[:-1]) * 1024
        elif size_str.endswith('M'):
            options['max_size'] = int(size_str[:-1]) * 1024 * 1024
        elif size_str.endswith('G'):
            options['max_size'] = int(size_str[:-1]) * 1024 * 1024 * 1024
        else:
            options['max_size'] = int(size_str)
    
    return args.command, options

def main():
    """Main entry point."""
    command, options = parse_args()
    
    try:
        collector = MCPCollector(options)
        
        if command == 'collect':
            result = collector.collect()
            
            if result:
                print("\nModelContextProtocol Batch Processor - Summary")
                print("===========================================================")
                print(f"Files collected: {result['file_count']}")
                print(f"Archive: {result['archive_path']}")
                print(f"Metadata: {result['metadata_path']}")
                print(f"Total size: {result['total_size']} bytes")
                print("")
                print("To read this archive: python mcp_collector.py read")
                print("===========================================================")
        
        elif command == 'read':
            result = collector.read_archive()
            
            if result:
                if options['format'] == 'json':
                    print(json.dumps(result, indent=2))
                else:
                    print(result)
        
        else:
            print("Error: No command specified. Use 'collect' or 'read'.")
            print("Run with --help for usage information.")
            sys.exit(1)
            
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
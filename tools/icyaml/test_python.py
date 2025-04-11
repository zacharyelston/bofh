#!/usr/bin/env python3
"""
Simple test script to verify Python and YAML functionality.
"""

import sys
import os

print("Python version:", sys.version)
print("Python executable:", sys.executable)
print("Current directory:", os.getcwd())

try:
    import yaml
    print("PyYAML is installed and working!")
    
    # Create a simple YAML structure
    test_data = {
        'name': 'ICYAML Test',
        'version': '1.0',
        'status': 'working'
    }
    
    # Dump to YAML
    yaml_output = yaml.dump(test_data)
    print("\nYAML output:")
    print(yaml_output)
    
    # Load from YAML
    reloaded = yaml.safe_load(yaml_output)
    print("\nReloaded data:", reloaded)
    
except ImportError:
    print("Error: PyYAML is not installed!")
    sys.exit(1)

print("\nAll tests passed successfully!")

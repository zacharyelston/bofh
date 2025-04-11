# ICYAML Outlier Detection

## Overview

The ICYAML Outlier Detection tool analyzes YAML structures across directories to identify missing keys and structure outliers. Rather than looking for specific values like the query tool, this module focuses on detecting inconsistencies in the structure itself - finding which directories are missing expected keys compared to the common patterns found across all directories.

## Key Features

- Recursively analyze YAML files across multiple directories
- Build a tree of key paths for each directory
- Identify common keys that appear in most directories
- Highlight directories missing common keys (outliers)
- Generate statistics about key usage and frequency
- Export detailed analysis as JSON for further processing

## When to Use

Use this tool when you want to:

1. Find inconsistencies across similar directories
2. Identify which directories need attention or fixes
3. Detect missing configuration elements
4. Understand the "average" structure of your YAML files
5. Find structural outliers that deviate from the norm

## Command Line Usage

```bash
./find_outliers.sh --dir /path/to/yaml/files --threshold 50 --output results.json
```

Options:
- `--dir, -d`: Directory containing YAML files to analyze (required)
- `--pattern, -p`: File pattern to match (default: *)
- `--threshold, -t`: Threshold percentage for common keys (default: 50)
- `--output, -o`: Output file for results (JSON)
- `--verbose, -v`: Enable verbose output
- `--help, -h`: Display help message

## Example: Analyze YAML configuration files

```bash
./analyze_yaml_outliers.sh
```

This will:
1. Analyze all YAML files in the YAML configuration files repository
2. Identify common keys across all directories
3. Find directories missing those common keys
4. Generate statistics about key usage
5. Export the results to `output/env_outliers.json`

To adjust the threshold for common keys:

```bash
./analyze_yaml_outliers.sh --threshold 75
```

## How It Works

The outlier detection process follows these steps:

1. **Key Path Extraction**: For each YAML file, extract all key paths (e.g., `metadata.name`, `spec.containers[0].image`)
2. **Directory Mapping**: Group key paths by directory to build a structural profile for each directory
3. **Common Key Analysis**: Identify keys that appear in a certain percentage of directories (based on threshold)
4. **Outlier Detection**: Find directories missing these common keys
5. **Statistics Generation**: Calculate key frequency, most common keys, etc.
6. **Result Reporting**: Display results and export to JSON

## Example Output

```
===== YAML Structure Analysis Results =====

Total directories analyzed: 25
Total unique keys found: 1243
Common keys (threshold: 50%): 87
Directories with missing keys: 8

----- Top 10 Most Common Keys -----
  metadata.name: 25 directories (100.0%)
  metadata.namespace: 25 directories (100.0%)
  kind: 25 directories (100.0%)
  apiVersion: 25 directories (100.0%)
  spec.template.spec.containers: 22 directories (88.0%)
  spec.template.spec.containers[0].name: 22 directories (88.0%)
  spec.template.spec.containers[0].image: 22 directories (88.0%)
  spec.selector: 20 directories (80.0%)
  spec.ports: 18 directories (72.0%)
  spec.ports[0].port: 18 directories (72.0%)

----- Directories Missing Common Keys -----

  Directory: spine-partner-service
  Missing 12 common keys:
    - spec.template.spec.containers[0].env
    - spec.template.spec.containers[0].ports
    - spec.template.spec.containers[0].resources
    ... and 9 more

  Directory: scdh-qic-api
  Missing 7 common keys:
    - spec.template.spec.volumes
    - spec.template.spec.containers[0].volumeMounts
    - spec.template.metadata.annotations
    ... and 4 more
```

## Integration with Other ICYAML Tools

The outlier detection works seamlessly with other ICYAML tools:

1. **Step 1: Find Outliers** - Use `find_outliers.sh` to identify directories with missing common keys
2. **Step 2: Investigate Details** - Use `icyaml query` to examine specific keys in the outlier directories
3. **Step 3: Visualize Structure** - Use `icyaml scan-enhanced` to create visual maps of the directory structures

## Best Practices

1. **Start with a Low Threshold** - Begin with 50% threshold and adjust as needed
2. **Focus on Key Outliers** - Concentrate on directories with many missing keys
3. **Check for Valid Exceptions** - Some outliers may be intentionally different
4. **Compare Similar Types** - Group analysis by resource type for more meaningful results
5. **Look for Patterns** - Identify common patterns in the missing keys

## Requirements

- Python 3.6+
- PyYAML

## Extending the Tool

The outlier detection can be extended in several ways:

1. **Value Analysis** - Add capabilities to analyze key values, not just structure
2. **Custom Rules** - Define specific structural rules to check
3. **Integration with CI/CD** - Run analysis as part of your CI/CD pipeline
4. **Visual Reporting** - Generate graphical representations of outliers
5. **Historical Tracking** - Track changes in structure over time

---

> "I see structure deviations... they don't know they're outliers."
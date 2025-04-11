# YAML Consistency Analyzer

## Overview

The YAML Consistency Analyzer is a powerful tool for identifying inconsistencies across your YAML configurations. It focuses on providing clear, actionable insights with specific examples showing both compliant and non-compliant files.

This tool helps you:
- Identify inconsistently used configuration keys
- Find missing security contexts and other critical settings
- Discover configuration drift across files
- Get concrete examples of both good and problematic configurations
- Receive actionable recommendations for standardization

## Quick Start

```bash
# Set your source directory
export SOURCE_DIR=/path/to/your/yaml/files

# Run the consistency analyzer
./analyze_consistency.sh

# Analyze with a specific file pattern
./analyze_consistency.sh --pattern "deployment-*"

# Specify a custom output file
./analyze_consistency.sh --output "custom_report.json"
```

## Understanding the Report

The consistency analyzer generates a comprehensive report that includes:

### 1. Summary Statistics
- Total files analyzed
- Resource types found (Deployment, Service, etc.)
- Total unique key paths found
- List of ignored key patterns (env variables, etc.)

### 2. Key Inconsistency Highlights
Organized by category:
- **Security**: Security context configurations, privileged settings
- **Metadata**: Labels, annotations, tags
- **Resources**: Resource requests, limits
- **General**: Other configuration inconsistencies

For each inconsistent key, you'll see:
- Usage percentage across all files
- Specific examples showing files that have the key and its value
- Specific examples showing files missing the key

### 3. Recommendations
Actionable guidance for standardizing configurations:
- Which keys should be consistently applied
- Suggested patterns for standardization

## Filtered Keys

By default, the analyzer ignores certain keys that are expected to vary across files:
- Environment variables (`env`, `environment`, `spec.template.spec.containers[0].env`, etc.)
- Configuration data (`data`, `value`, `values`)

This filtering helps focus the analysis on structural inconsistencies rather than expected variations.

## Example Output

```
=== YAML Consistency Analysis Report ===

Total files analyzed: 33
Resource types found: 4
  - Deployment: 18 file(s)
  - Service: 9 file(s)
  - CronJob: 4 file(s)
  - ConfigMap: 2 file(s)
Unique key paths found: 142

Ignored key patterns:
  - env
  - environment
  - spec.template.spec.containers[0].env
  - spec.containers[0].env
  - data
  - value
  - values

=== Key Inconsistency Highlights ===

Category: Security
Issue: Security Context Inconsistencies
Description: Security context configurations are inconsistently applied across files

Inconsistent keys:
  - spec.template.spec.containers[0].securityContext.runAsNonRoot: 21% of files (7/33)
    Examples with this key:
      * api-gateway-deployment.yaml: true
      * auth-service-deployment.yaml: true
    Examples missing this key:
      * data-processor-deployment.yaml
      * metrics-collector-deployment.yaml

Recommendation: Standardize security context settings across all containers

--------------------------------------------------

Category: Metadata
Issue: Inconsistent Labels and Annotations
Description: Labels and annotations are not consistently applied

Inconsistent keys:
  - spec.template.metadata.labels.tags.datadoghq.com/service: 3% of files (1/33)
    Examples with this key:
      * metrics-service-deployment.yaml: "metric-collector"
    Examples missing this key:
      * api-gateway-deployment.yaml
      * auth-service-deployment.yaml

Recommendation: Establish a standard set of labels and annotations for all resources
```

## How to Interpret Results

The analyzer shows you keys that appear inconsistently across files. For each key:

1. **Percentage and count**: Shows how prevalent the key is across your files
   - Example: `21% of files (7/33)` means the key appears in 7 out of 33 files

2. **Concrete examples**:
   - Files that have the key and their values
   - Files that are missing the key

3. **Recommendations** for standardization

This makes it easy to understand exactly what's inconsistent and where the issues are, enabling targeted fixes.

## Common Use Cases

### Finding Missing Security Settings

```bash
# Analyze security settings across all files
export SOURCE_DIR=/path/to/k8s/manifests
./analyze_consistency.sh
```

This will highlight files missing crucial security settings like:
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`

### Detecting Configuration Drift

```bash
# Compare configurations across environments
export SOURCE_DIR=/path/to/prod
./analyze_consistency.sh --output "prod_report.json"

export SOURCE_DIR=/path/to/staging
./analyze_consistency.sh --output "staging_report.json"
```

Then compare the reports to identify configuration drift between environments.

### Enforcing Tagging Standards

```bash
# Check for consistent tagging across services
export SOURCE_DIR=/path/to/services
./analyze_consistency.sh
```

This will show you which services are missing important tags like:
- `datadoghq.com/service`
- `app.kubernetes.io/name`
- `environment`

## Tips for Effective Analysis

1. **Focus on specific resource types**: Use the pattern option to analyze similar resources together
   ```bash
   ./analyze_consistency.sh --pattern "deployment-*"
   ```

2. **Look for security inconsistencies first**: They often represent the highest risk

3. **Use examples to create templates**: The examples of files with proper configurations can serve as templates for standardization

4. **Compare before and after**: Run the analysis before and after standardization to verify improvements

## Troubleshooting

- **No inconsistencies found**: If all files are identical or completely different, try narrowing the scope with more specific patterns
- **Too many results**: Focus on high-priority categories like Security and Resources first

## Integration with Other Tools

This analyzer works well with other ICYAML tools:

```bash
# First find inconsistencies
./analyze_consistency.sh

# Then query specific patterns based on findings
./arm64_docker.sh query "select securityContext from spec.template.spec.containers[0]"
```

# DISKVOYEUR - Data Collection Component

The data collection component gathers raw filesystem information for vector analysis.

## Collection Methods

### Basic Collection

The basic collection uses standard Unix tools to gather filesystem metadata:

```bash
# Collect basic metadata for all files in a directory
./py/basic_collection.sh /path/to/directory > raw_metadata.txt

# Process only part of a filesystem
./py/basic_collection.sh /home/user/documents > documents_metadata.txt
```

The basic collection gathers:
- Full file path
- File size in bytes
- Modification time
- File permissions
- File type
- User/Group IDs
- Hard link count
- Access/Change times

### Extended Collection

Extended collection adds content sampling and hashing:

```bash
# Collect extended metadata with content hashing
./py/extended_collection.sh /path/to/directory > raw_extended.txt

# Process only specific file types
find /path -name "*.pdf" | xargs ./py/extended_collection.sh > pdfs_extended.txt
```

The extended collection adds:
- SHA256 hash of file content
- MIME type
- First 1KB of file content (hexadecimal)

### Performance-Optimized Collection

For large filesystems, use parallelized collection:

```bash
# Collect data in parallel for better performance
./py/parallel_collection.sh /path/to/large/directory > large_data.txt

# Control parallelism level with GNU parallel
PARALLEL_JOBS=16 ./py/parallel_collection.sh /path > high_parallel_data.txt
```

## Storage Formats

Collected data can be stored in several formats:

### CSV Format

```bash
# Convert raw data to CSV
cat raw_metadata.txt | awk -F '|' '{print $1","$2","$3","$4}' > filesystem_data.csv
```

### SQLite Database

Create a structured database for more complex queries:

```bash
# Store metadata in SQLite database
./py/sqlite_storage.sh raw_metadata.txt
```

SQL queries for analysis:

```sql
-- Find largest files
SELECT path, size FROM files ORDER BY size DESC LIMIT 10;

-- Find recently modified files
SELECT path, datetime(modified, 'unixepoch') FROM files 
WHERE modified > strftime('%s', 'now', '-7 days') 
ORDER BY modified DESC;
```

### Binary Format

For efficient storage of large datasets:

```python
from vectorizer.collection.py.binary_storage import store_as_binary

# Convert raw data to numpy binary format
paths, data_files = store_as_binary('raw_metadata.txt')
print(f"Stored {len(paths)} file records in binary format")
```

## Special File Types

Different file types require specialized collection:

```bash
# Collect entropy information for binary files
./py/special_files.sh /path/to/binary/files

# Analyze text files for language detection and line counting
./py/special_files.sh /path/to/text/files
```

## Incremental Collection

For regular updates, use incremental collection:

```bash
# Only collect data for files modified since last scan
./py/incremental_collection.sh /path/to/monitor > incremental_update.txt

# Set up as a cron job for regular monitoring
# 0 * * * * /path/to/py/incremental_collection.sh /important/data >> /var/log/disk_changes.txt
```

## Integration

The collection component integrates with the feature extraction component:

```bash
# Full pipeline
./py/extended_collection.sh /path | ./extraction/py/extract_features.sh > feature_vectors.csv

# Process results further with analysis tools
./py/extended_collection.sh /path | ./extraction/py/extract_features.sh | ./analysis/py/analyze_vectors.sh cluster
```

## Dependencies

- Standard Unix tools (find, stat, xargs)
- GNU parallel (for performance-optimized collection)
- sha256sum, file, xxd (for extended collection)
- SQLite3 (for database storage)
- Python with NumPy, Pandas (for binary storage)

# Schema and Table Search Tools
## ModelContextProtocol (MCP)

This directory contains a collection of tools for analyzing database schemas and tables in codebases. These tools provide different perspectives and levels of detail on the database structure.

## Available Tools

### 1. `apps_tables_report.md`

A high-level summary of the major applications and their tables identified from the initial analysis. This is a good starting point to understand the overall database architecture.

### 2. `find_schema_tables.sh`

A shell script that searches for schema and table definitions in SQL files and generates a report (`schema_tables_inventory.md`). This script focuses on explicit schema and table creation statements.

**Usage:**
```bash
chmod +x find_schema_tables.sh
./find_schema_tables.sh [target_directory] [output_directory]
```

### 3. `analyze_schemas.py`

A more sophisticated Python script that performs deeper analysis of schemas and tables, including extracting column information and relationships between tables. This script generates both a markdown report (`schema_analysis_report.md`) and a JSON data file (`schema_data.json`) for further processing.

**Usage:**
```bash
chmod +x analyze_schemas.py
./analyze_schemas.py --target-dir=/path/to/codebase --output-dir=/path/to/output
```

### 4. `search_hql_patterns.sh`

A shell script that searches for SQL-like patterns in non-SQL files, which may represent Hive, Athena, or other data warehouse queries. This helps identify tables and schemas that might not be defined in traditional SQL migration files.

**Usage:**
```bash
chmod +x search_hql_patterns.sh
./search_hql_patterns.sh [target_directory] [output_directory]
```

## Process for Comprehensive Schema Analysis

For a complete understanding of the database architecture, follow these steps:

1. Review the `apps_tables_report.md` for a high-level overview
2. Run `find_schema_tables.sh` to identify explicit schema and table definitions
3. Run `analyze_schemas.py` for deeper analysis of tables and relationships
4. Run `search_hql_patterns.sh` to find references to tables in HQL and other files
5. Compare and consolidate the findings from all reports

## Typical Patterns

Most codebases follow these general patterns:

1. Each application has its own schema or uses a default schema
2. Migration files contain schema and table definitions
3. Some tables are shared across multiple applications
4. Different data storage systems may be in use (PostgreSQL, MySQL, Oracle, Redshift, Athena, etc.)

## Configuration

All tools in this directory can be configured in two ways:

1. Through the main BOFH config file at `../config.sh`
2. Through command-line parameters

Key configuration options:
- `DEFAULT_CODE_DIR`: Default target directory to search
- `DEFAULT_OUTPUT_DIR`: Default output directory for reports
- `DEBUG_LEVEL`: Level of debug information (0=none, 1=basic, 2=verbose)

## Next Steps

After analyzing the schemas and tables, consider:

1. Creating a comprehensive entity-relationship diagram
2. Documenting the data flow between applications
3. Identifying optimization opportunities in the database design
4. Evaluating schema consistency across applications

## Maintenance

These scripts may need adjustments as codebases evolve. The main patterns to look for are:

- `CREATE SCHEMA` statements
- `CREATE TABLE` statements
- `FOREIGN KEY` constraints
- `JOIN` clauses in SQL queries
- Schema references in the format `schema.table`

Periodically re-run these tools to keep your understanding of the database architecture up to date.

#!/usr/bin/env bash
# Purpose: This script orchestrates the startup sequence for the dbt container.
# Role: It prepares the environment by seeding static data and compiling the project before launching the MCP server.

set -e

# Load static seed files (CSV) into the Snowflake data warehouse
echo "==> Seeding dbt project..."
uv run dbt seed --profiles-dir . --project-dir .

# Compile the project to generate the manifest.json required by the MCP server
echo "==> Compiling dbt project to generate target/manifest.json..."
uv run dbt compile --profiles-dir . --project-dir .

# Launch the Model Context Protocol (MCP) server to enable AI interaction
echo "==> Starting dbt MCP server on port 8000..."
exec uv run python start_mcp.py
"""Purpose: This script is a wrapper that initializes and runs the dbt Model Context Protocol (MCP) server.
Role: It enables AI agents to interact with the dbt project metadata and provides a bridge for Docker port mapping.

The upstream dbt-mcp hardcodes host=127.0.0.1 in the FastMCP constructor,
which prevents Docker port mapping from working. This wrapper overrides
server.settings.host after creation so FASTMCP_HOST is respected.
"""

import asyncio
import os

from dbt_mcp.config.config import load_config
from dbt_mcp.config.transport import validate_transport
from dbt_mcp.mcp.server import create_dbt_mcp


def main() -> None:
    # Load dbt-specific configuration for the MCP server
    config = load_config()
    # Initialize the server instance asynchronously
    server = asyncio.run(create_dbt_mcp(config))

    # Apply the host binding from environment variables to support containerization
    host = os.environ.get("FASTMCP_HOST")
    if host:
        server.settings.host = host

    # Determine the communication protocol (default is stdio for CLI/pipe interaction)
    transport = validate_transport(os.environ.get("MCP_TRANSPORT", "stdio"))
    # Start the server with the specified transport method
    server.run(transport=transport)


if __name__ == "__main__":
    main()
# Before: 'description: Staging model for sales orders' — tells an agent almost nothing
# After: grain (one row per order), business entity (e-commerce sales order), join keys (JOIN to stg_adventure_db__customers via customer_id), source (PostgreSQL ecom system)
# Agent-friendly docs explicitly state: what the model represents, what grain it has, what columns join to other models, and what business questions it enables
# Column descriptions: not just 'customer_id' but 'Foreign key to stg_adventure_db__customers.customer_id — join here to get customer name, geography, and contact info'
# Without good docs, an agent might join on the wrong key, query the wrong grain, or ignore a relevant model entirely
#!/usr/bin/env python3
"""
dbt MCP Server Demo Client
"""

import asyncio
import json
import sys
from datetime import datetime

# Step 0: Import MCP client library
from mcp.client.sse import sse_client
from mcp.client.session import ClientSession

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
MCP_SERVER_URL = "http://localhost:8000/sse"
OUTPUT_LOG = "demo_output.log"

# -------------------------------------------------------------------
# Helper: log to both console and file
# -------------------------------------------------------------------
log_lines = []

def log(message: str):
    timestamp = datetime.now().strftime("%H:%M:%S")
    line = f"[{timestamp}] {message}"
    print(line)
    log_lines.append(line)

def save_log():
    with open(OUTPUT_LOG, "w") as f:
        f.write(f"dbt MCP Demo Output - {datetime.now().isoformat()}\n")
        f.write("=" * 60 + "\n\n")
        for line in log_lines:
            f.write(line + "\n")
    log(f"Output saved to {OUTPUT_LOG}")

# -------------------------------------------------------------------
# Demo Steps
# -------------------------------------------------------------------

async def run_demo():
    log("=" * 60)
    log("dbt MCP Server Demo")
    log("=" * 60)
    log("")

    # ----- STEP 1: Connect to the MCP server -----
    log("Step 1: Connecting to dbt MCP server...")
    async with sse_client(MCP_SERVER_URL) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            log("Connected successfully!")

            # ----- STEP 2: List available tools. The server responds with a list of functions it supports, such as list, compile, and get_lineage_dev -----
            log("")
            log("Step 2: Listing available tools...")
            tools_result = await session.list_tools()
            for tool in tools_result.tools:
                # Removed slicing to show full tool descriptions
                log(f"  - {tool.name}: {tool.description}")

            # ----- STEP 3: List all dbt models -----
            log("")
            log("Step 3: Discovering dbt models...")
            # Fixed resource_type to be a list [type=list_type]
            models_result = await session.call_tool("list", {"resource_type": ["model"]})
            # Removed slicing to show all models and their improved descriptions
            log(f"Found models:\n{models_result.content[0].text}")

            # ----- STEP 4: Get details on a specific model -----
            target_model = "stg_ecom__sales_orders" 
            log("")
            log(f"Step 4: Getting details for {target_model}...")
            details_result = await session.call_tool("get_node_details_dev", {"node_id": target_model})
            # Printing full details to show columns, tests, and dependencies
            log(f"Model Details:\n{details_result.content[0].text}")

            # ----- STEP 5: Compile SQL for a model -----
            log("")
            log("Step 5: Compiling SQL for a model...")
            compile_result = await session.call_tool("compile", {"models": target_model})
            # Printing full SQL output to satisfy verification
            log(f"Compiled SQL Output:\n{compile_result.content[0].text}")

            # ----- STEP 6: Explore model lineage. Lineage is the map of how data flows from your raw sources to your final reports. -----
            log("")
            log("Step 6: Exploring model lineage...")
            # unique_id format is model.<project_name>.<model_name>
            lineage_result = await session.call_tool("get_lineage_dev", {
                "unique_id": f"model.adventure.{target_model}",
                "depth": 2,
            })
            log(f"Lineage graph retrieved:\n{lineage_result.content[0].text}")

            # ----- WRAP UP -----
            log("")
            log("=" * 60)
            log("Demo complete!")
            log("=" * 60)


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

if __name__ == "__main__":
    try:
        asyncio.run(run_demo())
    except KeyboardInterrupt:
        log("\nDemo interrupted by user.")
    except Exception as e:
        log(f"\nError: {e}")
        log("Make sure the dbt MCP server is running locally.")
        log("Start it with: docker compose up dbt-mcp")
        sys.exit(1)
    finally:
        save_log()
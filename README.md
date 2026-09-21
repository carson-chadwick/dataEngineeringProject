# Adventure Works Data Platform
A complete data pipeline that utilizes Snowflake, dbt, and Prefect, allowing integration with AI through an MCP.

## Architecture

For an architecture diagram see screenshots/architecture.png

**Caption:** 
The architecture features a modular data platform that integrates multiple sources—PostgreSQL, MongoDB, and a REST API—into a centralized Snowflake warehouse. Data ingestion is handled by a custom Python ETL processor and Prefect orchestration, which manages the transition from local files to Snowflake internal stages and eventually into raw tables. Once the data is in Snowflake, dbt performs structured transformations across staging and intermediate layers, which are then exposed to AI agents via an MCP server.

## Problem Statement

The Adventure Works Data Platform unifies fragmented data from PostgreSQL, MongoDB, and REST APIs into a centralized Snowflake warehouse. Ingestion is managed by a Python ETL processor and Prefect orchestration, moving data through Snowflake internal stages into raw tables. From there, dbt transforms the data into staging and intermediate layers, creating a single source of truth accessible to AI agents via an MCP server. This architecture eliminates data silos, enabling stakeholders to perform cross-functional analysis on customer behavior and revenue attribution.

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Source Systems | PostgreSQL, MongoDB, REST API | These sources represent the real-world mix of relational, semi-structured, and external third-party data common in modern enterprises. |
| Extraction | Python ETL Processor | A custom processor enables fine-grained control over extraction logic and uses watermark patterns to ensure efficient, incremental data loading. |
| Warehouse | Snowflake | Snowflake provides a cloud-native platform with independent scaling of compute and storage alongside native support for semi-structured JSON data. |
| Transformation | dbt | Dbt treats data transformation like software engineering by providing built-in version control, automated testing, and interactive lineage documentation. |
| Orchestration | Prefect | Prefect offers a lightweight Python-based orchestration layer that simplifies workflow management through automated retries, detailed logging, and easy local development. |
| CI/CD | dbt Cloud + GitHub | This combination automates code deployments and schedules production runs to ensure that data models are always tested and up-to-date. |
| Agent Access | dbt MCP Server | The MCP server exposes transformed models as tools, allowing AI agents to securely query and reason about the data platform's context. |
| Containerization | Docker Compose | Docker ensures environmental consistency and reproducibility across development and production by packaging all services into a single portable unit. |

---

## Data Flow

Data enters the platform from three sources: transactional data from PostgreSQL, support logs from MongoDB, and clickstream events from a REST API. The extraction process utilizes a watermarking strategy to track the last_modified or event_timestamp values, ensuring only new or updated records are ingested during each cycle. Data is first staged as CSV or JSON files in Snowflake internal stages before the COPY INTO command loads them into raw tables.

In the dbt transformation layer, staging models like stg_adventure_db__customers and stg_web_analytics perform initial data cleaning, renaming columns for consistency and casting fields to correct data types. Intermediate models, such as int_sales_orders_with_customers and int_web_analytics_with_customers, then join these cleaned sources to create enriched datasets for analysis. This structured approach ensures that complex logic is centralized and reusable across the entire project.

Final data is consumed through Snowflake dashboards and a dbt MCP server, which exposes models as tools for AI agents to query directly. Data quality is maintained through dbt tests—including custom tests for inventory levels and row count minimums—while dbt Cloud and GitHub handle CI/CD by automating builds and scheduled runs. This lifecycle ensures that the serving layer always provides reliable, validated information to end users and agents.
---

## Setup and Run

### Prerequisites
- Docker Desktop
- Snowflake account (trial works)
- Python 3.9+
- dbt Cloud account (free tier)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/[TODO: your-username]/[TODO: your-repo-name].git
cd [TODO: your-repo-name]

# 2. Configure environment
cp .env.sample .env
# Edit .env with your Snowflake credentials

# 3. Create raw tables in Snowflake
# [TODO: describe how to set up the raw tables]

# 4. Start all services
docker compose up -d

# 5. Run dbt models and tests
cd dbt
dbt build

# 6. Start the MCP server
uv run python dbt/start_mcp.py

# 7. (Optional) Run the MCP demo
cd mcp
uv sync
uv run python demo_client.py
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `SNOWFLAKE_ACCOUNT` | Full Snowflake account identifier (e.g., `ab12345.us-east-1`) |
| `SNOWFLAKE_USER` | Snowflake username |
| `SNOWFLAKE_PASSWORD` | Snowflake password |
| `SNOWFLAKE_WAREHOUSE` | Compute warehouse name (e.g., `COMPUTE_WH`) |
| `SNOWFLAKE_DATABASE` | Target database (e.g., `IS566`) |
| `SNOWFLAKE_ROLE` | Snowflake role (default: `ACCOUNTADMIN`) |

See `.env.sample` for the full list.

---

## Project Milestones

### Milestone 1: Core Pipeline
Milestone 1 established the foundation of the data platform by implementing a custom Python ETL processor to extract transactional data from PostgreSQL (orders, order details) and support logs from MongoDB (chat logs) using watermarking logic. You developed 5 staging models, including stg_adventure_db__customers, stg_adventure_db__products, and stg_real_time__chat_logs, alongside 3 intermediate models such as int_sales_orders_with_customers to join disparate sources. Data quality was enforced through the implementation of standard dbt tests for uniqueness and nullity, plus custom logic to ensure integrity across the pipeline.

### Milestone 2: Orchestration, Quality, and Agent-Assisted Development
Milestone 2 introduced professional orchestration by deploying Prefect to manage the new web_analytics_flow, which ingests clickstream data from a REST API into Snowflake. This phase expanded the transformation layer with 2 new web analytics models—stg_web_analytics and int_web_analytics_with_customers—and integrated dbt Cloud for automated execution. Quality control was enhanced with source freshness checks and row-count minimum tests, while data visibility was finalized through the creation of granular Snowflake dashboards.

### Milestone 3: Agent Access and Portfolio
Milestone 3 focused on enabling AI interaction through the deployment of a dbt MCP server, which utilizes a custom start_mcp.py wrapper to expose warehouse models as tools for AI agents. You finalized the project portfolio by upgrading documentation in the README.md and technical_decisions.md and verified the system using a Python demo client to test agentic reasoning over the data. The project concluded with a comprehensive cleanup of the repository and the finalization of the architectural diagram to reflect the complete end-to-end flow.
---

## Key Metrics

<!-- Run actual Snowflake queries to fill in these numbers. Do NOT estimate or guess. -->

| Metric | Value |
|--------|-------|
| Raw records processed per cycle | 3,127 |
| Pipeline execution time | 26.16 sec |
| dbt models | 18 |
| dbt tests | 30 |
| Test pass rate | 100% |
| Data sources integrated | 5 |
| Source tables | 13 |
| Models exposed via MCP | 18 |
| Source freshness SLA | 24 hours |

---

## What I Learned

I learned that fundamental data engineering principles make data pipelines much more resilient. Moving data through the Medallion Architecture and using appropriate testing along the way ensures that data reaches the end user in a clean and reliable form. Applying CI/CD principles to data engineering was also very eye-opening. Data cleaning throughout the process can be difficult, but it is far better to clean the data within your pipeline than to pass along poor-quality data to analysts. In the future, I hope to apply what I have learned in real business applications to leverage data in answering businesses’ most complex questions.

---

## Future Improvements

- **AI Chatbot**: With MCP in place, I would like to connect a real AI chatbot to my database in the future. 
- **Protect Sensitive Data**: As I serve data to a chatbot, I want to ensure that sensitive information—or data that could introduce bias—is excluded from the AI’s reasoning.
- **Dashboard Integration**: While I have already created one dashboard (m1_task1.4.png), I would like to integrate a more robust data visualization tool, such as Tableau, into the data pipeline.

---

## Technical Decisions

See [technical_decisions.md](technical_decisions.md) for detailed documentation of key architectural choices.

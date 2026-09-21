# Purpose: This Dockerfile defines the containerized environment for the dbt project.
# Role: It ensures consistent execution across development, staging, and production environments by packaging dependencies.

FROM python:3.12-slim

# Install the 'uv' package manager for fast, reliable dependency resolution
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Install Python dependencies first for better layer caching
COPY pyproject.toml uv.lock ./
RUN uv sync --no-dev --frozen

# Copy all project-specific files into the container image
COPY dbt_project.yml profiles.yml ./
COPY models-m1/ ./models-m1/
COPY models-m2/ ./models-m2/
COPY analyses/ ./analyses/
COPY tests/ ./tests/
COPY seeds/ ./seeds/
COPY entrypoint.sh start_mcp.py ./

# Ensure the entrypoint script is executable
RUN chmod +x entrypoint.sh

# Run the orchestration script on container startup
CMD ["./entrypoint.sh"]
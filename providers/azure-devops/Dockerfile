# =============================================================================
# OSCR Azure DevOps Agent
# =============================================================================
# Official Azure Pipelines agent in a container with Docker support.
# Published to: oddessentials/oscr-azure-devops

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Azure Pipelines agent version (for documentation - actual tarball is pre-downloaded)
# Check for latest: https://github.com/microsoft/azure-pipelines-agent/releases
# NOTE: Keep version in sync with Makefile and .github/workflows/*.yml
ARG AGENT_VERSION=3.248.0

# -----------------------------------------------------------------------------
# Install dependencies
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    libicu70 \
    libssl3 \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install Docker CLI (for Docker-in-Docker workflows)
# -----------------------------------------------------------------------------
RUN curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors https://get.docker.com | sh

# -----------------------------------------------------------------------------
# Create non-root user
# -----------------------------------------------------------------------------
RUN useradd -m -s /bin/bash agent \
    && usermod -aG docker agent

# -----------------------------------------------------------------------------
# Install Azure Pipelines agent
# Tarball is pre-downloaded externally to avoid DNS issues in buildx.
# Local build: run `make download-azure-agent` first, then `make build-azure`
# CI build: workflow downloads tarball before Docker build step
# -----------------------------------------------------------------------------
WORKDIR /home/agent

# Copy pre-downloaded agent tarball (avoids flaky Azure CDN DNS in buildx)
COPY vsts-agent.tar.gz /tmp/vsts-agent.tar.gz

RUN tar xzf /tmp/vsts-agent.tar.gz \
    && rm /tmp/vsts-agent.tar.gz \
    && chown -R agent:agent /home/agent

# -----------------------------------------------------------------------------
# Setup workspace
# -----------------------------------------------------------------------------
RUN mkdir -p /home/agent/work \
    && chown -R agent:agent /home/agent/work

# -----------------------------------------------------------------------------
# Copy entrypoint
# -----------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# -----------------------------------------------------------------------------
# Switch to non-root user
# -----------------------------------------------------------------------------
USER agent
WORKDIR /home/agent

ENTRYPOINT ["/entrypoint.sh"]

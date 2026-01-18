# =============================================================================
# OSCR Azure DevOps Agent
# =============================================================================
# Official Azure Pipelines agent in a container with Docker support.
# Published to: oddessentials/oscr-azure-devops

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Azure Pipelines agent version
# Check for latest: https://github.com/microsoft/azure-pipelines-agent/releases
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
RUN curl -fsSL https://get.docker.com | sh

# -----------------------------------------------------------------------------
# Create non-root user
# -----------------------------------------------------------------------------
RUN useradd -m -s /bin/bash agent \
    && usermod -aG docker agent

# -----------------------------------------------------------------------------
# Download and install Azure Pipelines agent
# -----------------------------------------------------------------------------
WORKDIR /home/agent

RUN curl -fsSL -o vsts-agent.tar.gz \
    "https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz" \
    && tar xzf vsts-agent.tar.gz \
    && rm vsts-agent.tar.gz \
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

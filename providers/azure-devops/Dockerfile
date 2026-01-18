# =============================================================================
# OSCR Azure DevOps Agent
# =============================================================================
# Official Azure Pipelines agent in a container with Docker support.
# Published to: oddessentials/oscr-azure-devops
#
# IMPORTANT: This Dockerfile requires the agent tarball to be prefetched.
# Run `AGENT_VERSION=x.y.z ./scripts/prefetch-ado-agent.sh` before building.
# The build has NO outbound network dependency for the agent binary.

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Azure Pipelines agent version - must match prefetched tarball
# Update this and re-run prefetch when upgrading agent version
ARG AGENT_VERSION=4.266.2

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
# Install Azure Pipelines agent from prefetched tarball
# The tarball must exist at assets/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz
# This is downloaded by scripts/prefetch-ado-agent.sh BEFORE docker build
# -----------------------------------------------------------------------------
WORKDIR /home/agent

COPY assets/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz /tmp/vsts-agent.tar.gz

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

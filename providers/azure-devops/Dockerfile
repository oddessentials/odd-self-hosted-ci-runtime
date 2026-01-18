# =============================================================================
# OSCR Azure DevOps Agent
# =============================================================================
# Official Azure Pipelines agent in a container with Docker support.
# Published to: oddessentials/oscr-azure-devops
#
# Uses multi-stage build to extract agent from Microsoft's official image,
# avoiding flaky Azure CDN downloads during build.

# -----------------------------------------------------------------------------
# Stage 1: Extract agent from Microsoft's official image
# This avoids downloading from vstsagentpackage.azureedge.net which has
# intermittent DNS resolution issues in CI environments.
# -----------------------------------------------------------------------------
FROM mcr.microsoft.com/azure-pipelines/vsts-agent:ubuntu-22.04 AS agent-source

# -----------------------------------------------------------------------------
# Stage 2: Build our custom image
# -----------------------------------------------------------------------------
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

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
# Copy Azure Pipelines agent from Microsoft's official image
# -----------------------------------------------------------------------------
WORKDIR /home/agent
COPY --from=agent-source /azp/agent/ /home/agent/
RUN chown -R agent:agent /home/agent

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

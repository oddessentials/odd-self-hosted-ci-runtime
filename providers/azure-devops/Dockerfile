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
    python3 \
    python3-pip \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install semgrep (static analysis for AI code review)
# -----------------------------------------------------------------------------
# Pinned for reproducibility - check https://github.com/semgrep/semgrep/releases
ARG SEMGREP_VERSION=1.148.0
RUN pip3 install --no-cache-dir semgrep==${SEMGREP_VERSION}

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
# Download and install Azure Pipelines agent
# -----------------------------------------------------------------------------
WORKDIR /home/agent

RUN curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors \
    -o /tmp/vsts-agent.tar.gz \
    "https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz" \
    && tar xzf /tmp/vsts-agent.tar.gz \
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

# Verify semgrep is accessible as agent user (build-time check)
RUN semgrep --version || (echo "ERROR: semgrep not accessible as agent user" && exit 1)

ENTRYPOINT ["/entrypoint.sh"]

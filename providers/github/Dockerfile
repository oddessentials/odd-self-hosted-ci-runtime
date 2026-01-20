# =============================================================================
# OSCR GitHub Actions Runner
# =============================================================================
# Official GitHub Actions runner in a container with Docker support.
# Published to: oddessentials/oscr-github

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# GitHub Actions runner version
# Check for latest: https://github.com/actions/runner/releases
ARG RUNNER_VERSION=2.321.0
ARG RUNNER_ARCH=x64

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
RUN useradd -m -s /bin/bash runner \
    && usermod -aG docker runner

# -----------------------------------------------------------------------------
# Download and install GitHub Actions runner
# -----------------------------------------------------------------------------
WORKDIR /home/runner

RUN curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /home/runner

# -----------------------------------------------------------------------------
# Setup workspace
# -----------------------------------------------------------------------------
RUN mkdir -p /home/runner/work \
    && chown -R runner:runner /home/runner/work

# -----------------------------------------------------------------------------
# Copy entrypoint
# -----------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# -----------------------------------------------------------------------------
# Switch to non-root user
# -----------------------------------------------------------------------------
USER runner
WORKDIR /home/runner

# Verify semgrep is accessible as runner user (build-time check)
RUN semgrep --version || (echo "ERROR: semgrep not accessible as runner user" && exit 1)

ENTRYPOINT ["/entrypoint.sh"]

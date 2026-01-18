#!/usr/bin/env bash
# =============================================================================
# Prefetch Azure DevOps Agent
# =============================================================================
# Downloads the Azure Pipelines agent tarball for offline Docker builds.
# This script must be run BEFORE docker build to ensure network-independent builds.
#
# The agent is downloaded from GitHub releases (this repo), NOT Azure CDN.
# This avoids DNS issues with vstsagentpackage.azureedge.net in GitHub Actions.
#
# To mirror a new agent version:
#   1. Run the "Mirror Agent" workflow (workflow_dispatch)
#   2. Update AGENT_VERSION in CI workflows and Makefile
#
# Usage:
#   AGENT_VERSION=3.248.0 ./scripts/prefetch-ado-agent.sh
#
# Output:
#   providers/azure-devops/assets/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
AGENT_VERSION="${AGENT_VERSION:?AGENT_VERSION is required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/providers/azure-devops/assets"
OUTPUT_FILE="${OUTPUT_DIR}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"

# GitHub releases URL (this repo) - DNS-stable alternative to Azure CDN
GITHUB_REPO="${GITHUB_REPOSITORY:-oddessentials/odd-self-hosted-ci-runtime}"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/agent-v${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; }

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    log_info "Prefetching Azure DevOps agent v${AGENT_VERSION}"
    log_info "URL: ${DOWNLOAD_URL}"
    log_info "Output: ${OUTPUT_FILE}"

    # Create output directory
    mkdir -p "${OUTPUT_DIR}"

    # Skip if already downloaded
    if [[ -f "${OUTPUT_FILE}" ]]; then
        log_info "Agent tarball already exists, skipping download"
        log_info "To force re-download, delete: ${OUTPUT_FILE}"
        exit 0
    fi

    # Download with retries
    log_info "Downloading from GitHub releases..."
    if ! curl -fsSL \
        --retry 5 \
        --retry-delay 5 \
        --retry-all-errors \
        -o "${OUTPUT_FILE}" \
        "${DOWNLOAD_URL}"; then
        log_error "Failed to download Azure DevOps agent"
        log_error "URL: ${DOWNLOAD_URL}"
        log_error ""
        log_error "If the release does not exist, run the 'Mirror Agent' workflow first:"
        log_error "  gh workflow run mirror-agent.yml -f agent_version=${AGENT_VERSION}"
        rm -f "${OUTPUT_FILE}"
        exit 1
    fi

    # Verify download
    if [[ ! -s "${OUTPUT_FILE}" ]]; then
        log_error "Downloaded file is empty"
        rm -f "${OUTPUT_FILE}"
        exit 1
    fi

    local size
    size=$(stat -c%s "${OUTPUT_FILE}" 2>/dev/null || stat -f%z "${OUTPUT_FILE}" 2>/dev/null)
    log_info "Download complete: ${size} bytes"
    log_info "Agent tarball ready for Docker build"
}

main "$@"

#!/usr/bin/env bash
# =============================================================================
# OSCR GitHub Actions Runner Entrypoint
# =============================================================================
# Handles registration, execution, and cleanup of the GitHub Actions runner.
# Ephemeral by default: auto-registers on start, auto-unregisters on stop.

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-linux,docker,self-hosted}"
RUNNER_GROUP="${GITHUB_RUNNER_GROUP:-default}"
RUNNER_WORKDIR="/home/runner/work"
RUNNER_PERSISTENT="${RUNNER_PERSISTENT:-false}"

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2; }

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
validate_config() {
    local missing=()

    [[ -z "${GITHUB_PAT:-}" ]] && missing+=("GITHUB_PAT")
    [[ -z "${GITHUB_OWNER:-}" ]] && missing+=("GITHUB_OWNER")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing[@]}"; do
            log_error "  - ${var}"
        done
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Get registration token from GitHub API
# -----------------------------------------------------------------------------
get_registration_token() {
    local token_url

    if [[ -n "${GITHUB_REPO:-}" ]]; then
        # Repository-level runner
        token_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token"
    else
        # Organization-level runner
        token_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
    fi

    log_info "Requesting registration token..."

    local response
    response=$(curl -sS -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "${token_url}")

    REGISTRATION_TOKEN=$(echo "${response}" | jq -r '.token // empty')

    if [[ -z "${REGISTRATION_TOKEN}" ]]; then
        log_error "Failed to get registration token"
        log_error "Response: ${response}"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Get removal token for unregistration
# -----------------------------------------------------------------------------
get_removal_token() {
    local token_url

    if [[ -n "${GITHUB_REPO:-}" ]]; then
        token_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/remove-token"
    else
        token_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/remove-token"
    fi

    local response
    response=$(curl -sS -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "${token_url}")

    REMOVAL_TOKEN=$(echo "${response}" | jq -r '.token // empty')
}

# -----------------------------------------------------------------------------
# Register the runner
# -----------------------------------------------------------------------------
register_runner() {
    local config_url

    if [[ -n "${GITHUB_REPO:-}" ]]; then
        config_url="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}"
        log_info "Registering runner for repository: ${config_url}"
    else
        config_url="https://github.com/${GITHUB_OWNER}"
        log_info "Registering runner for organization: ${config_url}"
    fi

    # Clean up any existing runner configuration to prevent "already configured" errors
    # This can happen after container restarts or runner auto-updates
    if [[ -f ".runner" ]]; then
        log_info "Cleaning up existing runner configuration..."
        get_removal_token
        if [[ -n "${REMOVAL_TOKEN:-}" ]]; then
            ./config.sh remove --token "${REMOVAL_TOKEN}" || true
        fi
        rm -f .runner .credentials .credentials_rsaparams .env .path 2>/dev/null || true
    fi

    get_registration_token

    ./config.sh \
        --url "${config_url}" \
        --token "${REGISTRATION_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --labels "${RUNNER_LABELS}" \
        --runnergroup "${RUNNER_GROUP}" \
        --work "${RUNNER_WORKDIR}" \
        --unattended \
        --replace \
        --ephemeral

    log_info "Runner registered successfully: ${RUNNER_NAME}"
}

# -----------------------------------------------------------------------------
# Unregister the runner
# -----------------------------------------------------------------------------
unregister_runner() {
    if [[ "${RUNNER_PERSISTENT}" == "true" ]]; then
        log_info "Persistent mode: skipping unregistration"
        return
    fi

    log_info "Unregistering runner..."

    get_removal_token

    if [[ -n "${REMOVAL_TOKEN:-}" ]]; then
        ./config.sh remove --token "${REMOVAL_TOKEN}" || true
        log_info "Runner unregistered"
    else
        log_info "Could not get removal token, runner may remain registered"
    fi
}

# -----------------------------------------------------------------------------
# Cleanup handler
# -----------------------------------------------------------------------------
cleanup() {
    log_info "Received shutdown signal"
    unregister_runner
    exit 0
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    log_info "OSCR GitHub Actions Runner starting..."
    log_info "Runner name: ${RUNNER_NAME}"
    log_info "Labels: ${RUNNER_LABELS}"

    validate_config

    # Setup signal handlers for graceful shutdown
    trap cleanup SIGTERM SIGINT SIGQUIT

    # Register the runner
    register_runner

    # Start the runner
    log_info "Starting runner..."
    ./run.sh &

    # Wait for the runner process
    wait $!
}

main "$@"

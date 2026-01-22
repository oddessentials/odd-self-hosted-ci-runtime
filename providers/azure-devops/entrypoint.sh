#!/usr/bin/env bash
# =============================================================================
# OSCR Azure DevOps Agent Entrypoint
# =============================================================================
# Handles registration, execution, and cleanup of the Azure Pipelines agent.
# Ephemeral by default: auto-registers on start, auto-unregisters on stop.

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
AGENT_NAME="${RUNNER_NAME:-$(hostname)}"
AGENT_LABELS="${AGENT_LABELS:-linux,docker,self-hosted}"
AGENT_WORKDIR="/home/agent/work"
AGENT_PERSISTENT="${RUNNER_PERSISTENT:-false}"

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

    [[ -z "${ADO_PAT:-}" ]] && missing+=("ADO_PAT")
    [[ -z "${ADO_ORG_URL:-}" ]] && missing+=("ADO_ORG_URL")
    [[ -z "${ADO_POOL:-}" ]] && missing+=("ADO_POOL")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing[@]}"; do
            log_error "  - ${var}"
        done
        exit 1
    fi

    # Log registration scope
    if [[ -n "${ADO_PROJECT:-}" ]]; then
        log_info "Mode: Project-scoped agent (${ADO_PROJECT})"
    else
        log_info "Mode: Organization-level agent"
    fi
}

# -----------------------------------------------------------------------------
# Register the agent
# -----------------------------------------------------------------------------
register_agent() {
    log_info "Registering agent to pool: ${ADO_POOL}"
    log_info "Organization: ${ADO_ORG_URL}"

    # Clean up any existing agent configuration to prevent "already configured" errors
    # This can happen after container restarts or agent auto-updates
    if [[ -f ".agent" ]]; then
        log_info "Cleaning up existing agent configuration..."
        ./config.sh remove \
            --auth pat \
            --token "${ADO_PAT}" \
            --unattended || true
        rm -f .agent .credentials .credentials_rsaparams 2>/dev/null || true
    fi

    # Build config command with optional project scoping
    local config_args=(
        --url "${ADO_ORG_URL}"
        --auth pat
        --token "${ADO_PAT}"
        --pool "${ADO_POOL}"
        --agent "${AGENT_NAME}"
        --work "${AGENT_WORKDIR}"
        --unattended
        --replace
        --acceptTeeEula
    )

    # Add project scope if specified (narrows agent visibility to single project)
    if [[ -n "${ADO_PROJECT:-}" ]]; then
        config_args+=(--projectName "${ADO_PROJECT}")
    fi

    ./config.sh "${config_args[@]}"

    log_info "Agent registered successfully: ${AGENT_NAME}"
    log_info "Labels: ${AGENT_LABELS}"
}

# -----------------------------------------------------------------------------
# Unregister the agent
# -----------------------------------------------------------------------------
unregister_agent() {
    if [[ "${AGENT_PERSISTENT}" == "true" ]]; then
        log_info "Persistent mode: skipping unregistration"
        return
    fi

    log_info "Unregistering agent..."

    ./config.sh remove \
        --auth pat \
        --token "${ADO_PAT}" \
        --unattended || true

    log_info "Agent unregistered"
}

# -----------------------------------------------------------------------------
# Cleanup handler
# -----------------------------------------------------------------------------
cleanup() {
    log_info "Received shutdown signal"
    unregister_agent
    exit 0
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    log_info "OSCR Azure DevOps Agent starting..."
    log_info "Agent name: ${AGENT_NAME}"
    log_info "Pool: ${ADO_POOL}"

    # Ensure agent can access the Docker socket (Fixes permission denied errors in E2E)
    if [ -S /var/run/docker.sock ]; then
        log_info "Fixing Docker socket permissions..."
        sudo chmod 666 /var/run/docker.sock
    fi

    validate_config

    # Setup signal handlers for graceful shutdown
    trap cleanup SIGTERM SIGINT SIGQUIT

    # Register the agent
    register_agent

    # Start the agent
    log_info "Starting agent..."
    ./run.sh &

    # Wait for the agent process
    wait $!
}

main "$@"

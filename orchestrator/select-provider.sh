#!/usr/bin/env bash
# =============================================================================
# OSCR Provider Selection Script
# =============================================================================
# This script validates configuration and launches the appropriate provider.
# Usage: ./select-provider.sh [start|stop|logs|status]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# -----------------------------------------------------------------------------
# Colors for output
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Load environment
# -----------------------------------------------------------------------------
load_env() {
    if [[ ! -f "${ENV_FILE}" ]]; then
        log_error "Configuration file not found: ${ENV_FILE}"
        log_info "Copy env.example to .env and configure it first:"
        log_info "  cp env.example .env"
        exit 1
    fi

    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
}

# -----------------------------------------------------------------------------
# Validation functions
# -----------------------------------------------------------------------------
validate_provider() {
    if [[ -z "${CI_PROVIDER:-}" ]]; then
        log_error "CI_PROVIDER is not set"
        log_info "Valid values: github, azure-devops"
        exit 1
    fi

    case "${CI_PROVIDER}" in
        github|azure-devops)
            log_info "Provider: ${CI_PROVIDER}"
            ;;
        *)
            log_error "Invalid CI_PROVIDER: ${CI_PROVIDER}"
            log_info "Valid values: github, azure-devops"
            exit 1
            ;;
    esac
}

validate_github() {
    local missing=()

    [[ -z "${GITHUB_PAT:-}" ]] && missing+=("GITHUB_PAT")
    [[ -z "${GITHUB_OWNER:-}" ]] && missing+=("GITHUB_OWNER")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required GitHub configuration:"
        for var in "${missing[@]}"; do
            log_error "  - ${var}"
        done
        exit 1
    fi

    if [[ -z "${GITHUB_REPO:-}" ]]; then
        log_info "Mode: Organization runner (${GITHUB_OWNER})"
    else
        log_info "Mode: Repository runner (${GITHUB_OWNER}/${GITHUB_REPO})"
    fi
}

validate_azure_devops() {
    local missing=()

    [[ -z "${ADO_PAT:-}" ]] && missing+=("ADO_PAT")
    [[ -z "${ADO_ORG_URL:-}" ]] && missing+=("ADO_ORG_URL")
    [[ -z "${ADO_POOL:-}" ]] && missing+=("ADO_POOL")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required Azure DevOps configuration:"
        for var in "${missing[@]}"; do
            log_error "  - ${var}"
        done
        exit 1
    fi

    log_info "Organization: ${ADO_ORG_URL}"
    log_info "Agent Pool: ${ADO_POOL}"
}

validate_config() {
    validate_provider

    case "${CI_PROVIDER}" in
        github)
            validate_github
            ;;
        azure-devops)
            validate_azure_devops
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Docker Compose wrapper
# -----------------------------------------------------------------------------
compose_cmd() {
    docker compose -f "${SCRIPT_DIR}/docker-compose.yml" --profile "${CI_PROVIDER}" "$@"
}

# -----------------------------------------------------------------------------
# Commands
# -----------------------------------------------------------------------------
cmd_start() {
    log_info "Starting OSCR with ${CI_PROVIDER} provider..."
    compose_cmd up -d
    log_info "Runner started. View logs with: $0 logs"
}

cmd_stop() {
    log_info "Stopping OSCR..."
    compose_cmd down
    log_info "Runner stopped and unregistered (ephemeral mode)"
}

cmd_logs() {
    compose_cmd logs -f
}

cmd_status() {
    compose_cmd ps
}

cmd_build() {
    log_info "Building ${CI_PROVIDER} provider image..."
    compose_cmd build
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    local command="${1:-start}"

    load_env
    validate_config

    case "${command}" in
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        logs)
            cmd_logs
            ;;
        status)
            cmd_status
            ;;
        build)
            cmd_build
            ;;
        *)
            echo "Usage: $0 [start|stop|logs|status|build]"
            echo ""
            echo "Commands:"
            echo "  start   Start the runner (default)"
            echo "  stop    Stop and unregister the runner"
            echo "  logs    Follow runner logs"
            echo "  status  Show runner status"
            echo "  build   Build provider image locally"
            exit 1
            ;;
    esac
}

main "$@"

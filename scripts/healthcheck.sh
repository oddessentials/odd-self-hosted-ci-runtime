#!/usr/bin/env bash
# =============================================================================
# OSCR Health Check
# =============================================================================
# Verifies the OSCR runner is healthy and connected.
# Usage: ./healthcheck.sh
# Exit codes: 0 = healthy, 1 = unhealthy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATOR_DIR="${SCRIPT_DIR}/../orchestrator"
ENV_FILE="${ORCHESTRATOR_DIR}/.env"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# Load environment
# -----------------------------------------------------------------------------
if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
else
    echo -e "${RED}[FAIL]${NC} Configuration file not found: ${ENV_FILE}"
    exit 1
fi

# -----------------------------------------------------------------------------
# Check Docker
# -----------------------------------------------------------------------------
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}[FAIL]${NC} Docker is not running or not accessible"
        return 1
    fi
    echo -e "${GREEN}[OK]${NC} Docker is running"
    return 0
}

# -----------------------------------------------------------------------------
# Check container status
# -----------------------------------------------------------------------------
check_container() {
    case "${CI_PROVIDER:-}" in
        github|azure-devops)
            ;;
        *)
            echo -e "${RED}[FAIL]${NC} CI_PROVIDER not set or invalid"
            return 1
            ;;
    esac

    cd "${ORCHESTRATOR_DIR}"

    local status
    status=$(docker compose -f docker-compose.yml --profile "${CI_PROVIDER}" ps --format json 2>/dev/null | jq -r '.[0].State // empty' 2>/dev/null || echo "")

    if [[ "${status}" == "running" ]]; then
        echo -e "${GREEN}[OK]${NC} Runner container is running"
        return 0
    elif [[ -z "${status}" ]]; then
        echo -e "${YELLOW}[WARN]${NC} Runner container not found (not started?)"
        return 1
    else
        echo -e "${RED}[FAIL]${NC} Runner container status: ${status}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Check provider connectivity
# -----------------------------------------------------------------------------
check_github_connectivity() {
    if [[ -z "${GITHUB_PAT:-}" ]]; then
        echo -e "${YELLOW}[SKIP]${NC} GitHub PAT not configured"
        return 0
    fi

    local response
    response=$(curl -sS -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/user" 2>/dev/null || echo "000")

    if [[ "${response}" == "200" ]]; then
        echo -e "${GREEN}[OK]${NC} GitHub API connectivity verified"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} GitHub API returned HTTP ${response}"
        return 1
    fi
}

check_ado_connectivity() {
    if [[ -z "${ADO_PAT:-}" || -z "${ADO_ORG_URL:-}" ]]; then
        echo -e "${YELLOW}[SKIP]${NC} Azure DevOps credentials not configured"
        return 0
    fi

    local auth
    auth=$(echo -n ":${ADO_PAT}" | base64)

    local response
    response=$(curl -sS -o /dev/null -w "%{http_code}" \
        -H "Authorization: Basic ${auth}" \
        "${ADO_ORG_URL}/_apis/projects?api-version=7.0" 2>/dev/null || echo "000")

    if [[ "${response}" == "200" ]]; then
        echo -e "${GREEN}[OK]${NC} Azure DevOps API connectivity verified"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} Azure DevOps API returned HTTP ${response}"
        return 1
    fi
}

check_provider_connectivity() {
    case "${CI_PROVIDER:-}" in
        github)
            check_github_connectivity
            ;;
        azure-devops)
            check_ado_connectivity
            ;;
        *)
            echo -e "${YELLOW}[SKIP]${NC} Unknown provider, skipping connectivity check"
            return 0
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo "OSCR Health Check"
    echo "================="
    echo ""

    local exit_code=0

    check_docker || exit_code=1
    check_container || exit_code=1
    check_provider_connectivity || exit_code=1

    echo ""
    if [[ ${exit_code} -eq 0 ]]; then
        echo -e "${GREEN}All checks passed${NC}"
    else
        echo -e "${RED}Some checks failed${NC}"
    fi

    exit ${exit_code}
}

main "$@"

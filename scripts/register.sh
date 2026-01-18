#!/usr/bin/env bash
# =============================================================================
# OSCR Registration Helper
# =============================================================================
# Wrapper script to start the OSCR runner.
# Usage: ./register.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATOR_DIR="${SCRIPT_DIR}/../orchestrator"

echo "Starting OSCR runner..."
echo "This will register the runner with your CI provider."
echo ""

cd "${ORCHESTRATOR_DIR}"
./select-provider.sh start

#!/usr/bin/env bash
# =============================================================================
# OSCR Unregistration Helper
# =============================================================================
# Wrapper script to stop and unregister the OSCR runner.
# Usage: ./unregister.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATOR_DIR="${SCRIPT_DIR}/../orchestrator"

echo "Stopping OSCR runner..."
echo "This will unregister the runner from your CI provider."
echo ""

cd "${ORCHESTRATOR_DIR}"
./select-provider.sh stop

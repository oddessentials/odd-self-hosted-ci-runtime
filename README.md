# Odd Self-Hosted CI Runtime (OSCR)

**Docker-first, provider-pluggable self-hosted CI runtime.**

Run your CI pipelines at zero cloud cost using your own hardware.

## Features

- **Zero cloud cost** - Run CI on your existing infrastructure
- **Provider-pluggable** - GitHub Actions and Azure DevOps support
- **Ephemeral by default** - Auto-registers on start, auto-unregisters on stop
- **Docker-first** - Host OS agnostic, Linux containers only
- **Minimal workflow changes** - Just update `runs-on` in your YAML

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/oddessentials/odd-self-hosted-ci-runtime.git
cd odd-self-hosted-ci-runtime/orchestrator

# 2. Configure your provider
cp env.example .env
# Edit .env with your credentials (see Provider Setup below)

# 3. Start the runner
./select-provider.sh start

# 4. Update your workflow
# Change: runs-on: ubuntu-latest
# To:     runs-on: [self-hosted, linux]
```

## Provider Setup

### GitHub Actions

```bash
# Required in .env
CI_PROVIDER=github
GITHUB_PAT=ghp_xxxxxxxxxxxx  # Personal Access Token
GITHUB_OWNER=your-org        # Organization or user
GITHUB_REPO=your-repo        # Optional: omit for org-level runner
```

**PAT Scopes Required:**
- Repository runner: `repo`
- Organization runner: `admin:org`

### Azure DevOps

```bash
# Required in .env
CI_PROVIDER=azure-devops
ADO_PAT=xxxxxxxxxxxx           # Personal Access Token
ADO_ORG_URL=https://dev.azure.com/your-org
ADO_POOL=Default               # Agent pool name
```

**PAT Scopes Required:** `Agent Pools (read, manage)`

## Commands

```bash
cd orchestrator/

./select-provider.sh start    # Start the runner
./select-provider.sh stop     # Stop and unregister
./select-provider.sh logs     # Follow runner logs
./select-provider.sh status   # Show container status
./select-provider.sh build    # Build image locally
```

## Pre-built Images

Pull from Docker Hub instead of building locally:

```bash
docker pull oddessentials/oscr-github:latest
docker pull oddessentials/oscr-azure-devops:latest
```

## Compatibility Contract

OSCR enforces strict compatibility rules to ensure reliable operation:

| Rule | Description |
|------|-------------|
| **Linux-only** | All jobs execute in Linux containers. Windows/macOS jobs are not supported. |
| **Non-root** | Runner processes execute as non-root users. |
| **No fork PRs** | Self-hosted runners do not execute fork pull requests by default. |
| **Docker-in-Docker** | Jobs requiring Docker must use Docker-in-Docker or job containers. |
| **Ephemeral workspace** | Workspace is wiped between jobs. Do not rely on persistent state. |
| **One job at a time** | Each runner executes one job concurrently. |

### Workflow Requirements

Your workflows must be Linux-compatible. The only required change:

```yaml
# Before (cloud-hosted)
runs-on: ubuntu-latest

# After (self-hosted)
runs-on: [self-hosted, linux]
```

Optional labels for targeting specific runners:

```yaml
runs-on: [self-hosted, linux, docker]
```

## Scaling

OSCR does not implement auto-scaling. For multiple concurrent jobs, scale manually:

```bash
# Run 3 instances of the GitHub runner
docker compose -f docker-compose.yml --profile github up -d --scale github-runner=3
```

Each instance registers as a separate runner with a unique name.

## Security

See [docs/security.md](docs/security.md) for the full security model.

**Key points:**
- Runners execute as non-root
- Fork PRs are blocked by default
- Secrets are injected via provider-native mechanisms only
- Workspaces are ephemeral

## Documentation

- [Architecture](docs/architecture.md) - System design and components
- [Security](docs/security.md) - Threat model and hardening
- [Providers](docs/providers.md) - Provider-specific details
- [Usage](docs/usage.md) - Day-to-day operations
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## Development

OSCR uses a Makefile for consistent development commands:

```bash
make help          # Show available targets
make lint          # Run shellcheck on all scripts
make lint-docker   # Run shellcheck via Docker (no local install)
make verify        # Run all quality checks
make build         # Build all Docker images
make ci            # Full CI pipeline (lint + build)
```

For contributors, see [CONTRIBUTING.md](CONTRIBUTING.md) for design principles.

## Project Governance

- [INVARIANTS.md](INVARIANTS.md) - Non-negotiable design constraints
- [SPEC.md](SPEC.md) - Technical specification

## License

[MIT](LICENSE)

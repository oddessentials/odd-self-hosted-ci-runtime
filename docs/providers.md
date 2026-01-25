# Providers

OSCR supports multiple CI providers through a pluggable architecture. Each provider uses the official runner/agent binary with no modifications.

## GitHub Actions

### Overview

The GitHub provider uses the official [GitHub Actions Runner](https://github.com/actions/runner).

| Property | Value |
|----------|-------|
| Image | `oddessentials/oscr-github` |
| User | `runner` (non-root) |
| Workdir | `/home/runner/work` |

### Configuration

| Variable | Required | Description |
|----------|----------|-------------|
| `CI_PROVIDER` | Yes | Must be `github` |
| `GITHUB_PAT` | Yes | Personal Access Token |
| `GITHUB_OWNER` | Yes | User or organization name |
| `GITHUB_REPO` | No | Repository name (omit for org runner) |
| `RUNNER_NAME` | No | Custom runner name (default: hostname) |
| `RUNNER_LABELS` | No | Additional labels (default: `linux,docker,self-hosted`) |
| `GITHUB_RUNNER_GROUP` | No | Runner group for org runners (default: `default`) |

### PAT Scopes

**Repository-level runner:**
- `repo` - Full control of private repositories

**Organization-level runner:**
- `admin:org` - Full control of orgs and teams

### Runner Scopes

#### Repository Runner

Registers to a specific repository:

```bash
GITHUB_OWNER=myuser
GITHUB_REPO=myrepo
```

The runner appears in: Settings > Actions > Runners

#### Organization Runner

Registers to an organization (available to all repos):

```bash
GITHUB_OWNER=myorg
# GITHUB_REPO is not set
```

The runner appears in: Organization Settings > Actions > Runners

### Workflow Configuration

Target self-hosted runners:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on self-hosted runner"
```

Target specific labels:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, docker, gpu]
```

### Runner Groups

For organizations, runners can be assigned to groups:

```bash
GITHUB_RUNNER_GROUP=production
```

Configure group permissions in: Organization Settings > Actions > Runner groups

### Ephemeral Mode

By default, the runner registers with `--ephemeral`:
- Accepts one job, then unregisters
- Container restarts and re-registers after each job
- Clean state for every job

To disable (not recommended):
```bash
RUNNER_PERSISTENT=true
```

---

## Azure DevOps

### Overview

The Azure DevOps provider uses the official [Azure Pipelines Agent](https://github.com/microsoft/azure-pipelines-agent).

| Property | Value |
|----------|-------|
| Image | `oddessentials/oscr-azure-devops` |
| User | `agent` (non-root) |
| Workdir | `/home/agent/work` |

### Configuration

| Variable | Required | Description |
|----------|----------|-------------|
| `CI_PROVIDER` | Yes | Must be `azure-devops` |
| `ADO_PAT` | Yes | Personal Access Token |
| `ADO_ORG_URL` | Yes | Organization URL |
| `ADO_POOL` | Yes | Agent pool name |
| `ADO_PROJECT` | No | Project name (omit for org-level agent) |
| `AGENT_LABELS` | No | Comma-separated capabilities (default: `linux,docker,self-hosted`) |
| `RUNNER_NAME` | No | Custom agent name (default: hostname) |

### PAT Scopes

- `Agent Pools (Read & manage)` - Required for registration

### Agent Scopes

#### Organization Agent (Default)

Registers to a pool visible to all projects:

```bash
ADO_ORG_URL=https://dev.azure.com/myorg
ADO_POOL=Default
# ADO_PROJECT is not set
```

The agent appears in: Organization Settings > Agent pools

#### Project Agent

Registers to a pool visible only to a specific project:

```bash
ADO_ORG_URL=https://dev.azure.com/myorg
ADO_POOL=Default
ADO_PROJECT=MyProject
```

The agent appears in: Project Settings > Agent pools

### Pipeline Configuration

Target self-hosted agents:

```yaml
pool:
  name: Default

steps:
  - script: echo "Running on self-hosted agent"
```

Target with demands (matches AGENT_LABELS):

```yaml
pool:
  name: Default
  demands:
    - Agent.OS -equals Linux
    - docker
    - gpu  # Matches if AGENT_LABELS includes 'gpu'
```

### Capabilities

The agent automatically reports system capabilities plus custom labels from `AGENT_LABELS`:

- `Agent.OS`: Linux
- Docker-related capabilities (if Docker is available)
- Custom capabilities from `AGENT_LABELS` (e.g., `gpu=true`, `cuda=true`)

Example:
```bash
AGENT_LABELS=linux,docker,self-hosted,gpu,cuda
```

### Ephemeral Mode

By default, the agent:
- Auto-registers on container start
- Auto-unregisters on container stop
- Cleans up stale configuration on restart

To disable (not recommended):
```bash
RUNNER_PERSISTENT=true
```

---

## Adding New Providers

To add support for a new CI provider (e.g., GitLab, Gitea):

### 1. Create Provider Directory

```bash
mkdir -p providers/new-provider
```

### 2. Create Dockerfile

```dockerfile
# providers/new-provider/Dockerfile
FROM ubuntu:22.04

# Install dependencies
# Download official runner
# Create non-root user
# Copy entrypoint

USER newuser
ENTRYPOINT ["/entrypoint.sh"]
```

### 3. Create Entrypoint

```bash
#!/usr/bin/env bash
# providers/new-provider/entrypoint.sh

# Validate configuration
# Register with provider
# Start runner
# Handle shutdown
```

### 4. Add to Docker Compose

```yaml
# orchestrator/docker-compose.yml
services:
  new-provider-runner:
    image: oddessentials/oscr-new-provider:latest
    build:
      context: ../providers/new-provider
    environment:
      - NEW_PROVIDER_TOKEN=${NEW_PROVIDER_TOKEN}
    profiles:
      - new-provider
```

### 5. Update Validation

Add validation logic to `select-provider.sh`:

```bash
validate_new_provider() {
    # Check required variables
}
```

### Requirements

New providers must:
- Use official runner/agent binaries
- Run as non-root
- Support ephemeral registration
- Handle graceful shutdown
- Clean up on exit

No orchestrator code changes should be required.

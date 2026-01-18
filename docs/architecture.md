# Architecture

## Overview

OSCR is a thin orchestration layer that launches provider-specific CI runners inside Docker containers.

```
┌─────────────────────────────────────────────────────────┐
│                    Host OS                              │
│              (Windows/Linux/macOS)                      │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │                    Docker                          │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────────┐ │  │
│  │  │           oscr-network (bridge)              │ │  │
│  │  │                                              │ │  │
│  │  │  ┌────────────────────────────────────────┐  │ │  │
│  │  │  │     Provider Runner Container          │  │ │  │
│  │  │  │                                        │  │ │  │
│  │  │  │  ┌──────────────────────────────────┐  │  │ │  │
│  │  │  │  │   Official Runner/Agent Binary   │  │  │ │  │
│  │  │  │  │   (GitHub or Azure DevOps)       │  │  │ │  │
│  │  │  │  └──────────────────────────────────┘  │  │ │  │
│  │  │  │                                        │  │ │  │
│  │  │  │  User: runner/agent (non-root)         │  │ │  │
│  │  │  └────────────────────────────────────────┘  │ │  │
│  │  │                                              │ │  │
│  │  └──────────────────────────────────────────────┘ │  │
│  │                                                    │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  CI Provider Cloud    │
              │  (GitHub / Azure)     │
              └───────────────────────┘
```

## Components

### Orchestrator (`orchestrator/`)

The orchestrator is intentionally thin. It:

1. Validates environment configuration
2. Selects the appropriate provider
3. Launches exactly one provider container
4. Provides start/stop/logs/status commands

The orchestrator contains **no CI logic**. It is a configuration validator and process launcher.

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service definitions for each provider |
| `env.example` | Configuration template |
| `select-provider.sh` | Entry point script |

### Provider Containers (`providers/`)

Each provider is a self-contained directory with:

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image definition |
| `entrypoint.sh` | Registration and execution logic |

Providers are isolated by convention. Adding a new provider requires:

1. Create `providers/<name>/Dockerfile`
2. Create `providers/<name>/entrypoint.sh`
3. Add service definition to `docker-compose.yml`

No orchestrator code changes are required.

### Scripts (`scripts/`)

Helper scripts for common operations:

| Script | Purpose |
|--------|---------|
| `register.sh` | Start the runner |
| `unregister.sh` | Stop and unregister |
| `healthcheck.sh` | Verify connectivity |

## Data Flow

### Registration Flow

```
1. User runs: ./select-provider.sh start
2. Orchestrator validates .env configuration
3. Orchestrator launches provider container via docker compose
4. Container entrypoint.sh executes:
   a. Requests registration token from provider API
   b. Runs official runner config.sh
   c. Starts official runner run.sh
5. Runner connects to provider cloud and polls for jobs
```

### Job Execution Flow

```
1. Provider cloud assigns job to runner
2. Runner downloads job specification
3. Runner executes job steps inside container
4. Job artifacts uploaded via provider mechanisms
5. Runner reports completion to provider cloud
6. Runner polls for next job
```

### Shutdown Flow

```
1. User runs: ./select-provider.sh stop
2. Docker sends SIGTERM to container
3. Entrypoint traps signal and calls cleanup()
4. cleanup() unregisters runner from provider
5. Container exits
```

## Design Decisions

### Why Docker-First?

- **Host OS agnostic**: OSCR works identically on Windows, Linux, and macOS
- **Isolation**: Jobs cannot affect the host system
- **Reproducibility**: Container images provide consistent environments
- **Docker-in-Docker**: Workflows can build and run containers

### Why Provider-Pluggable?

- **No abstraction layer**: Official runners are used as-is
- **Feature parity**: All provider features work without modification
- **Maintenance**: Provider updates are independent

### Why Ephemeral by Default?

- **Security**: No state persists between jobs
- **Clean teardown**: Runners don't accumulate in provider dashboards
- **Replaceability**: Easy to migrate or replace OSCR

### Why No Auto-Scaling?

- **Simplicity**: Scaling adds significant complexity
- **Predictability**: One runner = one job is easy to reason about
- **Manual control**: Users can scale via `docker compose --scale`

## Network Architecture

Default: **Bridge network** (`oscr-network`)

- Containers can reach external networks
- Containers are isolated from host network
- Inter-container communication is possible (for multi-runner setups)

Alternative: **Host network** (opt-in)

```yaml
# In docker-compose.yml, add:
network_mode: host
```

Use host networking when:
- Jobs need to access services on localhost
- Performance is critical
- You understand the security implications

## Volume Mounts

| Mount | Purpose |
|-------|---------|
| `/var/run/docker.sock` | Docker-in-Docker support |
| `runner-work` / `agent-work` | Job workspace (ephemeral volume) |

The Docker socket mount allows workflows to build and run containers. This is required for most CI workflows but does have security implications (see [security.md](security.md)).

## Resource Limits

Default: No limits (container uses host resources)

For production deployments, add limits in `docker-compose.yml`:

```yaml
services:
  github-runner:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '1'
          memory: 2G
```

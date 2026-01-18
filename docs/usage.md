# Usage

## Prerequisites

- Docker (20.10+) and Docker Compose (v2)
- Network access to your CI provider (GitHub/Azure DevOps)
- Personal Access Token with appropriate scopes

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/oddessentials/odd-self-hosted-ci-runtime.git
cd odd-self-hosted-ci-runtime
```

### 2. Configure Environment

```bash
cd orchestrator
cp env.example .env
```

Edit `.env` with your provider credentials:

**GitHub:**
```bash
CI_PROVIDER=github
GITHUB_PAT=ghp_xxxxxxxxxxxx
GITHUB_OWNER=your-org
GITHUB_REPO=your-repo  # Optional for org-level
```

**Azure DevOps:**
```bash
CI_PROVIDER=azure-devops
ADO_PAT=xxxxxxxxxxxx
ADO_ORG_URL=https://dev.azure.com/your-org
ADO_POOL=Default
```

### 3. Start the Runner

```bash
./select-provider.sh start
```

### 4. Verify Registration

**GitHub:** Check Settings > Actions > Runners

**Azure DevOps:** Check Organization Settings > Agent pools > [Your Pool]

## Daily Operations

### Starting the Runner

```bash
cd orchestrator
./select-provider.sh start
```

The runner will:
1. Build the image (if not cached)
2. Register with your CI provider
3. Start polling for jobs

### Stopping the Runner

```bash
./select-provider.sh stop
```

The runner will:
1. Finish any in-progress job (graceful shutdown)
2. Unregister from the CI provider
3. Stop the container

### Viewing Logs

```bash
# Follow logs in real-time
./select-provider.sh logs

# Or view recent logs
docker compose -f docker-compose.yml --profile github logs --tail=100
```

### Checking Status

```bash
./select-provider.sh status
```

### Health Check

```bash
../scripts/healthcheck.sh
```

## Updating the Runner

### Using Pre-built Images

```bash
# Pull latest images
docker pull oddessentials/oscr-github:latest
docker pull oddessentials/oscr-azure-devops:latest

# Restart with new image
./select-provider.sh stop
./select-provider.sh start
```

### Building Locally

```bash
# Rebuild the image
./select-provider.sh build

# Restart
./select-provider.sh stop
./select-provider.sh start
```

### Updating Runner Version

Edit the Dockerfile to update the runner version:

```dockerfile
# providers/github/Dockerfile
ARG RUNNER_VERSION=2.321.0  # Update this

# providers/azure-devops/Dockerfile
ARG AGENT_VERSION=3.248.0   # Update this
```

Then rebuild:

```bash
./select-provider.sh build
./select-provider.sh stop
./select-provider.sh start
```

## Scaling

OSCR supports manual scaling for concurrent job execution.

### Running Multiple Instances

```bash
# Scale to 3 runners
docker compose -f docker-compose.yml --profile github up -d --scale github-runner=3
```

Each instance:
- Registers with a unique name (hostname-based)
- Accepts one job at a time
- Operates independently

### Naming Scaled Runners

For identifiable names, run separate instances:

```bash
# Instance 1
RUNNER_NAME=runner-01 ./select-provider.sh start

# Instance 2 (in another terminal or use different compose project)
RUNNER_NAME=runner-02 docker compose ... up -d
```

## Running as a Service

### Systemd (Linux)

Create `/etc/systemd/system/oscr.service`:

```ini
[Unit]
Description=OSCR Self-Hosted CI Runner
After=docker.service
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=/path/to/odd-self-hosted-ci-runtime/orchestrator
ExecStart=/path/to/odd-self-hosted-ci-runtime/orchestrator/select-provider.sh start
ExecStop=/path/to/odd-self-hosted-ci-runtime/orchestrator/select-provider.sh stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable oscr
sudo systemctl start oscr
```

### Docker Restart Policy

The docker-compose.yml includes `restart: unless-stopped`, so runners automatically restart after host reboot if Docker is configured to start on boot.

## Workflow Migration

### GitHub Actions

**Before (cloud-hosted):**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

**After (self-hosted):**
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
```

### Azure DevOps

**Before (Microsoft-hosted):**
```yaml
pool:
  vmImage: ubuntu-latest
```

**After (self-hosted):**
```yaml
pool:
  name: YourPoolName
```

## Docker-in-Docker

OSCR mounts the Docker socket, enabling workflows to build and run containers.

### Example: Build and Push

```yaml
# GitHub Actions
jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t myimage .
      - run: docker push myimage
```

```yaml
# Azure DevOps
steps:
  - script: docker build -t myimage .
  - script: docker push myimage
```

### Example: Run Tests in Container

```yaml
jobs:
  test:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
      - run: docker run --rm -v $(pwd):/app -w /app node:18 npm test
```

## Offline Operation

If the runner goes offline:
- Jobs queue in the CI provider
- No jobs are lost
- Jobs execute when the runner comes back online

To intentionally pause:

```bash
# Pause (keep registered but don't accept jobs)
docker compose -f docker-compose.yml --profile github pause

# Resume
docker compose -f docker-compose.yml --profile github unpause
```

## Monitoring

### Container Metrics

```bash
# Resource usage
docker stats

# Container health
docker compose -f docker-compose.yml --profile github ps
```

### Integration with Monitoring Systems

Export logs to your monitoring system:

```bash
# Example: Forward to syslog
docker compose -f docker-compose.yml --profile github up -d \
  --log-driver=syslog \
  --log-opt syslog-address=udp://logserver:514
```

### Alerting

Set up alerts for:
- Container exit (non-zero exit code)
- No jobs processed in X hours
- High resource usage

## Cleanup

### Remove Runner

```bash
./select-provider.sh stop
```

### Remove Images

```bash
docker rmi oddessentials/oscr-github:latest
docker rmi oddessentials/oscr-azure-devops:latest
```

### Remove Volumes

```bash
docker volume rm orchestrator_runner-work
docker volume rm orchestrator_agent-work
```

### Complete Cleanup

```bash
cd orchestrator
docker compose -f docker-compose.yml --profile github down -v --rmi all
docker compose -f docker-compose.yml --profile azure-devops down -v --rmi all
```

# Troubleshooting

## Quick Diagnostics

Run the health check first:

```bash
./scripts/healthcheck.sh
```

Check container logs:

```bash
cd orchestrator
./select-provider.sh logs
```

## Common Issues

### Runner Won't Start

#### "Configuration file not found"

**Symptom:**
```
[ERROR] Configuration file not found: /path/to/orchestrator/.env
```

**Solution:**
```bash
cd orchestrator
cp env.example .env
# Edit .env with your credentials
```

#### "CI_PROVIDER is not set"

**Symptom:**
```
[ERROR] CI_PROVIDER is not set
```

**Solution:**
Add to your `.env` file:
```bash
CI_PROVIDER=github
# or
CI_PROVIDER=azure-devops
```

#### "Invalid CI_PROVIDER"

**Symptom:**
```
[ERROR] Invalid CI_PROVIDER: gitlab
```

**Solution:**
OSCR currently supports `github` and `azure-devops` only.

### Registration Failures

#### GitHub: "Failed to get registration token"

**Symptom:**
```
[ERROR] Failed to get registration token
Response: {"message":"Bad credentials","documentation_url":"..."}
```

**Causes:**
1. Invalid PAT
2. PAT lacks required scopes
3. PAT has expired

**Solution:**
1. Generate a new PAT with correct scopes:
   - Repository runner: `repo`
   - Organization runner: `admin:org`
2. Update `.env` with the new PAT
3. Restart: `./select-provider.sh stop && ./select-provider.sh start`

#### GitHub: "Resource not accessible by integration"

**Symptom:**
```
{"message":"Resource not accessible by integration"}
```

**Causes:**
1. PAT doesn't have access to the specified repo/org
2. Wrong `GITHUB_OWNER` or `GITHUB_REPO`

**Solution:**
1. Verify `GITHUB_OWNER` and `GITHUB_REPO` are correct
2. Ensure the PAT has access to the repository/organization

#### Azure DevOps: "Authentication failed"

**Symptom:**
```
VS30063: You are not authorized to access ...
```

**Causes:**
1. Invalid PAT
2. PAT lacks `Agent Pools (Read & manage)` scope
3. Wrong organization URL

**Solution:**
1. Verify `ADO_ORG_URL` format: `https://dev.azure.com/your-org`
2. Generate a new PAT with `Agent Pools (Read & manage)` scope
3. Update `.env` and restart

#### Azure DevOps: "Pool not found"

**Symptom:**
```
Pool Default does not exist.
```

**Solution:**
1. Verify the pool name in Azure DevOps
2. Update `ADO_POOL` in `.env`
3. Ensure your PAT has access to the pool

### Container Issues

#### Container exits immediately

**Symptom:**
Container starts then exits within seconds.

**Diagnosis:**
```bash
docker compose -f docker-compose.yml --profile github logs
```

**Common causes:**
1. Registration failure (see above)
2. Missing environment variables
3. Network connectivity issues

#### "Cannot connect to Docker daemon"

**Symptom:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
1. Ensure Docker is running: `sudo systemctl start docker`
2. Verify socket permissions: `ls -la /var/run/docker.sock`
3. Add your user to docker group: `sudo usermod -aG docker $USER`

#### "Permission denied" errors

**Symptom:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Fix socket permissions
sudo chmod 666 /var/run/docker.sock

# Or add user to docker group (requires logout/login)
sudo usermod -aG docker $USER
```

### Job Execution Issues

#### Jobs not picked up

**Symptom:**
Jobs stay queued, runner appears idle.

**Diagnosis:**
1. Check runner status in CI provider dashboard
2. Verify labels match workflow requirements

**Solution:**
1. Ensure workflow `runs-on` matches runner labels
2. For GitHub: `runs-on: [self-hosted, linux]`
3. For Azure DevOps: Check pool name in pipeline YAML

#### Docker commands fail in jobs

**Symptom:**
```
docker: command not found
```
or
```
Got permission denied while trying to connect to the Docker daemon
```

**Solution:**
1. Verify Docker socket is mounted (check docker-compose.yml)
2. Ensure the runner user is in the docker group

#### Workspace not clean

**Symptom:**
Files from previous jobs appear in workspace.

**Cause:**
Volume persistence between jobs.

**Solution:**
1. Use `actions/checkout@v4` with `clean: true`
2. Or manually clean: `rm -rf $GITHUB_WORKSPACE/*`
3. For fresh state, recreate volumes:
   ```bash
   ./select-provider.sh stop
   docker volume rm orchestrator_runner-work
   ./select-provider.sh start
   ```

### Network Issues

#### Cannot reach external services

**Symptom:**
```
Could not resolve host: github.com
```

**Diagnosis:**
```bash
# Test from container
docker compose -f docker-compose.yml --profile github exec github-runner ping github.com
```

**Solutions:**
1. Check host DNS configuration
2. Try host networking:
   ```yaml
   # In docker-compose.yml
   network_mode: host
   ```
3. Configure DNS in compose:
   ```yaml
   dns:
     - 8.8.8.8
     - 8.8.4.4
   ```

#### Firewall blocking connections

**Symptom:**
Registration times out or fails.

**Required outbound access:**

GitHub:
- `github.com` (443)
- `api.github.com` (443)
- `*.actions.githubusercontent.com` (443)

Azure DevOps:
- `dev.azure.com` (443)
- `*.visualstudio.com` (443)
- `download.agent.dev.azure.com` (443)

### Performance Issues

#### Jobs run slowly

**Diagnosis:**
```bash
# Check resource usage
docker stats

# Check disk space
df -h
```

**Solutions:**
1. Add resource limits to prevent runaway jobs
2. Clean up Docker: `docker system prune -a`
3. Use faster storage for volumes

#### High memory usage

**Solution:**
Add memory limits:
```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G
```

## Debugging

### Enable verbose logging

```bash
# GitHub runner
docker compose -f docker-compose.yml --profile github exec github-runner \
  bash -c "export ACTIONS_RUNNER_DEBUG=true && ./run.sh"
```

### Shell into container

```bash
# GitHub
docker compose -f docker-compose.yml --profile github exec github-runner bash

# Azure DevOps
docker compose -f docker-compose.yml --profile azure-devops exec azure-devops-agent bash
```

### Check runner configuration

```bash
# GitHub
docker compose -f docker-compose.yml --profile github exec github-runner \
  cat .runner

# Azure DevOps
docker compose -f docker-compose.yml --profile azure-devops exec azure-devops-agent \
  cat .agent
```

### Test API connectivity

```bash
# GitHub
curl -H "Authorization: Bearer $GITHUB_PAT" \
  https://api.github.com/user

# Azure DevOps
curl -u ":$ADO_PAT" \
  "$ADO_ORG_URL/_apis/projects?api-version=7.0"
```

## Getting Help

1. Check the [GitHub Issues](https://github.com/oddessentials/odd-self-hosted-ci-runtime/issues)
2. Review provider documentation:
   - [GitHub Actions Runner](https://docs.github.com/en/actions/hosting-your-own-runners)
   - [Azure Pipelines Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents)
3. Open a new issue with:
   - OSCR version (git commit)
   - Provider (github/azure-devops)
   - Error messages
   - Sanitized logs (remove tokens!)

# Security

## Threat Model

OSCR operates in a threat environment where:

1. **Workflows are untrusted code** - CI jobs can execute arbitrary commands
2. **Secrets are high-value targets** - PATs and credentials must be protected
3. **The host is the trust boundary** - Container escape = full compromise

### Assets to Protect

| Asset | Impact if Compromised |
|-------|----------------------|
| Personal Access Tokens | Full repository/organization access |
| Job secrets | Credential theft, lateral movement |
| Host system | Complete infrastructure compromise |
| Other runners | Cross-job contamination |

### Threat Actors

| Actor | Capability | Mitigation |
|-------|------------|------------|
| Malicious PR author | Arbitrary code in workflow | Block fork PRs |
| Compromised dependency | Supply chain attack | Ephemeral workspace |
| Insider threat | Direct access to runner | Non-root execution, audit logs |

## Security Controls

### 1. Non-Root Execution

All runner processes execute as non-root users:

- GitHub: `runner` user
- Azure DevOps: `agent` user

This limits the impact of container escape vulnerabilities.

**Verification:**
```bash
# In a job step
whoami  # Should output: runner (or agent)
id      # Should show non-root UID
```

### 2. Fork PR Protection

**Self-hosted runners must not execute untrusted fork PRs by default.**

#### GitHub Actions

Add this condition to your workflow:

```yaml
jobs:
  build:
    if: github.event.pull_request.head.repo.full_name == github.repository
    runs-on: [self-hosted, linux]
```

Or configure at the repository level:
1. Go to Settings > Actions > General
2. Under "Fork pull request workflows", select "Require approval for all outside collaborators"

#### Azure DevOps

1. Configure branch policies to require PR approval
2. Use environment approvals for sensitive pipelines
3. Restrict pool access to trusted projects

### 3. Ephemeral Workspace

Each job executes in a clean workspace:

- Previous job artifacts are not accessible
- No state persists between runs (unless explicitly configured)
- Workspace is wiped on job completion

This prevents:
- Cross-job data leakage
- Persistent malware
- Credential caching attacks

### 4. Provider-Native Secret Injection

OSCR does not implement secret management. Secrets are:

- Defined in GitHub/Azure DevOps
- Injected by the official runner/agent
- Masked in logs by the provider

**Do not:**
- Store secrets in `.env` files (except PATs for registration)
- Pass secrets via custom environment variables
- Log secret values

### 5. Network Isolation

Default configuration uses a bridge network:

- Containers cannot access host-only services
- Inter-container traffic is isolated
- External network access is permitted (for package downloads, etc.)

For stricter isolation, consider:
- Firewall rules on the host
- Network policies (if using Kubernetes)
- Proxy configuration for egress control

## Hardening Recommendations

### PAT Rotation

Rotate Personal Access Tokens regularly:

1. Create new PAT with required scopes
2. Update `.env` file
3. Restart runner: `./select-provider.sh stop && ./select-provider.sh start`
4. Revoke old PAT

### Docker Socket Security

The Docker socket mount (`/var/run/docker.sock`) is required for Docker-in-Docker workflows but grants significant privileges.

**Risks:**
- Container can create privileged containers
- Container can mount host filesystem
- Effectively equivalent to root on host

**Mitigations:**
- Use rootless Docker if possible
- Consider Sysbox or similar runtimes
- Restrict which repositories can use self-hosted runners

### Resource Limits

Prevent resource exhaustion attacks:

```yaml
# In docker-compose.yml
services:
  github-runner:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
```

### Audit Logging

Enable audit logging on the host:

```bash
# Example: auditd rules for Docker
-w /var/run/docker.sock -k docker
-w /etc/docker -k docker
```

Monitor runner logs for suspicious activity:
```bash
./select-provider.sh logs | grep -E "(error|fail|denied)"
```

### Image Verification

If building images locally, verify the Dockerfile hasn't been tampered with:

```bash
# Check for unexpected changes
git diff providers/github/Dockerfile
git diff providers/azure-devops/Dockerfile
```

Use signed images when available:
```bash
docker pull oddessentials/oscr-github:latest
docker trust inspect oddessentials/oscr-github:latest
```

## Incident Response

### Compromised Runner

If you suspect a runner has been compromised:

1. **Stop immediately**: `./select-provider.sh stop`
2. **Revoke PATs**: Invalidate all tokens used by the runner
3. **Rotate secrets**: Regenerate any secrets the runner had access to
4. **Review logs**: Check for unauthorized job executions
5. **Rebuild**: Use fresh container images

### Leaked Secrets

If secrets are exposed in logs or artifacts:

1. **Rotate immediately**: Generate new credentials
2. **Audit access**: Review who/what accessed the exposed secret
3. **Update workflows**: Fix the leak source
4. **Notify**: Inform affected parties per your incident response plan

## Security Invariants

These rules are non-negotiable (see [INVARIANTS.md](../INVARIANTS.md)):

1. Runner containers run as non-root
2. Fork PRs are blocked by default
3. Secrets are injected via provider-native mechanisms only
4. Workspace is ephemeral

Any change violating these invariants requires explicit architectural review.

## Compliance Considerations

For regulated environments:

| Requirement | OSCR Approach |
|-------------|---------------|
| Audit trail | Use provider-native audit logs |
| Access control | Configure at provider level |
| Encryption at rest | Use encrypted Docker volumes |
| Encryption in transit | Provider uses TLS |
| Data residency | Runner executes on your infrastructure |

OSCR does not implement its own compliance controls. Use provider features and host-level security for compliance requirements.

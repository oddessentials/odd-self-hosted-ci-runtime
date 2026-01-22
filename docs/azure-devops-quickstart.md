# 🚀 Azure DevOps: OSCR Setup Guide

Complete guide to running AI-powered code reviews on your Azure DevOps repository using OSCR (Odd Self-hosted CI Runtime).

> 💡 **Using GitHub?** See [START_HERE.md](./START_HERE.md) for GitHub-specific setup instructions.

---

## Prerequisites

- **Docker Engine 20.10+** (Docker Desktop recommended)
- Azure DevOps account with admin access to an Agent Pool
- Git installed locally

---

## Step 1: Clone OSCR

```bash
git clone https://github.com/oddessentials/odd-self-hosted-ci-runtime.git
cd odd-self-hosted-ci-runtime/orchestrator
```

---

## Step 2: Create Azure DevOps PAT

1. Go to https://dev.azure.com/{your-org}/_usersSettings/tokens
2. Click **New Token**
3. Configure:
   - **Name**: `oscr-agent`
   - **Expiration**: 90 days (or your preference)
   - **Scopes**: Select **Custom defined**, then:
     - `Agent Pools` → **Read & manage**

4. Copy the token - you'll need it in the next step

---

## Step 3: Configure OSCR

Create a `.env` file in the `orchestrator` folder:

```env
CI_PROVIDER=azure-devops
ADO_PAT=your_token_here
ADO_ORG_URL=https://dev.azure.com/your-org
ADO_POOL=Default
# Optional: scope to specific project
# ADO_PROJECT=MyProject
AGENT_LABELS=linux,docker,self-hosted,ai-review
```

| Variable | Required | Description |
|----------|----------|-------------|
| `CI_PROVIDER` | Yes | Must be `azure-devops` |
| `ADO_PAT` | Yes | Personal Access Token from Step 2 |
| `ADO_ORG_URL` | Yes | Your organization URL |
| `ADO_POOL` | Yes | Agent pool name (e.g., `Default`) |
| `ADO_PROJECT` | No | Project name (omit for org-level) |
| `AGENT_LABELS` | No | Custom capabilities (comma-separated) |

---

## Step 4: Start OSCR

```
cd odd-self-hosted-ci-runtime/orchestrator
```

### On Linux/macOS:
```bash
./select-provider.sh start
```

### On Windows (PowerShell):
```powershell
docker compose --profile azure-devops up -d
```

This starts:
- **Azure Pipelines Agent** - picks up jobs from your pools
- **Ollama sidecar** - local LLM for air-gapped AI review (optional)

---

## Step 5: Verify Registration

1. Go to **Organization Settings** → **Agent pools** → **[Your Pool]**
2. Click the **Agents** tab
3. Your agent should appear with status **Online**

---

## Step 6: Update Your Repository's Pipeline

Modify your `azure-pipelines.yml` to use self-hosted agents:

**Before (Microsoft-hosted):**
```yaml
pool:
  vmImage: ubuntu-latest
```

**After (self-hosted OSCR):**
```yaml
pool:
  name: Default  # Your pool name
  demands:
    - Agent.OS -equals Linux
    - docker
```

### Using Custom Capabilities

If you set `AGENT_LABELS=gpu,cuda`, target with demands:

```yaml
pool:
  name: Default
  demands:
    - gpu
    - cuda
```

---

## Step 7: (Optional) Enable AI Code Review

### Create Pipeline Configuration

Create `.ai-review.yml` in your repository root:

```yaml
version: 1
trusted_only: true

passes:
  - name: static
    agents: [semgrep]
    enabled: true
  - name: local-ai
    agents: [local_llm]
    enabled: true

limits:
  max_files: 50
  max_diff_lines: 2000
```

### Add AI Review Stage

Add to your `azure-pipelines.yml`:

```yaml
stages:
  - stage: AIReview
    displayName: AI Code Review
    condition: eq(variables['Build.Reason'], 'PullRequest')
    jobs:
      - job: Review
        pool:
          name: Default
          demands:
            - ai-review
        steps:
          - checkout: self
            fetchDepth: 0
          - script: |
              npx odd-ai-reviewers review \
                --pr $(System.PullRequest.PullRequestId)
            displayName: Run AI Review
            env:
              OLLAMA_BASE_URL: http://ollama-sidecar:11434

> [!TIP]
> **Networking Pro-Tip**: If your pipeline needs to reach services running on your local machine (like a database or dev server), use **`http://host.docker.internal:{port}`** instead of `localhost`. 
> 
> Inside the runner container, `localhost` refers to the container itself. `host.docker.internal` is mapped to your host machine automatically by OSCR.
```

---

## Troubleshooting

### Agent not appearing in pool
```bash
docker logs orchestrator-azure-devops-agent-1
```

Common causes:
- Invalid PAT or expired token
- PAT missing `Agent Pools (Read & manage)` scope
- Incorrect `ADO_ORG_URL` format

### Agent offline after restart
OSCR automatically cleans up stale registrations. If issues persist:
```bash
docker compose --profile azure-devops down
docker compose --profile azure-devops up -d
```

### Pipeline stuck in queue
Verify pool has available agents:
1. Go to **Organization Settings** → **Agent pools**
2. Check **Agents** tab for online agents
3. Verify pipeline `pool.name` matches your pool

---

## Stopping OSCR

### On Linux/macOS:
```bash
./select-provider.sh stop
```

### On Windows (PowerShell):
```powershell
docker compose --profile azure-devops down
```

---

## Next Steps

- See [providers.md](./providers.md) for advanced ADO configuration
- See [ollama-integration.md](./ollama-integration.md) for local AI models
- See [troubleshooting.md](./troubleshooting.md) for common issues

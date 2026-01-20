# 🚀 START HERE: OSCR + AI Code Review Setup

Complete guide to running AI-powered code reviews on your repository using OSCR (Odd Self-hosted CI Runtime).

## Prerequisites

- Docker Desktop running
- GitHub account with admin access to a test repository
- Git installed locally

---

## Step 1: Clone OSCR

```bash
git clone https://github.com/oddessentials/odd-self-hosted-ci-runtime.git
cd odd-self-hosted-ci-runtime/orchestrator
```

---

## Step 2: Create GitHub PAT

1. Go to https://github.com/settings/tokens?type=beta
2. Generate new token with these permissions:
   - **Repository access**: Select your test repo (or All repositories)
   - **Permissions**:
     - `Contents: Read`
     - `Pull requests: Read and write`
     - `Checks: Read and write`
     - `Metadata: Read`
     - `Actions: Read and write` (for runner registration)
     - `Administration: Read and write` (for runner registration)

3. Copy the token - you'll need it in the next step

---

## Step 3: Configure OSCR

Create a `.env` file in the `orchestrator` folder:

```env
GITHUB_PAT=ghp_your_token_here
GITHUB_OWNER=your-username-or-org
RUNNER_LABELS=self-hosted,linux,docker,ai-review
RUNNER_PERSISTENT=false
```

---

## Step 4: Start OSCR with Ollama

### On Linux/macOS:
```bash
./select-provider.sh start
```

### On Windows (PowerShell):
```powershell
docker compose --profile github up -d
```

Pre-pull the model (required for local_llm agent):
```bash
docker exec oscr-ollama ollama pull codellama:7b
```

This starts:
- **GitHub Actions runner** - picks up jobs from your repos
- **Ollama sidecar** - local LLM for air-gapped AI review

---

## Step 5: Add Workflow to Your Repository

Create `.github/workflows/ai-review.yml` in your target repository:

```yaml
name: AI Review

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

jobs:
  ai-review:
    if: github.event.pull_request.head.repo.full_name == github.repository
    uses: oddessentials/odd-ai-reviewers/.github/workflows/ai-review.yml@main
    with:
      target_repo: ${{ github.repository }}
      target_ref: ${{ github.sha }}
      pr_number: ${{ github.event.pull_request.number }}
      runs_on: '["self-hosted", "linux", "ai-review"]'
    secrets:
      OLLAMA_BASE_URL: http://ollama-sidecar:11434
      # OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      # ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

---

## Step 6: Create AI Review Configuration

Create `.ai-review.yml` in your repository root:

```yaml
version: 1
trusted_only: true

passes:
  # Static analysis (free, always runs)
  - name: static
    agents: [semgrep]
    enabled: true

  # Local LLM review (free, requires Ollama sidecar)
  - name: local-ai
    agents: [local_llm]
    enabled: true

  # Cloud AI review (requires OPENAI_API_KEY or ANTHROPIC_API_KEY)
  # - name: cloud-ai
  #   agents: [opencode]
  #   enabled: true

limits:
  max_files: 50
  max_diff_lines: 2000

reporting:
  github:
    mode: checks_and_comments
    max_inline_comments: 20

gating:
  enabled: false
  fail_on_severity: error
```

---

## Agent Configuration Reference

| Agent | Required Secrets | Required Config | Notes |
|-------|------------------|------------------|-------|
| `semgrep` | None | None | Static analysis, always available |
| `local_llm` | None | `OLLAMA_BASE_URL` | Uses Ollama sidecar for local inference |
| `opencode` | `OPENAI_API_KEY` **or** `ANTHROPIC_API_KEY` | Optional: `MODEL` | Provider-agnostic (OpenAI, Claude, etc.) |
| `pr_agent` | `OPENAI_API_KEY` | Optional: `OPENAI_MODEL` | OpenAI-only |

> ⚠️ **Preflight Validation**: If an agent is enabled but required secrets are missing, the job will **fail immediately** with a clear error message.

---

## Setting Up Cloud AI (OpenCode)

### With OpenAI:
1. Add `OPENAI_API_KEY` secret to your repository (Settings → Secrets → Actions)
2. Update workflow:
   ```yaml
   secrets:
     OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
   ```
3. Enable the opencode pass in `.ai-review.yml`

### With Anthropic Claude:
1. Add `ANTHROPIC_API_KEY` secret to your repository
2. Update workflow:
   ```yaml
   secrets:
     ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
   ```
3. Set the model in `.ai-review.yml` or via `MODEL` env var:
   ```yaml
   reporting:
     github:
       mode: checks_and_comments
   ```

---

## Troubleshooting

### Runner not picking up jobs
```bash
docker logs orchestrator-github-runner-1
```

### Ollama connection failed
```bash
docker exec orchestrator-github-runner-1 curl -s http://ollama-sidecar:11434/api/version
```

### Preflight validation error
If you see: `Agent 'opencode' is enabled but missing required API key`
- Add `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` to repository secrets
- Or disable the opencode pass in `.ai-review.yml`

---

## Stopping OSCR

### On Linux/macOS:
```bash
./select-provider.sh stop
```

### On Windows (PowerShell):
```powershell
docker compose --profile github down
```

---

## Next Steps

- See [ollama-integration.md](./ollama-integration.md) for air-gap model provisioning
- See [usage.md](./usage.md) for advanced configuration
- See [troubleshooting.md](./troubleshooting.md) for common issues

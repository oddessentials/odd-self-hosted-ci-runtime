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

```bash
# Create .env file
cat > .env << 'EOF'
GITHUB_PAT=ghp_your_token_here
GITHUB_OWNER=your-username-or-org
RUNNER_LABELS=self-hosted,linux,docker,ai-review
RUNNER_PERSISTENT=false
EOF
```

---

## Step 4: Start OSCR with Ollama

```bash
# Start runner + Ollama sidecar
./select-provider.sh start

# Verify containers are running
docker ps | grep -E "oscr|ollama"

# Pre-pull the model (required for local_llm agent)
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
    # Only run on non-fork PRs (security)
    if: github.event.pull_request.head.repo.full_name == github.repository
    uses: oddessentials/odd-ai-reviewers/.github/workflows/ai-review.yml@main
    with:
      target_repo: ${{ github.repository }}
      target_ref: ${{ github.sha }}
      pr_number: ${{ github.event.pull_request.number }}
      runs_on: '["self-hosted", "linux", "ai-review"]'
    secrets:
      OLLAMA_BASE_URL: http://ollama-sidecar:11434
      # Optional: Add these for paid AI agents
      # OPENCODE_API_KEY: ${{ secrets.OPENCODE_API_KEY }}
      # OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

---

## Step 6: Create AI Review Configuration

Create `.ai-review.yml` in your repository root:

```yaml
version: 1
trusted_only: true

passes:
  # Pass 1: Static analysis (free, always runs)
  - name: static
    agents: [semgrep]
    enabled: true

  # Pass 2: Local LLM review (free, requires Ollama sidecar)
  - name: local-ai
    agents: [local_llm]
    enabled: true

  # Pass 3: Cloud AI review (requires API key)
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

## Step 7: Test It!

1. Create a test branch:
   ```bash
   git checkout -b test/ai-review
   ```

2. Add a file with intentional issues:
   ```python
   # test_security.py
   import os
   password = "hardcoded_secret_123"  # Semgrep will catch this
   connection = f"postgres://user:{password}@localhost/db"
   ```

3. Push and create a PR:
   ```bash
   git add .
   git commit -m "test: trigger AI review"
   git push origin test/ai-review
   # Create PR via GitHub UI
   ```

4. Watch the review run:
   - Check runs section shows "AI Code Review" in progress
   - Wait for completion
   - See findings in PR comments and check summary

---

## Agent Reference

| Agent | Type | Cost | Requirements |
|-------|------|------|--------------|
| `semgrep` | Static analysis | Free | None (pre-installed) |
| `local_llm` | AI (local) | Free | Ollama sidecar running |
| `opencode` | AI (cloud) | Paid | `OPENCODE_API_KEY` secret |
| `pr_agent` | AI (cloud) | Paid | `OPENAI_API_KEY` secret |

---

## Adding Cloud AI Agents

### OpenCode Agent

1. Get API key from https://opencode.ai
2. Add secret to your repository:
   - Settings → Secrets → Actions → New repository secret
   - Name: `OPENCODE_API_KEY`
   - Value: Your API key

3. Update `.ai-review.yml`:
   ```yaml
   passes:
     - name: static
       agents: [semgrep]
       enabled: true
     - name: semantic
       agents: [opencode]
       enabled: true
   ```

4. Update workflow to pass the secret:
   ```yaml
   secrets:
     OPENCODE_API_KEY: ${{ secrets.OPENCODE_API_KEY }}
   ```

### PR-Agent (OpenAI)

1. Get API key from https://platform.openai.com
2. Add `OPENAI_API_KEY` secret to repository
3. Add `pr_agent` to your agents list

---

## Troubleshooting

### Runner not picking up jobs

```bash
# Check runner logs
docker logs orchestrator-github-runner-1

# Verify labels match
docker exec orchestrator-github-runner-1 cat /home/runner/.runner
```

### Ollama connection failed

```bash
# Verify Ollama is running
docker exec orchestrator-github-runner-1 curl -s http://ollama-sidecar:11434/api/version

# Check model is pulled
docker exec oscr-ollama ollama list
```

### No findings generated

1. Verify `.ai-review.yml` exists in repo root
2. Check workflow logs for errors
3. Ensure file types are supported (`.py`, `.js`, `.ts`, etc.)

---

## Stopping OSCR

```bash
./select-provider.sh stop

# Remove all data (clean restart)
docker volume rm orchestrator_runner-work orchestrator_ollama-models
```

---

## Next Steps

- See [ollama-integration.md](./ollama-integration.md) for air-gap model provisioning
- See [usage.md](./usage.md) for advanced configuration
- See [troubleshooting.md](./troubleshooting.md) for common issues

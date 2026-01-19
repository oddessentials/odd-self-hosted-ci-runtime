# AI Code Review Integration Brainstorm

## Executive Summary

This document explores options for integrating AI-powered code review capabilities with the Odd Self-Hosted CI Runtime (OSCR). After analyzing the codebase and researching available tools, I present several architectural approaches with cost-benefit analysis.

---

## Understanding OSCR's Design Philosophy

Before proposing solutions, it's crucial to understand what OSCR is and isn't:

### Core Principles (from INVARIANTS.md)
- **Thin orchestrator** - No CI logic, only validation and process startup
- **Provider-pluggable** - Easy addition of new providers
- **Docker-first** - All jobs run in containers
- **Ephemeral by default** - Clean state for each job

### Explicit Non-Goals
- ❌ No unified runner binary
- ❌ No custom CI protocol
- ❌ **No AI/code review logic** ← Important!
- ❌ No workflow abstraction layer
- ❌ No auto-scaling in v1

This tells us: **AI code review should NOT be embedded into OSCR itself**. The architecture should remain separate, respecting OSCR's minimal design philosophy.

---

## Available AI Code Review Tools

### 1. PR-Agent by Qodo (Recommended)

**Repository**: [github.com/qodo-ai/pr-agent](https://github.com/qodo-ai/pr-agent)

**Pros:**
- ✅ Open source, MIT licensed
- ✅ Supports GitHub AND Azure DevOps (matches OSCR's providers!)
- ✅ BYO API keys (OpenAI, Claude, Gemini, Deepseek, Azure OpenAI)
- ✅ Multiple deployment modes (GitHub Action, GitHub App, webhook, Lambda)
- ✅ Highly customizable via TOML configuration
- ✅ ~30 seconds per review, low cost per PR
- ✅ Active development (version 0.31+)
- ✅ Self-hostable with Docker

**Cons:**
- ⚠️ Requires setup per repository (unless using GitHub App)
- ⚠️ Some advanced features only in paid Qodo Merge

**Key Commands:**
- `/review` - Automatic code review
- `/improve` - Code suggestions
- `/describe` - Auto-generate PR description
- `/ask [question]` - Ask about the PR

### 2. OpenCode.AI

**Repository**: [github.com/sst/opencode](https://github.com/sst/opencode)

**Pros:**
- ✅ 70k+ GitHub stars, mature project
- ✅ Provider-agnostic (Claude, OpenAI, Gemini, local models)
- ✅ GitHub App available (`/opencode` or `/oc` commands)
- ✅ Can work on issues AND PRs
- ✅ Creates branches and opens PRs autonomously

**Cons:**
- ⚠️ More of a coding agent than pure review tool
- ⚠️ No native Azure DevOps support
- ⚠️ Less focused on security/style review

**Best For:** When you want an AI to actually implement fixes, not just review

### 3. Kodus AI

**Repository**: [github.com/kodustech/kodus-ai](https://github.com/kodustech/kodus-ai)

**Pros:**
- ✅ Self-hostable
- ✅ Context-aware (learns codebase patterns)
- ✅ Custom review policies in plain language
- ✅ Dual analysis (LLM + AST parsing)

**Cons:**
- ⚠️ Smaller community
- ⚠️ LLM provider support unclear

### 4. DIY Claude/GPT Review Agent

**Pros:**
- ✅ Complete control
- ✅ Cheapest (just API costs)
- ✅ Custom to your exact needs

**Cons:**
- ⚠️ Development effort
- ⚠️ Maintenance burden
- ⚠️ Need to handle edge cases

---

## Architectural Options

### Option A: Separate "AI Review" Repository (Recommended)

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub/Azure DevOps                          │
│  ┌──────────┐          ┌──────────────┐          ┌───────────┐  │
│  │   PR     │──webhook─▶│ Review App   │─comments─▶│    PR     │  │
│  │ Created  │          │ (Standalone) │          │ Updated   │  │
│  └──────────┘          └──────────────┘          └───────────┘  │
│                               │                                  │
│                               │ LLM API                         │
│                               ▼                                  │
│                     ┌──────────────────┐                        │
│                     │ OpenAI/Anthropic │                        │
│                     └──────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│               OSCR (Unchanged, runs CI)                          │
│  ┌──────────┐          ┌──────────────┐          ┌───────────┐  │
│  │ PR Event │──────────▶│ Self-Hosted  │─results──▶│ CI Status │  │
│  │          │          │   Runner     │          │           │  │
│  └──────────┘          └──────────────┘          └───────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Implementation:**
1. Create `odd-ai-code-review` repository
2. Deploy PR-Agent as a GitHub App / Azure DevOps webhook
3. Self-host on minimal infrastructure (1 small VM or serverless)
4. Configure org-wide installation

**Why Recommended:**
- Clean separation of concerns
- OSCR remains minimal and unchanged
- AI review can scale independently
- Different lifecycle (AI tools evolve faster)
- Single deployment serves all repos

**Cost Estimate:**
- Compute: $0-20/month (Lambda free tier or small VM)
- LLM: ~$0.01-0.10 per PR review (GPT-4 Turbo or Claude Haiku)

---

### Option B: CI Step Integration

```yaml
# In user's workflow file
jobs:
  ai-review:
    runs-on: [self-hosted, linux]  # Uses OSCR!
    steps:
      - uses: actions/checkout@v4
      - name: AI Code Review
        uses: Codium-ai/pr-agent@main
        env:
          OPENAI_KEY: ${{ secrets.OPENAI_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          command: review
```

**Pros:**
- Uses OSCR's compute resources (true $0 cloud cost)
- Simple per-repo setup
- Runs as part of CI pipeline

**Cons:**
- Adds time to CI pipeline
- Requires workflow changes in each repo
- Review happens after push, not on PR open

**Best For:** Teams who want review as a CI gate

---

### Option C: Sidecar Container Pattern

```
┌──────────────────────────────────────────────────────────────┐
│                     Docker Host (OSCR)                        │
│  ┌─────────────────┐         ┌─────────────────────────────┐ │
│  │  GitHub Runner  │◄──────►│   AI Review Container       │ │
│  │  (OSCR GitHub)  │ shared │  (PR-Agent / Custom Agent)  │ │
│  │                 │ volume │                             │ │
│  └─────────────────┘         └─────────────────────────────┘ │
│                                         │                     │
│                                         │ LLM API            │
│                                         ▼                     │
│                               ┌─────────────────┐            │
│                               │ OpenAI/Claude   │            │
│                               └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

**Implementation:**
- Add `ai-review` service to OSCR's docker-compose.yml
- Run alongside provider runners
- Share workspace volume
- Triggered by webhook or file system watcher

**Cons:**
- Violates OSCR's "thin orchestrator" principle
- Increases complexity
- Couples AI review to CI runner lifecycle

**NOT Recommended** - breaks OSCR philosophy

---

### Option D: Platform Webhook Service (Most Scalable)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Your Infrastructure                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           AI Review Service (Centralized)                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │   │
│  │  │   GitHub    │  │ Azure DevOps│  │   GitLab        │   │   │
│  │  │   Webhook   │  │   Webhook   │  │   Webhook       │   │   │
│  │  │   Handler   │  │   Handler   │  │   Handler       │   │   │
│  │  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘   │   │
│  │         └────────────────┼──────────────────┘            │   │
│  │                          ▼                                │   │
│  │  ┌───────────────────────────────────────────────────┐   │   │
│  │  │              Review Orchestrator                   │   │   │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────────────┐   │   │   │
│  │  │  │Security │  │ Style   │  │ Architecture    │   │   │   │
│  │  │  │Reviewer │  │Reviewer │  │ Reviewer        │   │   │   │
│  │  │  │(Claude) │  │(GPT-4)  │  │ (Claude Opus)   │   │   │   │
│  │  │  └─────────┘  └─────────┘  └─────────────────┘   │   │   │
│  │  └───────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Implementation:**
- Standalone service that listens to all platform webhooks
- Multiple specialized AI reviewers (team concept)
- Provider-agnostic design (like OSCR itself!)
- Could be a new `odd-ai-review` project

**Why This Is Interesting:**
- Mirrors OSCR's provider-pluggable architecture
- Central service for entire organization
- Can mix different LLMs for different review types
- Completely decoupled from CI execution

---

## Recommended Architecture: "Team of Reviewers"

Combining the best ideas, here's a proposed architecture:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      odd-ai-reviewers (New Repo)                     │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Webhook Gateway                           │    │
│  │   - GitHub App installation (org-wide)                      │    │
│  │   - Azure DevOps Service Hook                               │    │
│  │   - PR opened/synchronized/ready_for_review events          │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Review Router                             │    │
│  │   - Determines which reviewers to activate                  │    │
│  │   - Respects .ai-review.yml config per repo                 │    │
│  │   - Rate limiting / cost controls                           │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│          ┌───────────────────┼───────────────────┐                  │
│          ▼                   ▼                   ▼                  │
│  ┌───────────────┐   ┌───────────────┐   ┌───────────────┐         │
│  │   Security    │   │    Style &    │   │ Architecture  │         │
│  │   Reviewer    │   │    Quality    │   │   Reviewer    │         │
│  │               │   │   Reviewer    │   │               │         │
│  │ - OWASP Top10 │   │ - Code style  │   │ - Design      │         │
│  │ - Secrets     │   │ - Best practs │   │   patterns    │         │
│  │ - Injection   │   │ - Complexity  │   │ - Coupling    │         │
│  │               │   │ - Duplication │   │ - Testability │         │
│  │ (Claude Haiku)│   │ (GPT-4 Turbo) │   │ (Claude Opus) │         │
│  └───────┬───────┘   └───────┬───────┘   └───────┬───────┘         │
│          │                   │                   │                  │
│          └───────────────────┼───────────────────┘                  │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                  Comment Aggregator                          │    │
│  │   - Deduplicates similar findings                           │    │
│  │   - Formats as GitHub/Azure DevOps comments                 │    │
│  │   - Throttles to avoid spam                                 │    │
│  │   - Optionally creates issues for critical findings         │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Platform Clients                          │    │
│  │   - GitHub: PR review comments, line comments               │    │
│  │   - Azure DevOps: PR threads, work items                    │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Per-Repository Configuration (`.ai-review.yml`)

```yaml
# .ai-review.yml in each repository
version: 1

# Which reviewers to enable
reviewers:
  security:
    enabled: true
    model: claude-haiku  # Cost-effective for security scanning
    sensitivity: high

  quality:
    enabled: true
    model: gpt-4-turbo
    rules:
      - max-complexity: 10
      - max-line-length: 120
      - require-tests: true

  architecture:
    enabled: false  # Only for major changes

# When to run reviews
triggers:
  - on: pull_request
    branches: [main, develop]
  - on: pull_request
    paths: ['src/**', 'lib/**']

# Cost controls
limits:
  max_files_per_review: 50
  max_tokens_per_review: 10000
  skip_if_over: true  # Skip review if limits exceeded

# Team notifications
notifications:
  slack: "#code-reviews"
  on: [security-critical, architecture-concern]
```

---

## Cost Optimization Strategies

### 1. Model Selection by Task

| Reviewer Type | Recommended Model | Cost per 1M tokens |
|--------------|-------------------|-------------------|
| Security (routine) | Claude Haiku | ~$0.25 |
| Style/Quality | GPT-4 Turbo | ~$10 |
| Architecture (rare) | Claude Opus | ~$75 |
| Quick triage | GPT-4 Mini | ~$0.15 |

### 2. Diff-Only Analysis
- Only send changed files + minimal context
- PR-Agent's "PR Compression" does this automatically
- Reduces token usage by 80-90%

### 3. Caching & Deduplication
- Cache reviews for unchanged files
- Skip files that were reviewed in previous commits
- Dedupe repeated patterns

### 4. Tiered Review Triggers
```yaml
# Small PRs: Full review
# Medium PRs: Security + Quality only
# Large PRs: Security scan only + manual review request
```

### 5. Free Tier Maximization
- AWS Lambda: 1M requests/month free
- GitHub Actions: Free for public repos
- Vercel/Cloudflare Workers: Generous free tiers

### Estimated Monthly Costs

| Scenario | PR Volume | Estimated Cost |
|----------|-----------|---------------|
| Small team | 50 PRs/month | $5-15 |
| Medium team | 200 PRs/month | $20-50 |
| Large team | 1000 PRs/month | $100-250 |

---

## Implementation Phases

### Phase 1: Quick Win with PR-Agent (Week 1)
1. Fork qodo-ai/pr-agent
2. Deploy as GitHub App (or Action per repo)
3. Configure with your OpenAI/Claude API keys
4. Enable on pilot repository
5. Gather feedback

### Phase 2: Custom Review Service (Weeks 2-4)
1. Create `odd-ai-reviewers` repository
2. Implement webhook gateway
3. Add multiple reviewer agents
4. Add `.ai-review.yml` configuration support
5. Deploy on your infrastructure

### Phase 3: OpenCode Integration (Optional)
1. Install OpenCode GitHub App
2. Use for issue-to-PR automation
3. Complement review with implementation suggestions

### Phase 4: Azure DevOps Support (If Needed)
1. Add Azure DevOps webhook handler
2. Implement Service Hook subscription
3. Map to existing reviewer logic

---

## Comparison Matrix

| Criteria | Option A (Separate Repo) | Option B (CI Step) | Option D (Webhook Service) |
|----------|-------------------------|-------------------|---------------------------|
| Respects OSCR philosophy | ✅ Yes | ✅ Yes | ✅ Yes |
| Setup complexity | Low | Medium | High |
| Scalability | High | Medium | Very High |
| Cost efficiency | High | High | Very High |
| Multi-platform support | Varies by tool | Via workflows | Native |
| Team of reviewers | Possible | Complex | Native |
| Maintenance burden | Low (use PR-Agent) | Low | Medium-High |

---

## Recommendation Summary

### Short Term (Get Started Fast)
**Use PR-Agent as a GitHub Action**
- Zero infrastructure
- BYO API keys
- Works immediately
- Add to OSCR documentation as suggested integration

### Medium Term (Scale Up)
**Deploy PR-Agent as a self-hosted GitHub App**
- Organization-wide installation
- Single deployment
- Better webhook responsiveness
- Still uses PR-Agent, low maintenance

### Long Term (Full Control)
**Build `odd-ai-reviewers` as a companion project**
- Team of specialized reviewers
- Multi-platform support (GitHub + Azure DevOps)
- Custom policies and configurations
- Mirrors OSCR's provider-pluggable philosophy

---

## Open Questions for Discussion

1. **Which platforms are priority?** GitHub only, or Azure DevOps too?
2. **What review types matter most?** Security? Style? Architecture?
3. **What's the acceptable latency?** Sync (block PR) or async (comment later)?
4. **Cost ceiling?** What's the monthly budget for LLM API calls?
5. **Private repos?** Any data sovereignty concerns?
6. **Integration with existing tools?** ESLint, SonarQube, etc.?

---

## Sources

- [PR-Agent by Qodo](https://github.com/qodo-ai/pr-agent) - Open-source PR reviewer
- [OpenCode.AI](https://github.com/sst/opencode) - AI coding agent with GitHub integration
- [Kodus AI](https://github.com/kodustech/kodus-ai) - Context-aware code reviews
- [Qodo Merge Documentation](https://qodo-merge-docs.qodo.ai/installation/github/) - PR-Agent installation guide
- [OpenCode GitHub Docs](https://opencode.ai/docs/github/) - GitHub integration details
- [Graphite: Best Open-Source AI Code Review Tools 2025](https://graphite.com/guides/best-open-source-ai-code-review-tools-2025)
- [9 Best GitHub AI Code Review Tools](https://www.codeant.ai/blogs/best-github-ai-code-review-tools-2025)

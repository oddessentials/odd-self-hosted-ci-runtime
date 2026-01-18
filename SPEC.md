## Odd Self-Hosted CI Runtime (OSCR)

### Goal

Create a **Docker-first, provider-pluggable self-hosted CI runtime** that allows teams to:

* Run CI at **$0 cloud cost**
* Switch from cloud-hosted runners with **minimal YAML changes**
* Remain **OS-agnostic** (Linux jobs only)
* Support **GitHub Actions and Azure DevOps** initially
* Extend later to GitLab / Gitea without redesign

---

## Non-Goals (explicit)

* No unified runner binary
* No custom CI protocol
* No AI / code review logic
* No workflow abstraction layer
* No UI beyond logs

This keeps overhead low.

---

## High-Level Architecture

```
[ Host OS (Windows/Linux/macOS) ]
            |
         Docker
            |
   ┌──────────────────┐
   │ OSCR Orchestrator│  ← thin wrapper
   └──────────────────┘
            |
   ┌──────────────────────────┐
   │ Provider Runner Container│  ← GitHub OR ADO
   └──────────────────────────┘
            |
     Cloud CI Control Plane
```

* Host OS is irrelevant beyond “runs Docker”
* Jobs always execute **inside Linux containers**
* Provider runner is **selected at startup**, not runtime

---

## Repo Structure (authoritative)

```
odd-self-hosted-ci-runtime/
├─ .editorconfig          # Editor consistency settings
├─ .gitattributes         # Line ending enforcement (critical for .sh files)
├─ .gitignore             # Ignored files (.env, node_modules, etc.)
├─ .dockerignore          # Docker build context exclusions
├─ LICENSE                # MIT license
├─ Makefile               # Build and quality targets
├─ README.md              # Quick start and overview
├─ SPEC.md                # This specification
├─ INVARIANTS.md          # Non-negotiable design constraints
├─ CONTRIBUTING.md        # Contributor guidelines
├─ .releaserc.json        # Semantic release configuration
├─ commitlint.config.js   # Conventional commits enforcement
├─ .github/workflows/
│  ├─ ci.yml              # Automated quality gates + commitlint
│  ├─ release.yml         # Semantic versioning and GitHub releases
│  ├─ publish.yml         # Docker Hub image publishing
│  └─ smoke-test.yml      # Manual runner verification
├─ azure-pipelines.yml    # Azure DevOps CI pipeline
├─ docs/
│  ├─ architecture.md
│  ├─ security.md
│  ├─ providers.md
│  ├─ usage.md
│  └─ troubleshooting.md
├─ orchestrator/
│  ├─ docker-compose.yml
│  ├─ env.example
│  └─ select-provider.sh
├─ providers/
│  ├─ github/
│  │  ├─ Dockerfile
│  │  └─ entrypoint.sh
│  └─ azure-devops/
│     ├─ Dockerfile
│     └─ entrypoint.sh
└─ scripts/
   ├─ register.sh
   ├─ unregister.sh
   └─ healthcheck.sh
```

---

## Provider Selection Contract

**Single env var (required):**

```
CI_PROVIDER=github | azure-devops
```

Optional:

```
RUNNER_LABELS=linux,docker,self-hosted
RUNNER_NAME=ci-desktop-01
```

The orchestrator:

* Validates env
* Launches **exactly one provider container**
* Fails fast on ambiguity

---

## Provider Responsibilities

### GitHub Provider

* Uses official GitHub Actions runner
* Registers runner via PAT
* Supports:

  * repo-scoped runners
  * org-scoped runners
* Labels drive YAML targeting

### Azure DevOps Provider

* Uses official ADO agent
* Registers via PAT
* Supports:

  * agent pools
  * demands via YAML

---

## Workflow Compatibility Rules (important)

### Required YAML change (minimal)

```yaml
runs-on: [self-hosted, linux]
```

Optional labels:

```yaml
runs-on: [self-hosted, linux, docker]
```

### Hard rule

* **No OS-specific steps**
* **No apt-get on host**
* **Docker-in-Docker or job containers only**

If a job worked on `ubuntu-latest`, it should work here.

---

## Security Model (must be enforced)

1. **Default deny for untrusted PRs**

   * Self-hosted runners do NOT run fork PRs
2. Secrets only injected by provider
3. Runner runs as **non-root**
4. Workspace wiped between jobs
5. Explicit documentation of threat model

This is non-negotiable.

---

## Operational Model

* Runner is:

  * Disposable
  * Pausable
  * Restartable
* Offline runner = jobs queue (acceptable)
* No auto-scaling in v1
* One runner = one job at a time

---

## Extensibility Contract (future-proofing)

To add GitLab / Gitea later:

* New folder under `providers/`
* Same env contract
* Same orchestrator interface
* No orchestrator changes required

This must be enforced via docs + code boundaries.

---

## Deliverables (Definition of Done)

1. **Working GitHub Actions self-hosted runner**
2. **Working Azure DevOps self-hosted agent**
3. **Docker-only setup**
4. **Minimal YAML diff documented**
5. **Security section explicit**
6. **One-page Quick Start**
7. **Troubleshooting guide**
8. **Smoke test workflow for each provider**
9. **Automated CI quality gates** (shellcheck, Docker builds)
10. **Repository standards compliance** (.gitattributes, .gitignore, LICENSE)

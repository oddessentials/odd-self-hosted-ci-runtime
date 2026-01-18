# INVARIANTS.md

## Odd Self-Hosted CI Runtime (OSCR)

This document defines **non-negotiable invariants** governing the design, implementation, and operation of OSCR.
Any change that violates an invariant **must not be merged** without explicit architectural review.

---

## 1. Architectural Invariants

1. **No Unified Runner Binary**
   OSCR SHALL NOT attempt to implement or wrap a universal CI runner.
   Only official provider runners/agents are used as-is.

2. **Provider Selection at Startup Only**
   The CI provider (GitHub, Azure DevOps) MUST be selected at container startup.
   Runtime switching is forbidden.

3. **Thin Orchestrator**
   The orchestrator SHALL contain no CI logic, provider logic, or workflow semantics.
   Its sole responsibility is validation and process startup.

4. **Docker-First Execution**
   All CI execution MUST occur inside Linux containers.
   The host OS is treated as an opaque Docker substrate.

---

## 2. Security Invariants

5. **Non-Root Execution**
   Provider runner containers MUST run as a non-root user at all times.

6. **No Fork PR Execution by Default**
   Self-hosted runners MUST NOT execute untrusted fork pull requests by default.
   Any deviation must be explicitly documented as unsafe.

7. **Provider-Native Secret Injection Only**
   Secrets SHALL be injected exclusively via provider-native mechanisms.
   OSCR MUST NOT implement its own secret management layer.

8. **Ephemeral Workspace**
   Each job MUST execute in a clean workspace.
   No job artifacts or state may persist between runs unless explicitly configured.

---

## 3. Operational Invariants

9. **One Runner = One Job**
   A single runner instance SHALL execute at most one job concurrently.

10. **Offline Is Acceptable**
    If the runner is offline, jobs may queue indefinitely.
    OSCR MUST NOT attempt auto-scaling or failover in v1.

11. **Fail Fast on Misconfiguration**
    Invalid environment configuration MUST cause immediate startup failure with clear error messages.

---

## 4. Compatibility Invariants

12. **Linux Job Compatibility Required**
    Workflows MUST be Linux-compatible.
    OSCR SHALL NOT support Windows-only or macOS-only job semantics.

13. **Minimal Workflow Diff**
    Migrating from cloud-hosted runners MUST require only a `runs-on` change plus labels.

14. **No Provider Feature Emulation**
    OSCR SHALL NOT emulate or re-implement provider features (caching, artifacts, matrices, etc.).

---

## 5. Build Invariants

15. **Network-Independent Docker Builds**
    OSCR Docker builds MUST be network-independent with respect to CI runner binaries.
    External dependencies (agent tarballs) SHALL be prefetched before `docker build`.
    No DNS hacks, `/etc/resolv.conf` modifications, or `curl --resolve` workarounds.

16. **Pinned and Explicit Versioning**
    CI runner agent versions MUST be explicitly pinned.
    Updating the agent version requires updating only `AGENT_VERSION` and running prefetch.

---

## 6. Extensibility Invariants

17. **Provider Isolation by Convention**
    Each provider implementation MUST live entirely under `providers/<name>/`.
    Adding a new provider MUST NOT require orchestrator changes.

18. **Documentation Is Part of the Contract**
    Any new behavior or capability MUST be reflected in documentation in the same change.

---

## 7. Governance Invariant

19. **Boring Is a Feature**
    OSCR prioritizes predictability, determinism, and safety over convenience or cleverness.

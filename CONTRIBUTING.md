# Why OSCR Exists

## Design Principles & Scope Guardrails for Contributors

Odd Self-Hosted CI Runtime (OSCR) exists to restore **determinism, cost control, and operational clarity** to CI execution by running official CI runners on user-owned infrastructure.

This section exists to help contributors understand **why OSCR looks simpler than most CI projects**, and why that simplicity is intentional and protected.

---

## The Problem OSCR Solves

Modern hosted CI platforms increasingly introduce **non-technical failure modes**, including:

* Opaque usage limits and throttling
* Silent feature gating
* Billing-driven service degradation
* Coupled pricing across unrelated features

These failures are:

* Not fixable by code changes
* Not reproducible locally
* Not diagnosable from configuration alone

OSCR exists to give teams a **reliable escape hatch** when hosted CI becomes unpredictable.

---

## What OSCR Is Responsible For

OSCR has **one responsibility**:

> **Run official CI runners on user-owned hardware in a predictable, portable, and secure way.**

To achieve this, OSCR:

* Launches provider-specific runners in Docker
* Enforces Linux container execution
* Keeps orchestration intentionally minimal
* Fails fast on misconfiguration

---

## What OSCR Explicitly Does *Not* Do

OSCR intentionally does **not**:

* Implement a CI engine
* Abstract workflow syntax
* Re-implement provider runners
* Emulate provider features
* Optimize scheduling or scaling
* Provide “smart” orchestration logic

If a feature proposal moves OSCR toward any of the above, it is likely **out of scope**.

---

## Why OSCR Uses Official Provider Runners Only

CI providers operate **closed control planes** with undocumented assumptions.

Re-implementing runners would:

* Introduce subtle incompatibilities
* Require constant reverse-engineering
* Increase long-term maintenance risk

OSCR treats provider runners as **authoritative** and executes them unchanged to preserve:

* Compatibility
* Supportability
* Predictable behavior

---

## Why Provider Selection Happens at Startup

OSCR enforces **startup-time provider selection** because runtime switching introduces:

* State leakage
* Security ambiguity
* Complex failure modes

A running OSCR instance must have **exactly one purpose**.

If a runner misbehaves, the correct recovery is always:

> **Stop the container. Fix configuration. Restart.**

---

## Why OSCR Is Docker-First and Linux-Only

Most production workloads are Linux-based, even when developed on other platforms.

OSCR enforces:

* Linux container execution
* Host OS invisibility

This prevents:

* Platform-specific scripting
* Conditional workflows
* Environment drift

If a workflow works on `ubuntu-latest`, it should work in OSCR.

---

## Why OSCR Defaults to Ephemeral Runners

Persistent runners accumulate:

* Configuration drift
* Zombie registrations
* Non-reproducible failures

OSCR defaults to **ephemeral runners** because they:

* Start clean
* Shut down clean
* Match modern CI best practices

Persistence is allowed only as an **explicit opt-in**.

---

## Why OSCR Does Not Run Fork PRs by Default

Self-hosted runners execute code on **user-owned machines**.

Running untrusted fork code risks:

* Secret exfiltration
* Host compromise
* Network lateral movement

OSCR chooses **safety over convenience**.

Any proposal to weaken this default requires explicit security review.

---

## Why OSCR Avoids “Smart” Orchestration

CI execution is security-sensitive and failure-prone.

Adding orchestration intelligence increases:

* Attack surface
* Debugging complexity
* Blast radius of failures

OSCR deliberately chooses:

* Validation
* Execution
* Termination

Nothing more.

---

## How to Evaluate a Proposed Change

Before submitting a PR, ask:

1. Does this change increase determinism?
2. Does it reduce or clarify cost?
3. Does it preserve provider behavior?
4. Does it keep the orchestrator boring?
5. Does it reduce security risk?

If the answer to **any** is “no,” the change likely does not belong in OSCR.

---

## Design Philosophy (Non-Negotiable)

OSCR prioritizes:

* **Determinism over convenience**
* **Transparency over abstraction**
* **Explicit cost over “free”**
* **Security over automation**
* **Boring over clever**

These principles are enforced through code, documentation, and review.

---

## Final Guidance to Contributors

OSCR is intentionally small.

If you find yourself thinking:

> “This would be more powerful if OSCR also did…”

Stop.

That power almost always belongs **outside** OSCR.

OSCR’s value comes from what it refuses to become.

---
name: astra-advisor
description: Run a software-delivery request through Sol Advisor with GPT-6 Astra / High as the primary orchestrator.
---

# Astra Advisor shorthand

Treat the text after `$astra-advisor:` as the user's task request.

Before taking any task action, resolve the installed `sol-advisor@sol-advisor` plugin
directory from `codex plugin list --json`, then read its
`skills/orchestration/SKILL.md` completely and follow it as the authoritative workflow.
Read every reference that workflow requires.

Apply exactly one variant substitution while following the canonical skill and its
references:

- Every requirement for the **primary session** to use GPT-5.6 Sol / High becomes a
  requirement to use GPT-6 Astra (`gpt-6-astra`) / High.

This substitution applies only to the primary orchestrator. Keep every auxiliary
role, route, preflight, spawn, verification, isolation, correction, and acceptance
contract unchanged. In particular, audit and full routes still use the installed
fresh `sol_advisor_sol_reviewer` role at Sol / High; do not substitute an Astra
reviewer.

Verify the primary model and effort when runtime metadata exposes them. If either
differs, tell the user to select Astra / High and stop before task work or delegation.
If runtime metadata does not expose them, ask the user to confirm Astra / High and
stop until confirmed. A skill cannot change the primary model itself; never assume or
claim this prerequisite is satisfied.

Plugin discovery and instruction loading are setup actions. Do not inspect or modify
the user's task workspace until the authoritative workflow has declared its
`SELECTIVE ROUTE`.

If the plugin or canonical skill cannot be resolved, stop and tell the user to run
the portable checkout's `./install.sh`. Never substitute an inferred or partial Sol
Advisor workflow.

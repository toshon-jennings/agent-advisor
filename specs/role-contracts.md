# Canonical spec — role contracts

Platform-agnostic. Defines the roles the workflow recognizes and what each harness must
guarantee about them. It does **not** name models — model pins are a platform concern and
live in [`../README.md`](../README.md#the-comparison-matrix) and in each platform's own
agent definitions.

## Three roles, and only three

| Role | Holds | Never |
|---|---|---|
| **Orchestrator** (the chair) | Intent, architecture, route choice, decomposition, the worker packet, verification, escalation, acceptance | Transfers architecture or acceptance by delegating |
| **Implementer** | Executing one complete five-part specification inside an owned file set | Spawns a further auxiliary; redesigns the architecture |
| **Reviewer** | One verdict on an inspected change set and its evidence | Writes, or implements its own fixes |

There is no fourth role. A "planner", a "researcher", or a "second reviewer" is the
orchestrator's own work under another name, and spawning one spends an auxiliary the
budget does not have.

## What stays in the chair, always

Delegating never transfers these:

- Resolving requirements and material ambiguity.
- Choosing architecture, interfaces, decomposition, and route.
- Writing the complete five-part worker specification for any selected implementer.
- Inspecting the actual diff and rerunning verification.
- Deciding whether newly observed risk warrants escalation.
- Judging the reviewer verdict when the route includes review, and accepting the
  deliverable.

## Two structural guarantees every harness must provide

These are the properties that make the prose above enforceable rather than aspirational.
A platform that cannot provide one must say so plainly rather than claim it.

### 1. Implementers cannot delegate onward

The one-auxiliary maximum is defeated the moment a worker can spawn its own worker. The
strong form of this guarantee removes the *capability* rather than forbidding it in the
prompt — but only two of the three harnesses currently achieve the strong form, and the
spec says which rather than averaging them:

| Harness | Mechanism | Strength |
|---|---|---|
| Codex | `developer_instructions` tells the lane to stop and signal rather than delegate | **Advisory** — the profile has no capability field |
| Claude Code | The agent's `tools:` frontmatter omits the `Agent` tool | Structural |
| Antigravity | The agent's `tools:` frontmatter omits every subagent tool | Structural |

Antigravity's agent bodies describe this as `enable_subagent_tools: false`. That string
is prose in the instruction body, not frontmatter; the allowlist omission is what actually
enforces it. The guarantee holds — the stated reason for it does not.

A platform in the advisory column must be *described* as advisory. Recording it as
structural is the specific error this table exists to prevent, because "the worker could
not have delegated" is the kind of claim an acceptance quietly rests on.

### 2. Reviewers cannot write

See [`reviewer-verdict.md`](reviewer-verdict.md#read-only-is-a-property-not-a-request).
Enforced by sandbox mode (Codex, out-of-process) or by tool list (Claude, Antigravity).

**"Cannot write" and "cannot run commands" are not the same prohibition**, and only the
first is universal. A sandboxed reviewer can still execute — the sandbox denies the write,
not the process — while a tool-list reviewer has no mechanism to run anything at all. The
invariant every harness holds is that a reviewer never *mutates* the change set and never
implements its own fixes. Whether it can independently re-derive evidence varies, so an
orchestrator must supply the verification evidence regardless and never assume the
reviewer can rerun its checks.

## Model pins are declarative unless the harness proves otherwise

This is the honest limit, and every platform here states it the same way.

An in-process subagent's **realized** model is generally not observable by the parent.
The pin lives in the agent definition, so the definition is what may be cited — never
"I verified the lane ran on X". Citing the pin is accurate; claiming observation is not.

The one exception is an out-of-process lane that reports its own realized model and
sandbox in a run header that a wrapper script can verify against the pin. That pin may be
stated as observed. **Never generalize that to an in-process lane.**

This distinction is not pedantry. "The reviewer was cross-vendor" is the load-bearing
claim in an acceptance, and an orchestrator that cannot tell the difference between a pin
and an observation will eventually make that claim on the strength of a config file.

## Spawn discipline

- Name the lane and nothing else. **Do not pass a model override on the spawn** — the
  lane's definition pins it, and an override silently defeats the pin.
- Spawn in the foreground. The orchestrator's next action is verification of the result,
  so there is nothing useful to do concurrently.
- Every auxiliary starts in a fresh context by construction. No reset flag is needed, and
  none should be simulated by re-pasting the conversation.
- **Lane names may be namespaced by the packaging that ships them.** A bare name against a
  namespaced install fails as "agent type not found" — which is indistinguishable from a
  genuinely unregistered lane, and only one of those is a real hard stop. Check the
  prefix before concluding a lane is missing.

## Preflight the selected lane only

Confirm the chair first. Then confirm only the lanes the declared route actually selects:

| Mode | Preflight |
|---|---|
| `solo` | none |
| `delegate` | the selected implementer |
| `audit` | the declared review lane |
| `full` | the declared review lane and the selected implementer |

A selected lane whose definition is missing or unregistered is a hard stop: tell the user
to install or repair it, and stop. Never silently substitute a different agent, a
different model, or the orchestrator's own inline work for a lane the route selected.

Preflight is a check on an **already-declared** selection. It is never a search for
whichever lane happens to be installed — a lane chosen by what the machine has is a lane
the transcript cannot account for.

## Escalating beyond the chair

Route escalation tops out at `full`. When newly observed risk exceeds what the chair
should own *at all* — the blast radius is wider than the declared scope, the architecture
itself is in question, or an acceptance mistake would be expensive to reverse — escalate
the **chair**, not the route.

No harness here lets a skill change the primary session's model, so this handoff is
explicit. Stop before further task work and tell the user:

- what was newly observed, and why it exceeds this chair;
- what is already done and verified, so the next chair does not redo it;
- which chair to enter after switching models.

Never simulate a higher chair from a lower one by spawning extra reviewers or claiming an
independence the current chair cannot obtain.

---
name: gem-advisor-max
description: The heavyweight tier of Gem Advisor's risk-gated selective routing for Antigravity. Gemini Pro 3.1 (High) or Claude Opus holds the primary session as orchestrator for high-stakes or wide-blast-radius work, independent review is the floor rather than the exception, and multi-model failover protects against Claude quota depletion. Use when the user invokes /gem-advisor-max or when everyday routed delivery has escalated to this tier.
---

# Gem Advisor Orchestration — heavyweight tier

This is the escalation tier of Gem Advisor. The everyday tier is
[`gem-advisor`](../gem-advisor/SKILL.md), where Gemini Pro 3.1 / Flash 3.8 orchestrates
and `solo` is the default. You are here because the stakes, blast radius, or difficulty
exceed what the everyday tier should own. The subject matter does not decide the tier —
the stakes do.

Act as the architect. Own the user's intent, architecture, route choice, decomposition,
implementation or delegation, parent verification, escalation decisions, and final
acceptance. The four modes are unchanged: `solo`, `delegate`, `audit`, and `full`.

Read [`../gem-advisor/references/role-contracts.md`](../gem-advisor/references/role-contracts.md)
before the first delegation. The lane pins, spawn contract, five-part worker packet,
failover policies, and mode contracts are shared with the everyday tier and are authoritative
here too. Only this file's route floor, primary chair requirements, and acceptance bar differ.

## Confirm the primary session

Run the primary session on Gemini Pro 3.1 (High) or Claude Opus. If the primary session
is on an everyday or lightweight model, stop before delegating and give the user two
clear choices: switch the chair to a heavyweight model (Gemini Pro 3.1 High or Claude Opus),
or drop down to everyday `gem-advisor` and accept its lower floor.

## Declare the route before task tools

Before the first task tool call, emit one machine-auditable declaration:

~~~text
SELECTIVE ROUTE
advisor: gem-advisor
tier: max
mode: solo | delegate | audit | full
risk: <concise, task-specific rationale>
orchestrator: <current model>
lanes: <planned subagent lanes and models>
failover: <none | active failover rule>
~~~

No task tool call may precede this declaration. Reading this skill and its references
is a setup action, not a task action.

## The floor at this tier is audit, not solo

The everyday tier defaults to `solo`. This tier does not. Independent review is the
floor here, because entering this tier is itself a recorded claim that the stakes are
high:

- `audit` is the default. The root orchestrator implements and verifies; a fresh
  `gem-reviewer` reviews the accumulated change set. That is one auxiliary — the tier's
  floor does not raise the default maximum.
- `full` is ordinary at this tier rather than exceptional. Select it whenever a bounded
  or judgment-heavy implementation is better executed by a pinned implementer and the
  change still warrants independent review.
- `delegate` drops independent review. Choose it only when the implementation is fully
  specified and the residual risk is in the building, not in the judging. Record why
  review was not warranted.
- `solo` is a downgrade from this tier's floor. It requires a recorded justification
  naming why no independent review is warranted on work you have already declared
  high-stakes. Never take it silently; if `solo` is genuinely right, the everyday tier
  was probably the correct tier.

Escalation rules are unchanged: a later declaration may only escalate when newly
observed risk justifies it, with the evidence recorded. Never silently downgrade.

## Cross-model review and quota-aware failover

At this tier, cross-model review provides rigorous independent scrutiny. The preferred
reviewer configuration depends on the primary chair:
- If the primary orchestrator is Gemini Pro 3.1 (High), the preferred reviewer is
  `Claude Opus` (or `Claude Sonnet`) for true cross-model validation.
- If the primary orchestrator is Claude Opus, the preferred reviewer is `Gemini Pro 3.1`
  for true cross-model validation.

### Automatic Failover Rule
Claude quota often runs out quickly under heavy usage. If Claude is selected for review
or complex implementation and encounters rate limits (429), quota exhaustion, or credit
depletion:
1. Immediately log the failover event in the selective route audit trail:
   `failover: Claude quota depleted -> failing over to Gemini Pro 3.1 fresh-context review`
2. Spawn `gem-reviewer` on `Gemini Pro 3.1` (or `GPT-OSS`).
3. Note in the final acceptance report that clean fresh-context review was performed under
   the recorded failover policy.
4. **Never stall, abort, or hang the task due to third-party quota exhaustion.**

## Review contract

The reviewer holds read-only tools and no bash, so it cannot run commands. Paste the
complete change set and the actual verification evidence into its prompt. It returns
exactly ship, fix-first, or rethink, and never implements its own fixes.

- `ship`: report completion with the verification evidence.
- `fix-first`:
  - audit: root implements the correction, re-verifies, and obtains a new fresh reviewer.
  - full: the selected implementer handles the correction, root re-verifies, and a new
    fresh reviewer reviews.
- `rethink`: revise the architecture and do not report completion.

Any implementation correction invalidates the prior verdict and requires a new fresh
review. At this tier, do not accept a deliverable on a stale verdict for any reason.

## Keep architect work in the primary session

Keep these in the primary session:

- Resolve requirements and material ambiguity.
- Choose architecture, interfaces, decomposition, and selective route.
- Write the complete five-part worker specification for any selected implementer.
- Inspect the actual diff and rerun verification.
- Decide whether newly observed risk warrants escalation.
- Judge the reviewer verdict and accept the deliverable.

Treat worker reports as claims. Auxiliary work substitutes for root work; it never
duplicates it.

## Dropping back down

If the work turns out to be contained after all, you may not silently finish it at a
lower bar. Either complete it at this tier's floor, or state plainly that the stakes
were lower than declared and hand the user the choice to rerun at the everyday tier.
Recording an overestimate is cheap; quietly delivering high-stakes work without the
review you declared is not.

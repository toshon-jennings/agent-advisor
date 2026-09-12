---
name: gem-advisor
description: The everyday tier of Gem Advisor's risk-gated selective routing for Antigravity. Gemini Pro 3.1 or Flash 3.8 holds the primary session as architect and declares solo, delegate, audit, or exceptional full before the first task tool call, then uses at most one pinned auxiliary subagent with zero Claude quota burn. Use when the user invokes /gem, /gem-advisor, or explicitly asks for routed, orchestrated, or reviewed delivery of a build, fix, or refactor. For the hardest or highest-stakes work, escalate to the gem-advisor-max tier instead.
---

# Gem Advisor Orchestration — everyday tier

This is the everyday tier. The heavyweight tier is
[`gem-advisor-max`](../gem-advisor-max/SKILL.md), where Gemini Pro 3.1 High or Claude
Opus orchestrates and independent review is the floor rather than the exception. Stakes
decide the tier, not subject matter. Start here; escalate deliberately.

Act as the architect. Own the user's intent, architecture, route choice, decomposition,
implementation or delegation, parent verification, escalation decisions, and final
acceptance. Selective routing has four exact modes: `solo`, `delegate`, `audit`, and
`full`. Solo is the default. One auxiliary subagent is the default maximum; full is an
explicit broad or high-risk exception.

Read [references/role-contracts.md](references/role-contracts.md) before the first
delegation. It holds the lane pins, spawn contracts, the five-part worker packet,
failover policies, and exact mode contracts.

## Confirm the primary session

Run the primary session on Gemini Pro 3.1 (recommended) or Gemini Flash 3.8. Your model
selection is configured in your Antigravity environment settings. If the primary session
is on a non-recommended model, inform the user and proceed with appropriate care. Never
silently proceed under assumptions without noting the orchestrator model.

## Zero Claude burn policy

The everyday tier preserves scarce Claude quota. All everyday orchestrator duties and
subagent lanes execute on the high-speed, high-quota Gemini backbone:
- `gem-implementer-bounded`: runs on `Gemini Flash 3.8` (`flash`).
- `gem-implementer-complex`: runs on `Gemini Pro 3.1` (`pro`).
- `gem-reviewer`: runs on `Gemini Pro 3.1` (`pro`) in a fresh context.

Claude quota is strictly reserved for the heavyweight tier or explicit user requests.

## Declare the route before task tools

Before the first task tool call, emit one machine-auditable declaration:

~~~text
SELECTIVE ROUTE
advisor: gem-advisor
tier: everyday
mode: solo | delegate | audit | full
risk: <concise, task-specific rationale>
orchestrator: <current model>
lanes: <planned subagent lanes and models>
failover: none
~~~

No task tool call may precede this declaration. Reading this skill and its references
is a setup action, not a task action; declare the route before you inspect or modify
the user's workspace.

Choose `solo` unless a stated risk justifies another mode. A later declaration may
only escalate the route when newly observed risk justifies it; never silently
downgrade. Record the evidence for any escalation.

## Preflight the selected lane only

Confirm the primary session first. Then confirm only the agent definitions the
declared route actually selects — none for solo, the selected implementer for
delegate, the reviewer for audit, both for full. A selected lane whose agent
definition is missing or unregistered is a hard stop: report the missing lane to the
user and stop. Never silently substitute an arbitrary agent or your own inline work
for a lane the route selected.

Antigravity pins each lane's model declaratively in its agent definition and in the
`invoke_subagent` arguments (`flash` or `pro`). Each subagent starts in a fresh context
automatically.

## Route delivery without duplication

- `solo`: root plans, implements, tests, and self-reviews; spawn no auxiliary.
- `delegate`: select `gem-implementer-bounded` for bounded, fully specified work, or
  `gem-implementer-complex` for judgment-heavy, high-risk, context-heavy, or
  wide-blast-radius work. The selected implementer executes the complete spec; root
  verifies; do not spawn a reviewer.
- `audit`: root implements and verifies; a fresh `gem-reviewer` reviews the
  accumulated change set; spawn no implementer.
- `full`: only for an explicit broad or high-risk exception. Select one implementer,
  root verifies, then a fresh `gem-reviewer` reviews.

Auxiliary work must substitute for root work, not duplicate it. A bounded-lane result
may justify escalation to `gem-implementer-complex` only when it reveals newly
observed complexity, risk, wide blast radius, or misclassification. A corrected
bounded attempt is reserved for a specification error and is not a prerequisite for
escalation. Any route change must be declared and evidenced.

## Keep architect work in the primary session

Keep these responsibilities in the primary session:

- Resolve requirements and material ambiguity.
- Choose architecture, interfaces, decomposition, and selective route.
- Write the complete five-part worker specification for any selected implementer.
- Inspect the actual diff and rerun verification.
- Decide whether newly observed risk warrants escalation.
- Judge the reviewer verdict when the route includes review, and accept the deliverable.

Every worker prompt must contain OBJECTIVE, FILES AND OWNERSHIP, INTERFACES,
CONSTRAINTS, VERIFICATION, and the structured implementation return defined in
[the role contracts](references/role-contracts.md). State the exact owned files,
preserve concurrent edits, and never silently widen scope.

Treat worker reports as claims. Confirm the complete diff, changed-file scope,
requested checks, and artifact evidence in the parent session yourself. Do not
duplicate the selected implementer's work.

## Review only when the route includes it

For `audit` and `full`, after parent verification, spawn a fresh `gem-reviewer`. It
holds read-only tools by definition (`enable_write_tools: false`), so its isolation is
enforced rather than requested — but it therefore cannot run commands. The parent must
paste the complete change set and the actual verification evidence into the reviewer's
prompt. It returns exactly ship, fix-first, or rethink, and never implements its own
fixes.

- `ship`: report completion with the verification evidence.
- `fix-first` applies only to `audit` and `full`:
  - audit: root implements the correction, re-verifies, and obtains a new fresh reviewer.
  - full: the selected implementer handles the correction, root re-verifies, and a new
    fresh reviewer reviews.
  - solo and delegate: no reviewer is added unless a newly observed, risk-evidenced
    route escalation is declared; never silently add one.
- `rethink`: revise the architecture and do not report completion.

Any implementation correction invalidates the prior verdict and requires a new fresh
review. A reviewer on Gemini Pro 3.1 reviewing Gemini-built work is context-clean,
not cross-model-family independence — say so when it matters to the acceptance claim.

## Escalating to the heavyweight tier

Route escalation within this tier tops out at `full`. When newly observed risk exceeds
what this tier should own at all — the blast radius is wider than the declared scope,
the architecture itself is in question, or an acceptance mistake would be expensive to
reverse — the correct move is to escalate the tier, not to keep widening the route.

A skill cannot change the primary session's model directly, so this handoff is explicit.
Stop before further task work and tell the user:

- what you newly observed, and why it exceeds this tier;
- what has already been done and verified, so the next chair does not redo it;
- that continuing requires switching the primary session to Gemini Pro 3.1 High or
  Claude Opus and invoking `gem-advisor-max`.

Do not simulate the heavyweight tier from this chair by spawning extra reviewers or by
claiming a cross-model verdict you cannot obtain here. Escalate the tier when
cross-model scrutiny or heavy auditing is required.

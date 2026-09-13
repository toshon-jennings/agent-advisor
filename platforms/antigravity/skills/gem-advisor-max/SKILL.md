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

At this tier, cross-model review provides rigorous independent scrutiny. **Every subagent
this plugin can spawn runs a Gemini model** — the CLI itself rejects anything else
(`unsupported model: must be one of 'inherit', 'flash', 'pro', 'flash_lite'`), which is
what `scripts/verify.sh` mirrors. Claude is a *chair* option here, never a reviewer lane.

So the independence a review can carry is decided by the chair, not by picking a better
reviewer:

| Chair | Best reachable reviewer | Independence |
|---|---|---|
| Claude Opus | `pro`, or `flash` | cross-vendor |
| Gemini Pro 3.1 (High) | `flash` | cross-model, same vendor |

If the work needs cross-vendor review, that is a reason to run the chair on Claude Opus
before starting — not something to arrange later by naming a reviewer the CLI will refuse
to spawn.

### Quota failover rule

Claude quota runs out quickly under heavy agentic usage. At this tier that is an expected
operating condition, not an exception, so the default is to keep moving — but only as far
as the review stays as independent as the one declared.

**The gate is the independence tier, not the mechanism.** Failing over to an equally
independent lane changes nothing the acceptance claims, so it needs no permission. Failing
over to a weaker one changes exactly what the acceptance claims, so it is the user's call.

Because Claude can only ever be the *chair* here, quota exhaustion does not kill the
reviewer — it kills the chair, and it takes the run's cross-vendor tier with it. The
session falls back to a Gemini chair, and every Gemini reviewer beneath a Gemini chair is
same-vendor at best. When that happens:

1. Log it in the selective route audit trail, naming what the tier actually became:
   `failover: Claude chair quota depleted -> Gemini Pro chair, gem-reviewer on flash
   (cross-model same-vendor; tier lowered)`
2. **Never review with the model the chair is running.** Under a Gemini Pro 3.1 chair,
   `gem-reviewer` on `pro` — or on `inherit`, which resolves to the same thing — is
   context-clean and nothing more. That is not a weaker review of the same kind; it is the
   removal of independent review while the transcript still says a review happened. Use
   `flash`, or stop. `scripts/verify.sh` refuses a reviewer pinned to `inherit` outright.
3. **The tier dropped, so stop and ask.** There is no tier-preserving move available: the
   only way back to cross-vendor is a Claude chair, which is the thing that just became
   unavailable. Say plainly that the review will be weaker, name what was declared and
   what is now reachable, offer the repair if one exists, and wait for the user.
4. State the realized independence in the acceptance report — cross-vendor, cross-model
   same-vendor, or context-clean only. Never describe a failover review as "clean
   fresh-context review" without saying which tier it actually carried.

**Never stall on quota exhaustion that a tier-preserving failover can absorb** — but note
that with today's lanes there is no such failover for the reviewer, so in practice this
tier asks. The rule is written for the capability, not the current roster: if a
cross-vendor reviewer lane ever becomes invocable, it applies without amendment.

For an **implementer** lane the calculus differs and the "never stall" instinct holds
fully: an implementer carries no independence claim, so swapping its model changes nothing
the acceptance asserts. Fail over immediately and declare it.

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

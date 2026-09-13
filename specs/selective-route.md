# Canonical spec — the SELECTIVE ROUTE declaration

Platform-agnostic. Every harness in `platforms/` implements this; none of them may
weaken it. Where a harness adds a field, it adds — it never removes.

## Why a declaration at all

Selective routing is a claim about *who executed the work*. A transcript that does not
carry that claim in a fixed, greppable shape cannot be audited after the fact, and an
orchestrator that decides its route silently is free to decide it in whichever direction
is convenient at the moment it matters. The declaration exists to move that decision
into the record *before* the outcome is known.

Three properties follow from that, and they are the whole point:

1. **It precedes the first task tool call.** Reading the workflow, its references, and
   the chair entry point is setup. Inspecting or modifying the user's workspace is task
   action. The declaration sits on the boundary.
2. **It is machine-auditable.** Fixed field names, one per line, in a fenced block. Not
   prose. A reviewer, a script, or a later session must be able to find it without
   interpreting sentences.
3. **It may only move up.** A route escalates on newly observed, recorded risk. It never
   silently downgrades. Stopping and reporting an unfinished route is *not* a downgrade;
   quietly executing a lesser route while claiming the declared one is.

## The declaration

~~~text
SELECTIVE ROUTE
chair: <the model that holds the primary session>
floor: <the lowest mode this chair may take without recorded justification>
mode: solo | delegate | audit | full
review: <the selected review lane, or `none` when the mode includes no review>
risk: <concise, task-specific rationale>
~~~

`risk:` is the field that does the work. A rationale that would fit any task is not a
rationale — it names what about *this* task justifies *this* mode.

Platform variants carry additional fields where the harness makes them meaningful:

| Field | Codex | Claude | Antigravity |
|---|---|---|---|
| `chair` | as `orchestrator` | `chair` | `orchestrator` |
| `floor` | implicit (`solo`) | `floor` | implicit per tier |
| `mode` | yes | yes | yes |
| `review` | implicit (single lane) | `review` | implicit per tier |
| `risk` | yes | yes | yes |
| `advisor` / `tier` | — | — | yes |
| `lanes` | — | — | yes |
| `failover` | — | on failover only | yes |

## The four modes

Exactly four. No fifth mode, no blend, no "solo but I'll also spawn a quick reviewer."

| Mode | Implementer | Reviewer | Auxiliaries spent |
|---|---|---|---|
| `solo` | orchestrator | orchestrator (self) | 0 |
| `delegate` | one selected lane | none | 1 |
| `audit` | orchestrator | one fresh lane | 1 |
| `full` | one selected lane | one fresh lane | 2 |

One auxiliary is the default maximum. `full` spends two and must be justified as
spending two — the justification is not satisfied by the work merely being large.

**Auxiliary work substitutes for orchestrator work; it never duplicates it.** An
orchestrator that delegates an implementation and then reimplements it has not spent one
auxiliary, it has spent one and wasted it. An orchestrator that finishes a partial
delegation itself has converted a declared `delegate` into an undeclared `solo` and made
its own declaration false.

## The route floor

The floor is set by the chair, not by this spec. It is the lowest mode that chair may
take *without a recorded justification naming why the lower mode is sufficient for work
this chair was entered for*.

A heavyweight chair with an `audit` floor is making a structural claim: at these stakes,
independent review is the norm rather than the exception. Letting that chair drop to
`solo` on a shrug would erase the only difference between the two chairs.

Selecting a mode **above** the floor in the *first* declaration needs no newly observed
risk — only a `risk:` line saying why the extra lane serves delivery. The escalation rule
governs *later* declarations.

## Fail-closed posture

The rule that makes the rest of it load-bearing: **a selected lane that cannot run is a
hard stop, not a licence to downgrade.**

Missing, conflicting, unavailable, or unobservable routing evidence stops the lane. It
does not silently fall back to the orchestrator's own hands, and it does not shop for
whichever lane happens to be installed. Availability never selects a lane — the
orchestrator selects it, and then preflights that selection.

The single exception is the announced review failover defined in
[`reviewer-verdict.md`](reviewer-verdict.md), which is gated on the independence tier: a
failover that preserves it is automatic, one that lowers it requires the user's
authorization, and one onto the chair's own model is refused outright. Every case is
declared. The rule was never that a route may not move down; it is that it may not move
down **silently**.

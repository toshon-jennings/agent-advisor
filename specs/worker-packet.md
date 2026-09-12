# Canonical spec — the five-part worker packet

Platform-agnostic. Every implementer lane in every harness receives this shape. A
delegation that omits a section is not a delegation, it is a request.

## Why five parts

Each section closes a specific failure mode observed when work is handed to a fresh
context that cannot see the conversation that produced it:

| Section | The failure it closes |
|---|---|
| OBJECTIVE | The worker optimizes for the literal instruction and misses the point. |
| FILES AND OWNERSHIP | The worker edits outside its lane, or reverts concurrent work. |
| INTERFACES | The worker "improves" a signature something else depends on. |
| CONSTRAINTS | The worker re-litigates a settled decision, or widens scope. |
| VERIFICATION | The worker reports completion it never checked. |

A sixth element — the structured return — closes the last one: a report the orchestrator
can inspect against the diff rather than take on faith.

## The packet

~~~text
OBJECTIVE
<Observable outcome and why it matters.>

FILES AND OWNERSHIP
You own only:
- <exact file or module>

You are not alone in the codebase. Other agents or the user may be editing concurrently.
Preserve their edits, do not revert unrelated work, and adapt to changes already present.
Do not modify files outside your ownership.

INTERFACES
- <Signatures, types, schemas, commands, or behavior that must remain compatible.>

CONSTRAINTS
- <Repository conventions, safety boundaries, excluded scope, and settled decisions.>

VERIFICATION
- Run: <exact command>
  Success: <concrete expected result>
- Inspect: <exact file, diff, or generated artifact>
  Success: <concrete expected evidence>

RETURN
Return exact commands and actual evidence. A completion claim without evidence is invalid.

IMPLEMENTATION REPORT
STATUS: complete | partial | blocked
OBJECTIVE: <one-line restatement>
CHANGES: <file-by-file summary from the actual diff>
VERIFIED: <exact commands plus concrete output evidence>
JUDGMENT CALLS: <decisions the specification left open, or none>
GAPS: <unfinished work, ambiguity, or none>
~~~

## STATUS reports the specification, not the effort

- `complete` — every VERIFICATION item was run or inspected and passed, and nothing in
  GAPS is outstanding.
- `partial` — the specification was understood and some of it is implemented, with
  identified work remaining. GAPS must name what is left.
- `blocked` — something outside the worker's reach stopped it. GAPS must name the blocker.

`STATUS: partial` with `GAPS: none` is a malformed report, not an empty obligation.

## The orchestrator inspects; it does not trust

Treat every worker report as a claim. Confirm the complete diff, the changed-file scope,
the requested checks, and the artifact evidence directly.

**The inspected diff decides the status, not the worker's claim.** A `complete` claim the
diff does not support is a partial return. A `partial` claim whose diff already satisfies
the packet is complete. Overriding in either direction is a recorded disposition — and the
upward override is the one the orchestrator has an interest in making, so it carries the
heavier evidence burden.

Throughout: **the specification means the packet as it was sent.** Narrowing the packet
after a return does not turn unfinished work into finished work.

## Handling a partial or blocked return

Diagnose the cause from what was inspected, then take exactly one disposition.

| Cause | Disposition |
|---|---|
| The specification was defective | Correct the packet, re-spawn the same lane **once** |
| The work exceeded the lane | Escalate the lane, or escalate the mode — newly observed risk, recorded |
| The blocker is outside every lane's reach | Stop and report |
| The risk exceeds the chair itself | Hand off the chair, not the route |

The correction budget is **one per lane, not one per route**. A lane reached later by
escalation carries its own single correction, so the longest bounded sequence is:
bounded → corrected bounded → complex → corrected complex → stop. The corrected packet
must actually differ. If the corrected attempt also returns `partial` or `blocked`, the
specification was not the cause.

A corrected re-spawn and a lane escalation both *replace* the implementer role rather
than adding one, so neither spends past the one-auxiliary default. Moving `delegate` to
`full` adds the reviewer role — that is a mode escalation, and is declared as one.

### Never absorb the remainder

Finishing a partial implementation in the primary session is the fail-closed hard stop
reached one step later. There is no size at which it becomes acceptable: "only the last
bit" is assessed by the party the judgment favors, and a corrected re-spawn is cheap.

Two things resemble absorbing the remainder but are not, because they were always the
orchestrator's own work:

- **Rerunning verification the worker could not run.** The orchestrator reruns
  verification in every route.
- **Resolving ambiguity, choosing an interface, or correcting the specification the gap
  exposed.** That must produce the *next packet*. If it produces the implementation
  instead, it was absorption. If it produces no further spawn at all, it was a descope,
  and is reported as one.

### Recording the return

~~~text
LANE RETURN
lane: <the lane that was spawned>
status: <the worker's claim>
inspected: <what the diff and the reran checks actually show>
override: none | accepted as complete | treated as partial
cause: specification | lane capacity | external blocker | chair-level risk | none
disposition: accept as complete | re-spawn same lane | escalate lane | escalate mode |
  stop and report | descope and report | hand off chair
evidence: <see below>
tree: <what partial work remains in the working tree>
~~~

`cause: none` belongs only to `accept as complete` and `descope and report` — the two
dispositions that diagnose no failure. And `accept as complete` following a `partial` or
`blocked` status requires `override: accepted as complete`; `override: none` beside it is
incoherent.

**Accepting a return the worker did not call complete** is the only disposition that ends
a route with a delivery claim, so its evidence has two halves and needs both:

- Every specification and VERIFICATION item in the packet **as sent**, with where the
  diff satisfies it. This half stands alone; an acceptance is never carried by the GAPS
  list.
- Every item the worker named in GAPS, answered — where the diff covers it, or why the
  packet as sent never asked for it. If one is genuinely outstanding, the disposition is
  not `accept as complete`.

If the packet asked for more than was delivered and the remainder is no longer wanted,
that is `descope and report`. Scope the user did not get is theirs to know about, and
calling it an acceptance hides it.

Leave partial work in the tree unless it is wrong, and name it in the next packet's FILES
AND OWNERSHIP so the next worker adapts to it instead of rediscovering it.

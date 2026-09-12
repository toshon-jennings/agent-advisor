# Antigravity subagent role contracts

Use these contracts with Gem Advisor's role-pinned Antigravity subagents. They adapt
Sol Advisor's risk-gated selective routing to Google Antigravity, preserving the
orchestrator's architectural ownership, enforcing single-auxiliary discipline, and
managing multi-model quotas across Gemini, Claude, and open weights.

This reference is shared by both tiers and is authoritative for lanes, spawning, the
five-part worker packet, failover handling, and mode contracts. It does not set the
route floor or required primary chair — those belong to the entering tier:
[`gem-advisor`](../SKILL.md) (everyday, Gemini Pro 3.1 / Flash 3.8 in the chair, `solo` floor) or
[`gem-advisor-max`](../../gem-advisor-max/SKILL.md) (heavyweight, Gemini Pro 3.1 High / Claude Opus in the chair, `audit` floor).

## Selective route declaration

Before the first task tool call, the root orchestrator emits one machine-auditable declaration:

~~~text
SELECTIVE ROUTE
advisor: gem-advisor
tier: everyday | max
mode: solo | delegate | audit | full
risk: <concise, task-specific rationale>
orchestrator: <current model>
lanes: <planned subagent lanes and models>
failover: <none | active failover rule>
~~~

One auxiliary is the default maximum in both tiers. The default mode is the entering
tier's floor — `solo` at the everyday tier, `audit` at the heavyweight tier. Any route
below the floor requires a recorded justification. A later declaration may only escalate
when newly observed risk justifies it and supplies concrete evidence; never silently
downgrade.

Confirm the required primary model first, then preflight only the lanes the route
selects: none for solo; one implementer for delegate; the reviewer for audit; one
implementer plus the reviewer for full. A selected lane whose agent definition is missing
or unregistered is a hard stop.

## Lane pins and capabilities

| Lane (`subagent_type`) | Default Model | High-Stakes / Cross-Model | Failover Model | Tool Permissions | Use |
|---|---|---|---|---|---|
| `gem-implementer-bounded` | `Gemini Flash 3.8` (`flash`) | `Claude Sonnet` | `Gemini Flash 3.7 / 3.6` | `enable_write_tools: true`, `enable_subagent_tools: false` | Delegate/full bounded, fully specified work |
| `gem-implementer-complex` | `Gemini Pro 3.1` (`pro`) | `Claude Opus` | `Gemini Pro 3.1` | `enable_write_tools: true`, `enable_subagent_tools: false` | Delegate/full judgment-heavy or high-risk work |
| `gem-reviewer` | `Gemini Pro 3.1` (`pro`) | `Claude Opus` | `GPT-OSS` (tier-preserving); `Gemini Pro 3.1` only when the chair is **not** Gemini Pro, and only with user authorization | `enable_write_tools: false`, `enable_subagent_tools: false` | Audit/full fresh review |

Two isolation invariants are enforced by Antigravity tool definitions rather than prose:

1. **Strict Single Auxiliary Bound**: Neither implementer holds subagent-spawning tools
   (`enable_subagent_tools: false`). A worker cannot delegate onward and violate the
   one-auxiliary ceiling.
2. **Enforced Read-Only Isolation**: The reviewer holds no write or command tools
   (`enable_write_tools: false`). It cannot modify files and cannot run terminal commands.
   The parent orchestrator must supply the change set and actual verification evidence
   in the reviewer's prompt.

## Multi-model quota management & failover policy

Claude models (Opus, Sonnet) offer distinct reasoning and cross-model scrutiny, but Claude
quotas deplete quickly under heavy agentic tasks. Gem Advisor manages quotas defensively:

- **Everyday Tier Zero Claude Burn**: The everyday tier runs entirely on the Gemini
  backbone (`Flash 3.8` and `Pro 3.1`), leaving Claude allowances intact for high-stakes work.
- **Graceful Quota Failover, gated by independence tier**: If Claude Opus or Sonnet is
  selected and encounters rate limits (429), quota exhaustion, or credit depletion, the
  orchestrator logs a machine-auditable failover in the selective route declaration naming
  both lanes and the realized independence:
  `failover: Claude quota depleted -> GPT-OSS fresh-context review (cross-vendor preserved)`

  **For an implementer lane**, execution continues immediately — an implementer carries no
  independence claim, so swapping its model changes nothing the acceptance asserts.

  **For the reviewer lane**, the acceptance rests on a statement about independence, so the
  failover target decides whether permission is needed:
  - A target that preserves the tier (cross-vendor → another cross-vendor lane) is
    automatic. Declare it and continue without stalling.
  - A target that lowers the tier requires explicit user authorization. Ask and wait.
  - A target running the chair's own model is never valid. Under a Gemini Pro 3.1 chair,
    `gem-reviewer` on `Gemini Pro 3.1` makes reviewer and orchestrator the same model:
    context-clean only, which is the absence of independent review rather than a weaker
    form of it. Refuse it.

  Never report a failover review without naming the independence it actually carried.
- **Declarative Model Pins**: Cite the agent definition and `invoke_subagent` arguments as
  the pin's source. If runtime metadata does not expose realized model telemetry, do not
  claim observed routing.

## Antigravity spawn contract

Spawn using Antigravity's subagent facility. If invoking pre-registered agents:

~~~text
invoke_subagent:
  TypeName: gem-implementer-bounded | gem-implementer-complex | gem-reviewer
  Role: <3-5 word task label>
  Model: flash | pro | inherit
  Workspace: inherit
  Prompt: <the complete five-part packet or review packet below>
~~~

If dynamically defining subagents via `define_subagent`, set:
- implementers: `enable_write_tools: true`, `enable_subagent_tools: false`, `enable_mcp_tools: false`
- reviewer: `enable_write_tools: false`, `enable_subagent_tools: false`, `enable_mcp_tools: false`

Every subagent starts in a fresh context. The parent orchestrator awaits subagent completion
and verifies the result directly.

## Shared implementation contract

Every implementer prompt must contain all five sections:

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

The primary session must inspect the diff and rerun verification itself.

## Exact mode contracts

- `solo`: root plans, implements, tests, and self-reviews. Spawn no auxiliary.
- `delegate`: one selected implementer executes the complete five-part specification.
  The root verifies. Do not spawn a reviewer.
- `audit`: root implements and verifies. A fresh `gem-reviewer` inspects the
  accumulated change set. Spawn no implementer. On `fix-first`, the root implements the
  correction, re-verifies, and obtains a new fresh reviewer.
- `full`: use only for an explicit broad or high-risk exception. One selected
  implementer executes the complete specification, the root verifies, and a fresh
  `gem-reviewer` inspects the accumulated change set. On `fix-first`, the selected
  implementer handles the correction, the root re-verifies, and a new fresh reviewer
  inspects the result.

Auxiliary work substitutes for root work; it must not duplicate it. A route escalates
only with newly observed, recorded risk; it never silently downgrades. Solo and
delegate have no reviewer unless a risk-evidenced escalation is declared.

Route escalation tops out at `full`. Risk that exceeds the entering tier itself is
handled by the tier handoff in that tier's skill, not by widening the route further.

## Reviewer prompt

Only for an audit or full route, after parent verification:

~~~text
ROLE
Act as the fresh final reviewer. You hold read tools only.

STATED GOAL
<The user's requested outcome.>

ACCUMULATED CHANGE SET
<Exact owned files plus the complete working-tree diff, pasted in full.>

INTERFACES AND CONSTRAINTS
- <Compatibility, repository rules, safety boundaries, and excluded scope.>

VERIFICATION EVIDENCE
- <command> -> <actual primary-session output evidence>
- <artifact or diff inspection> -> <actual evidence>

REVIEW
Read the actual files named above to confirm this account. Judge correctness,
completeness, regressions, scope discipline, interface preservation, test adequacy,
and material risk.

GEM REVIEW
VERDICT: ship | fix-first | rethink
REASON: <decisive evidence-based reason>
FINDINGS: <precise file references and required fixes, or none>
RESIDUAL RISK: <most important remaining risk, or none>
FAILOVER NOTE: <none | note if failover model was used due to Claude quota>
~~~

If any fix is made after review, discard the verdict and run a new fresh review.

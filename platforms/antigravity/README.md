# Gem Advisor

Risk-gated selective routing for Google Antigravity. The orchestrator owns intent,
architecture, verification, and acceptance, and declares a machine-auditable route
before its first task tool call. Solo delivery is normal; auxiliaries are spent
deliberately, one at a time.

Built for Google Antigravity. The routing model it implements — the machine-auditable route
declaration, the four delivery modes, and the five-part worker specification — is the
design of [Sol Advisor](https://github.com/DannyMac180/sol-advisor) by Daniel McAteer,
MIT licensed. This is an independent reimplementation for Google Antigravity, not a fork or a
port of his code; see [ORIGIN.md](ORIGIN.md) for exactly what carries over.

## Two tiers

Stakes decide the tier, not subject matter. Start everyday; escalate deliberately.

| | `gem-advisor` (everyday) | `gem-advisor-max` (heavyweight) |
|---|---|---|
| Orchestrator (primary session) | Gemini Pro 3.1 (or Flash 3.8) | Gemini Pro 3.1 (High) or Claude Opus |
| Route floor | `solo` | `audit` |
| `full` mode | Explicit exception | Ordinary |
| Below the floor | — | Needs recorded justification |
| Claude quota impact | **Zero Claude burn** (pure Gemini) | Optional cross-model with **graceful failover** |

## Routes

Both tiers share four exact modes, and at most one auxiliary subagent by default:

| Mode | Use it when | Delivery |
|---|---|---|
| `solo` | Risk is contained (default). | Root plans, implements, tests, self-reviews. |
| `delegate` | A complete spec is better executed by one implementer. | One pinned implementer; root verifies. No reviewer. |
| `audit` | Independent scrutiny matters more than delegation. | Root implements; a fresh read-only reviewer reviews. |
| `full` | Broad or high-risk work needing both. | One implementer, root verification, fresh review. |

## Lanes

| Lane (`subagent_type`) | Model | Tool Isolation |
|---|---|---|
| `gem-implementer-bounded` | `Gemini Flash 3.8` (`flash`) | Write + Bash, **no subagent spawning** |
| `gem-implementer-complex` | `Gemini Pro 3.1` (`pro`) | Write + Bash, **no subagent spawning** |
| `gem-reviewer` | `Gemini Pro 3.1` (`pro`) | **Strictly read-only**, no bash, no agent tools |

**Subagent lanes are Gemini-only.** `scripts/verify.sh` permits an agent `model:` of
`flash`, `flash_lite`, `pro` or `inherit`, and the spawn contract accepts
`flash | pro | inherit`. Claude models can hold the **primary session** at the max tier,
but cannot be spawned as a subagent, so cross-vendor *review* is available only when the
chair itself is Claude — at which point every Gemini reviewer lane is cross-vendor to it.
Under a Gemini chair, review is same-vendor at best, and a reviewer on the chair's own
model is context-clean only.

### Enforced Isolation
- **No recursive delegation**: Workers cannot spawn further subagents — their frontmatter `tools:` list names no subagent tool, so the single-auxiliary maximum cannot be broken by a worker delegating onward.
- **Enforced read-only reviewer**: The reviewer's frontmatter `tools:` list contains read tools only, so it cannot write and cannot run shell commands. The orchestrator pastes the complete diff and execution evidence directly into the reviewer's prompt.

  (The agent bodies describe these as `enable_subagent_tools: false` and `enable_write_tools: false`. Those strings are prose in the instruction text, not frontmatter keys — the allowlist omission is what actually enforces both. The guarantee holds; the stated reason for it does not.)

## Multi-model quota management & failover

Claude usage often runs out rapidly under heavy agentic tasks. Gem Advisor handles this cleanly:
1. **Everyday Tier Protection**: Runs entirely on Gemini Flash 3.8 and Gemini Pro 3.1, eliminating quota anxiety and protecting Claude credits.
2. **Failover on Exhaustion, gated by independence**: If Claude is selected for high-tier review and encounters rate limits (429) or credit exhaustion, the orchestrator logs a machine-auditable failover in the route declaration naming both lanes and the independence actually carried:
   `failover: Claude quota depleted -> gem-reviewer on flash (cross-model same-vendor; tier lowered)`
   An **implementer** lane fails over immediately — it carries no independence claim, so changing its model changes nothing the acceptance asserts. A **reviewer** lane does not: every subagent this plugin can spawn runs a Gemini model, so every reviewer failover lowers the independence the review was declared to have, and lowering it is the user's decision rather than the orchestrator's. It stops and asks.
   A failover onto the model the chair is running is refused outright — reviewer and orchestrator being the same model is the absence of independent review, not a weaker form of it.

## Installation

Run the guarded installer from the repository root:

~~~sh
./install.sh
~~~

Or use the Antigravity CLI directly:

~~~sh
agy plugin install .
~~~

Verify the installation:

~~~sh
./install.sh --check
~~~

## Verification

Run the comprehensive structural invariant test suite:

~~~sh
./scripts/verify.sh
~~~

This validates manifest JSON, agent boundaries, read-only reviewer isolation, skill frontmatter, invariant rules, link resolution, Daniel McAteer attribution, shell syntax, and native `agy plugin validate`.

## Usage

In Antigravity chat or TUI, invoke using the slash command or skill names:

~~~text
/gem Build this feature and verify it.
~~~

Or invoke the skill directly:

~~~text
gem-advisor: Refactor the authentication module.
~~~

For high-stakes tasks:

~~~text
gem-advisor-max: Redesign the core payment processing pipeline.
~~~

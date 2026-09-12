# Agent Advisor

One routing model, three execution harnesses.

> **This repo is maintainer infrastructure — there is nothing here to install.**
> To *use* selective routing, install the plugin for your harness:
> [claude-advisor](https://github.com/toshon-jennings/claude-advisor) (Claude Code),
> [gem-advisor](https://github.com/toshon-jennings/gem-advisor) (Antigravity), or
> [sol-advisor-portable](https://github.com/toshon-jennings/sol-advisor-portable) (Codex).
> This repo exists so those three stay honest with each other.
>
> It is public for one reason: [`specs/`](specs/) and the
> [comparison matrix](#the-comparison-matrix) are worth reading whether or not you ever
> touch the sync tooling. They are a written-down account of what the same routing model
> costs to enforce on three different harnesses — including where one of them cannot
> enforce it at all.

Agent Advisor is the canonical hub for three standalone implementations of the same
selective-routing workflow: **Sol Advisor** on Codex, **Claude Advisor** on Claude Code,
and **Gem Advisor** on Google Antigravity. The routing model lives here in
[`specs/`](specs/). Each harness's source lives in [`platforms/`](platforms/) and is
exported outward to its own repository by [`scripts/sync-spokes.sh`](scripts/sync-spokes.sh).

The workflow originates with [Sol Advisor](https://github.com/DannyMac180/sol-advisor) by
Daniel McAteer, MIT licensed. See [ORIGIN.md](ORIGIN.md) for what is carried over, what
is newly built, and how close each adaptation actually is.

## The routing model, in one paragraph

Before the first task tool call, the orchestrator emits a machine-auditable
`SELECTIVE ROUTE` declaration naming its mode and a task-specific risk rationale. There
are exactly four modes — `solo`, `delegate`, `audit`, `full` — and one auxiliary is the
default maximum. The orchestrator keeps architecture, decomposition, verification, and
acceptance in the primary session no matter which mode it declares; delegation moves
*execution*, never judgment. A selected lane that cannot run is a hard stop, not a licence
to quietly do the work by hand. The whole thing is designed so that a transcript can be
audited afterwards for whether the declared route is the route that actually ran.

The four canonical contracts:

| Spec | Defines |
|---|---|
| [`specs/selective-route.md`](specs/selective-route.md) | The declaration, the four modes, the route floor, the fail-closed posture |
| [`specs/role-contracts.md`](specs/role-contracts.md) | The three roles, structural guarantees, spawn discipline, preflight, chair escalation |
| [`specs/worker-packet.md`](specs/worker-packet.md) | The five-part implementer specification and partial/blocked handling |
| [`specs/reviewer-verdict.md`](specs/reviewer-verdict.md) | Review independence, the three-verdict rubric, the authorized failover path |

## Why three implementations instead of one abstraction

Because the interesting parts are not portable.

The routing model is genuinely platform-agnostic — a mode is a mode, and a five-part
packet is a five-part packet. But the properties that make it *enforceable* are made of
harness-specific machinery. "The reviewer cannot write" is a sandbox mode in Codex and an
absent tool name in the other two — and those are not even the same guarantee, since a
sandboxed reviewer can still run commands while a tool-list reviewer cannot. "The
implementer cannot delegate onward" is an omitted tool in Claude Code and Antigravity, and
in Codex is not enforced at all, only instructed. A shared abstraction that flattened
those into one sentence would describe a system none of the three harnesses actually has.

So the specs are the thing the three implementations are checked *against*, not a runtime
they share. The hub's job is to keep them honest with each other, not to pretend they are
the same program.

### Where they currently disagree

"One routing model" is the goal, not a finished fact. One substantive conflict is known
and is recorded rather than smoothed over:

**Review failover.** [`specs/reviewer-verdict.md`](specs/reviewer-verdict.md) requires the
orchestrator to *ask the user and wait* before falling back to a weaker review lane.
`platforms/antigravity/skills/gem-advisor-max/SKILL.md` mandates the opposite — automatic
failover on quota exhaustion, disclosed afterwards, and explicitly "never stall, abort, or
hang." Both disclose; they differ on who decides. Antigravity's position is defensible on
its own terms (quota exhaustion is an expected condition there, not an exception), which is
why this is flagged for a decision rather than silently normalized. See
[`specs/reviewer-verdict.md`](specs/reviewer-verdict.md#known-divergence--antigravity-does-not-implement-this-section)
and `HANDOFF.md`.

## The comparison matrix

### Chairs and route floors

| | **Codex** — Sol Advisor | **Claude Code** — Claude Advisor | **Antigravity** — Gem Advisor |
|---|---|---|---|
| Spoke | `~/sol-advisor-portable` | `~/claude-advisor` | `~/gem-advisor` |
| Plugin version | 0.6.0 (portable fork 2.0.0) | 0.3.0 | 0.1.0 |
| Chairs | Sol / High (`gpt-5.6-sol`), Astra / High (`gpt-6-astra`), Daybreak Blue / High | Opus 5 (`claude-opus-5`), Fable 5.1 (`claude-fable-5-1`) | everyday (Gemini Pro 3.1 / Flash 3.8), max (Gemini Pro 3.1 High or Claude Opus) |
| How chairs vary | Thin alias skills applying **one** substitution: the primary model. Every auxiliary lane stays pinned. | Chair skills set exactly two values: which model presides, and how low its route may go. | Two **tiers**, differing in chair, route floor, and acceptance bar. |
| Route floor | `solo` | `solo` (Opus) · `audit` (Fable) | `solo` (everyday) · independent review is the norm (max) |
| Successor | — (alias swap) | `opus` → `fable` | `gem-advisor` → `gem-advisor-max` |

### Lane pins

| | Codex | Claude Code | Antigravity |
|---|---|---|---|
| Bounded implementer | `gpt-5.6-luna` / max | `sonnet` | `flash` (Gemini Flash 3.8) |
| Complex implementer | `gpt-5.6-terra` / high | `opus` | `pro` (Gemini Pro 3.1) |
| Default reviewer | `gpt-5.6-sol` / high, in-process | **`reviewer-codex`** — `gpt-5.6-sol`, out-of-process | `gem-reviewer` — `pro` |
| Review failover | — | `reviewer-sonnet` (Opus chair) | multi-model, incl. Claude at the max tier |
| Weakest lane, never a failover | — | `reviewer` (pinned to the Opus chair's own model) | — |

Claude Advisor is the outlier: its **default** review lane is out-of-process, in a
different vendor's CLI. That is deliberate. Beneath an Opus chair, the strongest
in-process reviewer available is still same-vendor, and the plugin treats "cross-vendor"
as a claim worth the extra machinery rather than a nice-to-have.

### Isolation enforcement — the part that is genuinely different

| Property | Codex | Claude Code | Antigravity |
|---|---|---|---|
| Reviewer cannot write | **Structural** — `sandbox_mode = "read-only"` in the agent profile | **Structural** — frontmatter `tools:` lists read tools only; no write tools, no Bash | **Structural** — frontmatter `tools:` lists read tools only |
| Implementer cannot delegate onward | **Advisory** — the profile carries no such field; the restriction lives in `developer_instructions` prose | **Structural** — frontmatter `tools:` omits the `Agent` tool | **Structural** — frontmatter `tools:` omits every subagent tool |
| Where the rule lives | A TOML field (reviewer) · prose (implementers) | The absence of a name in a list | The absence of a name in a list |
| Failure mode if violated | Sandbox denies the write · nothing denies onward delegation | The tool is not callable | The tool is not callable |

Two corrections worth making explicitly, because the obvious reading of these projects'
own documentation is wrong on both:

- **The Codex implementers are not structurally prevented from delegating onward.** Their
  TOML profiles carry only `name`, `description`, `model`, `model_reasoning_effort`, and
  `developer_instructions`. The one-auxiliary maximum is enforced there by instruction,
  not by capability. The Codex *reviewer* is different — `sandbox_mode = "read-only"` is a
  real field and a real sandbox.
- **Antigravity's `enable_subagent_tools: false` and `enable_write_tools: false` are prose,
  not configuration.** Both strings appear in the agent files' instruction bodies, never in
  frontmatter. The actual enforcement is the frontmatter `tools:` allowlist, which simply
  does not name those tools — which *is* structural, just not for the reason the files
  claim.

So the honest summary is: read-only review is structurally enforced in all three; the
one-auxiliary maximum is structurally enforced in two of three, and rests on instructions
in Codex.

The Claude and Antigravity mechanism is the quietest and therefore the easiest to break by
accident: it is an *omission*, so adding a tool to the frontmatter for an unrelated reason
silently revokes the guarantee. `platforms/claude/scripts/verify.sh` check 10 asserts it
explicitly for that reason — it fails if a `reviewer*` agent gains any mutating tool, or an
`implementer*` agent gains `Agent`.

### Can you actually verify a lane ran on the model it was pinned to?

This is where the three harnesses differ most, and where all three are required to state
the limit rather than paper over it.

| | Codex | Claude Code | Antigravity |
|---|---|---|---|
| In-process pin, during the run | Declarative | Declarative | Declarative |
| In-process pin, after the run | **Verifiable post-hoc** — `inspect-agent-runtime.sh` reads the on-disk session rollout and emits allowlisted routing metadata | Not exposed | Not exposed |
| Out-of-process pin | — | **Verified** — Codex reports realized model and sandbox in its run header; `review-codex.sh` confirms both against the pin and fails on mismatch | — |

Everywhere a pin is declarative, the correct claim is *"the agent definition pins X"* —
never *"I verified the lane ran on X"*. Citing the pin is accurate; claiming observation
is not. This is not pedantry: "the reviewer was cross-vendor" is the load-bearing sentence
in an acceptance, and an orchestrator that cannot tell a pin from an observation will
eventually assert it on the strength of a config file.

### Quota protection

The three projects solve genuinely different economic problems.

| | Codex | Claude Code | Antigravity |
|---|---|---|---|
| Scarce resource | OpenAI quota | **Claude quota** | Claude quota (Gemini is plentiful) |
| Strategy | Reasoning effort is tiered per lane — `max` for bounded work, `high` elsewhere | **Spend Codex quota for review.** The default reviewer is out-of-process, so `audit` and `full` cost zero extra Claude beyond the chair | **Zero Claude burn.** Every everyday lane is Gemini; Claude is reserved for the max tier or an explicit request |
| Failover cost | — | Failing over to `reviewer-sonnet` *converts* the review back onto Claude quota — a real cost, and one more reason the failover is user-authorized rather than automatic | Multi-model failover so Claude depletion degrades the tier instead of stopping it |

Note the interaction the Claude side has to live with: its quota-cheapest review lane is
also its most independent one. Failing over is worse on *both* axes simultaneously, which
is exactly why it requires the user to say yes.

## Repository layout

~~~text
agent-advisor/
├── specs/                     canonical, platform-agnostic contracts
├── platforms/
│   ├── codex/                 mirrors the root of ~/sol-advisor-portable
│   ├── claude/                mirrors the root of ~/claude-advisor
│   └── antigravity/           mirrors the root of ~/gem-advisor
│       └── spoke.manifest     spoke path, expected remote, native validators, managed paths
└── scripts/
    └── sync-spokes.sh         --check (default) and --push
~~~

Each `platforms/<p>/` tree is laid out **exactly as that spoke's repository root**. That is
what lets every platform's native validator run in place, in the hub, before anything is
exported — the hub is the source of truth precisely because it can be validated as if it
were already installed.

## Syncing the spokes

Flow is one-directional: hub → spoke. Nothing in the tooling reads a spoke and writes the
hub, and the spoke repositories are never edited by hand.

Report drift without writing anything (this is the default):

```bash
./scripts/sync-spokes.sh --check
```

Export the hub to all three spokes:

```bash
./scripts/sync-spokes.sh --push
```

Scope either mode to one platform:

```bash
./scripts/sync-spokes.sh --push --platform claude
```

### What "fail-closed" means here

The defended-against failure is not "the sync errors out". It is "the sync silently
overwrites three live plugin repositories with something that does not validate", which
stays invisible until someone tries to use one. So `--push` refuses on any of:

1. A managed path listed in the manifest but **absent from the hub** — otherwise a hub
   mistake would delete that path from the spoke.
2. The hub tree **failing the platform's own native validator**. This runs before the
   spoke is touched at all.
3. The spoke **not existing**, not being a git work tree, or having an `origin` that does
   not match the manifest.
4. The spoke having **any uncommitted change**, tracked or untracked.

After applying, it re-runs the native validators *in the spoke* **and** re-runs the exact
drift comparison. If either fails, it rolls that spoke back to its committed state.

Rollback is lossless because Guards 4 and 5 hold **together**: Guard 4 proves the tree was
clean, so `git checkout` restores everything tracked; Guard 5 proves no git-ignored file
existed under a managed path, so `git clean -fdx` can remove push-created ignored files
without destroying anything that was already there. Neither guard is sufficient alone —
that is why the clean-tree requirement has no escape hatch.

The script never commits and never pushes to a remote. Review the diff in the spoke
yourself.

| Exit | Meaning |
|---|---|
| 0 | in sync and valid, or pushed and re-validated |
| 1 | drift detected (`--check` only) |
| 2 | a validation failed. **Two different cases share this code** — see below |
| 3 | a guard refused. Nothing was written **unless** the summary says otherwise |
| 4 | caller error |

Exit 2 covers both a **hub** validator failing during preflight, before anything is
written, and a **spoke** failing after the push — where "after the push" includes a failed
copy, a failing native validator, or drift that survived the apply, all of which take the
same rollback path. Exit 3 is normally a clean refusal with nothing written, but an earlier
platform can already have been applied and kept when a later one refuses at apply time.

**This is why the exit code alone is not the report.** The summary always names outcomes
explicitly: `WRITTEN AND KEPT`, `ROLLED BACK`, and `NEEDS ATTENTION` each list the affected
platforms, and the script will never claim "nothing was written" once any mutation has
begun. Read those lines, not just the exit status.

**Preflight is all-or-nothing; applying is not.** Every selected platform is fully
preflighted, and then re-validated a second time immediately before the first write. A
refusal in *either* pass halts the run with nothing written anywhere — that is the
guarantee, and it is the one that matters, because it means a bad manifest or a dirty
spoke can never produce a partial export.

Once writing begins the guarantee is weaker, and the README will not pretend otherwise:
each ready platform is attempted in turn, and a failure in one does **not** undo or skip
the others. A push can therefore end with one spoke updated and kept and another rolled
back. That outcome is real, it is reported by name on the `WRITTEN AND KEPT` and
`ROLLED BACK` lines, and the result line says `mixed` rather than summarising it as
either.

### Native validators per platform

| Platform | Validators run from the tree root |
|---|---|
| Codex | `sh plugins/sol-advisor/scripts/verify.sh` |
| Claude Code | `sh scripts/verify.sh`, then `claude plugin validate .` |
| Antigravity | `sh scripts/verify.sh`, then `agy plugin validate .` |

The Codex CLI ships no `plugin validate` subcommand, so the repo's own agent-profile
checker is the native validator there — it is not a lesser check, but it is a different
kind of one, and the table says so rather than implying parity.

## Attribution

The `SELECTIVE ROUTE` declaration, the four delivery modes, the single-auxiliary maximum,
and the five-part worker specification originate with **Daniel McAteer**'s
[Sol Advisor](https://github.com/DannyMac180/sol-advisor) (MIT). Every exported artifact
carries its licence notice. See [ORIGIN.md](ORIGIN.md) and [LICENSE](LICENSE).

# SUMMARY — agent-advisor source map

Read this before exploring. It is a map, not a tutorial; the reasoning lives in
[`README.md`](README.md) and [`specs/`](specs/).

**What this repo is:** the canonical hub for three standalone implementations of one
selective-routing workflow. It owns the routing model and exports each platform's source
to its own repository. It is not itself installed into any harness.

## Top level

| Path | What it is |
|---|---|
| `README.md` | The philosophy, the cross-platform comparison matrix, sync usage and exit codes |
| `ORIGIN.md` | Attribution to Daniel McAteer; how close each platform is to the original |
| `SUMMARY.md` | This file |
| `HANDOFF.md` | Active milestone tracking and open items |
| `MISTAKES.md` | Mistake ledger, newest first |
| `LICENSE` | MIT, hub notice, names the upstream notice |

## `specs/` — canonical contracts (platform-agnostic)

Read in this order; each assumes the previous.

| File | Go here for |
|---|---|
| `specs/selective-route.md` | The declaration grammar, the four modes, the route floor, fail-closed posture |
| `specs/role-contracts.md` | The three roles, the two structural guarantees, spawn discipline, preflight, chair escalation |
| `specs/worker-packet.md` | The five-part packet, `STATUS` semantics, the `LANE RETURN` block, "never absorb the remainder" |
| `specs/reviewer-verdict.md` | Independence tiers, the `ship`/`fix-first`/`rethink` rubric, the `REVIEW FAILOVER` block |

These are **not** exported to the spokes. See `specs/README.md` for why.

## `platforms/` — one directory per harness

Each directory mirrors **the root of its spoke repository exactly**, which is what lets
each platform's native validator run in place before export.

| Path | Spoke | Notable contents |
|---|---|---|
| `platforms/codex/` | `~/sol-advisor-portable` | `plugins/sol-advisor/` (`.codex-plugin/plugin.json`, `agents/*.toml`, `skills/orchestration/`), root `skills/` = thin chair aliases (sol, astra, daybreak), `.agents/plugins/marketplace.json`, `UPSTREAM.lock` |
| `platforms/claude/` | `~/claude-advisor` | `.claude-plugin/marketplace.json`, `plugins/claude-advisor/` (`agents/*.md`, `skills/{opus,fable,orchestration}/`, `scripts/review-codex.sh`), `scripts/verify.sh` |
| `platforms/antigravity/` | `~/gem-advisor` | `plugin.json` at root, `agents/*.md`, `skills/{gem-advisor,gem-advisor-max}/`, `commands/gem.md`, `rules/AGENTS.md`, `install.sh` |

### `platforms/<p>/spoke.manifest`

The contract between hub and spoke. Key=value lines, then a `[paths]` block.

| Key | Meaning |
|---|---|
| `platform_name` | Display name |
| `spoke_path` | Spoke working copy (`~` expanded) |
| `spoke_remote` | Expected `origin`; a mismatch refuses the push |
| `native_validator` | Repeatable. A shell command run from the tree root, in order |
| `[paths]` | The paths the hub **owns**. Anything else in the spoke is spoke-local and never touched |

Spoke-local by omission in all three: `HANDOFF.md` and `MISTAKES.md`. `.gitignore` **is** hub-managed — it carries the negations that stop the global gitignore hiding `SUMMARY.md`/`HANDOFF.md`, and that has to be uniform to be reliable.

## `scripts/`

| Path | What it does |
|---|---|
| `scripts/sync-spokes.sh` | `--check` (default, writes nothing) and `--push`. Guards, in-hub validation, diff report, apply, post-push validation, rollback. Exit 0/1/2/3/4 — see `README.md` |

There is no separate hub `verify.sh`: the hub's structural checks are the sync script's
own preflight, and duplicating them into a second entry point would give two answers to
one question.

## Where to make a change

**Always in `platforms/<p>/`, never in the spoke.** Then:

```bash
./scripts/sync-spokes.sh --check
```

```bash
./scripts/sync-spokes.sh --push --platform <codex|claude|antigravity>
```

Review and commit inside the spoke afterwards — the script never commits for you.

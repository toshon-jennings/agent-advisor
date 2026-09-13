# SUMMARY.md — Agent Orientation Cheat Sheet

> **PURPOSE:** This file exists to prevent unnecessary full-repo scans. AI
> agents MUST read this file first when they need orientation. It provides
> a map of the codebase so agents can jump directly to the relevant files
> instead of scanning every directory.

> **RULE:** Do NOT grep or glob the entire repo to find things. Use this
> document's pointers to navigate directly. Only search broadly when the
> answer isn't found via these pointers.

---

## Project

**Name:** gem-advisor
**Description:** Capability-routed software delivery for Google Antigravity with multi-model quota protection and graceful failover.
**Target Platform:** Google Antigravity (CLI `agy`, Antigravity Desktop, Antigravity IDE)
**Primary Language:** Markdown, YAML, JSON, Bash
**Framework:** Antigravity Plugin & Customization Architecture

---

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Google Antigravity (CLI `agy`, Desktop 2.0, IDE) |
| Core Plugin Manifest | `plugin.json` |
| Primary Models | Gemini Pro 3.1, Gemini Flash 3.8 (chair may also be Claude Opus at the max tier). Subagent lanes are restricted to `flash`, `flash_lite`, `pro`, `inherit` by `scripts/verify.sh`. |
| Subagents | Antigravity Native Subagents (`invoke_subagent`, `define_subagent`) |
| Installation & Checks | `agy plugin install`, `agy plugin validate` |

---

## Source Map

### Entry Points
| File | Role |
|---|---|
| `install.sh` | Standalone plugin installer and verification script |
| `plugin.json` | Antigravity plugin manifest |
| `commands/gem.md` | Slash command `/gem` entry point |

### Core Directories
| Directory | Contains |
|---|---|
| `skills/` | Agent skills (`gem-advisor`, `gem-advisor-max`) |
| `skills/gem-advisor/references/` | Authoritative role contracts and failover policies |
| `agents/` | Agent definitions (`gem-implementer-bounded`, `gem-implementer-complex`, `gem-reviewer`) |
| `commands/` | Slash commands (`/gem`) |
| `rules/` | Plugin rules (`rules/AGENTS.md`) |

### Cross-cutting Concerns
| Concern | Location |
|---|---|
| Role Contracts & Failover | `skills/gem-advisor/references/role-contracts.md` |
| Quota Management | `skills/gem-advisor/SKILL.md` |
| Heavyweight Audit Bar | `skills/gem-advisor-max/SKILL.md` |
| Handoff & Continuity | `HANDOFF.md` |
| Mistakes Log | `MISTAKES.md` |

---

## Key Architectural Patterns

1. **Selective Route Declaration**: Emits `SELECTIVE ROUTE` before any task tool calls.
2. **Single Auxiliary Maximum**: Solo default; at most one auxiliary subagent permitted by default.
3. **Zero Claude Burn on Everyday Tier**: Everyday tasks run entirely on Gemini Flash 3.8 and Gemini Pro 3.1.
4. **Graceful Failover, gated by independence tier**: If Claude hits 429 or quota limits, an implementer lane fails over immediately (it carries no independence claim). A reviewer lane may not: every invocable subagent runs a Gemini model, so every reviewer failover lowers the tier and needs user authorization. A fallback running the chair's own model is refused outright.
5. **Enforced Boundary Discipline**: Implementers have write tools but cannot spawn subagents; reviewer is strictly read-only with no bash.

---

## Common Gotchas

1. Never invoke task tools before emitting the `SELECTIVE ROUTE` declaration.
2. The reviewer is strictly read-only (`enable_write_tools: false`) and cannot run bash commands. Provide diffs and evidence in the prompt.
3. Keep Claude quota for high-stakes tasks; use Gemini Flash 3.8 for bounded specs.

---

## How to Navigate by Task

| If you need to... | Go to... |
|---|---|
| Modify tier rules | `skills/gem-advisor/SKILL.md` or `skills/gem-advisor-max/SKILL.md` |
| Update model assignments / failover | `skills/gem-advisor/references/role-contracts.md` |
| Update agent tool profiles | `agents/` |
| Validate plugin | Run `agy plugin validate .` or `./install.sh --check` |

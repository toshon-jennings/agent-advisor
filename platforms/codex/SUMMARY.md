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

**Name:** sol-advisor-portable
**Description:** Portable cross-platform capability-routed software delivery for Codex (Sol Advisor), Claude Code (Sol Advisor Claude), and Google Antigravity (Gem Advisor).
**Target Platform:** CLI, Antigravity Desktop, Codex CLI, Claude Code
**Primary Language:** Shell (Bash), Markdown, YAML, TOML, JSON
**Framework:** Agentic plugins and subagent role contracts

---

## Tech Stack

| Layer | Technology |
|---|---|
| Codex Plugin | Native OpenAI Codex Plugin (`plugins/sol-advisor`) |
| Claude Code Plugin | Claude Code Plugin (`plugins/sol-advisor-claude`) |
| Antigravity Plugin | Google Antigravity Plugin (`plugins/gem-advisor`) |
| Package Managers / Registries | `codex plugin`, `agy plugin`, Claude Code marketplace |
| Shell Automation | POSIX / Bash installer scripts |

---

## Source Map

### Entry Points
| File | Role |
|---|---|
| `install.sh` | Main cross-platform installer (Codex + Antigravity dispatch) |
| `install-gem-advisor.sh` | Dedicated Antigravity installer and verification script |
| `plugins/sol-advisor/scripts/install-agents.sh` | Codex companion custom agent installer |
| `plugins/sol-advisor/scripts/verify.sh` | Codex upstream exactness verifier |

### Core Directories
| Directory | Contains |
|---|---|
| `plugins/gem-advisor/` | Antigravity plugin: skills, agents, commands, rules, and docs |
| `plugins/gem-advisor/skills/` | Antigravity skills: everyday `gem-advisor` and heavyweight `gem-advisor-max` |
| `plugins/gem-advisor/agents/` | Antigravity agent profiles (`bounded`, `complex`, `reviewer`) |
| `plugins/gem-advisor/commands/` | Antigravity slash commands (`/gem`) |
| `plugins/gem-advisor/rules/` | Antigravity plugin rules (`rules/AGENTS.md`) |
| `plugins/sol-advisor/` | Pinned Codex upstream plugin, skills, and agents |
| `plugins/sol-advisor-claude/` | Claude Code plugin, everyday and max skills, and role contracts |
| `skills/` | Codex shorthand skills (`sol-advisor`, `astra-advisor`, `daybreak-advisor`) |
| `prompts/` | Codex `/sol` prompt definition |

### Cross-cutting Concerns
| Concern | Location |
|---|---|
| Antigravity Contracts & Failover | `plugins/gem-advisor/skills/gem-advisor/references/role-contracts.md` |
| Claude Contracts | `plugins/sol-advisor-claude/skills/sol-advisor/references/role-contracts.md` |
| Codex Operations & Preflight | `plugins/sol-advisor/skills/orchestration/references/operations.md` |
| Handoff & Session State | `HANDOFF.md` |
| Cross-device Setup | `PORTABLE.md` |
| Mistakes Log | `MISTAKES.md` |

---

## Key Architectural Patterns

1. **Capability-Routed Software Delivery**:
   The primary session orchestrator acts as the architect and retains intent, decomposition, parent verification, and final acceptance.
2. **Selective Route Declaration**:
   A machine-auditable `SELECTIVE ROUTE` declaration (`solo`, `delegate`, `audit`, or `full`) must precede the first task tool call.
3. **Single Auxiliary Maximum**:
   Solo is the default; at most one auxiliary subagent is permitted by default. Implementers cannot spawn subagents, and reviewers are strictly read-only.
4. **Multi-Model Quota Protection & Failover (Antigravity)**:
   Everyday tier runs 100% on Gemini backbone (`Flash 3.8` / `Pro 3.1`) to conserve Claude quota. High-tier cross-model review gracefully fails over to Gemini Pro 3.1 if Claude is rate-limited or depleted.

---

## What NOT to Touch

| Path | Why |
|---|---|
| `plugins/sol-advisor/` | Pinned upstream mirror. Update only deliberately via `UPSTREAM.lock`. |
| `.agents/plugins/marketplace.json` | Codex marketplace registration manifest. |
| `.claude-plugin/marketplace.json` | Claude Code marketplace manifest. |

---

## Common Gotchas

1. **Do not run task tools before declaring SELECTIVE ROUTE** — routing declaration must precede workspace modification.
2. **Reviewer isolation is strictly read-only** — the reviewer holds no write or bash tools. The parent must provide diffs and verification output in the prompt.
3. **Claude quota is scarce** — do not route routine tasks to Claude when Gemini Flash 3.8 and Gemini Pro 3.1 can execute them cleanly.

---

## How to Navigate by Task

| If you need to... | Go to... |
|---|---|
| Modify Antigravity routing / tier rules | `plugins/gem-advisor/skills/` |
| Modify Antigravity subagent definitions | `plugins/gem-advisor/agents/` |
| Update Antigravity role contracts & failover | `plugins/gem-advisor/skills/gem-advisor/references/role-contracts.md` |
| Verify Antigravity plugin | Run `agy plugin validate plugins/gem-advisor` or `./install-gem-advisor.sh --check` |
| Verify Codex plugin | Run `./install.sh --check` |

---
name: sol-advisor
description: Run a software-delivery request through the installed Sol Advisor orchestration workflow.
---

# Sol Advisor shorthand

Treat the text after `$sol-advisor:` as the user's task request.

Before taking any task action, resolve the installed `sol-advisor@sol-advisor` plugin
directory from `codex plugin list --json`, then read its
`skills/orchestration/SKILL.md` completely and follow it as the authoritative workflow.
Read any references that workflow requires. Plugin discovery and instruction loading
are setup actions; do not inspect or modify the user's task workspace until the
authoritative workflow has declared its `SELECTIVE ROUTE`.

If the plugin or canonical skill cannot be resolved, stop and tell the user to run
the portable checkout's `./install.sh`. Never substitute an inferred or partial Sol
Advisor workflow.

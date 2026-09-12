# Cross-device installation

This private mirror carries the complete Sol Advisor v0.6.0 plugin, its three native
custom-agent profiles, verification scripts, Sol/Astra/Daybreak advisor shorthands,
and the `/sol` prompt. It is pinned to
upstream commit `37b75cad535abdd46531f0227483a8842d045ab8`; see `UPSTREAM.lock`.

No Codex credentials, sessions, generated caches, or machine-specific configuration
belong in this repository.

## Install on another device

Requirements:

- A current Codex CLI or ChatGPT desktop app with plugins and native custom agents.
- `git`, `jq`, and a POSIX shell. On Windows, run this from WSL or Git Bash.
- GPT-5.6 Sol, GPT-6 Astra, or GPT Daybreak Blue at High for the primary task. Luna /
  Max and Terra / High are required only when the selected route delegates.

Clone this repository into a stable location:

~~~sh
git clone git@github.com:toshon-jennings/sol-advisor-portable.git
~~~

Enter the checkout:

~~~sh
cd sol-advisor-portable
~~~

Run the guarded installer:

~~~sh
./install.sh
~~~

Start a fresh Codex task so the skills and three custom-agent roles are discovered.
Select the primary model at High, then invoke its matching shorthand:

~~~text
$sol-advisor: Build the requested feature and verify it.
$astra-advisor: Build the requested feature and verify it.
$daybreak-advisor: Build the requested feature and verify it.
~~~

The namespaced plugin skill remains available as `$sol-advisor:orchestration`, and
the compatibility prompt remains available as `/sol TASK="..."`.

## Verify a device

~~~sh
./install.sh --check
~~~

The installer is fail-closed. It refuses to overwrite a modified `/sol` prompt,
refuses a conflicting marketplace registration, and delegates agent installation to
Sol Advisor's exactness-checking companion installer.

## Included files

- `.agents/plugins/marketplace.json`: local Codex marketplace manifest.
- `plugins/sol-advisor/`: pinned plugin, skill, agent profiles, and verification tools.
- `skills/*-advisor/SKILL.md`: top-level Sol, Astra, and Daybreak shorthands.
- `prompts/sol.md`: portable `/sol` command.
- `install.sh`: guarded, idempotent installer and full-device check.
- `UPSTREAM.lock`: upstream source, commit, and plugin version.

## Updating the mirror

Treat updates as deliberate releases. Review a newer upstream commit, replace the
vendored plugin files, update `UPSTREAM.lock`, run the upstream verifier, and test the
portable installer on one device before updating the others.

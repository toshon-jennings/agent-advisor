# Sol Advisor V2

An expanded, portable edition of Sol Advisor with a choice of primary Codex
orchestrators: GPT-5.6 Sol, GPT-6 Astra, or GPT Daybreak Blue.

## Credit and lineage

[Sol Advisor](https://github.com/DannyMac180/sol-advisor) was created by
[Daniel McAteer](https://github.com/DannyMac180). Daniel designed and implemented
the original Codex-native selective-routing workflow, including its route model,
worker roles, verification contract, and Sol-led orchestration.

This repository is an independently maintained expansion by
[Toshon Jennings](https://github.com/toshon-jennings). The original Codex plugin is
preserved under `plugins/sol-advisor/`, pinned to its upstream source and version in
[UPSTREAM.lock](UPSTREAM.lock), and remains MIT licensed. The V2 additions described
below are specific to this fork and do not imply upstream authorship or endorsement.

## What V2 adds

- Three primary-orchestrator choices, all at High reasoning.
- Exact `$sol-advisor:`, `$astra-advisor:`, and `$daybreak-advisor:` shorthands.
- One shared, risk-gated routing core instead of three drifting copies.
- Portable, fail-closed installation and byte-exact device checks.
- Cross-model review for Astra and Daybreak through the existing fresh Sol / High
  reviewer.

The original plugin behavior and native `$sol-advisor:orchestration` entry point stay
available. Astra and Daybreak change only the primary orchestrator; Luna / Max and
Terra / High remain the implementation lanes.
Luna / Max or Terra / High access is needed only when the selected route delegates.

## Install this fork

You need a current Codex CLI or ChatGPT desktop app with plugins enabled, native
custom-agent support, and `jq`.

~~~sh
git clone https://github.com/toshon-jennings/sol-advisor-portable.git
~~~

~~~sh
cd sol-advisor-portable
~~~

~~~sh
./install.sh
~~~

Start a fresh Codex task so the skills and custom-agent roles are discovered. Select
the matching primary model at High, then use one of these forms:

~~~text
$sol-advisor: Build this feature and verify it.
$astra-advisor: Build this feature and verify it.
$daybreak-advisor: Build this feature and verify it.
~~~

## Routes

| Mode | Use it when | Delivery |
|---|---|---|
| `solo` | Default; risk is contained. | Root plans, implements, tests, and self-reviews. |
| `delegate` | One complete spec is best executed by an implementer. | Luna / Max for bounded work or Terra / High for higher-risk work; root verifies. |
| `audit` | Independent final scrutiny matters most. | Root implements; a fresh read-only Sol / High reviews. |
| `full` | Explicit broad or high-risk exception. | One implementer, root verification, and a fresh Sol / High review. |

The primary orchestrator runs the show: it owns architecture, verification, escalation, and
acceptance. That chair is Sol / High by default, and Astra / High or Daybreak / High when
invoked through those aliases; the ownership is the chair's, whichever model holds it.
Solo is the default. One auxiliary is the default maximum. Auxiliary work substitutes for
primary work rather than duplicating it. The primary orchestrator declares a
`SELECTIVE ROUTE` before the first task tool call, may escalate only when newly observed
risk justifies it, and never silently downgrades. You do not need to select or manage a lane.

## Manual Codex maintenance

To register this checkout as a local marketplace:

~~~sh
codex plugin marketplace add /absolute/path/to/sol-advisor-portable
~~~

~~~sh
codex plugin add sol-advisor@sol-advisor
~~~

~~~sh
plugin_dir="$(codex plugin list --json | jq -r '.installed[] | select(.pluginId == "sol-advisor@sol-advisor") | .source.path')" && test -n "$plugin_dir" && test "$plugin_dir" != null && test -d "$plugin_dir" && test -f "$plugin_dir/scripts/install-agents.sh" && sh "$plugin_dir/scripts/install-agents.sh"
~~~

After pulling an update:

~~~sh
codex plugin marketplace upgrade sol-advisor
~~~

~~~sh
codex plugin add sol-advisor@sol-advisor
~~~

~~~sh
plugin_dir="$(codex plugin list --json | jq -r '.installed[] | select(.pluginId == "sol-advisor@sol-advisor") | .source.path')" && test -n "$plugin_dir" && test "$plugin_dir" != null && test -d "$plugin_dir" && test -f "$plugin_dir/scripts/install-agents.sh" && sh "$plugin_dir/scripts/install-agents.sh"
~~~

For exact routing, runtime-evidence, sandbox, and installer details, read
[advanced native operations](plugins/sol-advisor/skills/orchestration/references/operations.md).

## License

MIT. See [LICENSE](LICENSE). Original Sol Advisor attribution is retained above and
in the vendored plugin metadata.

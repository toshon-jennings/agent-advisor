#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf '%s\n' 'Usage: ./install.sh [--check]'
  printf '%s\n' '  no option  Install the marketplace, plugin, agents, three advisor aliases, and /sol prompt.'
  printf '%s\n' '  --check    Verify the complete portable installation without changing it.'
}

mode=install
case "${1-}" in
  '') ;;
  --check) mode=check ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

for required_command in codex jq git sh cmp; do
  command -v "$required_command" >/dev/null 2>&1 ||
    fail "required command is unavailable: $required_command"
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
plugin_dir="$script_dir/plugins/sol-advisor"
agent_installer="$plugin_dir/scripts/install-agents.sh"
prompt_source="$script_dir/prompts/sol.md"
skill_names='sol-advisor astra-advisor daybreak-advisor'
codex_dir="${CODEX_HOME:-${HOME}/.codex}"
prompt_dir="$codex_dir/prompts"
prompt_destination="$prompt_dir/sol.md"
skills_dir="$codex_dir/skills"

test -f "$script_dir/.agents/plugins/marketplace.json" ||
  fail "marketplace manifest is missing"
test -f "$plugin_dir/.codex-plugin/plugin.json" ||
  fail "plugin manifest is missing"
test -f "$agent_installer" ||
  fail "companion installer is missing"
test -f "$prompt_source" ||
  fail "/sol prompt source is missing"
for skill_name in $skill_names; do
  skill_source="$script_dir/skills/$skill_name/SKILL.md"
  test -f "$skill_source" ||
    fail "\$$skill_name alias source is missing"
done

if test -e "$prompt_destination" || test -L "$prompt_destination"; then
  test -f "$prompt_destination" && test ! -L "$prompt_destination" ||
    fail "existing /sol prompt is not a regular file: $prompt_destination"
  cmp -s "$prompt_source" "$prompt_destination" ||
    fail "existing /sol prompt differs and was left untouched: $prompt_destination"
fi

for skill_name in $skill_names; do
  skill_source="$script_dir/skills/$skill_name/SKILL.md"
  skill_dir="$skills_dir/$skill_name"
  skill_destination="$skill_dir/SKILL.md"
  if test -e "$skill_dir" || test -L "$skill_dir"; then
    test -d "$skill_dir" && test ! -L "$skill_dir" ||
      fail "existing \$$skill_name alias path is not a real directory: $skill_dir"
  fi
  if test -e "$skill_destination" || test -L "$skill_destination"; then
    test -f "$skill_destination" && test ! -L "$skill_destination" ||
      fail "existing \$$skill_name alias is not a regular file: $skill_destination"
    cmp -s "$skill_source" "$skill_destination" ||
      fail "existing \$$skill_name alias differs and was left untouched: $skill_destination"
  fi
done

marketplace_json=$(codex plugin marketplace list --json)
registered_root=$(printf '%s' "$marketplace_json" | jq -r \
  '.marketplaces[] | select(.name == "sol-advisor") | .root' | head -n 1)

if test -n "$registered_root"; then
  registered_root=$(CDPATH= cd -- "$registered_root" && pwd -P) ||
    fail "registered Sol Advisor marketplace is unavailable: $registered_root"
  test "$registered_root" = "$script_dir" ||
    fail "a different Sol Advisor marketplace is already registered at $registered_root"
elif test "$mode" = check; then
  fail "this portable Sol Advisor marketplace is not registered"
else
  codex plugin marketplace add "$script_dir"
fi

plugin_json=$(codex plugin list --json)
installed_plugin_dir=$(printf '%s' "$plugin_json" | jq -r \
  '.installed[] | select(.pluginId == "sol-advisor@sol-advisor" and .installed == true) | .source.path' | head -n 1)

if test -z "$installed_plugin_dir"; then
  test "$mode" = install || fail "Sol Advisor plugin is not installed"
  codex plugin add sol-advisor@sol-advisor
  plugin_json=$(codex plugin list --json)
  installed_plugin_dir=$(printf '%s' "$plugin_json" | jq -r \
    '.installed[] | select(.pluginId == "sol-advisor@sol-advisor" and .installed == true) | .source.path' | head -n 1)
fi

test -n "$installed_plugin_dir" && test -d "$installed_plugin_dir" ||
  fail "Codex did not report a valid installed Sol Advisor plugin directory"

if test "$mode" = check; then
  sh "$agent_installer" --check
  test -f "$prompt_destination" || fail "/sol prompt is not installed"
  cmp -s "$prompt_source" "$prompt_destination" ||
    fail "/sol prompt does not match the portable source"
  for skill_name in $skill_names; do
    skill_source="$script_dir/skills/$skill_name/SKILL.md"
    skill_destination="$skills_dir/$skill_name/SKILL.md"
    test -f "$skill_destination" || fail "\$$skill_name alias is not installed"
    cmp -s "$skill_source" "$skill_destination" ||
      fail "\$$skill_name alias does not match the portable source"
  done
  printf '%s\n' 'CHECK PASSED: marketplace, plugin, agents, three advisor aliases, and /sol prompt are exact.'
  exit 0
fi

sh "$agent_installer"
mkdir -p "$prompt_dir"
if test ! -e "$prompt_destination"; then
  install -m 0644 "$prompt_source" "$prompt_destination"
fi
for skill_name in $skill_names; do
  skill_source="$script_dir/skills/$skill_name/SKILL.md"
  skill_dir="$skills_dir/$skill_name"
  skill_destination="$skill_dir/SKILL.md"
  mkdir -p "$skill_dir"
  if test ! -e "$skill_destination"; then
    install -m 0644 "$skill_source" "$skill_destination"
  fi
done

sh "$agent_installer" --check
cmp -s "$prompt_source" "$prompt_destination" ||
  fail "/sol prompt post-install verification failed"
for skill_name in $skill_names; do
  skill_source="$script_dir/skills/$skill_name/SKILL.md"
  skill_destination="$skills_dir/$skill_name/SKILL.md"
  cmp -s "$skill_source" "$skill_destination" ||
    fail "\$$skill_name alias post-install verification failed"
done

printf '%s\n' 'INSTALL PASSED: start a fresh Codex task and invoke the advisor matching its selected orchestrator.'

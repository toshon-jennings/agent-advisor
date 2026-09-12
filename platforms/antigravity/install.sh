#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf '%s\n' 'Usage: ./install.sh [--check]'
  printf '%s\n' '  no option  Validate and install the gem-advisor plugin for Google Antigravity.'
  printf '%s\n' '  --check    Verify the complete installation without changing it.'
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

for required_command in agy sh cmp; do
  command -v "$required_command" >/dev/null 2>&1 ||
    fail "required command is unavailable: $required_command"
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
antigravity_plugins_dir="${HOME}/.gemini/config/plugins"
plugin_destination="$antigravity_plugins_dir/gem-advisor"

test -f "$script_dir/plugin.json" ||
  fail "plugin manifest is missing: $script_dir/plugin.json"
test -f "$script_dir/skills/gem-advisor/SKILL.md" ||
  fail "gem-advisor skill is missing"
test -f "$script_dir/skills/gem-advisor-max/SKILL.md" ||
  fail "gem-advisor-max skill is missing"
test -f "$script_dir/agents/gem-implementer-bounded.md" ||
  fail "bounded implementer agent is missing"
test -f "$script_dir/agents/gem-implementer-complex.md" ||
  fail "complex implementer agent is missing"
test -f "$script_dir/agents/gem-reviewer.md" ||
  fail "reviewer agent is missing"
test -f "$script_dir/commands/gem.md" ||
  fail "gem command is missing"

# Preflight validate this plugin
agy plugin validate "$script_dir" >/dev/null 2>&1 ||
  fail "source gem-advisor plugin failed validation"

files_to_check=(
  "plugin.json"
  "README.md"
  "ORIGIN.md"
  "skills/gem-advisor/SKILL.md"
  "skills/gem-advisor/references/role-contracts.md"
  "skills/gem-advisor-max/SKILL.md"
  "agents/gem-implementer-bounded.md"
  "agents/gem-implementer-complex.md"
  "agents/gem-reviewer.md"
  "commands/gem.md"
  "rules/AGENTS.md"
)

if test "$mode" = check; then
  test -d "$plugin_destination" ||
    fail "gem-advisor plugin is not installed at $plugin_destination"

  for rel_file in "${files_to_check[@]}"; do
    dest_file="$plugin_destination/$rel_file"
    src_file="$script_dir/$rel_file"
    test -f "$dest_file" || fail "missing installed file: $dest_file"
    cmp -s "$src_file" "$dest_file" || fail "installed file differs from source: $dest_file"
  done

  agy plugin validate "$plugin_destination" >/dev/null 2>&1 ||
    fail "installed gem-advisor plugin failed validation"

  printf '%s\n' 'CHECK PASSED: gem-advisor plugin, skills, agents, commands, and rules are exact.'
  exit 0
fi

# Install mode
mkdir -p "$antigravity_plugins_dir"

# Run agy plugin install
agy plugin install "$script_dir"
agy plugin enable gem-advisor >/dev/null 2>&1 || true

# Copy docs, rules, and references
cp -p "$script_dir/README.md" "$plugin_destination/README.md"
cp -p "$script_dir/ORIGIN.md" "$plugin_destination/ORIGIN.md"
if test -f "$script_dir/rules/AGENTS.md"; then
  mkdir -p "$plugin_destination/rules"
  cp -p "$script_dir/rules/AGENTS.md" "$plugin_destination/rules/AGENTS.md"
fi
if test -f "$script_dir/skills/gem-advisor/references/role-contracts.md"; then
  mkdir -p "$plugin_destination/skills/gem-advisor/references"
  cp -p "$script_dir/skills/gem-advisor/references/role-contracts.md" "$plugin_destination/skills/gem-advisor/references/role-contracts.md"
fi

# Validate post-install
for rel_file in "${files_to_check[@]}"; do
  dest_file="$plugin_destination/$rel_file"
  src_file="$script_dir/$rel_file"
  test -f "$dest_file" || fail "post-install file is missing: $dest_file"
  cmp -s "$src_file" "$dest_file" || fail "post-install verification failed for $dest_file"
done

agy plugin validate "$plugin_destination" >/dev/null 2>&1 ||
  fail "installed gem-advisor plugin failed validation"

printf '%s\n' 'INSTALL PASSED: gem-advisor is installed. In Antigravity, use /gem or invoke gem-advisor: <prompt>.'

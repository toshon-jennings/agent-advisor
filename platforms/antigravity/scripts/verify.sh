#!/usr/bin/env bash

# Runs gem-advisor's structural invariant checks in one pass.
# Each test prints exactly one 'ok' or 'FAIL' line. A failure in one check
# does not abort subsequent checks. Exits 0 on total pass, 1 on any failure.

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd -P)

status=0
total=0
failed=0

ok() {
  printf 'ok - %s\n' "$1"
  total=$((total + 1))
}

fail() {
  printf 'FAIL - %s\n' "$1"
  total=$((total + 1))
  failed=$((failed + 1))
  status=1
}

# 1. plugin.json is valid JSON with required metadata
detail=$(python3 - "$repo_root" <<'PY'
import json, os, sys

root = sys.argv[1]
manifest_path = os.path.join(root, "plugin.json")
errors = []

try:
    with open(manifest_path, encoding="utf-8") as fh:
        data = json.load(fh)
    if data.get("name") != "gem-advisor":
        errors.append(f"name must be 'gem-advisor', got {data.get('name')!r}")
    if not data.get("version"):
        errors.append("missing 'version'")
    if not data.get("description"):
        errors.append("missing 'description'")
except Exception as exc:
    errors.append(f"{manifest_path}: {exc}")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "plugin.json is valid JSON with required metadata"
else
  fail "plugin.json is valid JSON with required metadata ($detail)"
fi

# 2. every agent has valid frontmatter, matching name, and allowed model
detail=$(python3 - "$repo_root" <<'PY'
import glob, os, re, sys

root = sys.argv[1]
agents_dir = os.path.join(root, "agents")
allowed_models = {"flash", "pro", "flash_lite", "inherit"}
errors = []

for path in sorted(glob.glob(os.path.join(agents_dir, "*.md"))):
    rel = os.path.relpath(path, root)
    stem = os.path.splitext(os.path.basename(path))[0]
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    if not lines or lines[0].strip() != "---":
        errors.append(f"{rel}: missing frontmatter start")
        continue
    frontmatter = {}
    terminated = False
    for line in lines[1:]:
        if line.strip() == "---":
            terminated = True
            break
        match = re.match(r'^([A-Za-z_]+):\s*(.*)$', line)
        if match:
            frontmatter[match.group(1)] = match.group(2).strip()
    if not terminated:
        errors.append(f"{rel}: frontmatter not terminated")
        continue
    for key in ("name", "description", "tools", "model"):
        if not frontmatter.get(key):
            errors.append(f"{rel}: missing {key}")
    if frontmatter.get("name") and frontmatter["name"] != stem:
        errors.append(f"{rel}: name {frontmatter['name']!r} != filename stem {stem!r}")
    if frontmatter.get("model") and frontmatter["model"] not in allowed_models:
        errors.append(f"{rel}: model {frontmatter['model']!r} not in {sorted(allowed_models)}")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "agent frontmatter and models are well-formed"
else
  fail "agent frontmatter and models are well-formed ($detail)"
fi

# 3. reviewer agent is strictly read-only
detail=$(python3 - "$repo_root" <<'PY'
import os, sys

root = sys.argv[1]
reviewer_path = os.path.join(root, "agents/gem-reviewer.md")
errors = []

if not os.path.isfile(reviewer_path):
    errors.append("agents/gem-reviewer.md missing")
else:
    with open(reviewer_path, encoding="utf-8") as fh:
        content = fh.read()
    parts = content.split("---", 2)
    if len(parts) >= 3:
        frontmatter = parts[1]
        forbidden_tools = {"write_to_file", "replace_file_content", "run_command"}
        for tool in forbidden_tools:
            if tool in frontmatter:
                errors.append(f"gem-reviewer frontmatter includes mutating tool: {tool}")
    else:
        errors.append("gem-reviewer.md has invalid frontmatter structure")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "reviewer agent is strictly read-only"
else
  fail "reviewer agent is strictly read-only ($detail)"
fi

# 4. every skill has valid frontmatter whose name matches its directory
detail=$(python3 - "$repo_root" <<'PY'
import glob, os, re, sys

root = sys.argv[1]
skills_dir = os.path.join(root, "skills")
errors = []

for path in sorted(glob.glob(os.path.join(skills_dir, "*/SKILL.md"))):
    rel = os.path.relpath(path, root)
    parent = os.path.basename(os.path.dirname(path))
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    if not lines or lines[0].strip() != "---":
        errors.append(f"{rel}: missing frontmatter start")
        continue
    frontmatter = {}
    terminated = False
    for line in lines[1:]:
        if line.strip() == "---":
            terminated = True
            break
        match = re.match(r'^([A-Za-z_]+):\s*(.*)$', line)
        if match:
            frontmatter[match.group(1)] = match.group(2).strip()
    if not terminated:
        errors.append(f"{rel}: frontmatter not terminated")
        continue
    for key in ("name", "description"):
        if not frontmatter.get(key):
            errors.append(f"{rel}: missing {key}")
    if frontmatter.get("name") and frontmatter["name"] != parent:
        errors.append(f"{rel}: name {frontmatter['name']!r} != directory {parent!r}")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "skill frontmatter is well-formed"
else
  fail "skill frontmatter is well-formed ($detail)"
fi

# 5. commands and rules are present with required structure
detail=$(python3 - "$repo_root" <<'PY'
import os, sys

root = sys.argv[1]
errors = []

cmd_path = os.path.join(root, "commands/gem.md")
if not os.path.isfile(cmd_path):
    errors.append("commands/gem.md missing")
else:
    with open(cmd_path, encoding="utf-8") as fh:
        text = fh.read()
    if not text.startswith("---") or "description:" not in text:
        errors.append("commands/gem.md missing valid frontmatter")

rules_path = os.path.join(root, "rules/AGENTS.md")
if not os.path.isfile(rules_path):
    errors.append("rules/AGENTS.md missing")
else:
    with open(rules_path, encoding="utf-8") as fh:
        rules_text = fh.read()
    for phrase in ("SELECTIVE ROUTE", "advisor: gem-advisor", "Single Auxiliary Maximum", "Quota Protection"):
        if phrase not in rules_text:
            errors.append(f"rules/AGENTS.md missing required invariant: {phrase!r}")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "commands and rules preserve required invariants"
else
  fail "commands and rules preserve required invariants ($detail)"
fi

# 6. every subagent reference in skills matches a defined agent in agents/
detail=$(python3 - "$repo_root" <<'PY'
import glob, os, re, sys

root = sys.argv[1]
agents_dir = os.path.join(root, "agents")
skills_dir = os.path.join(root, "skills")

defined = {
    os.path.splitext(os.path.basename(p))[0]
    for p in glob.glob(os.path.join(agents_dir, "*.md"))
}

pattern = re.compile(r"TypeName:\s*([^\s,]+)")
errors = []

for dirpath, _, filenames in os.walk(skills_dir):
    for filename in filenames:
        if not filename.endswith(".md"):
            continue
        path = os.path.join(dirpath, filename)
        rel = os.path.relpath(path, root)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for name in pattern.findall(text):
            if name not in defined and name not in {"research", "self"}:
                errors.append(f"{rel}: invokes undefined subagent {name!r}")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "subagent references resolve to defined agents"
else
  fail "subagent references resolve to defined agents ($detail)"
fi

# 7. relative markdown links resolve
detail=$(python3 - "$repo_root" <<'PY'
import os, re, sys

root = sys.argv[1]
link_pattern = re.compile(r'\]\(([^)]+)\)')
errors = []

for dirpath, dirnames, filenames in os.walk(root):
    if ".git" in dirnames:
        dirnames.remove(".git")
    for filename in filenames:
        if not filename.endswith(".md"):
            continue
        path = os.path.join(dirpath, filename)
        rel = os.path.relpath(path, root)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for match in link_pattern.finditer(text):
            target = match.group(1).strip().split()[0] if match.group(1).strip() else ""
            if not target or target.startswith("#"):
                continue
            if target.startswith("http://") or target.startswith("https://") or target.startswith("mailto:"):
                continue
            link_path = target.split("#", 1)[0]
            if not link_path:
                continue
            resolved = os.path.normpath(os.path.join(dirpath, link_path))
            if not os.path.exists(resolved):
                errors.append(f"{rel}: broken link {target}")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "relative markdown links resolve"
else
  fail "relative markdown links resolve ($detail)"
fi

# 8. attribution to Daniel McAteer is present in README.md and ORIGIN.md
detail=$(python3 - "$repo_root" <<'PY'
import os, sys

root = sys.argv[1]
errors = []

for filename in ("README.md", "ORIGIN.md"):
    path = os.path.join(root, filename)
    if not os.path.isfile(path):
        errors.append(f"{filename} missing")
        continue
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    if "Daniel McAteer" not in text:
        errors.append(f"{filename} missing credit to Daniel McAteer")
    if "DannyMac180/sol-advisor" not in text:
        errors.append(f"{filename} missing link to DannyMac180/sol-advisor")

print("; ".join(errors))
PY
)
if [ -z "$detail" ]; then
  ok "Daniel McAteer attribution is present in README.md and ORIGIN.md"
else
  fail "Daniel McAteer attribution is present in README.md and ORIGIN.md ($detail)"
fi

# 9. shell syntax of installer and verification scripts
detail=""
for sh_file in "$repo_root/install.sh" "$repo_root/scripts/verify.sh"; do
  if [ -f "$sh_file" ]; then
    if ! bash -n "$sh_file" 2>/dev/null; then
      detail="${detail}${sh_file}: syntax error; "
    fi
  else
    detail="${detail}${sh_file}: missing; "
  fi
done
if [ -z "$detail" ]; then
  ok "shell scripts have valid bash syntax"
else
  fail "shell scripts have valid bash syntax ($detail)"
fi

# 10. native Antigravity CLI plugin validation
if command -v agy >/dev/null 2>&1; then
  agy_output=$(agy plugin validate "$repo_root" 2>&1) || detail="agy plugin validate failed: $agy_output"
  if [ -z "${detail:-}" ]; then
    ok "agy plugin validate passes natively"
  else
    fail "agy plugin validate passes natively ($detail)"
  fi
else
  ok "agy plugin validate (skipped, agy CLI not found on PATH)"
fi

if [ "$failed" -eq 0 ]; then
  printf 'summary: %d/%d checks passed\n' "$total" "$total"
else
  printf 'summary: %d/%d checks passed, %d failed\n' "$((total - failed))" "$total" "$failed"
fi

exit "$status"

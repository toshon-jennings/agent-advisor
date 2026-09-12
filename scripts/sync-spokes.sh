#!/usr/bin/env bash

# Export the hub's canonical platform trees to their downstream spoke repositories.
#
# Flow is one-directional by design: platforms/<p>/ is the source of truth and the
# spoke is the export target. Nothing in this script reads a spoke and writes the hub.
#
# Fail-closed. Every guard below refuses rather than proceeding on a maybe, because
# the failure mode being defended against is not "the sync errors out" — it is "the
# sync silently overwrites three live plugin repositories with something that does
# not validate", which is invisible until someone tries to use one.
#
# --push is two-phase: every selected platform is fully preflighted before ANY of them
# is written. A refusal in phase 1 means nothing was written anywhere.
#
#   --check   (default)  Validate the hub trees and report drift. Writes nothing.
#   --push               Preflight all, then apply, then re-validate and re-compare in
#                        each spoke. Rolls a spoke back if its post-push check fails.
#
# Exit: 0 success | 1 drift (check only) | 2 validation failed | 3 guard refused
#       | 4 caller error

set -uo pipefail

hub_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
platforms_dir="$hub_root/platforms"

mode=check
only_platform=

usage() {
  sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode=check ;;
    --push) mode=push ;;
    --platform)
      shift
      [ $# -gt 0 ] || { printf 'ERROR: --platform needs a value\n' >&2; exit 4; }
      only_platform=$1
      ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 4 ;;
  esac
  shift
done

# Highest severity seen. A refusal on one platform must never be masked by a later
# platform that happens to be clean.
worst=0
# Platforms actually written, so the final report can never claim "nothing was written"
# when something was.
applied=()       # written AND kept
rolled_back=()   # written then restored
stranded=()      # written, rollback did not fully restore — needs a human

note()  { printf '%s\n' "$*"; }
head2() { printf '\n%s\n%s\n' "$1" "$(printf '%*s' "${#1}" '' | tr ' ' '-')"; }
bad()   { printf 'REFUSED: %s\n' "$*" >&2; }
escalate() { [ "$1" -gt "$worst" ] && worst=$1; return 0; }

# --- manifest parsing --------------------------------------------------------

manifest_value() { sed -n "s/^$2=//p" "$1" | head -1; }
manifest_validators() { sed -n 's/^native_validator=//p' "$1"; }

manifest_paths() {
  sed -n '/^\[paths\]/,$p' "$1" | tail -n +2 \
    | sed 's/[[:space:]]*$//' \
    | grep -v '^[[:space:]]*$' \
    | grep -v '^#'
}

expand_home() {
  case "$1" in
    "~/"*) printf '%s\n' "${HOME}/${1#\~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

normalize_remote() { printf '%s\n' "${1%/}" | sed 's/\.git$//'; }

validator_is_sane() {
  # A native_validator is executed by run_validators and embedded into generated shell
  # and YAML by gen-spoke-checks.sh. Both make it code rather than data, so it gets the
  # same treatment as a managed path: a strict allowlist, checked before anything uses it.
  case $1 in
    '' ) return 1 ;;
    *[!A-Za-z0-9\ ._/=:-]* ) return 1 ;;
  esac
  return 0
}

is_exempt() {
  # True when a path has a component that is exactly .DS_Store, .git or .claude. These
  # are the paths rsync never writes and Guard 5 tolerates, so `git clean` must spare
  # them too. Compared component-by-component: a file literally named
  # "weird\n.claude\nfile" must NOT be classed as exempt.
  local path=$1 part
  local IFS=/
  for part in $path; do
    case "$part" in
      '.DS_Store' | '.git' | '.claude' ) return 0 ;;
    esac
  done
  return 1
}

# --- path containment --------------------------------------------------------
#
# A managed path is attacker-adjacent input even when the "attacker" is a typo: an
# entry of `..` would make the rsync --delete destination the spoke's PARENT. These
# checks run before any path is used for anything.

path_is_sane() {
  # path_is_sane <rel> -> 0 if syntactically safe as a relative, contained path
  local rel=$1 part
  case "$rel" in
    '' | /* | '~'* ) return 1 ;;
  esac
  local IFS=/
  for part in $rel; do
    case "$part" in
      # `.git` is fatal rather than merely unwise: managing it would let a push replace
      # the index and HEAD that rollback itself depends on.
      '' | '.' | '..' | '.git' ) return 1 ;;
    esac
  done
  return 0
}

contained_real() {
  # contained_real <base> <rel> -> prints the physically resolved path, or fails if
  # it escapes <base>. Resolving the PARENT with `pwd -P` is what catches a symlinked
  # directory component; the leaf is checked separately by the caller.
  local base=$1 rel=$2 parent leaf resolved base_real
  base_real=$(CDPATH= cd -- "$base" 2>/dev/null && pwd -P) || return 1
  parent=$(dirname -- "$base_real/$rel")
  leaf=$(basename -- "$rel")
  parent=$(CDPATH= cd -- "$parent" 2>/dev/null && pwd -P) || return 1
  resolved="$parent/$leaf"
  case "$resolved" in
    "$base_real"/*) printf '%s\n' "$resolved"; return 0 ;;
    *) return 1 ;;
  esac
}

# --- validation --------------------------------------------------------------

run_validators() {
  # run_validators <tree-root> <manifest> <label>
  local tree=$1 manifest=$2 label=$3 rc=0 line out vrc
  local ran=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    ran=1
    out=$( cd "$tree" && sh -c "$line" 2>&1 ); vrc=$?
    if [ "$vrc" -eq 0 ]; then
      note "  ok   [$label] $line"
    else
      note "  FAIL [$label] $line"
      printf '%s\n' "$out" | sed 's/^/         /' | tail -20
      rc=1
    fi
  done <<EOF
$(manifest_validators "$manifest")
EOF
  # A manifest with no validator would make every push unvalidated while still
  # reporting success. Treat it as a failure, not as "nothing to check".
  [ "$ran" -eq 1 ] || { note "  FAIL [$label] manifest declares no native_validator"; rc=1; }
  return $rc
}

# --- drift -------------------------------------------------------------------

compute_drift() {
  # compute_drift <hub_tree> <spoke> <paths> <outfile> -> 0 in sync, 1 drift
  local hub_tree=$1 spoke=$2 paths=$3 out=$4 rel drift=0
  : >"$out"
  while IFS= read -r rel; do
    if [ ! -e "$spoke/$rel" ]; then
      printf 'NEW      %s (absent in spoke)\n' "$rel" >>"$out"
      drift=1
      continue
    fi
    if ! diff -ruN -x '.git' -x '.DS_Store' -x '.claude' \
         "$spoke/$rel" "$hub_tree/$rel" >>"$out" 2>&1; then
      drift=1
    fi
  done <<EOF
$paths
EOF
  return $drift
}

# --- phase 1: preflight ------------------------------------------------------
#
# Every guard for every selected platform runs here, before anything is written.

preflight_platform() {
  local platform=$1
  local manifest="$platforms_dir/$platform/spoke.manifest"
  local hub_tree="$platforms_dir/$platform"

  head2 "$platform"

  [ -f "$manifest" ] || { bad "$platform: no spoke.manifest"; escalate 3; return 1; }

  local spoke_raw spoke pretty expected_remote
  spoke_raw=$(manifest_value "$manifest" spoke_path)
  pretty=$(manifest_value "$manifest" platform_name)
  expected_remote=$(manifest_value "$manifest" spoke_remote)
  [ -n "$spoke_raw" ] || { bad "$platform: manifest has no spoke_path"; escalate 3; return 1; }
  # An empty expected remote would silently disable the wrong-repo guard.
  [ -n "$expected_remote" ] || { bad "$platform: manifest has no spoke_remote"; escalate 3; return 1; }
  spoke=$(expand_home "$spoke_raw")

  note "  platform : ${pretty:-$platform}"
  note "  hub tree : platforms/$platform"
  note "  spoke    : $spoke"

  local paths
  paths=$(manifest_paths "$manifest")
  [ -n "$paths" ] || { bad "$platform: manifest lists no managed paths"; escalate 3; return 1; }

  # Guard 1 — the spoke must be the repository this manifest names.
  [ -d "$spoke" ] || { bad "$platform: spoke directory does not exist: $spoke"; escalate 3; return 1; }
  if ! git -C "$spoke" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    bad "$platform: spoke is not a git work tree: $spoke"; escalate 3; return 1
  fi
  local actual_remote grc
  actual_remote=$(git -C "$spoke" remote get-url origin 2>/dev/null); grc=$?
  if [ "$grc" -ne 0 ]; then
    bad "$platform: could not read origin in $spoke (git exit $grc)"; escalate 3; return 1
  fi
  if [ "$(normalize_remote "$actual_remote")" != "$(normalize_remote "$expected_remote")" ]; then
    bad "$platform: spoke origin is '$actual_remote', manifest expects '$expected_remote'"
    escalate 3; return 1
  fi

  # Guard 2 — every managed path must be syntactically safe, present in the hub,
  # contained in both trees, not a symlink, and the same node type on both sides.
  local rel hub_real spoke_real bad_path=0
  while IFS= read -r rel; do
    if ! path_is_sane "$rel"; then
      bad "$platform: unsafe managed path in manifest: '$rel'"; bad_path=1; continue
    fi
    if [ ! -e "$hub_tree/$rel" ]; then
      bad "$platform: managed path absent from hub: $rel"; bad_path=1; continue
    fi
    if [ -L "$hub_tree/$rel" ]; then
      bad "$platform: managed path is a symlink in the hub: $rel"; bad_path=1; continue
    fi
    if ! hub_real=$(contained_real "$hub_tree" "$rel"); then
      bad "$platform: managed path escapes the hub tree: $rel"; bad_path=1; continue
    fi
    # The destination must be validated whether or not the leaf exists: an absent leaf
    # under a SYMLINKED ANCESTOR still redirects the copy. contained_real resolves the
    # parent chain physically, so it is the check that matters, and it runs either way.
    if [ -L "$spoke/$rel" ]; then
      bad "$platform: managed path is a symlink in the spoke: $rel"; bad_path=1; continue
    fi
    if ! spoke_real=$(contained_real "$spoke" "$rel"); then
      bad "$platform: managed path or its parent escapes the spoke tree: $rel"; bad_path=1; continue
    fi
    if [ -e "$spoke/$rel" ]; then
      # A file in the hub over a directory in the spoke makes `cp` write INSIDE the
      # directory, leaving drift behind a successful-looking push.
      if { [ -d "$hub_tree/$rel" ] && [ ! -d "$spoke/$rel" ]; } || \
         { [ ! -d "$hub_tree/$rel" ] && [ -d "$spoke/$rel" ]; }; then
        bad "$platform: node type differs between hub and spoke: $rel"; bad_path=1; continue
      fi
    fi
  done <<EOF
$paths
EOF
  [ "$bad_path" -eq 0 ] || { escalate 3; return 1; }

  # Guard 3 — the hub tree must pass the platform's own native validators before it
  # is allowed anywhere near the spoke.
  # A bash script invoked with `sh` is undetectable on macOS, where /bin/sh IS bash, and
  # fails on Linux, where it is dash. CI caught exactly this; a local run never could.
  # Checking the declared interpreter against the script's shebang catches it anywhere.
  local vline script shebang
  while IFS= read -r vline; do
    if ! validator_is_sane "$vline"; then
      bad "$platform: native_validator is not a plain command: $vline"
      printf '           Allowed: letters, digits, space . _ / = : -\n' >&2
      printf '           It is executed and also embedded into generated code, so a quote\n' >&2
      printf '           or a semicolon here becomes arbitrary execution at commit time.\n' >&2
      escalate 3; return 1
    fi
    case "$vline" in
      "sh "*)
        script=${vline#sh }
        script=${script%% *}
        if [ -f "$hub_tree/$script" ]; then
          shebang=$(head -1 "$hub_tree/$script")
          case "$shebang" in
            *bash*)
              bad "$platform: manifest runs '$script' with sh, but its shebang is '$shebang'."
              printf "           /bin/sh is bash on macOS and dash on Linux, so this passes\n" >&2
              printf "           locally and fails in CI. Declare it as 'bash %s'.\n" "$script" >&2
              escalate 3; return 1
              ;;
          esac
        fi
        ;;
    esac
  done <<EOF
$(manifest_validators "$manifest")
EOF

  note "  validating hub tree:"
  if ! run_validators "$hub_tree" "$manifest" hub; then
    bad "$platform: hub tree fails its native validator; nothing was touched"
    escalate 2; return 1
  fi

  # Drift report (both modes).
  local tmp
  tmp=$(mktemp) || { bad "$platform: could not create a temp file"; escalate 3; return 1; }
  if compute_drift "$hub_tree" "$spoke" "$paths" "$tmp"; then
    note "  in sync  : spoke already matches the hub"
    rm -f "$tmp"
    [ "$mode" = push ] && note "  push     : nothing to apply (idempotent no-op)"
    return 1   # nothing to do; not an error
  fi

  note "  drift    : spoke differs from the hub"
  note "  --- diff (spoke -> hub) ---"
  sed 's/^/  /' "$tmp" | head -400
  local lines; lines=$(wc -l <"$tmp")
  [ "$lines" -gt 400 ] && note "  ... $((lines - 400)) more diff lines suppressed"
  note "  --- end diff ---"
  rm -f "$tmp"

  if [ "$mode" = check ]; then
    escalate 1
    return 1
  fi

  # Guard 4 — the spoke must be completely clean. This is what makes the post-push
  # rollback provably lossless, so it has no escape hatch.
  local dirty
  dirty=$(git -C "$spoke" status --porcelain 2>/dev/null); grc=$?
  if [ "$grc" -ne 0 ]; then
    bad "$platform: could not read git status in $spoke (git exit $grc)"; escalate 3; return 1
  fi
  if [ -n "$dirty" ]; then
    bad "$platform: spoke has uncommitted changes; refusing to overwrite them."
    printf '%s\n' "$dirty" | sed 's/^/           /' >&2
    printf '           Commit or stash them in %s, then re-run --push.\n' "$spoke" >&2
    printf '           (The clean-tree requirement is what makes rollback lossless.)\n' >&2
    escalate 3; return 1
  fi

  # Guard 5 — git-ignored files inside a managed directory are invisible to Guard 4
  # but ARE deleted by `rsync --delete`, and `git checkout` cannot restore them.
  # They are the one way this push could destroy something unrecoverably.
  # Pathspecs are passed literally, one at a time, so a path containing a glob
  # character cannot widen or narrow the query. git's exit status is checked: a failed
  # query returning empty must not read as "no ignored files".
  local ignored="" irc entry
  while IFS= read -r rel; do
    # NUL-delimited end to end: a filename containing a newline must not be split into
    # pieces that happen to look exempt. Components are compared exactly, never by regex
    # over concatenated text.
    git -C "$spoke" ls-files --others --ignored --exclude-standard -z \
      -- ":(literal)$rel" >"$scratch/ignored.bin" 2>/dev/null; irc=$?
    if [ "$irc" -ne 0 ]; then
      bad "$platform: could not list ignored files under '$rel' in $spoke (git exit $irc)"
      escalate 3; return 1
    fi
    while IFS= read -r -d '' entry; do
      is_exempt "$entry" || ignored="${ignored}  ${entry}"$'\n'
    done <"$scratch/ignored.bin"
  done <<EOF
$paths
EOF
  if [ -n "$ignored" ]; then
    bad "$platform: git-ignored files live inside managed paths and rsync --delete would"
    printf '           remove them with no way to restore. Move or commit them first:\n' >&2
    printf '%s\n' "$ignored" | sed 's/^/           /' >&2
    escalate 3; return 1
  fi

  # Stash what phase 2 needs, so it re-derives nothing.
  # Written to a temp name and moved into place, so phase 2 can never observe a
  # partially written path list and sync a prefix of it.
  if ! printf '%s\n' "$spoke" >"$scratch/$platform.spoke.tmp" \
     || ! mv -f "$scratch/$platform.spoke.tmp" "$scratch/$platform.spoke" \
     || ! printf '%s\n' "$paths" >"$scratch/$platform.paths.tmp" \
     || ! mv -f "$scratch/$platform.paths.tmp" "$scratch/$platform.paths"; then
    bad "$platform: could not record preflight state"
    escalate 3; return 1
  fi
  # Cheap integrity check: the cached list must round-trip to what we just validated.
  if [ "$(cat "$scratch/$platform.paths")" != "$paths" ]; then
    bad "$platform: preflight state did not round-trip; refusing to apply"
    escalate 3; return 1
  fi
  return 0
}

# --- phase 1b: re-validate every ready platform before the FIRST mutation --------
#
# Preflight ran earlier and a path replaced by a symlink in between would redirect
# `rsync --delete`. Running this per platform inside the apply loop would break the
# all-or-nothing boundary: platform 1 could already be written and kept when platform 3
# refused. So it is a separate sweep across every ready platform.
#
# This narrows the TOCTOU window; it does not close it. See HANDOFF.md.

revalidate_platform() {
  local platform=$1
  local hub_tree="$platforms_dir/$platform"
  local spoke paths rel
  spoke=$(cat "$scratch/$platform.spoke" 2>/dev/null) || spoke=""
  paths=$(cat "$scratch/$platform.paths" 2>/dev/null) || paths=""
  if [ -z "$spoke" ] || [ -z "$paths" ] || [ ! -d "$spoke" ]; then
    bad "$platform: preflight state is missing or unreadable; refusing to apply"
    return 1
  fi
  while IFS= read -r rel; do
    if ! path_is_sane "$rel" \
       || [ -L "$hub_tree/$rel" ] || [ -L "$spoke/$rel" ] \
       || ! contained_real "$hub_tree" "$rel" >/dev/null \
       || ! contained_real "$spoke" "$rel" >/dev/null; then
      bad "$platform: '$rel' failed re-validation at apply time"
      return 1
    fi
    # A destination with more than one hard link would be mutated in place by `cp -p`,
    # changing an alias outside the managed path. Copy-then-move avoids that, but a
    # directory full of them is not worth guessing about — refuse the file case here.
    if [ -f "$spoke/$rel" ] && [ ! -d "$spoke/$rel" ]; then
      local links
      links=$(stat -f '%l' "$spoke/$rel" 2>/dev/null || stat -c '%h' "$spoke/$rel" 2>/dev/null || echo 1)
      if [ "${links:-1}" -gt 1 ]; then
        bad "$platform: '$rel' has $links hard links in the spoke; refusing to overwrite"
        return 1
      fi
    fi
  done <<EOF
$paths
EOF
  return 0
}

# --- phase 2: apply ----------------------------------------------------------

apply_platform() {
  local platform=$1
  local manifest="$platforms_dir/$platform/spoke.manifest"
  local hub_tree="$platforms_dir/$platform"
  local spoke paths rel
  spoke=$(cat "$scratch/$platform.spoke" 2>/dev/null) || spoke=""
  paths=$(cat "$scratch/$platform.paths" 2>/dev/null) || paths=""
  # An empty $spoke would make every destination "/$rel" — an absolute write outside
  # the spoke entirely. Refuse rather than proceed on a failed read.
  if [ -z "$spoke" ] || [ -z "$paths" ] || [ ! -d "$spoke" ]; then
    bad "$platform: preflight state is missing or unreadable; refusing to apply"
    escalate 3; return 1
  fi

  head2 "$platform — applying"

  local apply_failed=0
  while IFS= read -r rel; do
    if [ -d "$hub_tree/$rel" ]; then
      rsync -a --delete --exclude '.git' --exclude '.DS_Store' --exclude '.claude' \
        "$hub_tree/$rel/" "$spoke/$rel/" || apply_failed=1
    else
      # copy-then-move: replaces the directory entry rather than writing through the
      # existing inode, so any other link to the old file is left untouched.
      #
      # The temporary is created by mktemp in the destination directory, not at a
      # predictable name: a guessable `$rel.sync-tmp.$$` could be pre-created as a
      # symlink, and `cp` would follow it and overwrite whatever it pointed at.
      local dest_dir tmp_dest
      dest_dir=$(dirname -- "$spoke/$rel")
      if tmp_dest=$(mktemp "$dest_dir/.sync-XXXXXXXX" 2>/dev/null) \
         && [ ! -L "$tmp_dest" ] \
         && cp -p "$hub_tree/$rel" "$tmp_dest" 2>/dev/null \
         && mv -f "$tmp_dest" "$spoke/$rel" 2>/dev/null; then
        :
      else
        [ -n "${tmp_dest:-}" ] && rm -f "$tmp_dest" 2>/dev/null
        apply_failed=1
      fi
    fi
    note "    wrote  $rel"
  done <<EOF
$paths
EOF

  local post_ok=1
  [ "$apply_failed" -eq 0 ] || { note "  a copy command failed"; post_ok=0; }

  if [ "$post_ok" -eq 1 ]; then
    note "  validating spoke after push:"
    run_validators "$spoke" "$manifest" spoke || post_ok=0
  fi

  # A validator can pass while drift remains. Re-run the exact comparison that
  # decided there was drift in the first place; only that proves synchronization.
  if [ "$post_ok" -eq 1 ]; then
    local tmp; tmp=$(mktemp)
    if compute_drift "$hub_tree" "$spoke" "$paths" "$tmp"; then
      note "  ok   [spoke] post-push diff is empty"
    else
      note "  FAIL [spoke] drift remains after applying:"
      sed 's/^/         /' "$tmp" | head -40
      post_ok=0
    fi
    rm -f "$tmp"
  fi

  if [ "$post_ok" -eq 1 ]; then
    applied+=("$platform")
    # The hook was just written into the spoke; leaving it inert would be half a job.
    if [ -x "$spoke/scripts/hooks/pre-commit" ] &&
       [ "$(git -C "$spoke" config core.hooksPath 2>/dev/null)" != "scripts/hooks" ]; then
      git -C "$spoke" config core.hooksPath scripts/hooks &&
        note "  hooks    : enabled core.hooksPath=scripts/hooks in the spoke"
    fi
    note "  pushed   : $spoke updated, validated, and verified in sync"
    return 0
  fi

  bad "$platform: spoke failed its post-push checks. Rolling back."
  # Safe because Guards 4 and 5 proved the tree was clean AND held no ignored files:
  # checkout restores the committed state, clean removes only what this push added,
  # inside managed paths only.
  local rb=0
  while IFS= read -r rel; do
    # Scoped to managed paths only. A repo-wide `checkout -- .` would also discard any
    # change made outside them between preflight and now.
    #
    # Failure is NOT treated as a rollback failure: a path the push newly created has no
    # index entry, so checkout errors with "did not match any file(s) known to git" while
    # `clean` below removes it completely. The verification at the end is authoritative;
    # this would otherwise report NEEDS ATTENTION on a perfectly clean rollback.
    git -C "$spoke" checkout -- ":(literal)$rel" >/dev/null 2>&1 || true
    # -x removes ignored files too. That is safe *here specifically* because Guard 5
    # proved no ignored file existed under this path before the push, so any ignored
    # file present now was created by the push — and plain `git clean -fd` would strand
    # it where neither `git status` nor the caller would ever see it.
    # Same exclusions Guard 5 tolerates and rsync never writes. Without them, `-x`
    # would delete spoke-local .claude/ and .DS_Store that the push did not create —
    # which is the opposite of lossless.
    git -C "$spoke" clean -fdxq -e '.DS_Store' -e '.claude' -- ":(literal)$rel" \
      >/dev/null 2>&1 || rb=1
  done <<EOF
$paths
EOF

  # Verify restoration against BOTH tracked and ignored state; plain `git status`
  # cannot see an ignored leftover.
  local after arc leftover entry lrc=0
  after=$(git -C "$spoke" status --porcelain 2>/dev/null); arc=$?
  leftover=""
  while IFS= read -r rel; do
    git -C "$spoke" ls-files --others --ignored --exclude-standard -z \
      -- ":(literal)$rel" >"$scratch/leftover.bin" 2>/dev/null || lrc=1
    while IFS= read -r -d '' entry; do
      is_exempt "$entry" || leftover="${leftover}  ${entry}"$'\n'
    done <"$scratch/leftover.bin"
  done <<EOF
$paths
EOF

  if [ "$rb" -eq 0 ] && [ "$arc" -eq 0 ] && [ "$lrc" -eq 0 ] \
     && [ -z "$after" ] && [ -z "$leftover" ]; then
    rolled_back+=("$platform")
    note "  rolled back: $spoke restored to its committed state (tracked and ignored)"
  else
    stranded+=("$platform")
    bad "$platform: ROLLBACK INCOMPLETE — inspect $spoke by hand before doing anything else"
    [ -n "$after" ] && printf '%s\n' "$after" | sed 's/^/           /' >&2
    [ -n "$leftover" ] && printf '           ignored leftovers: %s\n' "$leftover" >&2
  fi
  escalate 2
  return 1
}

# --- main --------------------------------------------------------------------

note "agent-advisor sync-spokes  (mode: $mode)"
note "hub: $hub_root"

for required in rsync git diff; do
  command -v "$required" >/dev/null 2>&1 || {
    printf 'ERROR: required command unavailable: %s\n' "$required" >&2; exit 4; }
done

# `core.hooksPath` is local git config and does not survive a clone, so a fresh checkout
# of the hub has no pre-commit hook until something sets it. Set it here: this script is
# the thing anyone working on the hub runs first, so nobody has to be told.
if git -C "$hub_root" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
   [ -x "$hub_root/scripts/hooks/pre-commit" ] &&
   [ "$(git -C "$hub_root" config core.hooksPath 2>/dev/null)" != "scripts/hooks" ]; then
  git -C "$hub_root" config core.hooksPath scripts/hooks &&
    note "enabled the hub's pre-commit hook (core.hooksPath=scripts/hooks)"
fi

scratch=$(mktemp -d) || { printf 'ERROR: could not create a temp dir\n' >&2; exit 4; }
trap 'rm -rf "$scratch"' EXIT
# Signal handlers must terminate, not merely tidy up: without the explicit exit a
# cancellation during the apply loop would be swallowed and copying would continue.
trap 'rm -rf "$scratch"; printf "\ninterrupted\n" >&2; exit 130' HUP INT TERM

selected=()
for dir in "$platforms_dir"/*/; do
  [ -d "$dir" ] || continue
  platform=$(basename "$dir")
  if [ -n "$only_platform" ] && [ "$platform" != "$only_platform" ]; then continue; fi
  selected+=("$platform")
done

if [ "${#selected[@]}" -eq 0 ]; then
  printf 'ERROR: no platform matched%s\n' "${only_platform:+: $only_platform}" >&2
  exit 4
fi

# Phase 1 — preflight everything.
ready=()
for platform in "${selected[@]}"; do  # non-empty: guarded above
  if preflight_platform "$platform"; then ready+=("$platform"); fi
done

# Phase 2 — apply, but only if every selected platform preflighted without a refusal.
if [ "$mode" = push ]; then
  if [ "$worst" -ne 0 ]; then
    printf '\n'
    note "HALTED: a platform refused during preflight, so nothing was written anywhere."
    note "        Fix the refusal above and re-run; --push is all-or-nothing across"
    note "        the selected platforms by design."
  elif [ "${#ready[@]}" -gt 0 ]; then
    # Guarded: bash 3.2 (macOS) treats "${arr[@]}" on an empty array as an unbound
    # variable under `set -u`, which would fail the idempotent no-op path.
    revalidate_failed=0
    for platform in "${ready[@]}"; do
      revalidate_platform "$platform" || revalidate_failed=1
    done
    if [ "$revalidate_failed" -ne 0 ]; then
      escalate 3
      printf '\n'
      note "HALTED: a platform failed re-validation just before the first write, so"
      note "        nothing was written anywhere."
    else
      for platform in "${ready[@]}"; do
        apply_platform "$platform" || true
      done
    fi
  fi
fi

printf '\n'
if [ "${#applied[@]}" -gt 0 ]; then
  note "WRITTEN AND KEPT: ${applied[*]}"
  note "         Review and commit in each spoke; this script never commits for you."
fi
if [ "${#rolled_back[@]}" -gt 0 ]; then
  note "ROLLED BACK    : ${rolled_back[*]} (restored to committed state)"
fi
if [ "${#stranded[@]}" -gt 0 ]; then
  note "NEEDS ATTENTION: ${stranded[*]} — rollback did not fully restore; inspect by hand"
fi
case "$worst" in
  0) if [ "${#applied[@]}" -gt 0 ]; then
       note "RESULT: pushed and verified in sync"
     else
       note "RESULT: all platforms in sync and valid"
     fi ;;
  1) note "RESULT: drift detected. Re-run with --push to export the hub." ;;
  2) if [ "${#stranded[@]}" -gt 0 ]; then
       note "RESULT: a validation failed after applying AND rollback was incomplete."
     elif [ "${#rolled_back[@]}" -gt 0 ] && [ "${#applied[@]}" -gt 0 ]; then
       # Mixed: some platforms were kept, others rolled back. Neither blanket sentence
       # is true, so defer to the explicit outcome lines rather than summarising wrongly.
       note "RESULT: mixed. Some spokes were updated and kept, others were rolled back."
       note "        The outcome lines above are authoritative; this line is not a summary."
     elif [ "${#rolled_back[@]}" -gt 0 ]; then
       note "RESULT: a validation failed after applying; every affected spoke was rolled"
       note "        back to its committed state."
     else
       note "RESULT: a validation failed. Nothing was written."
     fi ;;
  3) if [ "${#applied[@]}" -gt 0 ] || [ "${#rolled_back[@]}" -gt 0 ] \
        || [ "${#stranded[@]}" -gt 0 ]; then
       # Reachable when an earlier platform was applied and a later one then refused at
       # apply time. Never claim no writes once mutation has begun.
       note "RESULT: a guard refused, but writing had already begun. See the outcome"
       note "        lines above for exactly which spokes were touched."
     else
       note "RESULT: a guard refused. Nothing was written."
     fi ;;
esac
exit "$worst"

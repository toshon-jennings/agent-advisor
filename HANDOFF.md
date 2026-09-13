# HANDOFF — agent-advisor

**Objective:** establish `~/agent-advisor` as the single upstream source of truth that
governs, validates, and synchronizes the three selective-routing spokes — Codex
(`~/sol-advisor-portable`), Claude Code (`~/claude-advisor`), and Antigravity
(`~/gem-advisor`).

**Standing invariant:** never edit a spoke directly. All changes originate in
`platforms/<p>/` and export outward via `scripts/sync-spokes.sh`.

Last updated: 2026-09-12.

## Milestone 1 — Orientation and inspection

- [x] Inspect `~/sol-advisor-portable` — structure, `.codex-plugin/plugin.json`, three
      agent TOMLs, `install.sh`, `UPSTREAM.lock`, thin chair alias skills
- [x] Inspect `~/claude-advisor` — marketplace + plugin manifests, four agent
      definitions, two chair skills, `review-codex.sh`, `scripts/verify.sh`
- [x] Inspect `~/gem-advisor` — root `plugin.json`, three agent definitions, two tier
      skills, `commands/gem.md`, `rules/AGENTS.md`, `install.sh`
- [x] Confirm native validator surfaces: `claude plugin validate` and `agy plugin
      validate` exist; **`codex plugin validate` does not** — Codex's native check is the
      repo's own `plugins/sol-advisor/scripts/verify.sh`
- [x] `SUMMARY.md`, `HANDOFF.md`, `ORIGIN.md` created

## Milestone 2 — Canonical structure

- [x] `specs/selective-route.md`, `specs/role-contracts.md`, `specs/worker-packet.md`,
      `specs/reviewer-verdict.md`, `specs/README.md`
- [x] `platforms/{codex,claude,antigravity}/` seeded from the spokes (one-time import;
      read-only on the spokes)
- [x] Each `platforms/<p>/` mirrors its spoke root exactly, so every native validator
      runs in place inside the hub

## Milestone 3 — Sync tooling

- [x] `scripts/sync-spokes.sh` with `--check` (default) and `--push`, plus `--platform`
- [x] `spoke.manifest` per platform: spoke path, expected remote, native validators,
      managed paths
- [x] Guards verified against a synthetic hub/spoke pair, not the live repos:

      | Scenario | Result | Exit |
      |---|---|---|
      | push, clean spoke, valid hub | applied, post-validated | 0 |
      | re-push with no drift | idempotent no-op | 0 |
      | post-push validator fails | rolled back to committed state, tree clean | 2 |
      | spoke has uncommitted changes | refused, nothing written | 3 |
      | spoke `origin` ≠ manifest | refused, nothing written | 3 |
      | managed path absent from hub | refused, spoke intact | 3 |
      | drift, `--check` | reported, nothing written | 1 |
      | hub fails its native validator | refused before the spoke is touched | 2 |
      | unknown flag / no platform match | caller error | 4 |

- [x] Confirmed all three spokes byte-unchanged after the full test pass

## Milestone 4 — Documentation

- [x] `README.md` — the one-model/three-harness rationale
- [x] Comparison matrix: chairs and floors, lane pins, isolation enforcement,
      **pin verifiability**, **quota protection**

## Open items — for the next session

### 1. RESOLVED — the Codex validator failure

`sh plugins/sol-advisor/scripts/verify.sh` had failed since `d7e56c8` ("publish Sol
Advisor V2 upgrades"), which rewrote `README.md` without updating the checks guarding it.
Four causes, all fixed in the hub and exported:

- **Two were line-wrapping only.** The validator greps hard-wrapped prose for literal
  phrases, so a reflow can split a required phrase across a newline where `grep` can never
  match it. `need to select or manage a lane` and
  `Luna / Max or Terra / High access is needed only when` were both present and correct,
  merely straddling a break. Rewrapped; no wording changed.
- **Two were real regressions.** The V2 rewrite dropped the statements that the primary
  orchestrator owns architecture, verification, escalation and acceptance, and that
  auxiliary work substitutes for primary work rather than duplicating it. ("One auxiliary
  is the default maximum" is a count limit, not the substitution rule.) Restored.
- **Three checks demanded the upstream author's first-person newsletter pitch** — "I write
  Attention Heads… Subscribe to get new posts to your inbox" plus two campaign-tagged
  links. Those cannot be satisfied honestly in a fork maintained by someone else; the
  sentence would assert authorship that is not ours. Removed, with a comment recording
  why. McAteer attribution remains in the README prose and LICENSE.

`verify.sh` now exits 0 in both the hub tree and the spoke. `fork_version` 2.0.0 → 2.0.1.

**Latent fragility worth knowing:** this validator greps hard-wrapped prose for literal
phrases, so any future reflow of `platforms/codex/README.md` can break it again with no
content change at all. Run `--check` after editing that file.

### 2. RESOLVED — the Codex spoke's uncommitted work

Committed as `b288455` (PORTABLE.md and install.sh describing the three-advisor aliases,
plus the missing MISTAKES.md ledger).

A second, larger problem surfaced while clearing it: **none of the three spokes tracked
`SUMMARY.md` or `HANDOFF.md`.** The global gitignore at `~/.config/git/ignore` excludes
both names, so the files sat on disk, invisible to `git status`, unrecoverable if lost —
the same defect the round-1 review caught in this hub. All three spokes now track them,
and each spoke's `.gitignore` is hub-managed and carries the negation so it cannot recur.
`.claude/` (taste-signal state) is ignored in all three for the same reason: left
untracked it accumulates and permanently blocks `--push` via Guard 4.

This is exactly the class of problem the hub exists to catch — it was invisible in three
separate repos until one fail-closed guard refused to write into them.

### 3. A licence/origin inconsistency in the Claude spoke — flagged, not changed

`platforms/claude/LICENSE` states that "All code, agent definitions, and prose in this
repository are newly written for Claude." `platforms/claude/ORIGIN.md` states the opposite
and more precisely: an adaptation, with 29 of 69 workflow sentences at least 70% similar
to the original, some identical.

`ORIGIN.md` is the accurate one. The LICENSE sentence overstates originality.

**Resolved 2026-09-12.** Toshon directed the correction ("Make it truthful"). The two
false sentences — "independent Claude Code implementation" and "All code, agent
definitions, and prose in this repository are newly written for Claude" — were replaced in
`platforms/claude/LICENSE` with an accurate statement: an adaptation, substantial derived
prose including identical sentences, no file copied, new work named specifically, and
`ORIGIN.md` declared authoritative where the two appear to disagree.

- [x] Corrected in the hub and exported with `./scripts/sync-spokes.sh --push --platform claude`

**This was the first real push the tooling has performed.** It behaved as designed:
validated the hub tree, reported the diff (one file, one hunk), applied, re-ran both native
validators in the spoke, confirmed the post-push diff was empty, and reported
`WRITTEN AND KEPT: claude`. `git diff --stat` in the spoke shows exactly `LICENSE | 18 +++--`
and nothing else. The change is uncommitted in the spoke, which is correct — the script
never commits.

### 4. Not yet done

- [ ] No git remote on the hub; nothing committed yet beyond the working tree
- [ ] `specs/` is not machine-checked against the platform implementations — the specs
      are a human-readable contract by design (see `specs/README.md`), but a drift check
      for the *claims in the comparison matrix* (lane pins, tool lists) would be cheap
      and would catch a spoke silently changing a model pin

## Milestone 5 — Independent review and corrections

Review lane: `reviewer-codex`, out-of-process, cross-vendor. Realized header confirmed
`model: gpt-5.6-sol`, `sandbox: read-only`, `reasoning effort: high` — matching the pin.

First two invocations failed on Codex quota exhaustion (exit 3). No failover was taken;
the user chose to wait for the quota reset and rerun the declared lane. The rerun produced
a full verdict but the wrapper rejected the block as malformed (exit 5) because the
reviewer wrote `FINDINGS:` as a heading over a numbered list rather than inline.

**VERDICT: fix-first**, 7 findings. All 7 were independently confirmed against the files
before acting. All 7 are now corrected:

- [x] **F1 — managed paths could escape the spoke.** `[paths]` entries took no validation:
      `..` would have made the `rsync --delete` destination the spoke's *parent*. Added
      `path_is_sane` (rejects absolute, `.`, `..`, `~`, empty components) plus
      `contained_real` physical-containment checks, symlink rejection on both sides, and
      node-type matching. Also now requires a non-empty `spoke_remote` and at least one
      `native_validator` — both previously fail-open.
- [x] **F2 — clean-tree guard could fail open, rollback not provably lossless.** Every
      `git` invocation now has its exit status checked. Added Guard 5: git-ignored files
      inside managed paths are invisible to `git status` but *are* deleted by
      `rsync --delete`, and `git checkout` cannot restore them — the one unrecoverable
      path. Now refuses.
- [x] **F3 — all-platform push was only per-platform fail-closed.** Was: platform 1 could
      be written before platform 3 refused, while the summary said "Nothing was written."
      Now two-phase — every selected platform preflights before *any* is applied — plus a
      `WRITTEN:` line so the result can never misreport.
- [x] **F4 — success did not prove synchronization.** A passing validator could coexist
      with remaining drift. The exact drift comparison is now re-run after applying;
      remaining drift triggers rollback.
- [x] **F5 — required deliverables were git-ignored.** `~/.config/git/ignore` excludes
      `SUMMARY.md` and `HANDOFF.md` globally, so four required files were invisible to
      `git status` and would never have been committed. `.gitignore` now negates them;
      confirmed staged.
- [x] **F6 — the isolation matrix overstated enforcement.** Corrected in `README.md` and
      `specs/role-contracts.md`: the Codex implementers have **no** structural restriction
      on onward delegation (it is `developer_instructions` prose), and Antigravity's
      `enable_subagent_tools: false` / `enable_write_tools: false` appear only in agent
      prose bodies, never in frontmatter — the real mechanism there is the `tools:`
      allowlist omission.
- [x] **F7 — the canonical failover contract conflicts with Antigravity.** Recorded rather
      than smoothed over at the time; resolved later — see item 5 below.

Regression found and fixed during re-verification (not reviewer-reported): the two-phase
rewrite expanded `"${ready[@]}"` on a possibly-empty array, which under `set -u` in
bash 3.2 — the macOS default — is an unbound-variable error. It fired on the idempotent
no-op path, the most common real invocation. Guarded by a count check.

Post-correction guard matrix, all re-verified against a synthetic fixture:

| Scenario | Result | Exit |
|---|---|---|
| `..` / `.` / absolute / embedded traversal / `~` in `[paths]` | refused, spoke parent intact | 3 |
| symlinked managed path (hub or spoke) | refused | 3 |
| git-ignored file inside a managed dir | refused, file survived | 3 |
| manifest with no `native_validator` | refused | 2 |
| manifest with no `spoke_remote` | refused | 3 |
| two platforms, second refuses | **nothing written anywhere** | 3 |
| push, clean spoke, valid hub | applied, validated, drift re-checked empty | 0 |
| re-push with no drift | idempotent no-op | 0 |
| post-push validator fails | rolled back to committed state, tree clean | 2 |
| spoke dirty / wrong origin / path absent from hub | refused, nothing written | 3 |

- [ ] **A new fresh review is required and has not been run.** Any correction invalidates
      the prior verdict. The next review must use the same declared lane
      (`reviewer-codex`) and a prompt that requests `FINDINGS:` inline so the wrapper
      accepts the block.

## Milestone 6 — Second review round

Same lane, `reviewer-codex`, cross-vendor. Realized header again `model: gpt-5.6-sol`,
`sandbox: read-only`, `reasoning effort: high`. This time the block was well-formed
(exit 0) after the prompt was changed to require `FINDINGS:` inline.

**VERDICT: fix-first**, 8 findings. It confirmed round 1's fixes were materially present,
then found narrower edge cases. All 8 confirmed and corrected:

- [x] **R2-1 — destination checks skipped when the leaf did not exist.** The spoke-side
      symlink and containment checks sat inside `if [ -e "$spoke/$rel" ]`, so a *new*
      managed path under a symlinked ancestor was never validated. Moved outside the
      existence test.
- [x] **R2-2 — TOCTOU between preflight and apply.** Containment is now re-validated
      immediately before mutation. This narrows the window rather than closing it; see
      blind spots.
- [x] **R2-3 — Guard 5 ignored git's exit status and split/globbed its pathspec.** Now
      queries one path at a time with `-- ":(literal)$rel"` and refuses on git failure.
      A managed path containing a glob character is now handled correctly (verified).
- [x] **R2-4 — unchecked scratch read could produce an absolute destination.** If the
      phase-1 state file failed to read, `$spoke` became empty and every destination
      became `/$rel` — a write outside the spoke entirely. Now refuses on empty or
      missing state. This was the most severe finding of the round.
- [x] **R2-5 — rollback was neither lossless nor scoped.** `git clean -fd` (no `-x`) left
      behind files the push created that the spoke's `.gitignore` ignores, where neither
      `git status` nor the operator would ever see them; and `git checkout -- .` was
      repo-wide. Now `checkout` and `clean -fdx` are both scoped to literal managed
      pathspecs, and restoration is verified against tracked *and* ignored state. `-x` is
      safe only because Guard 5 proved no ignored file existed there beforehand.
- [x] **R2-6 — `WRITTEN:` could misstate what happened.** A platform was recorded as
      applied before success was known, and stayed recorded after a successful rollback.
      Now three distinct states: `WRITTEN AND KEPT`, `ROLLED BACK`, `NEEDS ATTENTION`.
- [x] **R2-7 — stale enforcement claims survived round 1.** `specs/reviewer-verdict.md:35`
      still cited Antigravity's `enable_write_tools: false`, and both it and `README.md`
      claimed every read-only reviewer "cannot run commands" — false for a Codex sandbox,
      which blocks *writes* while still permitting execution. Both corrected, and the
      distinction is now spelled out because it changes how the reviewer prompt must be
      written.
- [x] **R2-8 — `--help` printed `set -uo pipefail`.** Usage range off by two lines.

Re-verified after correction (synthetic fixture, then the real hub):

| Scenario | Result | Exit |
|---|---|---|
| symlinked spoke *ancestor*, leaf absent | refused; target dir stayed empty | 3 |
| managed path containing a glob character | pushed correctly | 0 |
| push creates a git-ignored file, then validator fails | rolled back incl. the ignored file; "tracked and ignored" verified | 2 |
| same scenario, reporting | `ROLLED BACK: fake`, not `WRITTEN AND KEPT` | 2 |
| pre-existing ignored file in managed dir | refused; file survived | 3 |
| missing `spoke_remote` / missing `native_validator` | refused | 3 / 2 |
| dirty spoke **with** drift | refused | 3 |
| `..` `.` absolute, traversal, `~` | refused | 3 |
| `--help` | no shell code in output | 0 |
| happy path / idempotent no-op / wrong origin / absent path | as before | 0 / 0 / 3 / 3 |

Note: an in-sync spoke that is dirty exits 0, not 3. That is correct — the dirty guard
sits after the drift check, and there is nothing to overwrite when nothing needs writing.

- [x] Third fresh review obtained (Milestone 7).

## Milestone 7 — Third review round

Same lane, `reviewer-codex`. Realized header again `gpt-5.6-sol` / `read-only` / `high`.
**VERDICT: fix-first**, 9 findings. It explicitly accepted the in-sync-dirty-spoke exit 0
as correct. All 9 confirmed and corrected:

- [x] **R3-1 — rollback deleted spoke-local ignored files.** Guard 5 tolerates ignored
      `.claude/` and `.DS_Store`, but `git clean -fdx` removed them — the opposite of
      lossless. `clean` now carries the same `-e` exclusions. Verified: both survive a
      rollback.
- [x] **R3-2 — cache writes unchecked and non-atomic.** A truncated paths file could sync
      a prefix and report success. Now written to a temp name, moved into place, checked,
      and round-tripped.
- [x] **R3-3 — apply-time re-validation broke the all-or-nothing boundary.** It ran per
      platform *inside* the apply loop, so platform 1 could be written and kept when
      platform 3 refused — while the summary said "Nothing was written." Split into a
      separate `revalidate_platform` sweep across every ready platform before the first
      mutation. Verified: platform 2 failing re-validation leaves platform 1 untouched.
- [x] **R3-4 — rollback of a newly created path falsely reported `NEEDS ATTENTION`.**
      `git checkout` errors on a path with no index entry, even though `git clean` removes
      it completely. Checkout failure is no longer treated as rollback failure; the
      tracked+ignored verification is authoritative. Verified: 0 false `NEEDS ATTENTION`.
- [x] **R3-5 — `.git` was not a forbidden path component.** Managing `.git` or
      `.git/config` would have let a push replace the index and HEAD that rollback itself
      depends on. Now rejected alongside `.`/`..`. Verified for `.git`, `.git/config`,
      `pkg/.git`.
- [x] **R3-6 — `cp -p` mutated the destination inode in place**, so a hard-linked managed
      file would change an alias outside the managed path. Now copy-to-temp-then-`mv`, and
      a destination with a link count above 1 is refused outright. Verified: the alias kept
      its original content.
- [x] **R3-7 — signal traps cleaned up but did not exit**, so a cancellation could be
      swallowed mid-apply. Now `exit 130`. Verified with SIGTERM.
- [x] **R3-8 — README's exit contract contradicted the code.** It credited Guard 4 alone
      for losslessness (it is Guards 4 and 5 together) and said exit 2 leaves nothing
      half-applied, which the new `NEEDS ATTENTION` branch contradicts. Rewritten.
- [x] **R3-9 — `ORIGIN.md` claimed every spoke carries its own `ORIGIN.md`.** The Codex
      spoke has none; it carries `UPSTREAM.lock` instead. Corrected.

## Milestone 8 — Fourth review round

Same lane. **VERDICT: fix-first**, but only **4** findings (7 -> 8 -> 9 -> 4), and it
confirmed MIT attribution preserved and the platform trees matching their spokes. All 4
corrected:

- [x] **R4-1 — predictable copy temporary.** `"$spoke/$rel.sync-tmp.$$"` could be
      pre-created as a symlink, and `cp` would follow it. Temporaries now come from
      `mktemp` in the destination directory and are symlink-checked before use.
- [x] **R4-2 — the ignored-file filter was not NUL-safe.** A filename containing newlines
      could be split into fragments that looked like exempt `.claude`/`.DS_Store`
      components and then be deleted by `rsync --delete`. **The reviewer's framing
      understated this: the real cause is that bash strips NUL bytes in command
      substitution**, so `$(git ... -z)` could never preserve the delimiters at all.
      Rewritten to route git's output through a file and read it with `read -r -d ''`,
      with an `is_exempt()` helper that compares path components exactly. Both the
      preflight and rollback pipelines now also fail closed on a git error.
      Verified: a file literally named `pkg/weird\n.claude\nfile.log` is refused and
      survives; a genuine `.DS_Store` / `.claude/` is still tolerated and survives a push.
- [x] **R4-3 — a mixed outcome could print a false "Nothing was written".** Reachable when
      one platform is applied and kept and a later one refuses at apply time. The exit-3
      summary is now conditional on the outcome arrays.
- [x] **R4-4 — the README's exit contract was still incomplete.** Exit 2 covers *two*
      cases (a hub validator failing before any write, and a spoke failing after), and a
      failed copy or surviving drift take the same rollback path as a failing validator.
      Documented.

## Milestone 9 — Fifth review round, and where the route actually stands

Same lane. **VERDICT: fix-first**, 4 findings. The reviewer explicitly confirmed the
imported trees match their spokes and that licensing and Daniel McAteer attribution are
preserved, and — importantly — it began routing the unfixable TOCTOU and the
interrupt-during-mutation case to RESIDUAL RISK rather than FINDINGS. All 4 corrected:

- [x] **R5-1 — `.claude` exemption was inconsistent between Guard 5 and rsync.**
      `is_exempt()` exempted a *regular file* named `.claude`, but rsync's
      `--exclude '.claude/'` matches directories only, so such a file would have been
      deleted by `--delete` while Guard 5 said it was safe. rsync now excludes `.claude`
      by name. Verified: a regular ignored file `pkg/.claude` survives a push.
- [x] **R5-2 — mixed outcomes were summarised falsely.** With one platform kept and
      another rolled back, exit 2 claimed every affected spoke had been rolled back. There
      is now an explicit `mixed` branch that defers to the outcome lines.
- [x] **R5-3 — README overclaimed `--push` as all-or-nothing.** Only *preflight* is.
      Once writing begins each ready platform is attempted and a failure in one does not
      undo the others. Rewritten to claim only what holds.
- [x] **R5-4 — the canonical role table said reviewers never run commands.** False for a
      sandboxed reviewer, which is denied writes but not execution. Narrowed to "writes,
      or implements its own fixes", with the distinction spelled out.

### Review round summary

| Round | Findings | Character |
|---|---|---|
| 1 | 7 | Structural: path traversal, fail-open guards, untracked deliverables, false enforcement claims |
| 2 | 8 | Serious edge cases: absolute-path destination, unrecoverable ignored-file deletion, repo-wide checkout |
| 3 | 9 | Narrower: `.git` as a managed path, hard links, signal traps, doc/code contradictions |
| 4 | 4 | Race hardening, NUL-safety, mixed-outcome reporting |
| 5 | 4 | Exemption consistency, summary truthfulness, two doc overclaims |

**The route has not reached `ship`.** Five rounds of `fix-first` were obtained on the
declared cross-vendor lane; every finding across all five was independently confirmed
against the files before being acted on, and all 32 are fixed and re-verified. Severity has
fallen sharply — rounds 4 and 5 found no new data-loss path under normal single-operator
operation — but the count has not reached zero, and a sixth round would very likely find
more documentation-consistency issues.

- [ ] **Decide whether to run a sixth review round.** Each round costs Codex quota and
      roughly ten minutes. The remaining findings have been consistency and truthfulness
      issues rather than defects that lose data. This is a spend decision, not a technical
      one, which is why it is recorded here rather than taken unilaterally.

### 5. RESOLVED — the Antigravity failover conflict

`specs/reviewer-verdict.md` required the user to authorize any review failover;
`gem-advisor-max` mandated automatic failover and "never stall." Recorded earlier as an
unresolved product decision.

**Resolving it found a real defect, which is why it was not a matter of taste.** Under a
`Gemini Pro 3.1` chair with a Claude reviewer, the automatic rule failed over to
`gem-reviewer` on `Gemini Pro 3.1` — **the chair's own model** — and step 3 instructed the
orchestrator to "note in the final acceptance report that clean fresh-context review was
performed." Reviewer and orchestrator would be the same model, which is context-clean only,
reported as though nothing had changed.

Both documents were arguing about the wrong variable. The question was never automatic
versus authorized; it is **does the acceptance claim change**. The canonical spec's own
justification proves it — authorization exists so an orchestrator cannot "reach the weaker
reviewer by supplying worse input," and that incentive only exists when the target *is*
weaker.

The unified rule, now in `specs/reviewer-verdict.md`:

| Failover | Requirement |
|---|---|
| Preserves the independence tier | Automatic. Declare it; do not stall. |
| Lowers the tier | Authorization required. Ask and wait. |
| Target shares the chair's model | Never valid. Refuse and stop. |

One rule, different behaviour per harness because their lanes differ — not two rules:

- **Claude Code always asks.** Its only in-process failover beneath an Opus chair is
  cross-model same-vendor, strictly lower than the cross-vendor lane it declares. Every
  failover it can reach degrades the claim. Its behaviour is unchanged; the workflow now
  explains that this is its lanes producing an absolute rather than a stricter rule.
- **Antigravity usually does not ask.** A 429 under a Gemini chair is answered by moving to
  `GPT-OSS`, still cross-vendor, tier preserved — automatic, declared, no stall. It stalls
  only when the sole reachable lane is weaker, which is the one case worth stalling for.

Changed: `specs/reviewer-verdict.md` (rule rewritten, divergence section replaced with how
each harness lands), `README.md`, `platforms/claude/.../orchestration/SKILL.md` (framing
only, no behaviour change), and on the Antigravity side `gem-advisor-max/SKILL.md`,
`gem-advisor/references/role-contracts.md` (including the lane table's failover column),
`rules/AGENTS.md`, `SUMMARY.md`, and `agents/gem-reviewer.md` — whose `FAILOVER NOTE` field
now requires naming the independence actually carried rather than just noting that a
failover happened.

- [x] Decided and aligned through the hub; exported and validated.

## Milestone 10 — Sixth review round

Same lane, `reviewer-codex`, `gpt-5.6-sol` / read-only / high. **VERDICT: fix-first**,
9 findings. It accepted the injection fix, the portability guard, attribution, the
newsletter-check removal and the 125-line ceiling, and confirmed Claude's behaviour was
genuinely unchanged. All 9 confirmed and fixed:

- [x] **R6-1 — `.claude`/`.DS_Store` were legal managed paths.** rsync's `--exclude` does
      not apply to a transfer root, and Guard 5 exempts the same names, so managing
      `pkg/.claude` would have exempted it from the ignored-file guard and let `--delete`
      remove its contents unrecoverably. Now rejected by `path_is_sane`. Verified: the
      manifest is refused and the file survives.
- [x] **R6-2 — `--check` wrote `.git/config`.** The hooksPath self-enable ran in both
      modes, so a mode documented as writing nothing reconfigured the repository it was
      inspecting. Now only `--push` sets it; `--check` prints the one-line command instead.
- [x] **R6-3 — the Antigravity spoke README still carried the old failover rule.** The
      previous round's "resolved across all seven files" claim was wrong: this file words
      it as `-> Gemini Pro 3.1 fresh-context review`, which none of the grep patterns used
      to find the others matched. The defect was live in a public README. Also corrected
      the same `enable_*_tools` overstatement there that the hub docs had already fixed.
- [x] **R6-4 — the prescribed failover target did not exist.** The resolution named
      `GPT-OSS` as a tier-preserving lane. `scripts/verify.sh` restricts agent models to
      `{flash, flash_lite, pro, inherit}` and the spawn contract accepts
      `flash | pro | inherit`: **no cross-vendor subagent is invocable at all.** Every
      GPT-OSS reference is removed, and the rule now states the true consequence — every
      reviewer failover available to Antigravity lowers the tier, so it asks, exactly like
      Claude Code. A new invocability note records that the lane table's "Claude Opus"
      cross-model column is intent, not a lane that can be spawned today.
- [x] **R6-5 — the canonical spec contradicted itself.** `selective-route.md` still called
      the exception "user-authorized" full stop, and the tier table offered a downgrade to
      context-clean that the next row forbids. Both corrected; context-clean is now stated
      as unreachable by authorization because it is definitionally the chair's own model.
- [x] **R6-6 — the README validator matrix still said `sh`** for the two bash validators,
      reproducing the exact Ubuntu failure CI had caught. Corrected, with the reason.
- [x] **R6-7 — orientation text called `.gitignore` spoke-local** although all three
      manifests manage it, and `CLAUDE.md` named the renamed `gen-spoke-hooks.sh`.
- [x] **R6-8 — version drift.** README reported fork 2.0.0 / claude 0.3.0 against actual
      2.0.1 / 0.3.1, and Antigravity shipped a behaviour change on 0.1.0. Matrix synced;
      `gem-advisor` bumped to 0.1.1.
- [x] **R6-9 — the Claude derivation figures were stale again**, since the failover edit
      added sentences. Re-measured: 147 → 151 sentences, percentages unchanged.

### Found by re-testing, not by the reviewer: rsync could skip a changed file

The regression sweep after these fixes failed the happy path deterministically on a fresh
fixture. Cause: `rsync -a` quick-checks on **size and mtime**. This hub writes files
programmatically, so two versions of one file can share a byte count and be written in the
same second — at which point rsync skipped a genuinely changed file and returned success.

`--checksum` is now passed, making the comparison content-based. Verified against a fixture
with artificially identical size *and* mtime.

Two things worth keeping from this: the bug was invisible to every guard except the
post-apply drift re-check added in round 3, which is the check that caught it; and it means
a `--push` could have reported success while leaving a spoke stale. No real push is known
to have hit it — every real push re-verified an empty post-push diff — but the window was
open the whole time.

## Known blind spots

- **`--push` has now run against a real spoke exactly once**, exporting a single-file
  LICENSE correction to `~/claude-advisor`. It validated, applied, re-validated, and
  verified an empty post-push diff. The rollback path has still only ever been exercised
  against a synthetic fixture, never for real.
- **An interrupt during the apply loop leaves a partially updated but clean-recoverable
  spoke.** The signal handler exits without rolling back, by design — rolling back from a
  signal handler mid-`rsync` is more dangerous than stopping. Guard 4 means the spoke was
  clean beforehand, so `git checkout -- . && git clean -fdx` inside that spoke restores
  it; the script tells you nothing about which platform it was interrupted on, so check
  each spoke's `git status`.
- **SIGINT is not trappable when the script is launched as a background job from a
  non-interactive shell** — the ignore disposition is inherited before the trap is set.
  SIGTERM works, and Ctrl-C from a terminal works. This is shell semantics, not a defect,
  but it means an unattended wrapper should send TERM rather than INT.
- **The apply-time re-validation narrows the TOCTOU window; it does not close it.** A path
  swapped for a symlink between the re-check and the `rsync` call would still redirect.
  Closing it properly needs an fd-based or locked apply, which POSIX shell on macOS does
  not offer cleanly. Accepted as residual for a single-operator local tool; it would not
  be acceptable for anything running unattended or multi-user.
- The bash 3.2 empty-array regression above was found by re-running the guard matrix, not
  by reading the diff. Any future change to the array handling in `sync-spokes.sh` should
  re-run that matrix rather than rely on inspection — `bash -n` does not catch it.
- The hub imported each spoke's **working tree**, so any uncommitted spoke state at import
  time is now baked into `platforms/`. Only the Codex spoke was dirty (item 2).
- Managed-path lists are hand-written. A new file added to a spoke under a *managed
  directory* is picked up automatically; a new top-level path is not, and will be silently
  spoke-local until someone adds it to the manifest.

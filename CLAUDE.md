# agent-advisor — working rules

This repo is the **hub**. It is not installed anywhere. It owns the source for three
plugin repositories and exports to them.

## The one rule that matters

**Never edit `~/sol-advisor-portable`, `~/claude-advisor`, or `~/gem-advisor` directly.**

Every change originates here, in `platforms/<platform>/`, and reaches a spoke only through
`scripts/sync-spokes.sh`. A hand-edit in a spoke is silently overwritten by the next push,
and the hub stops being the source of truth the moment one exists.

The exceptions are the files the hub does not manage — each spoke's `HANDOFF.md` and
`MISTAKES.md`. Those are spoke-local by design; `platforms/<p>/spoke.manifest` lists
exactly what the hub owns.

## Making a change

Edit under `platforms/<platform>/`, then:

```bash
./scripts/sync-spokes.sh --check
```

```bash
./scripts/sync-spokes.sh --push --platform <codex|claude|antigravity>
```

`--check` writes nothing. `--push` refuses unless the target spoke is committed and clean,
applies, re-runs that platform's native validators *in the spoke*, and rolls back if they
fail. It never commits — review and commit in the spoke yourself afterwards.

Exit codes: `0` fine · `1` drift (check only) · `2` validation failed · `3` guard refused ·
`4` caller error. Read the `WRITTEN AND KEPT` / `ROLLED BACK` / `NEEDS ATTENTION` lines
rather than inferring from the exit code.

## You do not need to remember to run it

`core.hooksPath` is set to `scripts/hooks`, and `pre-commit` runs `--check` and blocks the
commit if a platform tree fails its own validator. Drift between hub and spoke does not
block — that is what `--push` is for.

If you are about to tell a human to "remember" a procedural step, add a check instead.

Each spoke has one too, generated from its `spoke.manifest` by
`scripts/gen-spoke-hooks.sh` so a spoke's self-check and the hub's pre-export check cannot
disagree. **Regenerate and `--push` after changing any `native_validator` line.**

`core.hooksPath` is local git config, not a tracked file, so it does not survive a fresh
clone. **You should never have to set it by hand** — three things do it for you:

- `scripts/sync-spokes.sh` sets it for the hub on any invocation, and for each spoke it
  successfully pushes to.
- `install.sh` sets it in the Codex and Antigravity spokes.
- **CI is the backstop that needs no local state at all.** Every repo has a `validate`
  workflow running the same native validators on push and pull request, so a clone with
  no hook configured still cannot land a broken tree unnoticed.

The hook is a speed optimisation — it fails in two seconds instead of sixty. CI is the
guarantee. If you ever find yourself writing "remember to…", that is the signal to add a
layer here instead.

`.github/workflows/validate.yml` is generated too, so a manifest edited without
regenerating would leave CI and the hook enforcing different validator lists. The hub's
CI checks for exactly that and fails if the generated files are stale.

## Things that have bitten before

- **`platforms/codex/README.md` is validated by phrase matching.** Those checks are now
  whitespace-insensitive, so reflowing is safe, but the line cap (125) is real.
- **The global gitignore at `~/.config/git/ignore` excludes `SUMMARY.md` and `HANDOFF.md`.**
  Every `.gitignore` here negates it. If you add a repo, do the same, or those files will
  sit untracked and unrecoverable while `git status` looks clean.
- **Isolation is enforced by an absence.** Reviewer agents hold no write tools and no Bash;
  implementers hold no `Agent` tool. Adding a tool for an unrelated reason silently revokes
  the guarantee, so `platforms/claude/scripts/verify.sh` check 10 asserts it.
- **A `native_validator` value is code, not data.** It is executed by the sync and
  embedded into the generated hook and workflow. Both the generator and preflight enforce
  a strict allowlist for that reason — a manifest is a place a payload can hide while the
  dangerous artifact appears only in generated output nobody re-reads.
- **Do not claim a check exists without grepping for it.** That exact error shipped in this
  README and survived five review rounds.

## Attribution

The routing model originates with Daniel McAteer's
[Sol Advisor](https://github.com/DannyMac180/sol-advisor) (MIT). `ORIGIN.md` states each
platform's real relationship to it and measures the Claude adaptation's overlap rather than
asserting originality. Do not weaken or remove attribution in any exported artifact.

# MISTAKES — agent-advisor

Newest first. Format: **What happened | Root cause | Consequence | The rule that prevents
repeat**.

## 2026-09-13 — A validator held a false sentence in place

**What happened:** `platforms/codex/README.md` asserted "Sol / High runs the show", and
`plugins/sol-advisor/scripts/verify.sh` enforced that exact string. The repo ships three
chair aliases — Sol, Astra, Daybreak — so the sentence is false under two of them. Round 8
found it; seven prior rounds did not.

**Root cause:** the check grepped for a **specific chair's name** when the rule it meant to
protect was **that some chair owns architecture, verification, escalation and acceptance**.
Once a capability was added that the sentence did not cover, the validator stopped
protecting the rule and started protecting the error — and made correcting it a two-file
change, which is exactly the friction that leaves such sentences in place.

**Consequence:** a false ownership claim shipped in a public README and survived seven
cross-vendor review rounds, guarded by a check that made it look deliberate.

**The rule:** a phrase-matching check must grep the **invariant**, never an instance of it.
Before adding one, ask what the repo would have to do for the phrase to become false
without the rule becoming false — if there is such a change, match something more general.
This is the same failure as pinning a version string in prose, and the same fix.

## 2026-09-13 — Documentation claimed a lane the runtime rejects

**What happened:** `gem-advisor-max/SKILL.md` named `Claude Opus` as the preferred reviewer
under a Gemini chair. Antigravity cannot spawn a non-Gemini subagent at all: the CLI itself
answers `unsupported model: must be one of 'inherit', 'flash', 'pro', 'flash_lite'`. The
same file said so correctly two paragraphs later.

**Root cause:** the capability was never checked against the tool, only reasoned about from
our own documents. `agy plugin validate` does **not** validate model values — it accepts
`model: totally-not-a-real-model` and exits 0 — so the native validator gave false comfort
and the failure would only have appeared at spawn time.

**Consequence:** a documented review tier that could not be invoked, carried across eight
rounds as "intent" rather than being resolved.

**The rule:** settle a capability question against the **runtime**, not against the
project's own prose or a validator that may not check the field. `strings` on the binary,
or an actual spawn, beats any amount of internal consistency. And never treat a validator's
silence as confirmation without proving it would have objected to a wrong value.

## 2026-09-12 — Assumed a repo-local script was executable

**What happened:** the first attempt to run the Codex spoke's native validator from the
hub failed with `permission denied`. The manifest named it as a bare path, as if it were
an executable.

**Root cause:** `plugins/sol-advisor/scripts/verify.sh` is mode `644` in the spoke — the
import preserved that faithfully. Two sibling scripts in the same directory *are* mode
`755`, which made the assumption look safe.

**Consequence:** none beyond one failed command. Caught immediately, before the manifest
format was settled.

**The rule:** a `native_validator` entry is a **shell command string**, not a path — it is
run as `sh -c "<line>"` from the tree root, and the manifest writes `sh path/to/x.sh`
explicitly. Never infer that a checked-in script carries its exec bit.

## 2026-09-12 — Nearly tested the destructive push path against a live spoke

**What happened:** while verifying drift detection, a probe comment was appended to
`platforms/claude/README.md`. The obvious next step was to run `--push` and watch it
propagate — into `~/claude-advisor`, a live plugin source repository.

**Root cause:** convenience. The real spokes were right there and already wired up.

**Consequence:** none. The probe was reverted and the push was instead exercised against a
synthetic hub/spoke pair built in the scratchpad, which also made it possible to test
rollback, the dirty-tree guard, and the wrong-remote guard — none of which could have been
tested safely against a live repo at all.

**The rule:** test destructive tooling against a fixture, never against the thing it is
meant to protect. The fixture is not the weaker test here; it is the *stronger* one,
because it can be driven into failure states on purpose.

## 2026-09-12 — Shipped a fail-closed guard set with a path-traversal hole

**What happened:** the first version of `scripts/sync-spokes.sh` validated that every
managed path *existed in the hub*, and nothing else. It never checked that the path was
relative, normalized, or contained. A `[paths]` entry of `..` would have made the
`rsync --delete` destination the spoke's **parent directory**.

**Root cause:** I treated the manifest as trusted configuration because I wrote it. The
guard set was designed against the failure I was imagining — a stale or invalid spoke —
rather than against its own input.

**Consequence:** none in practice; caught by the cross-vendor review before any real push.
But the defect was in the one artifact whose entire purpose is to be fail-closed, and my
own testing had exercised every guard I thought of and therefore proved nothing about the
one I hadn't.

**The rule:** a path that reaches `rm`, `--delete`, or a destination argument is untrusted
input regardless of where it came from. Validate shape (relative, no `.`/`..`/`~`), resolve
it physically, prove containment in the intended root, and reject symlinked components —
before it is used for anything. "I wrote this config" is not a threat model.

## 2026-09-12 — Claimed structural enforcement that the files do not contain

**What happened:** `README.md` and `specs/role-contracts.md` asserted that all three
harnesses structurally prevent an implementer from delegating onward — citing "custom-agent
profiles with no nested invocation" for Codex and `enable_subagent_tools: false` for
Antigravity. Neither exists. The Codex TOMLs carry only model and instruction fields; the
Antigravity booleans appear solely in agent **prose bodies**, never in frontmatter.

**Root cause:** I read each project's self-description and repeated it, instead of reading
the agent definitions and describing what was actually in them. The Antigravity files
assert the boolean *about themselves*, which is exactly the kind of claim that survives
being copied because it sounds like configuration.

**Consequence:** a comparison matrix — whose only job is accuracy — overstated two of three
cells, in a document that elsewhere lectures about not confusing a pin with an observation.

**The rule:** when documenting what a file enforces, grep the file for the mechanism and
quote what is there. A project's description of its own guarantees is a claim to verify,
not a source to cite — and that applies most strongly when the claim is flattering and
conveniently phrased.

## 2026-09-12 — Fixed a guard but left the unchecked read that made it moot

**What happened:** the two-phase preflight rewrite stashed each platform's spoke path to a
scratch file, then read it back in phase 2 with a bare `spoke=$(cat ...)`. A failed read
would leave `$spoke` empty, turning every destination `"$spoke/$rel"` into the **absolute**
path `/$rel` — writing outside the spoke entirely, past every containment guard I had just
added for exactly that class of failure.

**Root cause:** I audited the paths that came from the manifest, because that was the
finding I was responding to, and treated values I had written myself one phase earlier as
trustworthy. The guard and the hole were added in the same edit.

**Consequence:** none — caught by the second review before any real push. But it would have
defeated the round-1 fix completely, which is the worst kind of defect: one that makes a
security control look present while routing around it.

**The rule:** when you add a containment check, enumerate *every* way the value it protects
can be produced, including the ones introduced by the same change. A guard on one input
path is not a guard. And check the exit status of every command whose empty output is
indistinguishable from a benign result.

## 2026-09-12 — Wrote a NUL-safe filter in a shell that cannot hold NULs

**What happened:** responding to a finding that the git-ignored-file check mishandled
filenames containing newlines, I rewrote it to read NUL-delimited output with
`read -r -d ''`. The rewrite was still completely broken, and a test caught it: the
dangerous file was destroyed exactly as before.

**Root cause:** the data never survived to reach the loop. **Bash strips NUL bytes in
command substitution**, so `listing=$(git ls-files -z ...)` silently discarded every
delimiter and concatenated the entries. I had written the correct *consumer* of NUL-safe
data while feeding it through a channel that cannot carry it.

**Consequence:** none — the test was written before the fix was believed. But had I
verified by reading the diff instead of running it, the finding would have been marked
fixed while the hole stayed open, which is worse than never having addressed it.

**The rule:** a fix for a data-handling bug is not verified until the original hostile
input is replayed and observed to fail safely. And in shell specifically: NUL-delimited
data must go through a file or a pipe, never through `$(...)` — command substitution is a
text channel and quietly truncates at the first NUL boundary.

## 2026-09-12 — Reported a fix as complete after grepping for the wrong strings

**What happened:** I resolved the Antigravity failover conflict, grepped for the old policy
across the platform tree, fixed every hit, and told the user it was "fixed across all seven
files that carried the old policy." The sixth review found the spoke's own `README.md` still
instructing the exact unsafe failover.

**Root cause:** I searched for the phrasings I had already seen — `failing over to Gemini
Pro`, `fallback to Gemini Pro` — rather than for the concept. The README words it
`-> Gemini Pro 3.1 fresh-context review`, which matches none of them. My completeness claim
rested on a grep whose patterns were derived from the files I had already found.

**Consequence:** a public README kept telling readers to do the unsafe thing, and I told the
user the opposite. The claim was wrong, not just the work.

**The rule:** a grep proves what it matched, never what it missed. Before claiming a sweep
is complete, search for the *subject* (`failover`, `quota`, the target's name) and read
every hit, or enumerate the file set independently. And do not put a count in a completion
claim — "all seven files" asserted a total I had never actually established.

## 2026-09-12 — Prescribed a lane that cannot be invoked

**What happened:** the failover rule I wrote told Antigravity to fail over to `GPT-OSS` to
preserve cross-vendor independence. No such lane exists. `scripts/verify.sh` restricts agent
models to `{flash, flash_lite, pro, inherit}` and the spawn contract accepts
`flash | pro | inherit` — every invocable subagent runs Gemini.

**Root cause:** `GPT-OSS` appeared in a documentation table as a "failover model", and I
treated a table entry as evidence of capability without checking whether anything could
spawn it. Identical in shape to claiming `verify.sh` contained a check it did not: reading a
description and repeating it instead of verifying the mechanism.

**Consequence:** the resolution's practical conclusion was backwards. I reported that
Antigravity "usually does not ask"; in reality no tier-preserving lane exists, so it always
asks. The reasoning was sound and the premise was false.

**The rule:** before writing a policy that names a lane, model, or tool, confirm something
can actually invoke it — grep the agent definitions and the spawn contract, not the prose
table. A capability claimed in documentation is a claim to verify, especially when it is the
half of the argument that makes your conclusion work.

## 2026-09-12 — Fixed the exported copy and left the false claim upstream. Twice.

**What happened:** the failover correction was applied to `platforms/antigravity/**` but not
to `README.md` and `specs/reviewer-verdict.md`, which kept asserting that Antigravity
"usually does not need to ask" by moving to "another cross-vendor lane" — a lane that does
not exist. The previous round had the mirror-image version of this: the hub docs were fixed
and the spoke's own README was missed.

**Root cause:** I treat "the platform files" and "the hub docs" as separate jobs and finish
one. Both describe the same behaviour, so a change to the behaviour is not done until both
are consistent — but nothing forces me to visit both, and the sync tooling cannot help
because `specs/` is deliberately not exported.

**Consequence:** two consecutive rounds shipped a document asserting something the
implementation contradicted, in a project whose entire premise is that the three
implementations stay honest with each other.

**The rule:** a behaviour change is scoped by *claim*, not by directory. Before calling one
done, grep the whole tree — hub and platforms — for the claim's subject and read every hit.
For this project specifically: `specs/` and `README.md` describe the same rules the
platforms implement, so they are always in scope for a rule change, and they are the two
places the sync tooling will never flag.

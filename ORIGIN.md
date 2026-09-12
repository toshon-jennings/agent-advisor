# Origin

Every routing idea in this monorepo traces to one project.

~~~text
concept_repository=https://github.com/DannyMac180/sol-advisor
concept_author=Daniel McAteer
concept_license=MIT
concept_version=0.6.0
hub_role=canonical source of truth for three downstream platform implementations
~~~

## What originates with Daniel McAteer

- The machine-auditable **`SELECTIVE ROUTE` declaration**, and the rule that it precedes
  the first task tool call.
- The **four delivery modes** — `solo`, `delegate`, `audit`, `full` — as an exact,
  closed set.
- The **single-auxiliary maximum**, with `full` as the justified exception.
- The **five-part worker specification** and its structured implementation report.
- The **fail-closed posture**: missing, conflicting, unavailable, or unobservable routing
  evidence stops a lane rather than falling back.
- The principle that the orchestrator retains architecture, verification, and acceptance
  regardless of the mode it declares.

None of that is reinvented here. It is the intellectual foundation, and it is the reason
three harnesses that share no code still behave recognizably alike.

## How close each platform actually is

These are three different relationships to the original, and flattening them into one
word would misrepresent at least two of them. This table is the hub's summary.

The Claude and Antigravity spokes each state their own relationship in their own
`ORIGIN.md`. **The Codex spoke has no `ORIGIN.md`** — it carries `UPSTREAM.lock`, which
pins the upstream repository, commit, and version instead. That is arguably sufficient for
a mirror, where the relationship is "this is the original," but it is a different artifact
making a narrower claim, and this file should not imply the three are equivalent.

| Platform | Relationship | What that means |
|---|---|---|
| **Codex** (`platforms/codex/`) | **Mirror of a fork.** `UPSTREAM.lock` pins the upstream commit. | The closest of the three. It is the original project, carried portably. |
| **Claude Code** (`platforms/claude/`) | **Adaptation.** Substantial prose derived from the original, not a clean-room rewrite. | Its `ORIGIN.md` measures the overlap at the sentence level and declines the stronger claim: no file was copied, but "independently written" would be false. |
| **Antigravity** (`platforms/antigravity/`) | **Independent reimplementation.** Concept carried, no file copied. | Agent definitions, skills, lane pins, the tier structure, and the quota defense are new work. |

The Claude entry is the one worth reading in full. It is unusual for a derivative project
to document its own resemblance in detail, and that file exists specifically to avoid
overstating originality — see `platforms/claude/ORIGIN.md`.

## What is new in this hub

- The `specs/` contracts themselves: a platform-agnostic statement of the routing model
  that none of the three spokes contained, because each stated it only in its own idiom.
- The hub-and-spoke structure, and the rule that spokes are export targets rather than
  editable sources.
- `scripts/sync-spokes.sh` and the `spoke.manifest` format: managed-path declarations,
  the guard sequence, in-hub native validation, and post-push rollback.
- The cross-platform comparison matrix in `README.md` — in particular the
  pin-verifiability and quota-protection axes, where the three projects differ in ways
  none of them could observe alone.

## Licence

The original is MIT, which permits derivative works — including close ones — provided the
copyright notice travels with them.

- `LICENSE` at this root carries the notice for the hub and names the original.
- `platforms/*/LICENSE` carries each spoke's own notice, preserved byte-for-byte from the
  spoke and exported unchanged. `LICENSE` is a managed path in all three manifests
  specifically so that attribution cannot drift out of an export.

The point of this file is not permission, which is not in question. It is to keep the
three relationships distinguishable, and to keep the attribution attached to the work
rather than to a README paragraph someone might trim.

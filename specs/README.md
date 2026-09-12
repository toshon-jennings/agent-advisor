# specs/ — the canonical contracts

Platform-agnostic. These four files are the source of truth for *what selective routing
is*. Everything under [`../platforms/`](../platforms/) is one harness's expression of
them, and a platform may extend a contract but never weaken it.

| Spec | Defines |
|---|---|
| [`selective-route.md`](selective-route.md) | The declaration grammar, the four delivery modes, the route floor, and the fail-closed posture |
| [`role-contracts.md`](role-contracts.md) | The three roles, the structural guarantees each harness must provide, spawn discipline, preflight, and chair escalation |
| [`worker-packet.md`](worker-packet.md) | The five-part implementer specification, the structured return, and how a partial or blocked return is dispositioned |
| [`reviewer-verdict.md`](reviewer-verdict.md) | Review lane independence, the three-verdict rubric, and the announced-and-authorized failover path |

## Reading order

If you are implementing a fourth harness, read them in the order above. Each one assumes
the previous.

## What "canonical" means here, and what it does not

It means: when a platform's wording and a spec's wording disagree about *intent*, the
spec is what the platform was trying to say, and the platform is what needs fixing.

It does **not** mean these files are pushed into the spokes. They are not — see the
managed-path manifests under `../platforms/*/spoke.manifest`. Each harness states its own
rules in its own idiom, because a Codex TOML profile, a Claude agent frontmatter, and an
Antigravity tool list are genuinely different objects and prose that pretends otherwise
would be worse in all three places.

The specs are the thing the three implementations are checked *against*, by a human
reading them side by side. They are deliberately not machine-enforced onto the spokes:
a sync that overwrote each platform's native phrasing with a shared abstraction would
produce three documents that describe a system none of the three harnesses actually has.

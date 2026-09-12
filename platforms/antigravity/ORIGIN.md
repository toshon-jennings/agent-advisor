# Origin

This project is a Google Antigravity implementation of the selective-routing workflow from
Sol Advisor, a Codex-native plugin by Daniel McAteer.

~~~text
concept_repository=https://github.com/DannyMac180/sol-advisor.git
concept_version=0.6.0
implemented_for=Google Antigravity
relationship=independent reimplementation, not a mirror or a fork
~~~

Carried over: the machine-auditable route declaration, the four delivery modes
(`solo`, `delegate`, `audit`, `full`), the one-auxiliary-by-default discipline, the
five-part worker specification, and the rule that the orchestrator owns architecture,
verification, and acceptance.

Newly built here: every agent definition, every skill, the Gemini and multi-model lane pins,
the two-chair tier structure, the zero-Claude-burn quota defense, graceful failover, `scripts/verify.sh`, and the
enforced tool isolation properties described in the README. No file is copied from the Codex project.

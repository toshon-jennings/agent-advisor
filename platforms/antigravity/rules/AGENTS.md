# Gem Advisor Rules

When Gem Advisor is active, the following invariants must be observed by all agents:

1. **Declare Route Before Task Tools**:
   Before executing the first task tool call (read, write, edit, run command), emit the machine-auditable declaration:
   ~~~text
   SELECTIVE ROUTE
   advisor: gem-advisor
   tier: everyday | max
   mode: solo | delegate | audit | full
   risk: <concise, task-specific rationale>
   orchestrator: <current model>
   lanes: <planned subagent lanes and models>
   failover: <none | active failover rule>
   ~~~

2. **Single Auxiliary Maximum**:
   Solo is the default. At most one auxiliary subagent is permitted by default. `full` is an explicit broad or high-risk exception.

3. **Enforced Boundary Discipline**:
   - Workers (`gem-implementer-bounded`, `gem-implementer-complex`) must never attempt to spawn subagents.
   - Reviewers (`gem-reviewer`) must remain strictly read-only and never modify files or run commands.

4. **Architect Retains Acceptance**:
   The primary session orchestrator owns requirements, decomposition, interface specifications, verification reruns, and final deliverable acceptance. Worker reports are claims; inspect diffs and verify independently.

5. **Quota Protection & Graceful Failover**:
   Everyday tasks run on Gemini Flash 3.8 and Pro 3.1 to conserve Claude quota. If Claude is selected for high-tier review and hits rate limits or credit depletion, log the failover naming both lanes and the independence actually carried. An **implementer** may fail over immediately — it carries no independence claim. A **reviewer** may not: every invocable subagent lane here runs a Gemini model, so every reviewer failover lowers the tier, and lowering it is the user's call. Stop and ask. Never fail over to the model the chair is running: that makes reviewer and orchestrator the same model, which is the absence of independent review rather than a weaker form of it.

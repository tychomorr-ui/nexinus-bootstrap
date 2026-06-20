# Adaptive intelligence — contract for a system that learns without lying

We want adaptive intelligence, not just a watcher. But adaptive = probabilistic
= can fabricate confidence, which cuts against the entire doctrine (measure,
never trust, fail closed). This contract is what makes intelligence SAFE to add.

## The law: intelligence rides ABOVE the floor, never replaces it

```
  ADAPTIVE LAYER  → proposes hypotheses, tunings, anomaly flags (INFERRED)
  -------------------------------------------------------------------
  DEAD-MAN'S-SWITCH → unforgeable floor: absence = alarm
  VERIFIER (fail-closed) → signature + freshness, UNKNOWN by default
  MEASURED PROBES / SIGNED HEARTBEATS → ground truth
```

The floor (MEASURED + VERIFIER + DEAD-MAN'S-SWITCH) is never overridden by the
layer above it. Intelligence can be wrong; the floor cannot be talked out of the
truth it measured.

## Three hard rules

1. **PROPOSE, NEVER ASSERT.** Adaptive output is a distinct provenance class:
   `INFERRED` — rendered visually separate from MEASURED/ATTESTED, never able to
   turn a node green on its own. "The model thinks Monarch is degrading" is a
   hypothesis shown beside the measured truth, not a status.
2. **PROPOSE, NEVER ACT UNSUPERVISED.** Intelligence may *recommend* a smallest-
   reversible action (restart, re-probe, escalate). A human or an explicitly
   allow-listed, logged automation executes it. No silent self-remediation — that
   is the fastest path back to fake-green at the smartest layer.
3. **THE MODEL IS ITSELF MEASURED.** The adaptive layer's own health feeds the
   dead-man's-switch (2H): if the model stops producing verified inferences, that
   absence is alarm, same as any node. An adaptive layer that can silently die
   without signal is just Finding 1 with a brain.

## What adaptive intelligence MAY do here (all advisory)

- **Baseline + anomaly:** learn per-node normal latency/uptime cadence; flag
  deviations as INFERRED anomalies with a confidence and the evidence behind it.
- **Adaptive thresholds:** propose TTL / escalation-window tuning from observed
  real cadence — but a human ratifies a threshold change; it is logged, not silent.
- **Cross-node correlation:** surface root-cause HYPOTHESES ("all three nodes
  went UNKNOWN within 30s → likely DNS/registrar, not three coincident outages").
- **Next-move suggestion:** recommend the smallest reversible action + its receipt
  to verify, mapping to the runbook.

## What it MUST NOT do

- Render anything as up/green/ATTESTED on inference alone.
- Auto-execute irreversible or unscoped actions.
- Replace a measured value with a predicted one, ever.
- Hide its own degradation (every adaptation + every model-health gap is visible).

## Provenance vocabulary (extended)

`MEASURED` (probe/signature) · `ATTESTED` (verified signed heartbeat) ·
`INFERRED` (adaptive hypothesis — advisory, never green) · `DOCTRINE` (intent).
The whole point of a separate INFERRED class: intelligence becomes additive
insight that can never quietly become counterfeit truth.

## Status: STANDBY
No adaptive layer ships until there is real measured history to learn from — which
requires nodes serving signed heartbeats first. Built on the floor, never instead
of it.

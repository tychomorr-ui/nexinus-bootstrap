# Censoring & the design freeze (Findings 2K, 2L — the last ones)

When an INFERRED prediction triggers an action, the action contaminates the
ground truth (fundamental problem of causal inference — no general solution at
2–4 nodes). The honest handling, not a rescue:

## Decompose one confounded claim into two clean ones
- **Leading-indicator score:** in the lag window before the action lands, did the
  precursor (memory/IO/error rate) continue the trajectory the model predicted?
  Clean, observed, no counterfactual.
- **Intervention-effect score:** "restart drops memory pressure below X within Y" —
  directly observable. Not "would it have died," but "did what I did do what I said."
- The original counterfactual ("would it have gone DOWN") stays unscoreable. Don't
  rescue it. Mark it.

## FINDING 2K — never silently exclude confounded predictions. Tag CENSORED.
Dropping action-triggering predictions from the Brier score computes calibration
from only the easy, never-acted-on cases — survivorship that looks trustworthy
while having zero scored data on the predictions you most depend on. Fix: new
provenance `CENSORED`; the dashboard always shows the censored count beside the
score: `calibration 0.04 (lower=better) · N=180 scored · 23 censored`. A score
with no visible denominator is an unfalsifiable claim — forbidden by our own rule.

## FINDING 2L — watch the CENSORED rate, or the system learns to avoid being graded.
If a clean score is easier than a censored one, there's a Goodhart gradient
toward acting less to look better-calibrated — while the job (catch failures early)
degrades. Fix: track CENSORED rate as a first-class number with an expectation;
it must track how often leading indicators actually cross the danger zone. Rate
falling while risk indicators stay flat = learning to dodge the grader, alarm it.

## Regression discontinuity — named, and its ceiling stated
Predictions just below the action cutoff vs just above are near-identical; the
below-threshold cohort is a local control. Legitimate technique. Honest ceiling:
at 2–4 nodes it is never statistically powered — qualitative, not a number to
trust like an A/B test. Say so in any doc that names it.

## Calibration probes — the non-monstrous control group
Not blanket withholding. On a small predetermined fraction of threshold crossings,
hold the auto-restart, tighten manual watch, bounded window, hard manual abort
floor — logged as a calibration probe. A handful of uncensored data points a year.
All that's achievable at this scale; still worth more than zero.

## Provenance vocabulary (sealed)
`MEASURED` · `ATTESTED` · `INFERRED` · `CENSORED` · `ABSTAIN` · `DOCTRINE`

---

## DESIGN FREEZE
The design has been sound on paper since Finding 1. Findings 1 → 2L are all
dispositioned. No further architecture is added until a node serves a real
signed heartbeat. The next artifact committed to this repo is a PUBLIC KEY in
`pubkeys/`, not another markdown file. Everything above is STANDBY until then.

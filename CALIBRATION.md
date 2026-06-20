# Calibration — what makes the intelligence ELITE, not just adaptive

Elite is not the model that claims the most. It is the one that knows when it is
wrong and says so. The dead-man's-switch catches a DEAD model. This catches the
harder, more dangerous failure: a model that is ALIVE and CONFIDENTLY WRONG — a
forgery the model itself believes.

## The regress trap, and the one exit

Grading an INFERRED signal with a second model just moves the question up one
level, now in probability-space (who calibrates the calibrator?). Infinite.

Exit: **do not grade inference with inference. Grade every inference against the
MEASURED reality that arrives next.** The model predicts at T; the probe/signed
heartbeat at T+1 is ground truth; the prediction is scored against it. The floor
is the grader. No second model, no regress — because the grader isn't an opinion,
it's the measured truth the whole system already produces.

## Mechanism (four pieces)

1. **Every INFERRED output is a falsifiable prediction with a probability.**
   Not "Monarch looks degraded" — "P(Monarch DOWN within 10m) = 0.72", logged with
   a timestamp and the evidence. A claim with no probability cannot be scored,
   so it is not allowed.
2. **Score it when ground truth lands.** At resolution time, compare the
   prediction to what MEASURED actually showed. Keep a rolling Brier score
   (mean squared error of probability vs outcome) per signal type, per node.
3. **Calibration is itself MEASURED and visible.** The model's Brier/calibration
   is a first-class telemetry value on the dashboard, same as latency. "How
   trustworthy is the intelligence right now" is never a vibe; it is a number
   with a trend.
4. **Drift => AUTO-ABSTAIN, fail-closed.** If rolling calibration crosses a
   threshold (worse than a no-skill baseline that always predicts base rates),
   the layer demotes itself: INFERRED outputs switch to `ABSTAIN` — visibly,
   loudly — and the floor (MEASURED + verifier + dead-man's-switch) carries on
   alone. A miscalibrated model that keeps talking is worse than silence.

## ABSTAIN is a feature, not a failure

New provenance state: `ABSTAIN` — "the intelligence does not currently meet its own
calibration bar, so it is declining to opine." An elite operator says 'I don't
know' on cue. A model that never abstains is not confident, it is uncalibrated.
ABSTAIN is rendered as honestly as DOWN — the system is proud to show it.

## Why this is the elite ceiling, stated plainly (invariant 4)

- It cannot drift into confident-wrong silently: confidence is continuously
  checked against measured outcomes, and the check is visible.
- It needs no watcher-of-the-watcher: the grader is the measured floor that
  already exists, not a new trusted component.
- It fails the right direction: lost calibration => abstain => floor-only, never
  => keep asserting. Same fail-closed law as everything beneath it.
- It is honest about its own limits in public, which is the actual mark of an
  elite system — not the breadth of what it claims, but the precision of what it
  refuses to claim.

## Provenance vocabulary (final)

`MEASURED` · `ATTESTED` · `INFERRED` (scored, calibrated prediction) ·
`ABSTAIN` (intelligence below its own bar) · `DOCTRINE` (intent).

## Status: STANDBY
Requires measured history to score against — which requires nodes serving signed
heartbeats. The intelligence earns the right to opine only after it has been
scored against enough real outcomes to prove it is calibrated. Until then it
ABSTAINS by default. Elite is a result you measure, not a label you apply.

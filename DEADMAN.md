# Dead-man's-switch — the termination point (who watches the watcher)

The regress ends here. Stop adding watchers; pick a termination point whose
DEFAULT state is already alarm. Switch from "detect bad, then alarm" to "require
continuous proof of good, and let silence itself be the alarm." A polling
watcher's own death and "all fine" look identical (no alert either way). A dead-
man's-switch's own death and the watched thing's death also look identical — but
here identical means BOTH fire, by default, with no logic needed to tell them
apart. The watcher need not correctly notice it failed; it only needs to stop
proving it's fine, and silence does the rest.

## Minimum design — four pieces, no more

1. **Gated check-in, not a bare timer.** The aggregator pings an external
   dead-man's-switch service ONLY when, this cycle, it has confirmed fresh AND
   properly verified data. The ping is the OUTPUT of the real verification, not
   a parallel heartbeat.
2. **Third-party termination point** — decorrelated from our infra. If the switch
   lived on Valkyrie, Valkyrie's death silences system and alarm together.
3. **Escalation window** — no check-in within ~2–3x normal interval => fires.
   Absence alone is sufficient; no human judgment to "decide."
4. **Multi-channel final notification** — push + SMS minimum, never email alone.

## FINDING 2H — an ungated check-in is decorative (2A in a third costume). HIGH.
A cron that pings every 5 min regardless monitors "is cron running," not "is the
system healthy." The check-in MUST be the literal output of the SAME pass/fail
logic that drives the status page — same function, same code path.

## FINDING 2I — one definition of "healthy." MED-HIGH.
Do NOT write a separate lightweight check for the alarm. One source of truth for
"healthy," consumed by BOTH the public status render AND the check-in gate. Two
definitions WILL drift, and drift = silent loss of meaning.

## FINDING 2J — single-channel notification relocates the SPOF to the last six inches. MED.
Email alone fails to spam / silent phone / provider outage. Multiple independent
channels. Cheapest fix in the whole review; easiest to skip.

## The honest ceiling (invariant 4)
This does not remove the human. It terminates at you, checking a phone. What it
changes: the thing that reaches you is triggered by ABSENCE, not by something
correctly detecting PRESENCE of a problem. The failures that defeat a polling
watcher (crashed, forgot, silently stopped) become the failures that make this
ring LOUDER. That is the real answer to "who watches the watcher": trust
relocated to the one place it always had to land — a human with a phone.

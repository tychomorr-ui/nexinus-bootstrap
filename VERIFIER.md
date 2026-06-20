# Verifier build spec — fail-CLOSED by construction

Binding rules for the heartbeat verifier (browser static page AND aggregator).
Written before the verifier exists so it is built correct, not patched later.
Unifying law (from the review): *every place a guarantee can silently downgrade
must emit a visible signal — a render state, a log line, an alert.* "ATTESTED"
must never mean "nobody happened to notice it stopped being true."

## 2A — Fail-open-by-omission is the #1 risk. Structure, not try/catch.

The danger is not bad math; it's a swallowed exception leaving the last good
render in the DOM, reading as ATTESTED forever. Mandatory structure:

1. EVERY render cycle FIRST sets the node to `UNVERIFIED` (visible error state).
2. Only an explicit positive `true` verification result transitions out of it.
3. NEVER reuse a prior render as fallback. "Did not complete" and "succeeded"
   must never share a default. Default is always UNVERIFIED/error.
4. Verification returns a boolean; a thrown exception => UNVERIFIED, never green.

## 2B — Verify untouched bytes, before any parse.

Ed25519 verifies exact bytes. Re-serializing a parsed object will drift
(key order, whitespace, int/float). Rules:
- Verify over the RAW response bytes of the `payload` string, before JSON.parse.
- NEVER parse the counter into a JS Number before verifying (doubles lose
  precision above 2^53). Treat counter as an opaque string until after verify.
- Parse ONLY after verification succeeds, and only for display.
- If verification fails because of a byte mismatch: that is correct. Do NOT
  "fix" it by re-canonicalizing and verifying the object — that silently converts
  an unforgeable check into "trust the browser's interpretation." Forbidden.

## 2C — SPKI/PEM import + mandatory test vector.

`openssl pkey -pubout` emits PEM (armored base64). WebCrypto `importKey('spki')`
wants raw DER bytes: strip `-----BEGIN/END-----`, strip ALL whitespace/newlines,
atob, into Uint8Array. Ship a KNOWN-ANSWER test vector (fixed pubkey + message +
signature => must verify true) that runs on every deploy, so an OpenSSL/browser
format drift fails CI, not a visitor staring at a stuck page.

## 2D — Native Ed25519 is missing for ~1/5 of real users. Be honest, no polyfill.

Native WebCrypto Ed25519: Chrome 137+ (2025), Firefox 129+, Safari 17+. Older/
managed/embedded browsers throw 'unrecognized algorithm'. Do NOT ship a pure-JS
Ed25519 polyfill (new attack surface + supply-chain dep). Instead: catch the
unsupported-algorithm throw and render an explicit `VERIFICATION UNSUPPORTED IN
THIS BROWSER` state — never fall through to anything resembling green. (This is
just 2A applied to one specific throw.)

## 2E — Aggregator history store: FAIL CLOSED on missing/corrupt. (one-line, do first)

The history store is the only thing between true non-replay and TTL-only. If it's
unreadable/empty on startup: REJECT everything (UNKNOWN) until re-baselined.
NEVER treat "no history" as "accept this one" — that makes corrupt-then-replay a
one-step attack. Also: writes must be atomic/locked (no concurrent lost updates
rolling a counter backward). Backup/restore of Valkyrie reopens replay windows
for every heartbeat between snapshot and restore — treat a restore as a forced
re-baseline event and log it visibly.

## 2F — Hash chain only helps with an EXTERNAL checkpoint. Say so.

A hash chain proves nothing against whoever can rewrite both chain and storage
(hashing needs no secret). Against the real threat (Valkyrie compromise, or you
restoring a stale backup) it's decorative WITHOUT an external anchor. Fix:
periodically publish only the chain-TIP hash outside Valkyrie's write control
(a scheduled GitHub Action appends it here / bakes it into the static page). Then
a rollback is detectable — regenerated local chain won't match the anchored tip.
This borrows GitHub-account integrity (Finding 4); document it as defense-in-
depth (both must fall, a higher bar than either), not a free lunch.

## Status: STANDBY until a real node signs. Build this against real bytes, never a mock.

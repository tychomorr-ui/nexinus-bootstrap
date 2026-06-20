# Attestation doctrine — how a node proves its own state

This document is the binding rule for cryptographic attestation. It exists
because the wrong choice here fails *silently* — it keeps looking like proof
while no longer being proof. Read this before writing any signing code.

## The decision: Ed25519, never HMAC

HMAC is symmetric — the key that *verifies* a signature is the same key that
*forges* it. That forces leaking the key into the public verifier, or faking
independence. Both violate the DNA. We use **Ed25519 (asymmetric)**: the node
signs with its private key; anyone verifies with the public key. A public key is
not a secret — safe to embed in client-side JS and commit here in plaintext.

## THE ONE RULE (non-negotiable)

> A private key is generated ONLY on the node it belongs to, and the ONLY thing
> that ever leaves that node is the public half.

Never generate a node key on a laptop "to test." Never push a private key through
this repo. Never paste one into a terminal, chat, or clipboard. Break it once and
every property below quietly stops holding while still looking like it holds.

## Keygen is idempotent

The setup script generates a key ONLY if none exists
(`if [ ! -f /etc/nexinus/node.key ]`). A re-run never rotates the key out from
under the registered public key. Rotation is a deliberate, separate act.

## FINDING 1G — authenticated public-key handoff (no TOFU)

On-node keygen proves "the private key never left." It does NOT prove the public
key the aggregator first receives actually came from that node and not an
impersonator during provisioning. Do not build a new upload endpoint for this.
**Push the public key out over the channel you already authenticate and trust —
SSH / WireGuard you control — never a second, weaker path.** First registration
is the one moment the whole scheme rests on trust; anchor it to an already-
trusted channel.

## The guarantee boundary (say it out loud — invariant 4)

A stateless verifier cannot detect "I have seen this exact valid message
before." That is what stateless means; it is not a missing feature. So we divide
guarantees explicitly and never pretend otherwise:

| Verifier | Holds history? | Guarantees | Does NOT guarantee |
|----------|----------------|------------|--------------------|
| Static page (GitHub Pages) | no | valid signature + approximate freshness (TTL) | non-replay |
| Aggregator | yes | all of the above + counter monotonicity (true non-replay) | — |

**The static fallback proves authenticity and approximate freshness; it does NOT
prove non-replay. Full replay protection exists only where heartbeat history is
kept (the aggregator).** This boundary is stated in the UI, not hidden.

### Replay defense on the stateless path = tight TTL, not the counter

The counter only does work if something remembers the last value. On a zero-
backend page nothing does, so the lever is TTL width. For the directly-served
signed heartbeat (the node rewrites it every 15s), set a tight freshness window
(~90–120s). A captured-and-replayed "up" is then convincing for under ~2 minutes
before it fails on staleness regardless of signature validity. That makes replay
low-value rather than load-bearing — the honest most a stateless verifier can do.

> Note: the aggregated `status.json` (15-min refresh) keeps its wider 32-min
> wrapper TTL. The tight ~90s TTL applies to the per-node signed `/health`
> heartbeat, which is rewritten every 15s on the node.

### If true counter-replay defense is ever wanted (ranked, honestly)

1. Browser-local state — only protects a returning tab; not a real guarantee.
2. A GitHub Action writes a per-node ratchet file (last counter) on GitHub infra,
   outside the node SPOF. Worst case if compromised: false-stale (DoS), never a
   forged "up" (no private key). Reintroduces Finding 4 dependency — not free.
3. Hash-chain each heartbeat (embed prev hash) so the ratchet is tamper-evident:
   a rollback shows a broken seam to anyone holding any prior heartbeat.

Default: do NONE of these. Keep the static page zero-dependency and document the
boundary. Replay-immunity is the aggregator's job because it already has history.

## On-node key generation (run ONCE per node, at provision)

```bash
mkdir -p /etc/nexinus && chmod 700 /etc/nexinus
[ -f /etc/nexinus/node.key ] || openssl genpkey -algorithm ed25519 -out /etc/nexinus/node.key
chmod 600 /etc/nexinus/node.key
openssl pkey -in /etc/nexinus/node.key -pubout -out /etc/nexinus/node.pub
# Public half is the ONLY thing that leaves — hand it over SSH/WireGuard (1G),
# then commit it to pubkeys/<node>.pub (plaintext is correct for a public key).
```

## Signed heartbeat shape

Sign the exact payload STRING (not a re-serialized object — avoids canonical-
ization ambiguity); serve that same string back so the verifier checks identical
bytes:

```
payload = '{"node":"tesseract-a","status":"up","counter":<int>,"measured_at":"<iso8601>"}'
served  = { "payload": <payload as a JSON string>, "sig": base64(ed25519_sign(node.key, payload)), "alg":"ed25519" }
```

Counter increments only on a successful self-measurement, never on failure.

## Verification (each path runs what it CAN, and says what it can't)

1. Verify `sig` over the exact `payload` bytes with the node's public key. Fail → UNKNOWN.
2. Reject if `measured_at` older than the path's TTL. → UNKNOWN.
3. Aggregator ONLY: reject if `counter` <= last counter seen (true non-replay). → UNKNOWN.
4. Pass all applicable checks → may render real status. Only then is "ATTESTED" honest.

## Status: STANDBY

No node signs yet. Until a real signed heartbeat passes verification, every node
reads UNKNOWN/measured-only — never ATTESTED. The word "ATTESTED" ships in public
only after the verification path above is live and passing on real signatures.

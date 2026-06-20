# Attestation doctrine — how a node proves its own state

This document is the binding rule for cryptographic attestation. It exists
because the wrong choice here fails *silently* — it keeps looking like proof
while no longer being proof. Read this before writing any signing code.

## The decision: Ed25519, never HMAC

HMAC is symmetric — the key that *verifies* a signature is the same key that
*forges* it. That forces an unacceptable choice:

- Put the key in the public status page so it can verify → anyone who views
  source can forge any node's status forever. (Leak the secret.)
- Don't verify on the page, only echo what the aggregator said → the
  "independent" status page is cosmetic. (Fake the independence.)

Both violate the DNA. **We use Ed25519 (asymmetric) instead.** The node signs
with its private key; anyone verifies with the public key. A public key is, by
definition, not a secret — it is safe to embed in client-side JS, commit to this
repo in plaintext, and hand to anyone.

## THE ONE RULE (non-negotiable)

> A private key is generated ONLY on the node it belongs to, and the ONLY thing
> that ever leaves that node is the public half.

Never generate a node key on a laptop "to test." Never push a private key through
this repo "temporarily." Never paste one into a terminal, chat, or clipboard.
Break this rule once and every property below quietly stops holding while still
looking like it holds — which is the exact failure class this whole effort fights.

## What this buys (maps to the findings)

- **1C (key has nowhere safe to live):** resolved. The verifier only ever needs
  public keys. The GitHub Pages page verifies signatures itself, in-browser,
  with zero secret material in its code. Independent verification was the easy
  part once the primitive is asymmetric.
- **1D (aggregator becomes a master keyring):** resolved. The aggregator holds
  only public keys. Compromising Valkyrie yields Valkyrie's data, not the power
  to forge Monarch's or Tesseract-A's signatures.
- **1E (replay of a captured valid heartbeat):** resolved by putting a
  strictly-increasing counter AND `measured_at` INSIDE the signed bytes. Every
  verifier rejects a signature whose counter has not advanced past the last one
  seen. A real signature over stale data fails the freshness check even though
  the signature itself is valid.
- **1F (bootstrap & rotation):** resolved. Keygen happens on-node at provision.
  Rotation = generate a new keypair on the node, publish the new public key
  (safe to commit anywhere). A key on a currently-DOWN node cannot be rotated
  and cannot be trusted as fresh either — which is correct: a node you can't
  reach should read UNKNOWN, not ATTESTED.

## On-node key generation (run ONCE per node, at provision)

Uses openssl, already present on the box. Private key stays in /etc/nexinus,
mode 600, never copied off.

```bash
mkdir -p /etc/nexinus && chmod 700 /etc/nexinus
openssl genpkey -algorithm ed25519 -out /etc/nexinus/node.key
chmod 600 /etc/nexinus/node.key
# Public half — this is the ONLY part that leaves the node:
openssl pkey -in /etc/nexinus/node.key -pubout -out /etc/nexinus/node.pub
cat /etc/nexinus/node.pub   # copy this; commit it to pubkeys/<node>.pub
```

## Signed heartbeat shape

The node signs a canonical payload that contains its own freshness proof:

```
payload = {"node":"tesseract-a","status":"up","counter":<monotonic int>,"measured_at":"<iso8601>"}
sig     = ed25519_sign(node.key, exact_payload_bytes)
heartbeat = { ...payload, "sig": base64(sig) }
```

The counter is read from /etc/nexinus/counter, incremented, and written back on
every successful self-measurement — never on a failed probe.

## Verification (aggregator AND the static page do the SAME check)

1. Look up the node's public key from `pubkeys/<node>.pub` (committed plaintext).
2. Verify `sig` over the exact payload bytes. Fail → UNKNOWN.
3. Reject if `counter` <= last counter seen for that node (replay). → UNKNOWN.
4. Reject if `measured_at` older than the freshness TTL. → UNKNOWN.
5. Only if all pass: render the node's real status.

Only a heartbeat that passes all four may be labeled ATTESTED. That is the only
use of the word "ATTESTED" that is honest in public.

## Status: STANDBY

No node signs yet (nodes must be serving first). Until a real signed heartbeat
arrives, every node reads UNKNOWN/measured-only — never ATTESTED. We do not ship
the word "ATTESTED" anywhere public until the verification path above is live
and passing on real signatures.

/*
 * ZAPIER "Code by Zapier" step — live second-witness refresher.
 *
 * HARDENED for Finding 1B (timestamp authenticity):
 *  - NO optimistic timestamps. A node's `measured_at` is stamped ONLY after its
 *    own probe round-trip completes. A hung/failed probe yields status "down"
 *    and a CURRENT measured_at for that failure (an honest, fresh "down") — it
 *    never reuses a last-known "up", and it never stamps a node it didn't reach.
 *  - The wrapper `generated` is just the run time; the reader gates each node on
 *    its OWN measured_at, so a forged wrapper can't vouch for unprobed nodes.
 *
 * Wire-up: Schedule (15 min) → this Code step → GitHub "Update File" status.json
 *          with content = {{output__content}}.
 */

const ENDPOINTS = [
  { name: "xinus-monarch (sovereign · monarch.xinus.one)", url: "https://monarch.xinus.one/health" },
  { name: "xinus-monarch (bolt endpoint)",                 url: "https://xinus-monarch-epoint.bolt.host/health" },
  { name: "valkyrie.nexinus.net",                          url: "https://valkyrie.nexinus.net" },
  { name: "xinus.one",                                     url: "https://xinus.one" },
  { name: "tesseract-a (nexinus.net)",                     url: "https://nexinus.net/health" },
];

async function probe(ep) {
  const t0 = Date.now();
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 7000);
  try {
    const res = await fetch(ep.url, { method: "GET", redirect: "follow", signal: ctrl.signal });
    clearTimeout(timer);
    const latencyMs = Date.now() - t0;
    let healthOk = null;
    try { if (/"ok"\s*:\s*true/.test(await res.text())) healthOk = true; } catch (_) {}
    const up = res.ok;
    // measured_at stamped HERE — only because this probe actually completed.
    return { name: ep.name, status: up ? "up" : "down", reachable: up,
             latencyMs: up ? latencyMs : null, healthOk, measured_at: new Date().toISOString() };
  } catch (_) {
    clearTimeout(timer);
    // Probe failed/timed out: honest fresh "down". Never reuse a prior "up".
    return { name: ep.name, status: "down", reachable: false, latencyMs: null,
             healthOk: null, measured_at: new Date().toISOString() };
  }
}

const nodes = [];
for (const ep of ENDPOINTS) nodes.push(await probe(ep));

const feed = {
  generated: new Date().toISOString(),
  source: "Zapier scheduled probe (independent second witness)",
  nodes,
};

output = { content: JSON.stringify(feed, null, 2) };

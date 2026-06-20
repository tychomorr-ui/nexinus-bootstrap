/*
 * ZAPIER "Code by Zapier" step (Run JavaScript) — the live second-witness refresher.
 *
 * HOW TO USE:
 * 1. Zap trigger: Schedule by Zapier → every 15 minutes.
 * 2. Action: Code by Zapier → Run JavaScript → paste this whole file.
 * 3. Action: GitHub → "Update File" (or Webhooks PUT to the GitHub contents API)
 *    on repo tychomorr-ui/nexinus-bootstrap, path status.json,
 *    content = {{output__content}} from this step.
 *
 * It probes each endpoint from Zapier's servers (an INDEPENDENT vantage point
 * from the app's browser probe — a real second witness), then emits the exact
 * JSON shape Truth Point's ExternalWitness expects. No fabricated data: a node
 * that doesn't answer is reported down.
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
    try {
      const text = await res.text();
      if (/"ok"\s*:\s*true/.test(text)) healthOk = true;
    } catch (_) {}
    const up = res.ok;
    return { name: ep.name, status: up ? "up" : "down", reachable: up, latencyMs: up ? latencyMs : null, healthOk };
  } catch (_) {
    clearTimeout(timer);
    return { name: ep.name, status: "down", reachable: false, latencyMs: null, healthOk: null };
  }
}

const nodes = [];
for (const ep of ENDPOINTS) nodes.push(await probe(ep));

const feed = {
  generated: new Date().toISOString(),
  source: "Zapier scheduled probe (independent second witness)",
  nodes,
};

// Zapier Code steps return via `output`. The GitHub Update File action reads
// output.content as the new file body.
output = { content: JSON.stringify(feed, null, 2) };

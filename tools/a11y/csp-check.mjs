// Content-Security-Policy check for generated sites (#82 / epic #77).
//
// Serves a built site over HTTP (a policy's 'self' means an origin, which
// file:// does not give), loads every page in headless Chromium, and fails on
// any policy violation the browser reports. On the search page it also runs a
// query, so Pagefind's WebAssembly and fetches are exercised under the policy.
//
// Usage: node csp-check.mjs <site-dir> [--query <term>]
import { chromium } from "playwright";
import { createServer } from "node:http";
import { createReadStream, readdirSync, statSync, existsSync } from "node:fs";
import { join, extname, normalize } from "node:path";

const args = process.argv.slice(2);
const qi = args.indexOf("--query");
const query = qi >= 0 ? args.splice(qi, 2)[1] : "plugin";
const root = args[0];
if (!root) {
  console.error("usage: node csp-check.mjs <site-dir> [--query <term>]");
  process.exit(2);
}

const types = {
  ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript",
  ".mjs": "text/javascript", ".json": "application/json", ".svg": "image/svg+xml",
  ".png": "image/png", ".jpg": "image/jpeg", ".woff2": "font/woff2", ".woff": "font/woff",
  ".wasm": "application/wasm", ".xml": "application/xml", ".txt": "text/plain", ".map": "application/json",
};
const server = createServer((req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, "http://x").pathname));
  let file = join(root, path);
  if (existsSync(file) && statSync(file).isDirectory()) file = join(file, "index.html");
  if (!file.startsWith(normalize(root)) || !existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "content-type": types[extname(file)] || "application/octet-stream" });
  createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}`;

function htmlUnder(dir, prefix = "") {
  return readdirSync(dir).flatMap((name) => {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) return htmlUnder(full, `${prefix}${name}/`);
    return name.endsWith(".html") ? [`${prefix}${name}`] : [];
  });
}
const pages = htmlUnder(root).sort();

const browser = await chromium.launch();
const context = await browser.newContext();
await context.addInitScript(() => {
  document.addEventListener("securitypolicyviolation", (e) => {
    console.error(`CSP violation: ${e.violatedDirective} blocked ${e.blockedURI || "inline"} at ${e.sourceFile || document.location.pathname}:${e.lineNumber || 0}`);
  });
});
const page = await context.newPage();
const violations = [];
page.on("console", (m) => { if (m.type() === "error" && /Content Security Policy|CSP violation/.test(m.text())) violations.push(m.text()); });
page.on("pageerror", (e) => violations.push(`page error: ${e.message}`));

let checked = 0, withPolicy = 0;
for (const p of pages) {
  const before = violations.length;
  await page.goto(`${base}/${p}`, { waitUntil: "load" });
  const policy = await page.$eval('meta[http-equiv="Content-Security-Policy"]', (m) => m.content).catch(() => null);
  if (policy) withPolicy++;
  if (p === "search.html") {
    const input = await page.$("#app-search input");
    if (input) { await input.fill(query); await page.waitForTimeout(1500); }
    const results = await page.$$(".pagefind-ui__result");
    if (input && results.length === 0) violations.push("search.html: no results under the policy (Pagefind blocked?)");
  }
  checked++;
  if (violations.length > before) console.log(`✗ ${p}`);
}
await browser.close();
server.close();

for (const v of violations) console.log(`  ${v}`);
console.log(`csp-check: ${checked} page(s), ${withPolicy} with a policy, ${violations.length} violation(s)`);
process.exit(violations.length === 0 ? 0 : 1);

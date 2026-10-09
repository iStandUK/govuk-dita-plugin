// Embedded view check (#201): a site built with govuk.embed=yes, one of its
// pages framed by a host page on the same origin and opened with ?embed=1.
//
// Serves the site over HTTP with a host page of its own at /__host.html, and
// fails unless, in headless Chromium:
// - the framed page shows its content and none of its furniture;
// - axe finds no WCAG 2.2 AA violation, and no Content-Security-Policy is broken;
// - a link in an inlined SVG diagram moves the frame, not the host page, and
//   keeps embed=1; so does a text link;
// - the same page opened at the top level, or framed without JavaScript, is
//   shown in full.
//
// Usage: node embed-check.mjs <site-dir> <page> [svg-link-href] [text-link-page]
//   e.g. node embed-check.mjs out/kitchen-embed topics/media.html reference-full.html topics/task-full.html
//   The text link is followed on text-link-page (default: <page>), framed the same way.
import { chromium } from "playwright";
import { AxeBuilder } from "@axe-core/playwright";
import { createServer } from "node:http";
import { createReadStream, statSync, existsSync } from "node:fs";
import { join, extname, normalize } from "node:path";

const [root, pagePath, svgHref = "", textPage = pagePath] = process.argv.slice(2);
if (!root || !pagePath) {
  console.error("usage: node embed-check.mjs <site-dir> <page> [svg-link-href]");
  process.exit(2);
}

const types = {
  ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript",
  ".mjs": "text/javascript", ".json": "application/json", ".svg": "image/svg+xml",
  ".png": "image/png", ".jpg": "image/jpeg", ".woff2": "font/woff2", ".woff": "font/woff",
  ".wasm": "application/wasm", ".xml": "application/xml", ".txt": "text/plain", ".map": "application/json",
};
const host = (src) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Host</title></head>
<body><main><h1>Host</h1><iframe title="Embedded page" src="${src}" style="width:1200px;height:800px"></iframe></main></body></html>`;
const server = createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  if (url.pathname === "/__host.html") {
    res.writeHead(200, { "content-type": types[".html"] });
    res.end(host(url.searchParams.get("src")));
    return;
  }
  const path = normalize(decodeURIComponent(url.pathname));
  let file = join(root, path);
  if (existsSync(file) && statSync(file).isDirectory()) file = join(file, "index.html");
  if (!file.startsWith(normalize(root)) || !existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "content-type": types[extname(file)] || "application/octet-stream" });
  createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}`;
const hostFor = (p) => `${base}/__host.html?src=${encodeURIComponent(`/${p}?embed=1`)}`;
const hostUrl = hostFor(pagePath);

const failures = [];
const check = (ok, what) => { console.log(`${ok ? "✓" : "✗"} ${what}`); if (!ok) failures.push(what); };
const furniture = [".app-masthead", ".app-sidebar", ".govuk-footer", ".govuk-pagination", ".govuk-phase-banner"];
const shown = (frame, selector) => frame.$eval(selector, (e) => !!(e.offsetWidth || e.offsetHeight || e.getClientRects().length)).catch(() => false);

async function frameOf(page) {
  const handle = await page.waitForSelector("iframe");
  const frame = await handle.contentFrame();
  await frame.waitForLoadState("load");
  return frame;
}

const browser = await chromium.launch();

// 1. Framed, with ?embed=1
const context = await browser.newContext();
await context.addInitScript(() => {
  document.addEventListener("securitypolicyviolation", (e) => {
    console.error(`CSP violation: ${e.violatedDirective} blocked ${e.blockedURI || "inline"}`);
  });
});
const page = await context.newPage();
const errors = [];
page.on("console", (m) => { if (m.type() === "error" && /Content Security Policy|CSP violation/.test(m.text())) errors.push(m.text()); });
page.on("pageerror", (e) => errors.push(`page error: ${e.message}`));
await page.goto(hostUrl, { waitUntil: "load" });
let frame = await frameOf(page);
check(await frame.$eval("html", (e) => e.classList.contains("app-embed")), "framed with ?embed=1: html has app-embed");
for (const s of furniture) {
  if (await frame.$(s)) check(!(await shown(frame, s)), `framed: ${s} is hidden`);
}
check(await shown(frame, "main"), "framed: the content is shown");
const axe = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]).analyze();
for (const v of axe.violations) console.log(`  axe: ${v.id} (${v.nodes.length})`);
check(axe.violations.length === 0, "framed: no axe violations");

if (svgHref) {
  const link = await frame.$(`svg a[href$="${svgHref}"], svg a[*|href$="${svgHref}"]`);
  check(!!link, `framed: the diagram has a link to ${svgHref}`);
  if (link) {
    check(!(await link.getAttribute("target")), "framed: the diagram link has no target");
    await Promise.all([frame.waitForNavigation(), link.click()]);
    frame = await frameOf(page);
    const url = new URL(frame.url());
    check(url.pathname.endsWith(`/${svgHref}`) && url.searchParams.get("embed") === "1",
      `diagram link moved the frame, keeping embed=1 (${url.pathname}${url.search})`);
    check(page.url() === hostUrl, "diagram link left the host page where it was");
    check(await frame.$eval("html", (e) => e.classList.contains("app-embed")), "the next page is embedded too");
  }
}

await page.goto(hostFor(textPage), { waitUntil: "load" });
frame = await frameOf(page);
const textLink = await frame.$$eval("main a[href]", (as) => {
  const a = as.find((x) => x instanceof HTMLAnchorElement && !x.getAttribute("href").startsWith("#")
    && new URL(x.href).origin === location.origin && !x.target && x.offsetWidth > 0);
  if (a) a.setAttribute("data-embed-check", "");
  return a ? a.getAttribute("href") : null;
});
check(!!textLink, `framed: ${textPage} has a link to another page of the site`);
if (textLink) {
  await Promise.all([frame.waitForNavigation(), frame.click("[data-embed-check]")]);
  frame = await frameOf(page);
  check(new URL(frame.url()).searchParams.get("embed") === "1", `text link kept embed=1 (${textLink})`);
}
for (const e of errors) console.log(`  ${e}`);
check(errors.length === 0, "no CSP violations or script errors");
await context.close();

// 2. Opened at the top level with ?embed=1: the full page
const top = await browser.newPage();
await top.goto(`${base}/${pagePath}?embed=1`, { waitUntil: "load" });
check(!(await top.$eval("html", (e) => e.classList.contains("app-embed"))), "top level with ?embed=1: no app-embed");
check(await shown(top.mainFrame(), ".app-masthead"), "top level: the masthead is shown");
await top.close();

// 3. Framed without JavaScript: the full page (NFR-A3)
const noJs = await browser.newContext({ javaScriptEnabled: false });
const plain = await noJs.newPage();
await plain.goto(hostUrl, { waitUntil: "load" });
const plainFrame = await frameOf(plain);
check(await shown(plainFrame, ".app-masthead"), "framed without JavaScript: the masthead is shown");
await noJs.close();

await browser.close();
server.close();
console.log(`embed-check: ${failures.length} failure(s)`);
process.exit(failures.length === 0 ? 0 : 1);

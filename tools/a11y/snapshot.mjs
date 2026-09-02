// Visual snapshots for govuk-frontend upgrades (#35 / NFR-M2).
//
// Captures full-page PNGs of representative pages at a fixed viewport. These are
// not pixel-diffed in CI (headless font rendering differs across environments and
// would be flaky); instead CI uploads them as an artifact so a reviewer can eyeball
// the rendering when the vendored govuk-frontend is bumped. Run locally the same way
// to compare before/after a version change.
//
// Usage: node snapshot.mjs <out-root> <snapshot-dir>
//   <out-root>       a built site directory (e.g. out/manual)
//   <snapshot-dir>   where the PNGs are written
import { chromium } from "playwright";
import { pathToFileURL } from "node:url";
import { mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";

const [outRoot, snapDir] = process.argv.slice(2);
if (!outRoot || !snapDir) {
  console.error("usage: node snapshot.mjs <out-root> <snapshot-dir>");
  process.exit(2);
}

// Representative pages: the cover, a content topic, a table page, a note page,
// the glossary and a booklist — enough to show the framework's key components.
const pages = [
  ["index.html", "home"],
  ["topics/introduction.html", "topic"],
  ["topics/demo-tables.html", "tables"],
  ["topics/demo-notes.html", "notes"],
  ["glossary.html", "glossary"],
  ["figurelist.html", "figurelist"],
];

mkdirSync(snapDir, { recursive: true });
const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: 1024, height: 768 } });
const page = await context.newPage();
let n = 0;

for (const [rel, label] of pages) {
  const file = join(outRoot, rel);
  if (!existsSync(file)) continue;
  await page.goto(pathToFileURL(file).href, { waitUntil: "load" });
  await page.screenshot({ path: join(snapDir, `${label}.png`), fullPage: true });
  n += 1;
}

await browser.close();
console.log(`captured ${n} snapshot(s) to ${snapDir}`);

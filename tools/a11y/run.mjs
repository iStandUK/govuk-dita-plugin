// axe-core accessibility checks for the generated sites (#35 / NFR-A1).
//
// Loads each built HTML page over file:// in headless Chromium and runs axe-core
// at WCAG 2.1 A and AA. Prints every violation with the offending selectors and
// exits non-zero if any page has violations.
//
// Usage: node run.mjs <html-file> [<html-file> ...]
import { chromium } from "playwright";
import { AxeBuilder } from "@axe-core/playwright";
import { pathToFileURL } from "node:url";
import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";

function htmlUnder(target) {
  if (statSync(target).isDirectory()) {
    return readdirSync(target).flatMap((name) => htmlUnder(join(target, name)));
  }
  return target.endsWith(".html") ? [target] : [];
}

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("usage: node run.mjs <html-file-or-dir> [...]");
  process.exit(2);
}
const files = args.flatMap(htmlUnder).sort();

const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
let total = 0;

for (const file of files) {
  await page.goto(pathToFileURL(file).href, { waitUntil: "load" });
  const { violations } = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
    .analyze();
  if (violations.length) {
    total += violations.length;
    console.log(`\n✗ ${file}`);
    for (const v of violations) {
      const nodes = v.nodes.map((n) => n.target.join(" ")).join(", ");
      console.log(`  [${v.impact}] ${v.id}: ${v.help}`);
      console.log(`    ${nodes}`);
      console.log(`    ${v.helpUrl}`);
    }
  }
}

await browser.close();
console.log(`\naxe checked ${files.length} page(s); ${total} violation type(s) found`);
process.exit(total === 0 ? 0 : 1);

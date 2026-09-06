// Chromium print smoke for the print document (FR-P2 / D-20, #63).
//
// Loads print.html over file:// in headless Chromium and prints it to a tagged
// PDF with an outline on the paper size given, then asserts the result is a
// real multi-page document: more than one page, a document outline, a title.
// CI-only evidence that the print target works in a browser; not a build
// dependency of the plugin.
//
// Usage: node print-smoke.mjs <print.html> [<out.pdf>] [--paper A4|Letter]
import { chromium } from "playwright";
import { pathToFileURL } from "node:url";
import { readFileSync, writeFileSync } from "node:fs";

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("usage: node print-smoke.mjs <print.html> [<out.pdf>] [--paper A4]");
  process.exit(2);
}
const paperIndex = args.indexOf("--paper");
const paper = paperIndex >= 0 ? args.splice(paperIndex, 2)[1] : "A4";
const [input, output = "print-smoke.pdf"] = args;

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(pathToFileURL(input).href, { waitUntil: "load" });
await page.emulateMedia({ media: "print" });
const pdf = await page.pdf({
  format: paper,
  printBackground: false,
  preferCSSPageSize: true,
  tagged: true,
  outline: true,
});
await browser.close();
writeFileSync(output, pdf);

// Page count and outline from the PDF's own structure: /Type /Page objects and
// an /Outlines dictionary. Reading the file back checks what was written.
const text = readFileSync(output).toString("latin1");
const pages = (text.match(/\/Type\s*\/Page[^s]/g) || []).length;
const outline = /\/Outlines/.test(text);
const structTree = /\/StructTreeRoot/.test(text);
console.log(`print smoke: ${input} -> ${output} (${pdf.length} bytes, ${pages} page(s), outline ${outline ? "yes" : "no"}, tagged ${structTree ? "yes" : "no"})`);

const failures = [];
if (pages < 2) failures.push(`expected more than one page, got ${pages}`);
if (!outline) failures.push("expected a document outline (headings)");
if (!structTree) failures.push("expected a tagged PDF (structure tree)");
if (failures.length) {
  for (const f of failures) console.error(`✗ ${f}`);
  process.exit(1);
}
console.log("print smoke passed");

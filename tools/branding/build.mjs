// Vendor-time Sass recompile of govuk-frontend with brand palettes (#47).
// Compiles each src/<brand>.scss to the plugin's resource dir as
// govuk-frontend-<version>-<brand>.min.css. Run: npm run build
import * as sass from "sass";
import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const version = JSON.parse(
  readFileSync(join(here, "node_modules/govuk-frontend/package.json"))
).version;
const outDir = join(here, "../../org.istanduk.gov-uk/resource/govuk-frontend");

for (const file of readdirSync(join(here, "src")).filter((f) => f.endsWith(".scss"))) {
  const brand = file.replace(/\.scss$/, "");
  const { css } = sass.compile(join(here, "src", file), {
    style: "compressed",
    loadPaths: [join(here, "node_modules")],
    quietDeps: true,
  });
  const out = join(outDir, `govuk-frontend-${version}-${brand}.min.css`);
  writeFileSync(out, css);
  console.log(`${brand}: ${css.length} bytes -> ${out}`);
}

# Verification tooling

Checks the CI runs against the built sites (issue #35). Build a site first, e.g.

```
dita --input docs/manual/manual.ditamap --format govuk --output out/manual
```

then:

| Tool | Checks | Run |
|---|---|---|
| `check_links.py` | Every internal `href`/`src` resolves, and `#fragment` anchors exist (NFR) | `python3 tools/check_links.py out/manual [...]` |
| `page_weight.py` | Each page shell (HTML+CSS+JS) is under the budget, uncompressed (NFR-P2) | `python3 tools/page_weight.py --report --budget-kb 300 out/manual` |
| `a11y/run.mjs` | axe-core at WCAG 2.2 AA over every page (NFR-A1) | `node tools/a11y/run.mjs out/manual [...]` |
| `a11y/snapshot.mjs` | Full-page PNGs for eyeballing a govuk-frontend upgrade (NFR-M2) | `node tools/a11y/snapshot.mjs out/manual out/snapshots` |

Build determinism (FR-B6) is checked in CI by building twice and comparing byte-for-byte.

The accessibility tools need their dependencies once:

```
cd tools/a11y && npm ci && npx playwright install chromium
```

`run.mjs` and `snapshot.mjs` accept files or directories (directories are walked for `.html`).

## Branding recompile (`tools/branding`)

The NHS variant's stylesheet, `org.istanduk.gov-uk/resource/govuk-frontend/govuk-frontend-6.5.0-nhs.min.css`,
is govuk-frontend recompiled from its own Sass against the NHS palette (design/09, D-17). It is
built here at vendor time and **committed**, so end-user builds stay Node-free (D-12):

```
cd tools/branding && npm ci && npm run build
```

CI rebuilds it on every run and fails if the committed file drifts from `src/nhs.scss`.

Licensing: the recompiled CSS is a derivative of govuk-frontend and stays under its MIT licence
with Crown copyright attribution (see the vendored `NOTICE.md`). It contains colours and
metrics only — no NHS logo, no Frutiger. The NHS identity is restricted to NHS organisations
and the NHS brand font is licensed, so neither is bundled; the plugin renders the logo inline
from `nhsuk-frontend`'s MIT-licensed artwork only when `govuk.branding=nhs` is selected, warns in
the build log, and falls back to Arial for the typeface.

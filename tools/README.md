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

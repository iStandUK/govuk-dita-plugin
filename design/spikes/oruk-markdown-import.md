# Spike — ORUK website content into the DITA pipeline (discovery)

**Status:** discovery complete, no plugin code changed · **Date:** 2026-09-04 · **Feeds:** a bounded conversion spike and design decisions on Markdown-sourced publications

For Nicholas Oughtibridge (iStandUK), 4 September 2026. Evidence: the `oruk-standard-and-website` repository (commit 4508f4b, 2026-07-07), the live site, DITA-OT 4.4.1 with org.lwdita 5.9.1 and org.istanduk.gov-uk 0.9.2, and the working files under `scratchpad/oruk-work/` (the prototype converter, the specification-topic generator and the verification scripts live in the separate **ORUK content-migration repository**, kept out of the plugin). Findings were checked adversarially by three independent verifiers and a completeness critic; where they corrected the first draft, the corrected position is what appears here.

## 1. Answer

**Topics from Markdown: yes, with a pre-processing pass.** The 87 Markdown files are plain GitHub-flavoured Markdown rendered by `marked` at library defaults, and the toolkit's bundled org.lwdita reads them as `format="markdown"` topics (the stricter `mdita` profile rejects any `###` heading). The raw files do not build: one stray `</code>` in `content/developers/overview/index.md` aborts the whole publication, `<br/>` inside list items and heading-level jumps are fatal, and every internal link is root-absolute. The prototype converter turned 80 of the 87 files into 54 topics that build cleanly, but adversarial verification found losses the word-coverage check could not see (literal `**` in the PID tables, lost table-header cells, the use-case reading order, the "Updated" date). They are fixable and now enumerated.

**Maps from JSON: yes.** `content/sitemap.json`, the byte-ordered folder listings and the YAML front matter are the whole site structure; they generated a DTD-valid bookmap (6 chapters, 50 topicrefs) reproducing 52 of 59 current URLs. `content/home/index.json` supplies the cover; the gantt and changelog JSON become topics. `content/metadata.json` is dead (the verbatim Next.js docs example, imported by nothing) and `src/redirects.json` holds host-level redirects that belong in hosting configuration. One correction from verification: the six use cases must follow the `links` front-matter chain, not alphabetical order.

**Separating application from content: yes, except five routes.** Validator, register, dashboard (list and per-feed) and community directory read MongoDB, a Heroku API or the GitHub App; they stay an application and the static site links to them (17 of the 74 internal Markdown links point at them). The three reference pages (API, data model, specification) are JSON-rendered shells, not Markdown, and should be generated in the idiom of the existing ORUK DITA corpus, which a spike showed builds clean. The visual identity changes: the live site is a bespoke ORUK look (Inter, teal `#00625e`, MHCLG footer logotype), neither GOV.UK Frontend nor iStandUK.

## 2. What the repository contains

**Content.** 87 `.md` files, 265,690 bytes, about 34,600 words: `content/` 85, `docs/` 1 (a wiki export, not site content), `public/steering/README.md`. 60 files carry front matter (`modified` 60, `title` 32, `slug` 24, `description` 8, `links` 7, `image` 6, `pdf` 3); `slug` is always a teaser sentence, and 46 `modified` values are one script batch-stamp. Headings are ATX H1 to H4; 34 files have no H1 (25 use-case fragments composed by `src/app/adopt/use-cases/[slug]/page.tsx`, 6 versioned developer stubs, 3 of them empty) and 4 have several. Raw HTML is concentrated in three files: `adopt/03_pid.md` (351 tags, three single-line HTML tables), `adopt/02_business_case.md` (232 tags, two styled tables, a styled callout `<div>`, 8 blockquote-plus-`<cite>` pull quotes) and `info/privacy/index.md` (a table with a malformed `</tr`). No authored page uses a pipe table, code fence, footnote or task list. Assets: ten image references, 13 steering PDFs (11 MB), five `/pdf` documents, one `.xlsx`, and `public/specifications/{1.0,3.0}/` (OpenAPI plus 29 schema files) which the 3.0 OpenAPI `$ref`s address by absolute URL.

**Structure.** `content/sitemap.json` (28 uniquely named nodes, depth 2; `name`, `label`, `contentPath`, `urlPath`, `teaser`, `hide`, `dynamic`, `autoMenu`, `offsite`). The three `dynamic` sections list their folder with `fs.readdirSync` and no sort, so the `10-`, `01_` and `1001` prefixes are the order and part of the public URL. Also `content/home/index.json` (hero, five boxes, conclusion), `src/redirects.json` (six legacy hostnames, 308) and `next.config.ts` (`/dashboard` to `/developers/dashboard`).

**Routes** (68 distinct on-site URLs found live, 11 of them dashboard feed records; the live `sitemap.xml` lists only 20, one being the bogus `/adopt/undefined`; the table below counts route kinds, including two generated non-HTML endpoints):

| Class | Routes | URLs |
|---|---|---|
| Content (Markdown) | `/about/*`, `/adopt/*` incl. six composed use cases, `/community`, `/community/join`, `/developers` + overview, compliance, data-sharing, validator/results, `/case-studies/*`, `/info/*`, 404 | 52 |
| Generatable static (JSON-driven) | `/`, `/adopt/gantt`, `/developers/changelog`, `/developers/{api,schemata,specifications}` (client-rendered from `public/specifications`), `/sitemap`, `/sitemap.xml` | 8 |
| Dynamic application | `/community/directory`, `/developers/dashboard`, `/developers/dashboard/[id]` (11 feeds), `/developers/register`, `/developers/validator`, `/api/health` | 6 |

## 3. Two routes for the content

### Route A: reference the Markdown directly through org.lwdita

Every topicref must carry `format="markdown"` (the extension is never used for detection). Each heading level becomes a nested `<topic>`, front matter goes to `<prolog><data>` (only `title` is used, and only when there is no H1), HTML and pipe tables become CALS. Building the raw files fails: `Expected end tag tight-list-p but was codeph` (overview line 93), `Empty tag stack` for `<br/>` in list items, `[DOTJ013E]` for heading jumps, `[DOTX008E] The resource 'file:/adopt/calculator.png' cannot be loaded` for root-relative `src`. The first proof needed 47 logged shims before all 86 files parsed; the prototype converter applies 248 rewrites under 47 rules. `mdita` rejected 5 of 10 sampled files.

| Markdown construct (corpus count) | lwdita markdown mode | Notes |
|---|---|---|
| ATX headings H1 to H4 (475) | Supported | each level nests a topic; ids from title text (`3.1 Collect & manage data` becomes `31-collect--manage-data`) |
| Root-absolute links (68), `<img src="/…">` (6) | Not usable | become `scope="external"` or `file:/`; must be rewritten |
| Bare URLs (3) | Lost | GFM autolinks them; lwdita leaves text |
| HTML `<table>` (6) | CALS | `<th>` outside `<thead>` becomes `<td>`; `**` inside an HTML block stays literal |
| Blockquote + `<cite>` (14) | Supported | `<lq>`, `<cite>` |
| `<br/>` (23) | Fatal inside list items | rewrite as hard line breaks |
| Stray `</code>` (1), heading level jumps (2 files) | Abort the build | repair |
| Images with title (4) | Supported | title becomes a visible caption the live site lacks |
| `{{API_ENDPOINT_URL}}` (4), `$version` (3), bare `[text]` and `{id}` | Literal or mangled | substitute or escape first |
| YAML `>-` folded scalars (13) | Read as literal `>-` | flatten first |
| Front matter `modified`, `links`, `pdf`, `image` | Ignored | carry into the map |

Route A keeps Markdown as the editing format, so ORUK's GitHub contributors keep their workflow, but every build then depends on the pre-processor. The robustness check showed the prototype converter is shaped to today's tree: a new use-case folder without its four fragments, a sitemap child without a content folder, and a new top-level section each crash it with `FileNotFoundError`, while files outside the sitemap (`api/2.0.md`, `community/newsletter/index.md`) are silently ignored and never logged. That brittleness belongs to the converter, not to org.lwdita, and it bites both routes equally on the day of conversion; the difference is that under Route A it is a permanent build-time dependency that must be hardened and maintained, whereas under Route B it runs once and its output is then checked and repaired by hand.

### Route B: convert once to DITA XML and maintain DITA

`dita --format=dita` on the prototype map produced 54 well-formed `<!DOCTYPE topic>` files with the `content/` layout preserved. The known losses (Section 5) become one-time hand repairs rather than converter rules, and DITA gives keyrefs into the existing corpus, reusable boilerplate and no runtime dependence on a fragile converter.

**Recommendation.** Route B for the guidance content, using the prototype converter as the migration tool and the verifiers' diff scripts as the acceptance check. Route A only as a transition if ORUK insists on Markdown editing, with the converter's silent cases turned into errors. The deciding question is not the converter but the editing model (Section 8): who edits case studies and steering minutes afterwards, and in what.

## 4. Maps from the JSON and page tree

The prototype `oruk2dita.py` (492 lines, standard library, 0.15 s) reads `content/sitemap.json`, `content/home/index.json`, the gantt and changelog JSON and 80 Markdown files, and writes one bookmap:

- **Chapters**: the six visible top-level nodes in array order; `hide` nodes become preface or backmatter (`not-found` with `toc="no"`).
- **Topicrefs**: `childNodes` in JSON order, then dynamic folder files in byte order; `<navtitle>` from the sitemap label or front-matter `title` with `locktitle="yes"` (without it the sidebar shows H1s); `<shortdesc>` from `teaser`, `slug` or `description`; `<critdates><revised>` from `modified`.
- **Cover**: `mainbooktitle` "Open Referral UK" plus two `booktitlealt` from the hero; the five home boxes become chapter shortdescs that `govuk.homepage.layout=auto` renders as a grouped landing page; `bookmeta` from `src/app/layout.tsx`.
- **Composed pages**: six use cases merged from `index`, hero image, four fragments and the shared getting-started callout; the versioned reference pages merged from `index`, `3.0` and `1.0`; the three landings that exist only in `page.tsx` generated from their `mainHeading`; gantt JSON to a table topic; changelog JSON to sections; `docs/legacy` as an appendix.
- **Application and offsite nodes**: `<topicref scope="external">` to the forum, the community directory, the register page and the validator. The dashboard has no node because `content/sitemap.json` has none (the live header and sitemap omit it too, so parity holds); the combined map's Tools part must add it explicitly, with the `/dashboard` redirect.

**Correction (both verifiers).** The use cases are sorted alphabetically (map lines 39 to 49); the authored order is the `links` chain index, reuse-data, empower, automated-checks, combine, keep-local, use-combined, how-to-adopt, which the live site renders as previous/next and the numbered list on `/adopt/use-cases` repeats. Map, sidebar and pagination must follow it.

**URLs and redirects.** Keeping the `content/` layout yields `<path>.html` for the 22 extensionless articles and `<dir>/index.html` for the rest; a hosting rule (Vercel `cleanUrls`, Netlify pretty URLs, nginx `try_files`) keeps every current URL byte-identical. On top: rename `content/developers/specification` to `specifications` (done), redirect `/sitemap` to `/` and `/dashboard` to `/developers/dashboard`, move the six host redirects unchanged into host configuration, and point the broken `/contact` link in `not-found/index.md` at `/info/contact`. Page `<title>` follows the H1 rather than the sitemap label (four of the nine generic pages differ). The plugin produces no `sitemap.xml`. **Fragment ids change:** the app gives H2s ids of the form `lowercase_with_underscores`; org.lwdita derives `lowercase-with-hyphens` from the heading text, so the five in-page anchor links, the two `#service` anchors into the schemata page and any inbound external links with fragments break silently unless the converter emits the app's ids or the break is accepted and documented. **Stray URLs:** the prototype also publishes three pages the live site never had (`docs/legacy-…`, `home/benefits`, `not-found/index`); drop the legacy wiki export (it also causes the build's only warning and is the second-heaviest page), hide the home benefits topic (`toc="no"`) or fold it into the cover, and map the 404 topic through the host's not-found rule.

## 5. The prototype build

| Measure | Result |
|---|---|
| Source files read | 80 of 87 (not read: the four application-page intros, `validator/examples.md`, `maintenance.md`, `steering/README.md`) |
| Map | 54 markdown topics, 34 assets, 51 URLs; `xmllint --valid` passes; 248 rewrites under 47 rules |
| `-f govuk` | exit 0, 56 HTML pages, 1 warning; istanduk cover, logo and overlay present |
| `-f dita` | exit 0, 54 well-formed topics, same warning |
| Nu HTML validator | 0 errors |
| Internal links | 3,528 checked across 56 pages, 0 broken |
| Page weight | heaviest shell 283.4 KB uncompressed, 53.5 KB gzipped (`search.html`); all under the 300 KB budget |
| Search | Pagefind index built by default (`govuk.search=auto`; 15 files, 1.0 MB); the live site has none, no query was exercised, and shipping search is a decision (`--govuk.search=no` turns it off) |
| Accessibility (axe-core, WCAG 2.2 AA, `tools/a11y/run.mjs`) | 56 pages, 0 violations; note axe cannot see the lost table row headers below, which remain a real regression until fixed |
| URLs reproduced | 52 of 59 (not produced: five application routes, `/sitemap`, `/sitemap.xml`) |
| Reproducibility | second run: identical `rules.log`, `pages.json` and build results |

Commands (P = `scratchpad/oruk-work/prototype`):

```
python3 P/oruk2dita.py
ot-compat/bin/dita --input=P/src/oruk.ditamap --format=govuk --output=P/out \
  --govuk.branding=istanduk --govuk.homepage.layout=auto --govuk.favicon=oruk/public/favicon.ico \
  "--govuk.footer.licence=…CC BY-SA 4.0…" "--govuk.footer.links=Accessibility statement|https://openreferraluk.org/info/accessibility;…"
ot-compat/bin/dita --input=P/src/oruk.ditamap --format=dita --output=P/out-dita
java -jar dist/vnu.jar --errors-only --skip-non-html P/out
python3 /Users/nicholas/source/GDS-DITA/tools/check_links.py P/out
python3 /Users/nicholas/source/GDS-DITA/tools/page_weight.py --report --budget-kb 300 P/out
```

The one warning: `[DOTJ075W] Absolute link 'https://github.com/OpenReferralUK/oruk-standard-and-website/wiki/images/architecture.png' without correct @scope attribute` (docs/legacy).

**What the verifiers found.** The fidelity check rendered every source file with the site's own `marked` and diffed block by block against the prototype pages: 25 of the 48 one-to-one pages have zero non-link differences, and the prototype's 0.971 to 1.000 word coverage is true but blind to the following, all confirmed:

1. `adopt/03_pid`: the 18 `<strong>` labels inside the HTML tables were rewritten to `**…**`, which is not parsed inside HTML blocks; page and DITA topic show literal `**TOTAL**`, `**Leadership**`, `**£45k**`.
2. Ten first-column `<th>` row headers in `02_business_case` and the three header cells of the privacy lawful-basis table became `<td>` (the DITA table has no `<thead>`): an accessibility regression.
3. Two `font-weight:900; text-align: right` cells lost bold and alignment (49 of 51 right-aligned cells, not all).
4. Use-case order (Section 4).
5. `modified` reaches `<critdates>` but is rendered nowhere; the live site shows "Updated: 22/03/2025" and the plugin has no critdates rendering.
6. Three bare URLs that GFM autolinks (`case-studies/1001`, `1012`, `docs/legacy`) are plain text; `[Architecture](https://github.com/OpenReferralUK /…)` (space in the URL) became an empty `<xref/>`.
7. Undisclosed presentation changes: image titles promoted to visible "Figure n." captions on three pages; the PDF banner moved from the top to a closing paragraph; the grey callout background gone.

The coverage check confirmed the page set (52 content URLs; chapter order equals the live `/sitemap`) and the same use-case fault. The robustness check confirmed determinism and exposed the brittleness described under Route A. Corrected position: the pipeline works and is measured; the converter is a usable migration tool, not yet a faithful one, and its defects are listed.

## 6. What does not migrate and where it goes

| Item | Today | Recommendation |
|---|---|---|
| Validator (`/developers/validator`, `?url=`, `/results`) | posts to a Heroku API | External tool; intro and results guide become static pages linking out (6 content links) |
| Dashboard (`/developers/dashboard`, `/[id]`) | MongoDB tables, 11 feeds | External tool; one content link targets a live record id |
| Register your feed | GitHub App issue creation | External tool |
| Community directory | MongoDB `services` | External tool; its Markdown intro becomes a static page linking out (4 links) |
| Schemata, API, specification explorers | client-rendered from `public/specifications`, cookie version picker | Generate reference topics (Section 7), both versions as pages; keep the JSON verbatim at `/specifications/3.0/schema/*.json` (OpenAPI `$ref` contract) |
| Changelog, gantt (`data.json`) | React components; gantt absent from sitemap | Generated topics (done); accept loss of gantt shading or drop it |
| Community join | Markdown + Mailchimp link | Static page |
| Cookies and Vercel Analytics | consent bar; analytics injected regardless of consent | The plugin has no cookie or analytics parameters and the static site sets no cookies, so both go unless iStandUK adds analytics through `args.css`/`args.js`-style customisation; a decision, not a default |
| `/sitemap`, `/sitemap.xml`, `/api/health` | generated | Cover contents replace `/sitemap`; generate `sitemap.xml` from the map; drop health |
| "Updated" dates | front-matter `modified`, but 46 of 60 values are one script batch stamp (2025-03-22) | Do not render them as-is; take real dates from git history or an editorial date at migration, or drop the line |
| `maintenance.md`, `steering/README.md`, both `metadata.json` | unused or operational | Dropped |

## 7. Combined publication with the existing ORUK DITA corpus

The existing corpus (design/07: 1,465 files, 45 class topics, 454 element topics, 454 property stubs, 11 data-type tables, 32 SVGs, 530 keys, two bookmaps) is a data-model reference and nothing else; the website is its mirror image (guidance, adoption, case studies, community, plus a UK-profile subset of 19 classes and 141 properties, an 11-endpoint API and a changelog the corpus lacks). A 245-line spike (`gen_spec_topics.py`) generated 24 class topics, 11 endpoint topics, a 38-key key map and a bookmap from the 3.0 JSON in the corpus idiom (Topic DTD, CALS, keyref-only xrefs, `svgref` by keyref): `dita -f govuk --govuk.branding=istanduk` gave 0 DITA-OT messages, 38 pages, 1,899 internal links with none broken, and 2 Nu errors caused by the plugin's SVG inliner materialising SVG 1.1 DTD default attributes (`contentScriptType`, `contentStyleType`) from Graphviz's `<!DOCTYPE svg>`: a fix in `xsl/foreign.xsl`, mode `govuk-svg-inline`.

Proposed bookmap: one publication with four parts. **Guidance** (converted about, adopt, use cases, case studies, community, developer guidance, info). **Reference** (the International-bookmap idiom for data model and data types, UK-profile `core` flagged from the schema field, plus generated API endpoint topics; the `#service` links from `developers/compliance` become keyrefs to class topics). **Specifications** (topics linking the verbatim OpenAPI and schema JSON, 3.0 current, 1.0 as an appendix). **Tools** (external topicrefs to validator, dashboard, directory, register, forum). Per-topic pages, never `chunk="to-content"` (dita-ot#4465: Combined-schemas gave 287 broken links under chunking, International gave 0).

## 8. Risks and open questions

- **Licence of the content, unresolved in the source.** The ORUK README says documentation is CC BY-SA 4.0 and code BSD 3-Clause; the site footer links "Creative Commons Attribution-ShareAlike 4.0" to the repository's LICENSE file, but that file contains only BSD 3-Clause text ("HSDS-UK and associated documentation are licensed under the BSD 3-Clause License"). Republishing under the iStandUK brand needs ORUK to state which applies; if CC BY-SA, ShareAlike binds the published site and the combined publication. The licence of the existing ORUK DITA corpus is not recorded in our evidence either and must be confirmed before combining.

- **Branding and sponsorship.** The accessibility statement says the site is run by iStandUK on behalf of MHCLG and the footer carries the MHCLG logotype; whether the iStandUK brand replaces the ORUK identity is a stakeholder decision.
- **Extensionless URLs** depend on a hosting rule; without it 22 article URLs change.
- **Editing model.** Today authors edit GitHub-flavoured Markdown in the website repository with CI (build, lint, Playwright axe, Trivy) and a staging preview. Route B moves editing to DITA; who edits case studies and steering minutes afterwards, with what editor, repository layout, review and preview flow, is not answered by the evidence and decides between the routes.
- **Hosting and the host split.** Where the static site lives, who operates it, and how the five application routes keep serving on `openreferraluk.org` beside static output (reverse proxy or path split), plus a host able to do the six host-based redirects, is undecided; the plugin's own primary hosting target is still open (design OQ-4).
- **Metadata and SEO parity.** The live layout emits application name, keywords, publisher, Open Graph description and `en_GB` locale; whether the prototype's `<head>` carries description and Open Graph metadata was not inspected, and `sitemap.xml` generation is a plugin gap.
- **Freshness of the source.** The clone is at commit 4508f4b (7 July 2026); the live survey ran on 3 September. Only four live pages were diffed against the clone, so a crawl of the 52 content URLs against the repository (or a re-clone at cutover) is needed to confirm the migration source is current.
- **Verification net.** The website's CI (build, lint, axe, reachable-pages test, Trivy) is replaced page-for-page by the plugin's tooling used in this discovery (Nu, axe-core via `tools/a11y`, `check_links.py`, `page_weight.py`, plus the 59-URL reachability list), but a workflow wiring them to the content repository has to be written.
- **Plugin gaps surfaced:** no critdates rendering, no `sitemap.xml`, SVG DTD-default attributes, footer links emitted verbatim, default licence line to override for CC BY-SA content.
- **Reference pages** lose the version picker; two static versions is the plain alternative.
- **Source defects** will surface in review: folded `>-` teasers, `# News Story Five` as the H1 of case study 1009, the malformed `</tr`, `http:///`, schemeless `www.` links.
- **Analytics and cookies** are unconditional today; the static site needs a stated position.

## 9. Recommended next steps

A bounded spike on the prototype converter and the plugin, accepted against the six criteria below. Indicative sizing, by task rather than a single figure (S: up to a day, M: two to three days, L: a week or more; assumptions: one engineer familiar with the plugin, ORUK content frozen during the work):

| Task | Size |
|---|---|
| Converter fidelity fixes (seven listed defects) and use-case order | M |
| Converter robustness (named errors, unlisted files reported) | S |
| Plugin: `sitemap.xml`, SVG DTD-default attributes, dated "Updated" line if wanted | M |
| Reference part from the OpenAPI/schema JSON in the corpus idiom, keyrefs from guidance | M |
| Combined bookmap, hosting preview with clean-URL rule and redirects, 59-URL check | M |
| Hand review of the 23 pages that still differ, licence and editing-model decisions with ORUK | L, mostly not engineering |

Acceptance criteria:

1. **Fidelity.** `oruk-work/fidelity/blockdiff.py` reports zero non-link differences on every one-to-one page after the seven listed defects are fixed (HTML-block `<strong>` left alone, `<thead>` and `rowheader="firstcol"` preserved, style-to-align without dropping bold, bare URLs wrapped, the `Architecture` URL repaired, caption and PDF-banner placement decided).
2. **Order.** Use-case map order equals the `links` chain; pagination on `reuse-data` shows previous "Open Referral UK use cases" and next "Empower professionals to support people".
3. **Robustness.** The four cases in `verify-robustness/mutant_run.py` either convert or fail with a named error; unlisted files are reported, never silently dropped.
4. **Plugin.** Emit `sitemap.xml`; strip DTD-default attributes on inlined SVG; render a dated "Updated" line only once real dates exist (Section 6); Nu 0 errors, axe 0 violations, 0 broken links and the 300 KB shell budget still hold.
5. **Combined map.** The Guidance part and the spike's Reference part build under one bookmap with keyrefs from `developers/compliance` into the class topics, 0 broken links.
6. **Hosting.** A preview on a static host with the clean-URL rule and the redirect set, checked against the 59-URL list in `structure-json/pagetree.json`: 52 return 200 at byte-identical paths, the five application routes redirect to the live host.

The spike settles Route A against Route B; the evidence so far favours B.

## 10. Where the code lives

The prototype converter (`oruk2dita.py`), the specification-topic generator (`gen_spec_topics.py`), the structure-only proof map, the fidelity diff scripts and the derived page tree and content inventory are kept in a **separate ORUK content-migration repository**, not in the plugin: they are migration tooling for one publisher's corpus, they depend on that website's shape, and they will change as the content does. The plugin keeps only this report, as the design record of what Markdown-sourced publications need from it.

The gaps this discovery found in the plugin itself are tracked here: [#59](https://github.com/iStandUK/govuk-dita-plugin/issues/59) inlined SVG carries DTD default attributes and fails validation, [#60](https://github.com/iStandUK/govuk-dita-plugin/issues/60) generate `sitemap.xml`, [#61](https://github.com/iStandUK/govuk-dita-plugin/issues/61) render topic dates.

# 02 — Requirements

Requirements are numbered for traceability (the matrix in
[04-components.md](04-components.md) maps each to the component that satisfies it) and
prioritised MoSCoW-style: **M**ust, **S**hould, **C**ould. Anything below the line in
[the roadmap](#deferred-roadmap) is **W**on't-have for v1.

## Functional requirements

### Build and integration (FR-B)

| ID | Requirement | Priority |
|---|---|---|
| FR-B1 | The plugin registers a transtype **`govuk`** that extends `html5`, so `dita --input=<map> --format=govuk` performs a complete build | M |
| FR-B2 | The plugin installs with `dita install <zip-or-url>` and, once published, by name from the DITA-OT plugin registry | M |
| FR-B3 | All behaviour described below is controlled by documented build parameters (`govuk.*`), settable on the command line, in `.ditaotproject`/project files, or via Ant properties | M |
| FR-B4 | The core build requires only DITA-OT 4.x and its bundled Java — no Node.js, no network access | M |
| FR-B5 | The build works with standard DITA 1.3 maps and bookmaps, including keys/keyscopes, conref, chunking, and DITAVAL filtering (all inherited from `html5` preprocessing and must not be broken by overrides) | M |
| FR-B6 | A build from unchanged source produces byte-identical output (deterministic), so hosting diffs are meaningful | S |

### Navigation and layout (FR-N)

| ID | Requirement | Priority |
|---|---|---|
| FR-N1 | Every page carries a persistent left-hand navigation reflecting the full map hierarchy (tech-docs pattern), with the current topic highlighted and its ancestors expanded | M |
| FR-N2 | Navigation sections expand/collapse with JavaScript; **without JavaScript the full tree is visible and usable** (progressive enhancement) | M |
| FR-N3 | Each page shows an "On this page" contents list of its own second-level headings when there are two or more | S |
| FR-N4 | On small viewports the sidebar collapses behind a menu control, following the tech-docs/service-navigation mobile pattern | M |
| FR-N5 | Previous/next links (GOV.UK pagination component, block variant) appear at the foot of each page in map reading order | S |
| FR-N6 | Breadcrumbs (GOV.UK breadcrumbs component) can be enabled by parameter; default off in the sidebar layout | C |
| FR-N7 | Every page has a skip link, correct landmark structure (`header`, `nav`, `main`, `footer`), and a visible focus order matching the Design System | M |
| FR-N8 | A site home page is generated from the map (title, shortdesc/abstract, top-level entry links) | S |

### Content rendering (FR-R)

The full element-by-element mapping is in [04-components.md](04-components.md); these
requirements govern its behaviour.

| ID | Requirement | Priority |
|---|---|---|
| FR-R1 | Body content renders with GOV.UK typography classes (headings, body text, lists, links) at the Design System's scale and spacing | M |
| FR-R2 | DITA `note` maps by type to the appropriate component: inset text for neutral notes/tips, warning text for warning/caution/danger/important, with generated labels localisable | M |
| FR-R3 | Tables (`table`, `simpletable`, and specialisations) render as `govuk-table` with caption, header scope, and responsive overflow handling | M |
| FR-R4 | Codeblocks render as monospace `<pre><code>` blocks with horizontal scrolling (no syntax highlighting in v1 — Roadmap R1) | M |
| FR-R5 | Figures and images render with captions, `alt` text preserved, and never overflow the content column | M |
| FR-R6 | Task topics render steps as numbered lists with clear command/result styling | S |
| FR-R7 | Related links and map-driven `reltable` links render as a "Related content" section following the GOV.UK pattern | S |
| FR-R8 | `shortdesc` renders as a lead paragraph (`govuk-body-l`) at the top of the page | S |
| FR-R9 | Footnotes, `draft-comment` (when enabled), and `required-cleanup` behave as in `html5`, restyled | C |

### Glossary and abbreviations (FR-G)

| ID | Requirement | Priority |
|---|---|---|
| FR-G1 | `glossentry` topics referenced from the map are collected into a single A–Z glossary page (grouped by initial letter, with letter navigation) | M |
| FR-G2 | `abbreviated-form` keyrefs render as `<abbr title="...">` with the expansion, linked to the glossary entry | M |
| FR-G3 | `term` elements with keyrefs to glossary entries link to the glossary | S |
| FR-G4 | Glossary sort order respects the build language's collation (en-GB in v1) | S |

### Back-of-book index (FR-X)

| ID | Requirement | Priority |
|---|---|---|
| FR-X1 | `indexterm` markup across the publication is collected into an A–Z index page with links to the pages (and nearest anchors) where each term occurs | M |
| FR-X2 | Nested index terms render as indented sub-entries | S |
| FR-X3 | `index-see` and `index-see-also` render as "see …" / "see also …" cross-references | C |

### Search (FR-S)

| ID | Requirement | Priority |
|---|---|---|
| FR-S1 | An optional post-build step runs Pagefind over the generated site to build a client-side search index | M |
| FR-S2 | A search field appears in the header/sidebar area, with results shown on a dedicated search page; markup degrades gracefully (field hidden) when no index is present | M |
| FR-S3 | Navigation, headers, and footers are excluded from indexing (`data-pagefind-body` scoping) so results match page content only | M |
| FR-S4 | If Pagefind is not installed, the build **succeeds with a clear notice**, producing a site without search — Pagefind is never a hard dependency | M |

### Branding and theming (FR-T)

| ID | Requirement | Priority |
|---|---|---|
| FR-T1 | Default branding is **neutral**: no crown, no GDS Transport font (system font stack; no request for font assets is ever made), a plain header bar carrying the service/publication name | M |
| FR-T2 | `govuk.branding=official` enables full GOV.UK branding: crown logotype in the header, GDS Transport fonts copied and loaded, OGL/crown-copyright footer — for use only by genuine GOV.UK services (documented prominently) | M |
| FR-T3 | Service name, home link, phase banner (alpha/beta with feedback link), footer links, and footer licence text are all parameter-driven | M |
| FR-T4 | Publishers can append their own stylesheet after the plugin's (standard `args.css`/`args.cssroot` behaviour preserved) | S |
| FR-T5 | Favicon and social-preview metadata are parameter-driven, with neutral defaults | C |

## Non-functional requirements

| ID | Requirement | Priority |
|---|---|---|
| NFR-A1 | Generated sites conform to **WCAG 2.2 AA**. Everything govuk-frontend provides (contrast, focus states, touch targets) is preserved; everything the plugin adds (nav tree, glossary, index, search page) is built and tested to the same standard | M |
| NFR-A2 | Output is valid HTML5 (checked in CI with the Nu validator) with a single `h1` per page and a correct heading hierarchy | M |
| NFR-A3 | Full functionality except search is available with JavaScript disabled | M |
| NFR-P1 | Sites are fully self-contained: **no CDN, no external requests** of any kind at runtime | M |
| NFR-P2 | Page weight budget: HTML+CSS+JS for a typical topic page under ~300 KB uncompressed excluding content images; no render-blocking JS | S |
| NFR-V1 | Output URLs derive deterministically from source file paths, so republishing does not break inbound links | M |
| NFR-V2 | No cookies are set and no personal data is processed by default, so no cookie banner is required; any future analytics integration must be opt-in and bring its own consent handling | M |
| NFR-I1 | All generated UI text (labels like "Contents", "Warning", "Search", "Menu") comes from DITA-OT string files, overridable and translatable; `@xml:lang` flows through to `lang` attributes | S |
| NFR-M1 | The plugin uses **only documented DITA-OT extension points** — no copied/patched toolkit internals — and CI builds a fixture publication against each supported DITA-OT minor release | M |
| NFR-M2 | The vendored govuk-frontend release is pinned and recorded; upgrades are deliberate changes validated by visual regression snapshots | M |
| NFR-L1 | Licence Apache-2.0; vendored govuk-frontend (MIT) retained with its licence and attribution; release versioning is semver | M |

## Deferred (roadmap)

| ID | Item | Notes |
|---|---|---|
| R1 | Syntax-highlighted codeblocks | Build-time highlighting (no runtime JS highlighting); revisit when code-heavy publications need it |
| R2 | Version switcher | `/v1/`, `/v2/` publishing with a switcher component and "not the latest version" notification banner |
| R3 | Print stylesheet | Print-friendly CSS for single topics |
| R4 | Search-term handling extras | Result highlighting, search suggestions — track Pagefind features |
| R5 | Multi-publication landing site | One build aggregating several maps under a shared home page |
| R6 | Feedback pattern | GOV.UK "Is this page useful?" — needs a backend, so out of static scope for now |
| R7 | Additional UI locales | Welsh (cy) first, per GOV.UK practice |
| R8 | Guide-pattern layout | Alternative breadcrumbs+contents linear layout, selectable per map |

# 03 — Architecture

## Overview

The plugin is a **standard DITA-OT extension plugin** whose transtype `govuk` extends the
built-in `org.dita.html5`. It changes *what the HTML looks like* — templates, classes,
page furniture, assets — while inheriting *how DITA is processed* (preprocessing, key/conref
resolution, filtering, chunking, link management) unchanged from the toolkit. Two generators
(glossary, index) and one optional post-build step (Pagefind) are added around the inherited
pipeline.

This is the same architectural pattern proven by `net.infotexture.dita-bootstrap`.

## Build pipeline

```mermaid
flowchart TD
    IN[/"DITA map + topics<br/>(+ DITAVAL, keys)"/] --> PRE

    subgraph OT["Inherited from DITA-OT html5"]
        PRE["Preprocessing<br/>(filter, keyref, conref,<br/>chunk, move-meta, topicpull)"]
        PRE --> TOPICS["Topic rendering<br/>dita2html5 XSLT<br/>with govuk overrides imported"]
        PRE --> NAV["Navigation generation<br/>(map → per-page nav tree,<br/>nav-toc=full)"]
    end

    subgraph GOVUK["Added by the govuk plugin"]
        TOPICS --> GLOSS["Glossary page generator<br/>(XSLT pass over preprocessed<br/>glossentry topics)"]
        TOPICS --> IDX["Index page generator<br/>(XSLT pass collecting indexterm)"]
        NAV --> WRAP["Page assembly<br/>(GOV.UK template: header,<br/>sidebar, main, footer)"]
        TOPICS --> WRAP
        WRAP --> ASSETS["Asset copy<br/>govuk-frontend dist CSS/JS,<br/>overlay CSS, plugin JS"]
        ASSETS --> BRAND{"govuk.branding?"}
        BRAND -- "neutral (default) / istanduk" --> NOFONT["Stock CSS + neutral overlay<br/>(+ iStandUK overlay); no restricted asset"]
        BRAND -- "nhs / official" --> IDENT["NHS: recompiled palette CSS + NHS overlay<br/>official: stock CSS + crown overlay<br/>inline logo, build warning, no font or crest file"]
    end

    NOFONT --> OUT[/"Static site"/]
    FONT --> OUT
    GLOSS --> OUT
    IDX --> OUT

    OUT --> PF{"Pagefind available<br/>and govuk.search=yes?"}
    PF -- yes --> PFRUN["pagefind --site out/<br/>writes /pagefind/ index"]
    PF -- "no (notice logged)" --> DONE
    PFRUN --> DONE[/"Deployable site"/]
```

Key property: everything left of the `govuk` subgraph is upstream DITA-OT behaviour we do not
fork. If a future DITA-OT release changes preprocessing, we inherit the fix.

## Plugin anatomy

Plugin ID **`org.istanduk.gov-uk`** (decided — see
[05-decision-log.md](05-decision-log.md), D-10). **As built at v0.1.0** — the implementation
consolidated the proposed rendering modules into fewer files (`blocks.xsl` carries typography,
tables, notes, and SVG handling; the cover stylesheet replaced the proposed `home.xsl`), and
the glossary/index/search/strings pieces remain planned:

```
org.istanduk.gov-uk/
├── plugin.xml                 # transtype govuk extends html5; params; ant.import +
│                              #   dita.conductor.html5.param features
├── build_dita2govuk.xml       # Ant: dita2govuk = init (args.xsl, cover xsl, nav-toc,
│                              #   branding guard) → dita2html5 → asset copy
├── insertParameters.xml       # passes govuk.* Ant properties into the topic XSLT
├── xsl/
│   ├── dita2govuk.xsl         # shell: imports html5 chain, then template + blocks
│   ├── template.xsl           # page skeleton: govuk-template, masthead, grid
│   │                          #   (sidebar + main), footer, CSS links, scripts
│   ├── blocks.xsl             # typography via set-output-class; notes → inset/warning;
│   │                          #   tables incl. spans; svgref alt; captions
│   └── map2govuk-cover.xsl    # GOV.UK home page: title, bookmap abstract,
│   │                          #   attribution, contents tree (args.html5.toc.xsl)
│   └── utility-pages.xsl      # glossary + index harvest and A–Z pages (FR-G, FR-X)
│   └── search.xsl             # Pagefind attributes from DITA semantics (FR-S5, #54)
├── resource/
│   ├── govuk-frontend/        # vendored v6.5.0 compiled CSS/JS + maps, VERSION,
│   │                          #   LICENSE, NOTICE — no fonts or crown imagery;
│   │                          #   + NHS-palette recompile (-nhs.min.css, tools/branding)
│   ├── css/
│   │   ├── overlay-neutral.css  # neutral branding: local font aliasing, crest suppression
│   │   ├── overlay-istanduk.css, overlay-nhs.css, overlay-official.css  # per-mode mastheads/footers
│   │   └── plugin.css           # masthead, sidebar, contents, figures, code, links
│   └── js/
│       └── plugin.js          # menu toggle, caret collapse, chunked-page highlight
├── messages.xml               # build messages GOVK001W/002E (dita.xsl.messages)
└── strings/                   # generated-text registry + strings-en-gb.xml (NFR-I1)
```

Search (FR-S) needed no directory of its own: the Ant init probes for Pagefind and the
`govuk.search-index` target runs it post-build; the search page is emitted by the cover
stylesheet via `xsl:result-document`.

The repository root carries `LICENSE` (Apache-2.0) and the design docs; the vendored MIT
licence and NOTICE live beside the govuk-frontend assets.

## Extension-point wiring

The plugin touches the toolkit **only** through documented extension points and properties.
Verified against DITA-OT 4.4.1, the as-built wiring differs from the original sketch in one
useful way: instead of the global `dita.xsl.html5` extension point (which would inject our
XSLT into *every* html5-family transtype), the `dita2govuk.init` target sets the **`args.xsl`
property**, scoping all overrides to the `govuk` transtype — plain `html5` builds on the same
toolkit are untouched. The cover page is routed the same way via **`args.html5.toc.xsl`**.

```mermaid
flowchart LR
    subgraph plugin["plugin.xml + build_dita2govuk.xml declare"]
        T["transtype govuk<br/>extends html5<br/>(+ param declarations)"]
        F1["feature: ant.import<br/>→ build_dita2govuk.xml"]
        F2["property: args.xsl<br/>→ xsl/dita2govuk.xsl<br/>(set in dita2govuk.init)"]
        F3["feature: dita.conductor.html5.param<br/>→ insertParameters.xml<br/>(govuk.* params, if:set-guarded)"]
        F4["property: args.html5.toc.xsl<br/>→ xsl/map2govuk-cover.xsl"]
        F5["feature: dita.xsl.strings<br/>(planned, C-14)"]
    end

    subgraph ot["DITA-OT core + org.dita.html5"]
        E1["Ant conductor<br/>(target registry)"]
        E2["html5.topic xslt task"]
        E3["XSLT parameter set"]
        E4["html5.map cover xslt task"]
        E5["Generated-text<br/>string tables"]
    end

    T --> E1
    F1 --> E1
    F2 --> E2
    F3 --> E3
    F4 --> E4
    F5 -.-> E5
```

Because `dita2govuk.xsl` *imports* the standard html5 chain first and the plugin's modules
after it (higher import precedence), any element we don't override keeps its default html5
rendering — a safety net for uncommon DITA elements, proven in practice by the ORUK corpus
(design/07). The one subtlety found during implementation: element classes are appended
through the `set-output-class` mode (the hook `commonattributes` actually uses), so an
author's `@outputclass` still replaces the plugin's default classes per element.

## Page template

Every generated page follows the GOV.UK page template adapted to the tech-docs layout:

```mermaid
flowchart TD
    subgraph page["Page: html.govuk-template … body"]
        SKIP["Skip link — 'Skip to main content'"]
        HDR["Header<br/>neutral: plain bar + service name<br/>official: GOV.UK header with crown"]
        SVC["Service navigation row (optional)<br/>+ search field when search enabled"]
        PHASE["Phase banner (optional: alpha/beta)"]
        subgraph width["govuk-width-container → govuk-grid-row"]
            subgraph side["one-third / sidebar column"]
                NAVT["nav: map tree<br/>current page highlighted,<br/>JS expand/collapse"]
            end
            subgraph mainc["two-thirds / content column — main id='main-content'"]
                LEAD["h1 + shortdesc lead"]
                OTP["'On this page' contents (FR-N3)"]
                BODY["Topic body — mapped elements<br/>(see 04-components.md)"]
                REL["Related content"]
                PAG["Prev/next pagination"]
            end
        end
        FTR["Footer<br/>neutral: configurable links + copyright line<br/>official: OGL + crown copyright"]
    end
    SKIP --> HDR --> SVC --> PHASE --> width --> FTR
```

Implementation notes:

- The `<body>` opens with the standard govuk-frontend snippet that adds `js-enabled` /
  `govuk-frontend-supported` classes, and ends with `type="module"` script that runs
  `initAll()` plus the plugin's nav/search wiring.
- The sidebar renders the **full** tree on every page (`nav-toc=full` behaviour inherited from
  html5), so the no-JS experience is complete; JS collapses distant branches on load. For very
  large maps this bloats every page — mitigation on the roadmap (partial tree + fetch).
- One `h1` per page; DITA section titles map to `h2` and below to keep hierarchy valid.

## Build parameters (initial set)

Status as of v0.1.0: ✅ implemented · ⬜ planned (each arrives with its feature).

| Parameter | Values / default | Purpose | Status |
|---|---|---|---|
| `govuk.branding` | `neutral` (default) \| `istanduk` \| `nhs` \| `official` | FR-T1/T2 — neutral carries no restricted identity; `istanduk` layers the iStandUK theme (D-14); `nhs` and `official` the NHS and crown identities on a recompiled palette (D-17), each warned in the build log | ✅ all four (v0.9.1) |
| `govuk.service.name` | text; default map/book title | Masthead service/publication name | ✅ |
| `govuk.service.url` | URL; default site home | Masthead link target | ✅ (#49) |
| `govuk.phase` | empty (default) \| `alpha` \| `beta` \| any tag | Phase banner | ✅ (#49) |
| `govuk.feedback.url` | URL | Phase banner feedback link | ✅ (#49) |
| `govuk.search` | `auto` (default) \| `yes` \| `no` | Search UI + Pagefind step; `auto` = on if Pagefind found | ✅ |
| `govuk.pagefind.cmd` | path; default `pagefind` on PATH | Locate the Pagefind binary | ✅ |
| `govuk.search.ranking` | `default` \| `reference` \| JSON object | FR-S5 — how results are scored; `reference` favours exact-title pages (D-18) | ✅ (#54) |
| `govuk.homepage.layout` | `auto` (default) \| `start` \| `annotated` \| `list` \| `grid` \| `grouped` \| `accordion` | D-13 — landing-page layout; `auto` selects from map shape | ✅ |
| `govuk.homepage.depth` | 1–9; default `2` | Levels of the map shown by the grid/grouped/accordion/start layouts (1 = entries only; 2 = + children; 3+ nest) | ✅ |
| `govuk.pagination` | `yes` (default) \| `no` | FR-N5 — previous/next block pagination in reading order | ✅ |
| `govuk.breadcrumbs` | `no` (default) \| `yes` | FR-N6 | ⬜ |
| `govuk.footer.links` | `label\|url;label\|url` | Extra footer links | ✅ (#49) |
| `govuk.footer.licence` | text | Footer licence/credit line (neutral, iStandUK, NHS; official keeps the OGL) | ✅ (#49) |
| `govuk.favicon` | path | Favicon copied into the output and linked from every page | ✅ (#49) |
| `args.css`, `args.cssroot`, `args.copycss` | inherited | Publisher CSS appended last (FR-T4) | ✅ |

## Search architecture

Pagefind was chosen (see decision log) because it indexes the *rendered output*, needs no
build-time integration with XSLT, ships as a self-contained binary, and its UI is a small
self-hosted JS/CSS bundle — consistent with the no-CDN rule.

- The Ant `govuk.search` step runs after all HTML is written: `pagefind --site <outdir>`.
  Output lands in `<outdir>/pagefind/` alongside the site.
- Page markup scopes indexing with `data-pagefind-body` on `<main>` so navigation and page
  furniture never pollute results (FR-S3).
- The search page loads Pagefind's UI bundle *from the site itself*; the plugin restyles it
  with Design System form/typography classes.
- Absence handling (FR-S4): if the binary is missing and `govuk.search=auto`, the build logs a
  notice and emits the site without the search field. `govuk.search=yes` with no binary is a
  build **error**, because the publisher explicitly asked for search.

## Branding architecture

Neutral by default; the iStandUK theme, the NHS identity and the official GOV.UK identity on
request (`govuk.branding`, D-14, D-17). All four modes render the same GOV.UK Design System
component markup; they differ in three places only:

1. **Base stylesheet** — neutral, iStandUK and official load the unmodified vendored
   `govuk-frontend` dist; NHS loads `govuk-frontend-6.5.0-nhs.min.css`, the same release
   recompiled from its Sass against the NHS palette at vendor time by `tools/branding` and
   committed (builds stay Node-free, D-12; CI rebuilds it and fails on drift).
2. **Overlay stylesheet** — one small overlay per mode loads after the base:
   `overlay-neutral.css` aliases the font stack to system fonts and suppresses crest/crown
   rules (also under iStandUK, which adds `overlay-istanduk.css` for its masthead);
   `overlay-nhs.css` and `overlay-official.css` style the identity mastheads and footers.
3. **Template branches** — masthead and footer templates branch on the mode: neutral emits the
   service name; iStandUK its logo; NHS the white masthead with the NHS logo and an NHS footer;
   official the GOV.UK masthead with crown-and-wordmark and the Open Government Licence /
   Crown copyright footer.

What is and is not shipped is the legal core of the design (constraint C1):

- **No restricted font file** — GDS Transport (official GOV.UK services) and Frutiger (NHS
  organisations) are never bundled; both modes fall back to a system stack and an entitled
  publisher supplies the font via `args.css`.
- **No crest or favicon imagery** — the crown-and-wordmark and the NHS logo are inline SVG
  drawn from the MIT-licensed artwork of govuk-frontend and nhsuk-frontend, emitted only in
  the corresponding mode; the footer crest image is not shipped.
- **A build-log warning in both restricted modes** every time they are used; selecting the
  mode asserts entitlement (gov.uk services; NHS organisations or others with permission
  from NHS England / DHSC). The manual's legal topic states the position for publishers.

CI asserts that no mode's output contains a font file or crest asset, that neutral output
references no restricted asset at all, and that the NHS stylesheet matches its Sass source.

## Glossary and index generation

As built, both are **harvested during the cover transformation** (`utility-pages.xsl`) rather
than as separate Ant passes: the normalised map supplies the reading structure and output
paths, and `document()` loads each referenced *preprocessed* topic once (keys and conrefs
already resolved) to collect content. Both pages are emitted with `xsl:result-document` and
appear only when their source markup exists.

- **Glossary** — every `glossentry` topic referenced by the map (resource-only keydefs
  included) is collected, sorted with en-GB collation, grouped by initial letter, and emitted
  as `glossary.html` with letter navigation, showing term, acronym, and definition linked to
  the entry's own page. `abbreviated-form`/`term` references link to those entry pages with
  first-use expansion semantics inherited from the toolkit.
- **Index** — `indexterm` elements are collected per rendered page with the containing
  topic's anchor, merged case-insensitively, nested one level, and emitted as
  `index-page.html` (name avoids colliding with the site `index.html`);
  `index-see`/`index-see-also` render as "see …" / "see also …" lines.

Sidebar links to both pages are switched by a build-time source scan (the pages themselves
are generated from the resolved map, which is definitive). Neither generator exists in the
html5 base — they are the plugin's largest pieces of genuinely new processing logic.

## Risks and mitigations

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
| govuk-frontend markup contracts change between releases (components require exact structure/classes) | Medium / High | Pin the vendored release (NFR-M2); visual-regression + axe snapshots on upgrade; keep component markup in few, focused XSLT modules |
| DITA-OT html5 internals shift between 4.x minors | Medium / Medium | Only documented extension points (NFR-M1); CI matrix across supported releases (4.4.1 upward) with a fixture publication |
| Full nav tree on every page bloats output for very large maps | Medium / Medium | Accept for v1; measured on the 10,000-topic trial at ~24 KB per page (site 324 → 569 MB once a large branch joined the tree), inside the 300 KB page budget; roadmap: partial tree + JSON fetch (OQ-11) |
| Overlay CSS or the NHS recompile drifts from the vendored dist as govuk-frontend evolves | Medium / Low | Keep overlays minimal (fonts + masthead/footer only); CI rebuilds the NHS stylesheet from Sass and fails on drift; CI checks that no font/crest asset is referenced |
| Pagefind availability varies across environments | High / Low | `auto` mode with graceful skip (FR-S4); document binary install; consider bundling per-OS binaries later |
| Index/glossary logic has no upstream reference implementation in html5 | Certain / Medium | Treat as first-class components with their own fixtures and tests; PDF plugin's index behaviour is the semantic reference |
| Legal misuse: someone selects `govuk.branding=official` without being a GOV.UK service, or `nhs` without being an NHS organisation | Low / High (reputational) | Prominent documentation (README, manual legal topic) + a build-log warning every time either restricted mode is used; no restricted font or crest file ships in any mode |

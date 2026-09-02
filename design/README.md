# GDS-DITA — design documentation

A design for an open-source **DITA Open Toolkit (DITA-OT) plugin** that publishes DITA content
directly as a static website using the **GOV.UK Design System** (GDS), with no dependency on
commercial help-output tooling.

**Status:** Implemented through **v0.9.0** (living document) · **Started:** 2026-09-01 · **Author:** Nicholas Oughtibridge (with Claude)

## How to read this folder

| Document | Contents |
|---|---|
| [01-context.md](01-context.md) | Background, goals, non-goals, constraints, prior art, feature-parity analysis against the current commercial output |
| [02-requirements.md](02-requirements.md) | Numbered functional and non-functional requirements, prioritised (MoSCoW), plus the deferred roadmap |
| [03-architecture.md](03-architecture.md) | Build pipeline, plugin anatomy, extension-point wiring, page template, search and branding architecture, risks |
| [04-components.md](04-components.md) | Component inventory, DITA-element → GOV.UK-component mapping, requirements traceability matrix |
| [05-decision-log.md](05-decision-log.md) | Decisions taken so far, with options considered and rationale |
| [06-open-questions.md](06-open-questions.md) | Questions still needing a decision before or during implementation |
| [07-gap-analysis-oruk.md](07-gap-analysis-oruk.md) | Gap analysis of the Open Referral UK corpus: full-sweep feature inventory, verified dispositions, findings |
| [08-gap-analysis-dita13.md](08-gap-analysis-dita13.md) | Gap analysis of the full DITA 1.3 specification against the plugin, with the verified 1.0 gap list |

## Summary of agreed direction

The plugin (working transtype name **`govuk`**) **extends the built-in `org.dita.html5`
transtype**, overriding its XSLT to emit GOV.UK Design System markup. It **vendors the
precompiled `govuk-frontend` release** so a build needs only DITA-OT and Java. Branding is
**configurable with a non-government default** (no crown, no GDS Transport font) because those
assets are legally restricted to official GOV.UK services. Site search uses **Pagefind** as an
optional post-build step. The layout follows the **GDS Technical Documentation Template**
pattern (persistent left-hand navigation). Version 1 includes **glossary/abbreviation** and
**back-of-book index** generation. The plugin is released under **Apache-2.0** on GitHub and
listed in the DITA-OT plugin registry, targeting **DITA-OT 4.4.1 or later**.

See [05-decision-log.md](05-decision-log.md) for the reasoning behind each of these.

## Progress

| Milestone | Delivered |
|---|---|
| [`design` release](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/design) | Agreed design: documents 01–06, decisions D-01…D-11 |
| Proof of Concept ([epic #1](https://github.com/iStandUK/govuk-dita-plugin/issues/1)) | Walking skeleton: `govuk` transtype, GOV.UK page template and typography, sidebar navigation, vendored govuk-frontend v6.5.0 (D-12), fixture + CI with Nu HTML validation |
| ORUK gap analysis ([07](07-gap-analysis-oruk.md)) | Full-sweep inventory of the Open Referral UK corpus; two fixes; `oruk-mini` fixture; upstream bug confirmed on [dita-ot#4465](https://github.com/dita-ot/dita-ot/issues/4465) |
| Gap closure ([epic #12](https://github.com/iStandUK/govuk-dita-plugin/issues/12)) | GOV.UK home pages (bookmap abstract + attribution), mobile menu + caret navigation, figure/caption styling with `svgref` alt text |
| [**v0.1.0**](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.1.0) | First installable release, verified end-to-end from the public URL |
| [**v0.2.0**](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.2.0) / [v0.2.1](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.2.1) | Landing-page layouts (D-13) + depth control, Pagefind search, localisable strings, glossary and index generation, header search + footer support links, iStandUK theme (D-14) |
| DITA 1.3 gap analysis ([08](08-gap-analysis-dita13.md)) | Full-spec coverage assessment with the `dita13-kitchen` fixture; the verified 1.0 gap list |
| [**v0.3.0**](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.3.0) | v0.9 epic ([#26](https://github.com/iStandUK/govuk-dita-plugin/issues/26)) tranche: valid HTML5 throughout (hazard panels, modern choicetable/properties tables, #27), native MathML (#28) and inline SVG with working links (#37), dl/lq/ui-d and task/troubleshooting styling (#30, #31), DITAVAL flag styling (#29), reading-order pagination (#32), bookmap figure/table lists and appendix grouping (#33). Official branding deferred to 1.0 (D-16) |
| [**v0.9.0**](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.9.0) | Closes the v0.9 epic ([#26](https://github.com/iStandUK/govuk-dita-plugin/issues/26)): residue verification fixtures (conref push, ditavalref, flag images, object, frontmatter/backmatter, coderef, glossgroup, RTL) with a glossary dead-link fix (#34); bookmap metadata in the footer (#42); and the CI safety net — axe-core WCAG 2.2 AA, internal-link check, page-weight budget, build determinism, visual snapshots, DITA-OT version matrix (#35). **Robust enough for live trials.** |

Per-requirement status lives in the **Status column of
[02-requirements.md](02-requirements.md)**. v0.9.0 closes the P1–P3 gap list in
[08-gap-analysis-dita13.md](08-gap-analysis-dita13.md) and the verification NFRs. The 1.0
backlog = **live trials**, then the remaining v1 epic ([#15](https://github.com/iStandUK/govuk-dita-plugin/issues/15))
items: official branding (FR-T2, [#20](https://github.com/iStandUK/govuk-dita-plugin/issues/20))
and the registry listing ([#21](https://github.com/iStandUK/govuk-dita-plugin/issues/21)).

## Glossary of terms used throughout

- **DITA-OT** — the DITA Open Toolkit, the open-source publishing engine for DITA content.
- **Transtype** — a DITA-OT output format (transformation type), selected with `dita -f <transtype>`.
- **GDS** — the UK Government Digital Service; here shorthand for its design practice.
- **GOV.UK Design System** — the component/pattern library at design-system.service.gov.uk.
- **govuk-frontend** — the npm package of CSS/JS/assets implementing the Design System.
- **Tech Docs Template (TDT)** — the GDS Technical Documentation Template, the layout reference for this plugin.
- **Pagefind** — a static-site search tool that indexes rendered HTML after the build.
- **Current commercial output** — the HTML-help transformation bundled with the commercial DITA toolchain used today; it demonstrates market need and sets the feature baseline, but is an input to requirements only — never part of the architecture, and none of its assets are reused.

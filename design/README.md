# GDS-DITA — design documentation

A design for an open-source **DITA Open Toolkit (DITA-OT) plugin** that publishes DITA content
directly as a static website using the **GOV.UK Design System** (GDS), with no dependency on
commercial help-output tooling.

**Status:** Draft for review · **Date:** 2026-09-01 · **Author:** Nicholas Oughtibridge (with Claude)

## How to read this folder

| Document | Contents |
|---|---|
| [01-context.md](01-context.md) | Background, goals, non-goals, constraints, prior art, feature-parity analysis against the current commercial output |
| [02-requirements.md](02-requirements.md) | Numbered functional and non-functional requirements, prioritised (MoSCoW), plus the deferred roadmap |
| [03-architecture.md](03-architecture.md) | Build pipeline, plugin anatomy, extension-point wiring, page template, search and branding architecture, risks |
| [04-components.md](04-components.md) | Component inventory, DITA-element → GOV.UK-component mapping, requirements traceability matrix |
| [05-decision-log.md](05-decision-log.md) | Decisions taken so far, with options considered and rationale |
| [06-open-questions.md](06-open-questions.md) | Questions still needing a decision before or during implementation |

## Summary of agreed direction

The plugin (working transtype name **`govuk`**) **extends the built-in `org.dita.html5`
transtype**, overriding its XSLT to emit GOV.UK Design System markup. It **vendors the
precompiled `govuk-frontend` release** so a build needs only DITA-OT and Java. Branding is
**configurable with a non-government default** (no crown, no GDS Transport font) because those
assets are legally restricted to official GOV.UK services. Site search uses **Pagefind** as an
optional post-build step. The layout follows the **GDS Technical Documentation Template**
pattern (persistent left-hand navigation). Version 1 includes **glossary/abbreviation** and
**back-of-book index** generation. The plugin is released under **Apache-2.0** on GitHub and
listed in the DITA-OT plugin registry, targeting **DITA-OT 4.x**.

See [05-decision-log.md](05-decision-log.md) for the reasoning behind each of these.

## Glossary of terms used throughout

- **DITA-OT** — the DITA Open Toolkit, the open-source publishing engine for DITA content.
- **Transtype** — a DITA-OT output format (transformation type), selected with `dita -f <transtype>`.
- **GDS** — the UK Government Digital Service; here shorthand for its design practice.
- **GOV.UK Design System** — the component/pattern library at design-system.service.gov.uk.
- **govuk-frontend** — the npm package of CSS/JS/assets implementing the Design System.
- **Tech Docs Template (TDT)** — the GDS Technical Documentation Template, the layout reference for this plugin.
- **Pagefind** — a static-site search tool that indexes rendered HTML after the build.
- **Current commercial output** — the HTML-help transformation bundled with the commercial DITA toolchain used today; it demonstrates market need and sets the feature baseline, but is an input to requirements only — never part of the architecture, and none of its assets are reused.

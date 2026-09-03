# govuk-dita-plugin

An open **DITA Open Toolkit (DITA-OT) plugin** that publishes DITA content directly as a
static website styled with the **GOV.UK Design System**.

**Status: v0.9 — robust, in live trials** —
[v0.9.2](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.9.2) builds on the
v0.9.0 base (full DITA 1.3 spec coverage and a CI safety net — WCAG 2.2 AA via axe-core, valid
HTML, internal-link and page-weight checks, build determinism) with **NHS and official GOV.UK
branding** (#47), **parameter-driven page furniture** — phase banner, service URL, favicon,
footer links and licence (#49) — and the first live trial's findings from a 10,000-topic data
dictionary: a build warning for navigation keys the toolkit leaves unresolved (#51), a
Troubleshooting topic for two DITA-OT 4.4 behaviours (#52), and **search relevance driven by
the DITA itself** (#54). Next is a
[1.0 registry listing](https://github.com/iStandUK/govuk-dita-plugin/issues/15) after the
trials. Coverage of bookmaps, keys, chunking, and the SVG domain is verified against real
corpora ([ORUK](design/07-gap-analysis-oruk.md), [DITA 1.3](design/08-gap-analysis-dita13.md)).

## Try it

```bash
dita install https://github.com/iStandUK/govuk-dita-plugin/releases/download/v0.9.2/org.istanduk.gov-uk-0.9.2.zip
dita --input=docs/manual/manual.ditamap --format=govuk --output=out/manual
```

Requires [DITA-OT 4.4.1+](https://www.dita-ot.org/) and Java 17+; nothing else. Optionally,
[Pagefind](https://pagefind.app/) on the build machine enables site search — the plugin does
not bundle the indexer, but published sites carry the search index and interface, so readers
never install anything. Without Pagefind, builds simply omit search. That second
command builds the **[user manual](docs/manual/)** — itself a DITA bookmap, so the result at
`out/manual/index.html` is both the documentation and a live demonstration of every
capability the plugin supports.

## What it does

One command turns a DITA map into a complete, self-contained static site:

```bash
dita --input=publication.ditamap --format=govuk
```

The output uses GOV.UK Design System components, typography, and accessibility behaviour, laid
out in the style of the GDS Technical Documentation Template (persistent left-hand
navigation), with optional client-side search whose relevance follows the DITA (short
descriptions weighted, `search-ignore` and `search-demote` honoured), a generated A–Z
glossary, and a back-of-book index. Generated sites are built to **WCAG 2.2 AA** and checked
on every build with [axe-core](https://github.com/dequelabs/axe-core), the Nu HTML validator,
an internal link checker, and a page-weight budget in CI. When the toolkit itself misbehaves
on a large publication, the manual's Troubleshooting topic records what it looks like and
the remedy.

## Why

Organisations publishing standards and guidance from DITA sources currently rely on
commercial help-output tooling. Those products demonstrate the market need, but there is no
open route from DITA straight to a GOV.UK-styled website. This plugin provides one: pure
DITA-OT + Java at build time, Apache-2.0 licensed, installable with `dita install`.

## Design

The design is documented in [design/](design/):

| Document | Contents |
|---|---|
| [design/README.md](design/README.md) | Index, summary of the agreed direction, and the release history |
| [design/01-context.md](design/01-context.md) | Background, goals, constraints, prior art, feature-parity analysis |
| [design/02-requirements.md](design/02-requirements.md) | Prioritised functional and non-functional requirements, with status, plus roadmap |
| [design/03-architecture.md](design/03-architecture.md) | Build pipeline, plugin anatomy, extension points, branding and search architecture, risks |
| [design/04-components.md](design/04-components.md) | Component inventory, DITA → GOV.UK element mapping, traceability |
| [design/05-decision-log.md](design/05-decision-log.md) | Decisions taken, with options and rationale |
| [design/06-open-questions.md](design/06-open-questions.md) | Open questions and next steps |
| [design/07-gap-analysis-oruk.md](design/07-gap-analysis-oruk.md) | Gap analysis against the Open Referral UK corpus |
| [design/08-gap-analysis-dita13.md](design/08-gap-analysis-dita13.md) | Gap analysis against the full DITA 1.3 specification |
| [design/09-nhs-branding.md](design/09-nhs-branding.md) | How the NHS and crown variants were scoped: recoloured GDS, not a second frontend |

Architecture in one paragraph: the plugin's `govuk` transtype **extends the built-in
`org.dita.html5` transtype**, inheriting all DITA processing (keys, conref, filtering,
chunking) and overriding only the rendering. It **vendors a pinned release of
[govuk-frontend](https://github.com/alphagov/govuk-frontend)** so builds need no Node.js, and
adds three pieces the base toolkit lacks: glossary and index page generation, and an optional
[Pagefind](https://pagefind.app/) search step that degrades gracefully when not installed.

## Branding — important

`govuk.branding` selects one of four looks. The default is deliberately the one that carries
no restricted identity.

| Value | What you get | Who may use it |
|---|---|---|
| `neutral` (default) | Design System layout and components, system fonts, a plain masthead with your service name, no crown or crest | Anyone |
| `istanduk` | Neutral plus the iStandUK theme (logo and brand colours) | Anyone building for iStandUK; the logo is iStandUK's mark |
| `nhs` | The NHS Design System palette and typography on the same components: white masthead with the NHS logo, NHS footer | **NHS organisations only.** The NHS identity — the letters and the logo — is restricted; any other body needs permission from NHS England or the Department of Health and Social Care |
| `official` | Full GOV.UK branding: the crown and GOV.UK logotype in the masthead, Open Government Licence and Crown copyright in the footer | **Genuine GOV.UK services only**: on the gov.uk domain, delivered by or for a government department |

What the plugin ships, and what it deliberately does not:

- **No restricted font is bundled.** GDS Transport is licensed for official GOV.UK services
  and Frutiger, the NHS brand font, to NHS organisations. Both fall back to a system stack
  (Arial); an entitled publisher supplies the font through `args.css`.
- **No crest or favicon imagery is bundled.** The crown-and-wordmark and the NHS logo are
  rendered inline from the MIT-licensed artwork in govuk-frontend and nhsuk-frontend
  respectively, and only when the corresponding mode is selected. The footer's crown crest
  image is never shipped.
- **Both restricted modes warn in the build log** every time they are used. Selecting one
  asserts that your organisation is entitled to that identity; the licences on the code
  grant no right to either brand.
- The NHS variant is NHS-branded *GOV.UK Design System* output, recoloured at vendor time
  from govuk-frontend's own Sass. It is not a rebuild on the NHS's `nhsuk-frontend` and
  provides no NHS-specific components.

The manual's [legal](docs/manual/topics/legal.dita) and [branding](docs/manual/topics/branding.dita)
topics carry the full position; [design/09](design/09-nhs-branding.md) records how the NHS
variant was scoped.

## Licence

[Apache-2.0](LICENSE). The plugin vendors
[govuk-frontend](https://github.com/alphagov/govuk-frontend) v6.5.0 (MIT, © Crown Copyright,
Government Digital Service) with its licence and attribution retained, together with an
NHS-palette recompile of the same release built from its Sass at vendor time
([tools/branding](tools/branding)); see the vendored
[NOTICE](org.istanduk.gov-uk/resource/govuk-frontend/NOTICE.md). Neither licence grants any
right to the GOV.UK or NHS brands.

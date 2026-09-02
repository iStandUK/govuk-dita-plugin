# 09 — NHS branding: gap analysis and approach

**Date:** 2026-09-02 · **Purpose:** assess what it takes for the plugin to produce
**NHS-branded** output, and record the approach agreed for [#47](https://github.com/iStandUK/govuk-dita-plugin/issues/47).
Companion to the official (GOV.UK crown) branding in [#20](https://github.com/iStandUK/govuk-dita-plugin/issues/20).

## The key distinction

The **NHS Design System is a separate frontend** — [`nhsuk-frontend`](https://github.com/nhsuk/nhsuk-frontend)
(v10.6.1 at time of writing, MIT-licensed, `nhsuk-*` class prefix) — **not a theme of
`govuk-frontend`.** It shares GDS's lineage and accessibility bar but has diverged in colour,
components, and header/footer markup.

The plugin renders `govuk-*` markup on the vendored `govuk-frontend` throughout. So "conform to
the standards the NHS system uses" splits in two, and the project's steer (*"no NHS-specific
extensions to the GDS"*) resolves it:

- **Identity, colour, typography and accessibility standards** — achievable as an **NHS-branded
  GOV.UK Design System output** (a brand variant of the GDS base).
- **The `nhsuk-frontend` component system itself** (care cards, NHS warning callout, NHS
  expander, do/don't lists, task list…) — **out of scope.**

The honest name for the deliverable is therefore **"NHS-branded GOV.UK Design System output"** —
not a reimplementation on `nhsuk-frontend`.

## Scope

**Branding conformance only, on the GDS base.**

Non-goals (explicit):

- No `nhsuk-frontend` / `nhsuk-*` markup.
- No NHS-specific components.
- **Accepted residual (G7):** GDS components recoloured to NHS *look like GDS components in NHS
  colours*, not NHS Design System components. Stated up front in the manual.

## Where a GDS-based output already aligns

| Area | Alignment |
|---|---|
| Layout, grid, spacing, landmarks, skip link | Shared GDS heritage — no gap |
| Accessibility bar | NHS targets **WCAG 2.2 AA** (AAA where possible) — exactly what the axe-core CI net (#35) enforces |
| Typography | NHS's brand font **Frutiger is licensed, not web-distributed**; `nhsuk-frontend` ships **no font files** and falls back to `"Frutiger W01", Arial, sans-serif`. Same situation as GDS Transport; the neutral Arial stack already matches. Body scale (19px/16px) ≈ matches |

## Gap table

| # | Gap | Disposition |
|---|---|---|
| **G1** | **Palette** — NHS Blue `#005eb8` (links/header), Green `#007f3b` (buttons/success), text `#212b32`, secondary `#4c6272`, page bg `#f0f4f5`, link hover `#7C2855` / visited `#330072` / active `#002f5c`, error `#d5281b`. Ours are GDS values (link `#1d70b8`, button `#00703c`, text `#0b0c0c`). | **Largest gap.** Delivered by a Sass recompile of `govuk-frontend` against brand colour variables (below). |
| **G2** | **Focus colour** — NHS `#ffeb3b` vs GDS `#ffdd00`. | Recompile (`$govuk-focus-colour`). |
| **G3** | **Header + NHS logo** — NHS blue/white bar with the NHS lozenge (inline SVG, `aria-label="NHS"`), service name, optional search. | Per-variant overlay + masthead branch. Legal-gated. |
| **G4** | **Footer** — NHS footer styling and link colours; the generated footer (incl. bookmeta copyright, #42) inherits the variant. | Per-variant overlay. |
| **G5** | **Frutiger** — NHS brand font, free to NHS organisations on registration, not redistributable. | Do **not** bundle; default Arial (as now); document self-hosting. Same handling as GDS Transport. |
| **G6** | **Generated pages** — search, glossary, index, figure/table lists emit `govuk-*`. | Inherit the variant so nothing renders half-GDS. |
| **G7** | **Component appearance** — recoloured GDS components ≠ NHS Design System components. | Documented boundary in the Branding + Accessibility manual topics. |
| **G8** | **Branding model** — today `neutral`/`istanduk`/`official`. | Add `nhs`; `nhs` and `official` are official identities, each legal-gated (D-17). |
| **G9** | **Contrast re-verification** — the NHS palette has known weak combos (e.g. border-on-background). | Re-run the axe/contrast CI (#35) per variant. |

## Legal gating (both official identities)

The **GOV.UK crown / GDS Transport** and the **NHS logo / "NHS" letters** are each restricted —
the crown to genuine GOV.UK services, the NHS identity to NHS organisations (non-NHS bodies need
DHSC / NHS England permission;
[who can use the NHS Identity](https://www.england.nhs.uk/nhsidentity/identity-guidelines/who-can-use-the-nhs-identity/)).
Both variants must be **off by default, never bundled or enabled implicitly, gated behind an
explicit entitlement assertion, with a build-log warning** — the machinery FR-T2/#20 defines for
the crown, generalised to two identities.

## Approach: Sass recompile, then branch per variant

The plugin vendors **precompiled** `govuk-frontend` so end-user builds need no Node (D-12). The
recompile keeps that guarantee by running at **maintainer/vendor time**:

1. **Palette foundation.** A vendor-time Sass build imports `govuk-frontend` with brand colour
   variables overridden (`$govuk-brand-colour`, `$govuk-link-colour`, `$govuk-focus-colour`,
   `$govuk-text-colour`, `$govuk-secondary-text-colour`, `$govuk-success-colour`, button
   colours, `$govuk-body-background-colour`…). It emits a recoloured, minified CSS per brand
   (e.g. `govuk-frontend-6.5.0-nhs.min.css`), which is committed as a vendored asset. Builds
   still ship only CSS — no Node at build time.
2. **Branch per variant.** `generateCssLinks` selects the base stylesheet by
   `govuk.branding`; a thin per-variant overlay handles what palette variables don't reach
   (header background, the NHS logo, footer). Variants:
   - `nhs` — NHS identity
   - `official` — GOV.UK crown identity (the #20 work, delivered on the same foundation)

Component *structure* stays GDS (a button is still `govuk-button`, recoloured); this is exactly
the G7 boundary.

## Out of scope

`nhsuk-frontend` adoption; NHS-specific components and patterns; the Welsh/bilingual NHS
variants; anything that is not colour, typography, header/footer identity, or the legal gate.

## Sources

- [NHS Design System — colour](https://service-manual.nhs.uk/design-system/styles/colour)
- [NHS Design System — typography](https://service-manual.nhs.uk/design-system/styles/typography)
- [NHS Design System — header](https://service-manual.nhs.uk/design-system/components/header)
- [`nhsuk-frontend`](https://github.com/nhsuk/nhsuk-frontend)
- [NHS Identity — who can use it](https://www.england.nhs.uk/nhsidentity/identity-guidelines/who-can-use-the-nhs-identity/)

# 05 — Decision log

Decisions taken with Nicholas on 2026-09-01, lightweight-ADR style. Status **Accepted** unless
noted. Revisit a decision by adding a superseding entry, not by editing history.

*Implementation note (v0.1.0):* D-01, D-02, D-03 (neutral half), D-05, D-07, D-08, D-09,
D-10, D-11, and D-12 are implemented and validated in the released plugin. D-04 (Pagefind
search) and D-06's glossary/index features are decided but not yet built — they head the v1
backlog. D-03's official-branding mode remains declared-but-unimplemented (FR-T2).

---

## D-01 · Extend the `html5` transtype

**Options:** (a) extend `org.dita.html5` with XSLT overrides; (b) standalone transtype on the
preprocess pipeline; (c) two-stage DITA-OT → static-site generator (e.g. Eleventy +
x-govuk plugin).

**Decision:** (a) — extend `html5`.

**Rationale:** Inherits the whole processing pipeline (keys, conref, DITAVAL, chunking, link
management) and upstream fixes; single-command build; the pattern is proven in the wild by
`net.infotexture.dita-bootstrap`. (b) re-implements navigation and chunking glue for no gain.
(c) reuses GDS tooling but adds a Node toolchain, a second build stage, and an intermediate
format to maintain — against the "DITA-OT + Java only" constraint.

**Consequences:** Markup control is bounded by what the html5 import chain lets us override —
acceptable, since import precedence covers all rendering templates. We must track html5
behaviour across DITA-OT minors (mitigated by NFR-M1/C-15).

---

## D-02 · Vendor the precompiled govuk-frontend dist

**Options:** (a) vendor the prebuilt release; (b) Sass build pipeline in the plugin;
(c) vendored default plus optional documented npm re-theme workflow.

**Decision:** (a) — vendor the pinned dist. (c) can grow out of (a) later without rework.

**Rationale:** Keeps the build pure DITA-OT + Java (FR-B4); upgrades are a deliberate
drop-in + snapshot test. Sass-level theming isn't needed for v1: the only divergence from
stock styling is the neutral-branding overlay, which is small enough to hand-write over the
compiled CSS.

**Consequences:** No Sass variables — neutral mode is a CSS overlay, which must be kept
minimal and re-verified when the vendored release is bumped (risk logged in 03-architecture).

---

## D-03 · Branding configurable, non-government default

**Options:** (a) configurable with neutral default; (b) official GOV.UK branding baked in;
(c) never emit official branding at all.

**Decision:** (a).

**Rationale:** The crown and GDS Transport font are legally restricted to official GOV.UK
services. The publications driving this work (standards bodies, arm's-length material) must
not use them, but the plugin should still serve genuine government services. Neutral-by-default
is the safe failure mode; (c) would exclude the government audience an open plugin should serve.

**Consequences:** Branding becomes a first-class module (C-13) with template branches,
conditional asset copying, and a documented legal position; official mode logs a warning so
misuse is at least deliberate.

---

## D-04 · Pagefind for search, as an optional post-build step

**Options:** (a) Pagefind; (b) Lunr.js with a build-generated JSON index (the GDS
tech-docs-template approach); (c) no search in v1.

**Decision:** (a).

**Rationale:** Search is a hard expectation carried over from the current commercial output (parity table, 01-context).
Pagefind indexes the rendered HTML with zero XSLT integration, scales far better than Lunr,
ships as a self-contained binary (no Node runtime), and self-hosts its UI (no CDN, NFR-P1).
Lunr would make index generation our code to write and maintain.

**Consequences:** One binary outside the DITA-OT world. Softened by `govuk.search=auto`
(graceful skip with notice, FR-S4) so Pagefind never becomes a hard dependency.

---

## D-05 · Tech-docs sidebar layout

**Options:** (a) GDS Technical Documentation Template pattern (persistent left nav);
(b) GOV.UK mainstream guide pattern (breadcrumbs + contents + prev/next); (c) both,
selectable.

**Decision:** (a); (b) recorded as roadmap R8.

**Rationale:** Reference/standards documentation has deep trees — the sidebar is the right
pattern and the closest match to the help-system mental model readers already have. Implementing
both roughly doubles v1 layout work.

**Consequences:** Nav module (C-03) is the largest front-end component; guide-pattern layout
remains possible later because rendering and layout are separated in the XSLT.

---

## D-06 · V1 content features: glossary/abbreviations and back-of-book index

**Options considered (multi-select):** syntax-highlighted code; glossary & abbreviations;
back-of-book index; version switcher.

**Decision:** Glossary & abbreviations (FR-G) and index (FR-X) in v1. Syntax highlighting →
roadmap R1; version switcher → roadmap R2.

**Rationale:** Glossary and index are load-bearing for standards publications and both exist
in the current commercial output (parity). Highlighting and versioning are valuable but
separable, and neither blocks the architecture.

**Consequences:** C-08/C-09 are genuinely new logic (html5 has no reference implementation) —
budgeted as such and given their own fixtures.

---

## D-07 · Apache-2.0, GitHub, DITA-OT plugin registry

**Options:** (a) Apache-2.0 + GitHub + registry; (b) MIT + GitHub + registry; (c) private for
now.

**Decision:** (a).

**Rationale:** Matches DITA-OT's own licence (least friction for the plugin ecosystem) and
includes the patent grant. The MIT-licensed govuk-frontend can be vendored under Apache-2.0
distribution with its licence text and attribution retained (NFR-L1).

**Consequences:** Public repo hygiene from day one (licence headers, NOTICE for vendored
assets, semver releases, registry `plugin.json` metadata).

---

## D-08 · Target DITA-OT 4.x

**Options:** (a) 4.x line; (b) also support 3.6+; (c) latest release only.

**Decision:** (a) — the 4.x line, exact minimum minor to be pinned (done: D-11, 4.4.1).

**Rationale:** 4.x is what current commercial DITA editors bundle and gives a clean XSLT 3.0/Saxon
baseline. Supporting 3.x adds a compatibility test burden for installs that can upgrade;
latest-only would break users on stable editor releases.

**Consequences:** CI matrix across supported 4.x minors (NFR-M1); extension-point IDs verified
against the pinned minimum at implementation start.

---

## D-09 · Repository home: iStandUK/govuk-dita-plugin, public

**Options:** repo name `dita-govuk`, `GDS-DITA`, or `govuk-dita-plugin`; public now vs private
until first release.

**Decision:** Public repository **`iStandUK/govuk-dita-plugin`** from the design phase onward.

**Rationale:** `govuk-dita-plugin` is the most explicit about what the project is. Publishing
the design openly matches D-07 (open plugin) and invites early review; the repo contains only
design documents, which stand on their own.

**Consequences:** Narrows OQ-1 to the plugin ID alone (resolved by D-10). Public-repo hygiene
(licence, vendor-neutral language) applies from the first commit.

---

## D-10 · Plugin ID: `org.istanduk.gov-uk`

**Options:** `uk.istand.govuk`, `io.github.istanduk.govuk`, `org.istanduk.gov-uk`.

**Decision:** **`org.istanduk.gov-uk`**.

**Rationale:** Reverse-DNS on the iStandUK identity, following DITA-OT convention
(`org.dita.html5`, `net.infotexture.dita-bootstrap`); the `gov-uk` segment names the target
design system without claiming to *be* GOV.UK.

**Consequences:** Closes OQ-1. The plugin directory, `plugin.xml` `@id`, and registry entry
all use `org.istanduk.gov-uk`; the transtype users type remains the short `govuk`
(`dita -f govuk`).

---

## D-11 · Minimum DITA-OT version: 4.4.1

**Options:** any 4.x minor from 4.0 upward; 4.4.1 (the latest release at decision time).

**Decision:** **DITA-OT 4.4.1** is the pinned minimum and the primary CI target.

**Rationale:** 4.4.1 is the current latest release (verified against the dita-ot GitHub
releases on 2026-09-01), so extension-point verification (NFR-M1) happens once against a
fresh baseline rather than against older minors no one installs new, and the plugin starts
life with the longest possible runway before its minimum feels old.

**Consequences:** Closes OQ-2. Documentation states "DITA-OT 4.4.1 or later"; the CI matrix
starts at 4.4.1 and adds newer releases as they appear; extension-point IDs
(03-architecture) are verified against 4.4.1 at implementation start.

---

## D-12 · Vendored front-end release: govuk-frontend v6.5.0

**Options:** stay on the v5.x line the design documents assumed; move to the current v6.x
line.

**Decision:** **govuk-frontend v6.5.0** is the pinned vendored release.

**Rationale:** v6.x is the current line (the v5.x assumption predated checking the releases);
pinning the latest stable matches the D-11 philosophy. v6 also bakes in the 2025 GOV.UK
rebrand, so no rebrand flag is needed. Verified against the fixture publication visually and
by the CI checks.

**Consequences:** Constraint C5 updated; the pin is recorded in
`resource/govuk-frontend/VERSION.txt`/`NOTICE.md` and the `$govuk-frontend-version` XSLT
variable. Upgrades follow the NFR-M2 process (deliberate change, fixture rebuild, checks).

---

## D-13 · Landing-page layouts: auto-selected by map shape, publisher-overridable

**Date:** 2026-09-02 (accepted from the
[landing-page layouts spike](spikes/landing-page-layouts.md), PR #13).

**Options:** keep the single plain contents tree; adopt boxed tiles via an extension library
(MoJ/x-govuk cards); a fixed richer layout; or a set of GDS-core layouts selected
automatically with an override.

**Decision:** The cover page selects its layout **automatically from the map's shape** —
1 top-level entry → guide start (Start button); 2–8 → annotated contents (link +
`shortdesc`); 9+ or multi-chapter bookmaps → grouped sections — with a
**`govuk.homepage.layout`** parameter (`auto | start | list | grid | grouped | accordion`)
keeping control in the publisher's hands. "Tiles" are delivered as the GDS typography-grid
idiom, never boxed cards; the accordion is explicit opt-in only.

**Rationale:** Pragmatic: every layout uses only core govuk-frontend (no new dependencies),
builds from data the cover generation already has, and reuses `shortdesc` as entry
descriptions — the biggest visual upgrade over both the current page and the commercial
outputs' bare lists. The override preserves publisher control where `auto` guesses wrong.

**Consequences:** Extends FR-N8/C-10 and the 03-architecture parameter table; implementation
tracked as its own issue with fixture coverage per layout; `list` keeps today's behaviour
available for continuity.

*Implementation note:* delivered on the v1 epic branch with one addition — `annotated` is
also accepted as an explicit override value (the spike named the layout but omitted it from
the parameter's enumeration).

---

## D-14 · Publisher theme: `govuk.branding=istanduk`

**Date:** 2026-09-03.

**Options:** publisher CSS only via `args.css` (FR-T4); a generic theme mechanism; or a
built-in iStandUK theme value.

**Decision:** A third `govuk.branding` value, **`istanduk`**, layered on top of neutral mode:
white masthead with the iStandUK logo above a brand-blue rule (the treatment established in
iStandUK's adoption-tracker), `--govuk-brand-colour: #003888` (Pantone 072) driving the
govuk-frontend v6 brand surfaces such as the footer band, and an Arial text stack per the
brand guideline (Rockwell is proprietary and appears only inside the outlined logo artwork).

**Rationale:** iStandUK is the plugin's home organisation and its publications are the
first users; the brand assets were already curated in adoption-tracker (`design/brand`),
including a redistributable outlined-path logo and a documented palette. Layering on neutral
keeps every legal guarantee intact; publisher-specific theming for other organisations
remains available via `args.css`.

**Consequences:** `overlay-istanduk.css` and the logo ship in the plugin
(`resource/brand/istanduk/` with provenance README); CSS load order is
plugin.css → overlays so themes win the cascade; masthead furniture accepts a branding
parameter. A generic multi-theme mechanism can grow from this pattern if other organisations
need built-in themes.

---

## D-15 · Release staging: 0.9 before registry, registry at 1.0

**Date:** 2026-09-03.

**Options:** go straight for a 1.0 with registry listing once the gap list closes; or stage
a 0.9 first and defer the registry.

**Decision:** Target **v0.9** for the full gap-list, official branding, and verification
work (epic #26); run **live trials** on real publications; only then submit to the DITA-OT
plugin registry and release **v1.0** (#21).

**Rationale:** The registry makes the plugin discoverable to the whole DITA community —
first impressions there are lasting. A 0.9 proven robust in live use is the evidence that
the listing is deserved; the verification NFRs (axe, determinism, page weight, visual
regression) belong to the robustness work, not the listing step.

**Consequences:** #21 narrowed to registry-only; verification NFRs moved to #35 inside the
0.9 epic; epic #15 restaged as 0.9 → live trials → 1.0.

## D-16 · Official branding deferred from 0.9 to 1.0

**Date:** 2026-09-02.

**Options:** keep official branding (`govuk.branding=official`, #20) inside the v0.9 epic as
D-15 first framed it; or move it to the v1.0 epic so it does not gate live trials.

**Decision:** Move **#20 out of the v0.9 epic (#26) and into the v1 epic (#15)**. v0.9 ships
with neutral and iStandUK branding only; official branding lands for **1.0**.

**Rationale:** Live trials run on iStandUK's own publications, which use neutral/iStandUK
branding — official GOV.UK branding is not needed to start them, and holding 0.9 for it only
delays the feedback the staging exists to gather. Official mode also carries the heaviest
legal surface (crown, GDS Transport, OGL, entitlement assertion) and depends on assets the
publisher supplies from their own govuk-frontend copy; that scrutiny belongs with the 1.0
release gate, not the robustness milestone. Refines D-15, which had bundled it into 0.9.

**Consequences:** #26 goal and acceptance drop official branding; #15 gains #20 as a direct
sub-issue; design/08 and the C-13 disposition note the 1.0 target. The build-log warning and
neutral-default guarantees already shipped are unaffected.

## D-17 · Official branding: NHS and crown as recoloured GDS, not nhsuk-frontend

**Date:** 2026-09-02.

**Options:** (a) build a true NHS Design System output on `nhsuk-frontend` (its own `nhsuk-*`
markup and components); (b) offer NHS as a **brand variant** of the existing GOV.UK Design
System output — NHS colour, typography, header/footer identity on GDS component structure.

**Decision:** Option (b). Add **`govuk.branding=nhs`** alongside the crown `official`, both
delivered by a **Sass recompile** of `govuk-frontend` against brand colour variables at
maintainer/vendor time (the compiled CSS stays vendored, so builds remain Node-free — preserves
D-12), plus a thin per-variant overlay for header/footer/logo. No `nhsuk-frontend`, no
NHS-specific components ([design/09](09-nhs-branding.md), #47).

**Rationale:** `nhsuk-frontend` is a separate frontend, not a GDS theme; adopting it would fork
the whole rendering chain and duplicate the plugin. Most NHS *conformance* the users need is
identity, colour, typography and accessibility — all reachable as a recoloured GDS variant. The
NHS's Frutiger font (licensed, not web-shipped, Arial fallback) mirrors the GDS Transport
situation we already handle, and the NHS logo is legally restricted to NHS organisations exactly
as the crown is to GOV.UK services — so both are gated by one mechanism.

**Consequences:** `govuk.branding` gains `nhs`; #47 delivers both official identities on a shared
recompiled-palette foundation and supersedes #20's crown-only scope; the accepted residual is
that recoloured GDS components are not NHS Design System components (documented). Neutral stays
the default and no restricted asset (crown, NHS logo, Frutiger, GDS Transport) is ever bundled.

## D-18 · Search relevance follows the DITA, with a query-time scoring preset

**Date:** 2026-09-03.

**Options:** (a) leave Pagefind's scoring and markup untouched; (b) tune weights inside the
plugin by element type; (c) expose Pagefind's ranking options as a build parameter and let DITA
semantics drive the index attributes.

**Decision:** Option (c), both halves ([#54](https://github.com/iStandUK/govuk-dita-plugin/issues/54)).
`govuk.search.ranking` selects `default`, `reference` (`termFrequency: 0, pageLength: 0`) or a
JSON object passed through; the DITA carries the rest — `shortdesc` weighted 4,
`outputclass="search-ignore"` excludes, `outputclass="search-demote"` or
`importance="obsolete|deprecated"` demotes (body 0.3, title 2, shortdesc 1), prolog `keywords`
become searchable metadata, `searchtitle` the result title, `category`/`audience` filters.

**Rationale:** measured on the 10,000-page trial index with ten queries: Pagefind's defaults
buried exact-title definition pages; index-time multipliers (title weight 7 → 10, boosted
keywords) changed nothing because repeated terms saturate; the query-time preset fixed seven
of ten; only exclusion fixed the rest; and demotion works through the title weight, not the
body. Publishers' DITA already encodes the needed semantics (summaries, retired items,
cross-reference lists), so the plugin translates rather than guesses.

**Consequences:** search relevance is a documented, testable contract (FR-S5, fixture,
manual section); the default scoring is unchanged for existing sites; publishers with
dictionary-like content set `reference` and mark their lists; generated corpora gain three
cheap markers.

## D-19 · Toolkit limitations: diagnose, warn, document — do not reimplement

**Date:** 2026-09-03.

**Context:** the first live trial hit two DITA-OT 4.4.1 behaviours — the chunk
compatibility-mode regression and keys left unresolved inside keyref'd maprefs — both
reproduced in plain `html5` output with three-topic cases.

**Decision:** the plugin does not work around toolkit preprocessing defects by
re-implementing key resolution or chunking. It (1) confirms the behaviour upstream with a
minimal reproduction, (2) makes the silent case loud where it is the last to see the merged
map (`GOVK001W`), and (3) documents the remedy for publishers (manual Troubleshooting topic)
and for the source generator (hand-off notes). Reproductions are kept in `design/drafts/`
until filed.

**Rationale:** preprocessing is the toolkit's contract (NFR-M1); duplicating it would fork
behaviour the plugin cannot keep in step with, while a warning plus a documented setting or
source change resolves the trial in practice and helps every other DITA-OT user.

**Consequences:** `messages.xml` and the `keyref-nest` fixture exist; the manual carries a
Troubleshooting topic; upstream filing (dita-ot#4755 already covers the `copy-to` half) is a
standing offer rather than a blocker.

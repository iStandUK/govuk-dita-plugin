# 05 — Decision log

Decisions taken with Nicholas on 2026-09-01, lightweight-ADR style. Status **Accepted** unless
noted. Revisit a decision by adding a superseding entry, not by editing history.

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

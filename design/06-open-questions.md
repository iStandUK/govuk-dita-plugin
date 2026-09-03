# 06 — Open questions

Questions that need your direction before or during implementation, roughly in the order
they'll block work. None of them changes the architecture in 03; they mostly set names,
defaults, and fixtures.

| ID | Question | Options / notes | Blocks |
|---|---|---|---|
| ~~OQ-1~~ | **Resolved.** Repo home (D-09): `iStandUK/govuk-dita-plugin`, public. Plugin ID (D-10): `org.istanduk.gov-uk` | — | — |
| ~~OQ-2~~ | **Resolved.** Minimum DITA-OT version pinned (D-11): **4.4.1**, the latest release at decision time | — | — |
| ~~OQ-3~~ | **Resolved in practice (v0.1.0).** Output keeps source-derived filenames (inherited behaviour, per the recommendation); NFR-V1 marked met. Pretty extensionless URLs remain a hosting concern | — | — |
| OQ-4 | **Primary hosting target.** GitHub Pages implies a sub-path base URL (`/<repo>/`) — relative links handle it, but CI deploy workflow and Pagefind config should be tested against the real target | GitHub Pages / S3 / other? | C-15 deploy check, docs |
| OQ-5 | **Phase banner default for your publications.** `none` is the plugin default — but should your sites launch as `beta`? | Per-publication choice | Nothing (parameter exists either way) |
| ~~OQ-6~~ | **Resolved (v0.9.1, #49).** Footer licence text and links are per-publication parameters: `govuk.footer.licence` and `govuk.footer.links`; the default remains the bookmap copyright or the map title | — | — |
| OQ-7 | **Multi-publication needs.** Is one map = one site enough for now (roadmap R5 covers aggregation), or do you need a shared landing page across ContSys / ORUK / FHIR-ESD sooner? | Affects whether R5 gets pulled forward | Roadmap ordering |
| ~~OQ-8~~ | **Resolved in practice (v0.1.0).** Two synthetic fixtures exist and run in CI: `fixtures/poc` (element coverage) and `fixtures/oruk-mini` (ORUK idioms). Real corpora are used for local verification only (design/07); nothing licensed sits in the public repo | — | — |
| OQ-9 | **Languages.** Is en-GB-only acceptable for v1 UI strings (structure is translation-ready, NFR-I1), with Welsh as roadmap R7? | Confirm | C-14 scope |
| OQ-10 | **Roadmap ordering.** After v1: which of R1 (syntax highlighting), R2 (version switcher), R3 (print CSS), R8 (guide layout) matters most to you? | Prioritisation only | Post-v1 planning |
| OQ-11 | **Sidebar weight on very large publications.** The full tree on every page cost the 10,000-topic trial about 24 KB per page (site 324 → 569 MB once the data-sets branch joined the tree), still inside the 300 KB page budget. Is that acceptable for hosting, or should a partial tree / fetched navigation come forward from the roadmap? | Accept / `govuk.nav.depth`-style limit / lazy navigation | Roadmap ordering |

## Suggested next steps (updated at v0.1.0)

The walking skeleton, fixtures, rendering modules, home pages, and navigation enhancements
are delivered and released ([v0.1.0](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.1.0));
per-requirement status is in [02-requirements.md](02-requirements.md). Toward a v1 release:

1. ~~**Search** (FR-S, C-11)~~ — done on the v1 epic branch: Pagefind step with
   `auto`/`yes`/`no`, generated search page, `data-pagefind-body` scoping, both paths in CI.
2. ~~**Glossary and index** (FR-G/C-08, FR-X/C-09)~~ — done on the v1 epic: harvested in the
   cover pass, exercised and demonstrated by the manual's own glossary and index.
3. ~~**Localisable UI strings** (NFR-I1, C-14)~~ — done on the v1 epic branch via
   `dita.xsl.strings`; answers OQ-9 structurally (translations are additive files).
4. ~~**Official branding mode** (FR-T2, C-13)~~ — done in v0.9.1: NHS and crown variants on a
   recompiled palette (#47, D-17) and the furniture parameters (#49); no restricted asset is
   sourced or shipped — logos render inline in the chosen mode, fonts fall back.
5. **Registry listing** (FR-B2, #21) after the live trials; the verification NFRs (axe,
   determinism, page weight, links) landed in v0.9.0 (#35).
6. ~~**Landing-page layouts** (#14, D-13)~~ — done on the v1 epic branch.

Meanwhile, watch [dita-ot#4465](https://github.com/dita-ot/dita-ot/issues/4465) (chunk
cross-reference bug) and apply the `parent.dita#child-id` keying workaround in the ORUK
generator when convenient. The first live trial added two more DITA-OT 4.4 behaviours, both
documented in the manual's Troubleshooting topic with reproductions ready to file
([drafts](drafts/)): the chunk compatibility-mode regression
([dita-ot#4755](https://github.com/dita-ot/dita-ot/issues/4755) covers the `copy-to` half)
and unresolved keys inside keyref'd maprefs.

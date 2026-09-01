# 06 — Open questions

Questions that need your direction before or during implementation, roughly in the order
they'll block work. None of them changes the architecture in 03; they mostly set names,
defaults, and fixtures.

| ID | Question | Options / notes | Blocks |
|---|---|---|---|
| OQ-1 | **Plugin ID.** ~~Repo home~~ decided (D-09): `iStandUK/govuk-dita-plugin`, public. Remaining: the reverse-DNS plugin ID — `uk.istand.govuk`? `io.github.istanduk.govuk`? (convention per `org.dita.html5`, `net.infotexture.dita-bootstrap`) | Depends on whether iStandUK controls a domain to name under | `plugin.xml`, registry entry |
| OQ-2 | **Exact minimum DITA-OT version.** D-08 says "4.x" — pin which minor? Pragmatic choice: whatever DITA-OT your current editing toolchain bundles, verified at implementation start | Check the DITA editor's bundled DITA-OT version | CI matrix, extension-point verification |
| OQ-3 | **URL scheme.** Keep source topic filenames (`concepts/c-scope.html`, maximum link stability with today's output) or slugify from titles (nicer URLs, breaks when titles change)? Pretty extensionless URLs are a hosting concern, not a build concern | Recommend: keep source-derived names (NFR-V1 leans this way) | C-01 naming, NFR-V1 tests |
| OQ-4 | **Primary hosting target.** GitHub Pages implies a sub-path base URL (`/<repo>/`) — relative links handle it, but CI deploy workflow and Pagefind config should be tested against the real target | GitHub Pages / S3 / other? | C-15 deploy check, docs |
| OQ-5 | **Phase banner default for your publications.** `none` is the plugin default — but should your sites launch as `beta`? | Per-publication choice | Nothing (parameter exists either way) |
| OQ-6 | **Neutral-mode footer defaults.** What licence statement and links should your publications carry — e.g. an open-licence statement for the standards content? | Parameter default text | C-13 defaults, docs examples |
| OQ-7 | **Multi-publication needs.** Is one map = one site enough for now (roadmap R5 covers aggregation), or do you need a shared landing page across ContSys / ORUK / FHIR-ESD sooner? | Affects whether R5 gets pulled forward | Roadmap ordering |
| OQ-8 | **Fixture content.** Can a cut of a real publication (e.g. part of ContSys) be used as the public CI fixture, or must the fixture be synthetic? Licensing of the fixture matters in a public repo | Synthetic fallback always possible | C-15 |
| OQ-9 | **Languages.** Is en-GB-only acceptable for v1 UI strings (structure is translation-ready, NFR-I1), with Welsh as roadmap R7? | Confirm | C-14 scope |
| OQ-10 | **Roadmap ordering.** After v1: which of R1 (syntax highlighting), R2 (version switcher), R3 (print CSS), R8 (guide layout) matters most to you? | Prioritisation only | Post-v1 planning |

## Suggested next steps

1. Resolve OQ-1 and OQ-2 (names and version pin) — everything else can proceed in parallel.
2. Scaffold the plugin skeleton (C-01, C-02, C-12) and prove the walking skeleton: one small
   map → styled pages with sidebar nav, neutral branding, building with `dita -f govuk`.
3. Build the fixture publication (C-15) early — it is both the test subject and the review
   artefact for every rendering decision in [04-components.md](04-components.md).
4. Iterate rendering modules (C-04…C-07), then glossary/index (C-08/C-09), then search (C-11).

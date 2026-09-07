# 11 — Security review: posture, findings and the requirements they add

**Status:** review 2026-09-06; epics #65, #71, #77 delivered 2026-09-07, #83 with them · **Date:** 2026-09-07 · **Question:** what can reach a reader, a publisher or the repository that should not, and what does the plugin do about it? · **Feeds:** NFR-S1–S4 in [02](02-requirements.md), decision [D-22](05-decision-log.md), the manual's *Securing a published site* topic.

## 1. Threat model

Three parties. The **publisher** runs the build, sets parameters and hosts the result — trusted. **Content authors** may be many, may be a generator (the 10,000-topic data-dictionary trial), or a community (the ORUK corpus) — partly trusted: what they write reaches readers. **Readers** get a static site: no server-side code, no cookies, no analytics, and, in every branding mode, no request to another origin at runtime.

So the surface is narrow and specific:

1. **Content that becomes code or a request in the reader's browser** — an SVG diagram with a script, a `javascript:` link, an image fetched from a third party (which also tells that party who is reading).
2. **The supply chain behind the plugin** — what the build downloads, which actions run with which token, how the release asset comes to exist, whether the vendored govuk-frontend files are the files they claim to be.
3. **The repository as a public, registry-listed project** — who can change `main`, how a vulnerability is reported, whether the process is written down.

DITA-OT's own XML parsing (external entities, DTD and catalog resolution) sits below the plugin and is out of its hands; it is named as such in `SECURITY.md`.

## 2. Principle for content: publisher choice, warnings not errors

Every behaviour that touches content risk is a **parameter with a safe default**, and every finding is a **build warning** — the build always completes, the log says what was found and what was done. Authors are never blocked by the publisher's policy; publishers are never surprised by content. This is the sponsor's rule for the whole category and it is applied uniformly (see the table in §4).

## 3. Findings and dispositions

| Category | Finding (2026-09-06) | Disposition |
|---|---|---|
| Content | Inlined SVG copied verbatim: `script`, `on*` handlers, `foreignObject`, `javascript:` links, remote references reached the page | `govuk.svg.sanitize` (default on), `GOVK004W` — #78 |
| Content | SVG 1.1 doctype defaults invalidated pages | dropped on inlining — #59 |
| Content | `svgref`/`mathmlref` could inline any XML file on the build machine | `govuk.inline.scope=input` (default), `GOVK005W` — #80 |
| Content | Search ranking JSON written raw into an inline script; inline module script for govuk-frontend | data attribute + `govuk/search.js`; `govuk/init.js` — #79 |
| Content | Remote images/objects, embeds, script-scheme links rendered silently | `govuk.content.warnings`, `govuk.content.policy` warn\|strip, `GOVK006W` — #81 |
| Content | No way for a host to apply a strict CSP | `govuk.csp` no\|meta\|policy, `GOVK007W`; body-class snippet byte-identical to govuk-frontend's so its published hash applies — #82 |
| Content | Body-class snippet differed from the Design System's | aligned (`' js-enabled' +`) — #82 |
| Supply chain | Workflow token writable; actions tag-pinned; downloads unverified; Pagefind floating; asset zipped by hand; vendored CSS unguarded | `permissions: contents: read`; SHA pins + Dependabot; checksums; pinned Pagefind and Nu (npm); tag-triggered release workflow with attestation; govuk-frontend release-zip comparison — #66–#70 |
| Governance | `main` unprotected; releases pushed directly; no disclosure route; no scaffolding | Gitflow with `dev`, rulesets on both branches, `SECURITY.md`, private reporting, secret scanning, Dependabot updates, `CONTRIBUTING.md`, templates, `docs/RELEASING.md` — #72–#76, D-22 |
| Documentation | Nothing told publishers how to host safely or authors what the build would do | *Securing a published site* and *Build messages* topics, NFR-S1–S4, this record — #84–#87 |

## 4. The content controls at a glance

| Parameter | Default | Effect | Warning |
|---|---|---|---|
| `govuk.svg.sanitize` | `yes` | strip active/remote content from inlined SVG | `GOVK004W` |
| `govuk.inline.scope` | `input` | inline SVG/MathML only from under the input directory | `GOVK005W` |
| `govuk.content.warnings` | `yes` | report remote images/objects, embeds, script-scheme links | `GOVK006W` |
| `govuk.content.policy` | `warn` | render as authored, or `strip` to a placeholder | — |
| `govuk.csp` | `no` | `meta` emits a policy the pages satisfy; a literal policy passes through | `GOVK007W` |
| `govuk.site.url`, `govuk.sitemap` | `auto` | `sitemap.xml` + `robots.txt`; print document excluded and `noindex` | — |
| `govuk.dates` | `no` | critdates as a metadata line (date quality is the source's) | — |

## 5. What CI proves on every run

Every branding mode references no other origin in HTML or CSS; the CSP build is served over HTTP, every page loaded and a search run with zero violations; the emitted snippet hashes to the value in the policy; the kitchen fixture's unsafe SVG, remote image, script link and embed produce exactly the expected output and warnings under each parameter value; the scope fixture is refused by default and admitted with `any`; Nu (current release), axe, the link checker and the determinism double-build cover the new outputs; workflow token read-only, actions SHA-pinned, downloads checksummed, vendored govuk-frontend byte-identical to its release zip.

## 6. Residual risks

- **DITA-OT's parser** and preprocessing (XXE, DTD resolution, chunking) are the toolkit's; the plugin documents the boundary and routes reports.
- **Hosts without header control** get a `<meta>` policy, which cannot express `frame-ancestors`; the manual says so.
- **Publisher-hosted fonts on another origin** need a literal policy; `meta` is same-origin by design.
- **Dates and authorship** come from the source; the plugin shows them only when asked (#61).
- **Third-party runtime code** (govuk-frontend, Pagefind UI) is pinned and self-hosted, not audited by this project; Dependabot and the release-zip guard notice changes, they do not judge them.

## 7. Requirements added

NFR-S1–S4 in [02](02-requirements.md): content never reaches readers as active or remote content without a publisher choice, and risks are warned; the build and release chain is least-privilege, pinned, verified and attested; sites can carry a strict CSP with published guidance; a disclosure route and supported-versions policy exist. Traceability in [04](04-components.md) (component C-18).

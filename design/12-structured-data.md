# 12 — Structured data and machine-readable metadata from DITA

**Status:** proposed 2026-09-07 (no code; decisions in [OQ-13](06-open-questions.md)) · **Question:** what schema.org structured data and other machine-readable tags — Open Graph, social cards, Dublin Core, canonical and pagination links — can the plugin generate from DITA for its static GOV.UK Design System sites, what is worth generating in 2026, and how should it be controlled? · **Feeds:** roadmap item R9 in [02](02-requirements.md); a future FR-D requirement group; the manual.

## 1. Answer in brief

Yes, and most of it is already in the DITA. A map or bookmap carries a title, an abstract, an author, an organisation, copyright and dates; every topic has a title, a short description, a type (concept, task, reference, troubleshooting, glossary entry), a place in the map, and optionally keywords, audience, category and its own dates. That is enough for a complete set of **Open Graph and social-card tags**, a **canonical URL**, and **schema.org JSON-LD** for the site, each page, its breadcrumb trail, the publisher and the glossary — without asking authors for anything new.

What has changed since structured data was fashionable is the payoff. In 2026 the search-engine rich results that once rewarded `HowTo` and `FAQPage` markup are gone (Sections 4 and 8), so the case rests on three durable things: **link previews** wherever a page is shared (that is Open Graph, the single most visible gain for a government publisher), **discoverability and attribution** (Article dates and publisher, breadcrumbs, `Dataset` for data-dictionary publications, and a licence statement machines can read), and **honest ingestion by search and AI crawlers** that read JSON-LD and, increasingly, `llms.txt`. The recommendation (Section 9) is a `govuk.metadata` parameter with a `basic` default that emits the Open Graph and canonical set, a `full` level that adds JSON-LD by page type, and the same rule as the rest of the plugin: derived from the source, publisher-controlled, never inventing a date or a person, and validated in CI. Effort is small for `basic` and medium for `full`.

## 2. What a page carries today

The html5 base writes `<meta name="copyright">` (a bare "(C) Copyright <year>"), `<meta name="generator" content="DITA-OT">` and `<meta name="description">` from the short description; its `get-meta.xsl` can also emit `keywords`, `abstract`, product-info and rights metas when the prolog provides them. The plugin adds the search metadata Pagefind reads (`keywords`, `searchtitle`, category and audience filters), the page language from `@xml:lang`, the sitemap and `robots.txt` (#60), `noindex` on the print document, and the optional dates line (#61). There is no canonical link, no Open Graph, no social card and no JSON-LD. The manual's `install.html` head is exactly `charset`, `copyright`, `generator`, `description`, `title`, `viewport` and the stylesheets.

## 3. What GOV.UK and NHS pages carry (observed 7 September 2026)

A GOV.UK guidance page emits `og:site_name`, `og:type` (`article`), `og:url`, `og:title`, `og:description` and a site-wide `og:image`; `twitter:card` (`summary`); `description`; and two `application/ld+json` blocks — the machine-readable metadata component that renders schema.org **Article**/**NewsArticle**, **BreadcrumbList**, **Government service**, **Organisation**, **Person**, **Dataset** and search-results schemas depending on the document type. It also emits a family of `govuk:*` meta tags (`govuk:format`, `govuk:schema-name`, `govuk:organisations`, `govuk:taxon-*`, `govuk:public-updated-at`, `govuk:withdrawn`…) that feed GOV.UK's own analytics and publishing platform; they have no meaning outside gov.uk and should not be imitated.

An NHS condition page emits `og:url`, `og:site_name`, `og:description`, `og:type` (`website`), `og:locale` (`en_GB`), a default social image, and JSON-LD of type **MedicalWebPage**.

Both therefore treat Open Graph plus JSON-LD as the baseline, with the JSON-LD type chosen per page type. That is the model to follow.

## 4. What consumers still act on

- **Google recommends JSON-LD** and accepts microdata and RDFa equally; markup must be valid and reflect visible content. **Article** structured data (headline, image, `datePublished`, `dateModified`, author) is used for article results and "last updated" signals; **BreadcrumbList** is used to render breadcrumb trails in results; **Organization** (logo, `sameAs`) feeds knowledge panels; **Dataset** feeds Dataset Search.
- **HowTo** rich results were deprecated in September 2023 and the documentation removed. **FAQ** rich results were restricted to authoritative government and health sites in August 2023, deprecated in May 2026 and the documentation removed. The **sitelinks search box** (`WebSite` + `SearchAction`) was withdrawn in 2024 and its documentation removed. The vocabularies remain valid schema.org and other consumers may read them, but no search feature rewards them now.
- **Open Graph** and `twitter:card` drive the link preview in Teams, Slack, LinkedIn, X, Mastodon, WhatsApp and most chat and mail clients — the place a government publication is most often shared. Without them a shared link shows a bare URL or a scraped first paragraph.
- **AI crawlers** read JSON-LD and `description`; the `llms.txt` convention (a plain-text index at the site root) is gaining adoption and already has a DITA-OT plugin in the registry. It is an adjacent opportunity, not part of this proposal (see R9's notes).
- **Dublin Core** (`DC.*`/`DCTERMS.*` metas) is read by library, repository and some government metadata harvesters; cheap to emit alongside, and the toolkit already knows the fields.

## 5. Mapping DITA to schema.org and Open Graph

| DITA source | Page | schema.org | Open Graph / other |
|---|---|---|---|
| map/bookmap `title`/`mainbooktitle`, `booktitlealt`, `bookmeta` author/organisation/copyright, `govuk.site.url` | cover | `WebSite` (name, url, inLanguage, publisher → `Organization` or `GovernmentOrganization` with name, url, logo) | `og:site_name`, `og:type=website`, `og:title`, `og:description`, `og:url`, `og:image`, `og:locale` |
| topic `title`, `shortdesc`/`abstract`, `@xml:lang`, position in the map, prolog `critdates`, `author`, `keywords`, `audience`, `category` | every topic page | `TechArticle` (a `CreativeWork`/`Article` subtype fit for documentation): headline, description, inLanguage, isPartOf → WebSite, datePublished/dateModified (only when `govuk.dates` is on), author/publisher (organisation by default), keywords, audience, articleSection (the chapter's navtitle), license, mainEntityOfPage | `og:type=article`, `og:title`, `og:description`, `og:url`, `article:section`, `article:modified_time`/`published_time` (dates rule), `article:tag` from keywords; `twitter:card=summary`; `rel=canonical`; `rel=prev`/`next` from reading order |
| `task` with `steps` | task pages | `HowTo` with `HowToStep` (name from `cmd`, text from `info`) — valid vocabulary, no rich result | as topic |
| `glossentry`/`glossgroup` | glossary page | `DefinedTermSet` with `DefinedTerm` (name, alternateName from acronym, description) | as page |
| ancestor topicrefs | every topic page | `BreadcrumbList` (site → chapter → … → page); the sidebar layout shows no visible breadcrumb but the markup is legitimate for a hierarchy the page belongs to | — |
| `figurelist`/`tablelist`, index, search | utility pages | `WebPage` (name, isPartOf) | `og:type=website` |
| publication marked as a dataset (bookmeta `data` or `outputclass="dataset"`) | cover | `Dataset` (name, description, publisher, license, temporalCoverage from dates, `distribution` if the map links a download) — the data-dictionary trial is this case | — |
| footer licence: official → Open Government Licence, otherwise `govuk.footer.licence`/bookrights | all | `license` (a URL: OGL v3 for official; a parameter otherwise) | — |
| print document | `print.html` | none — it is `noindex` and a duplicate of the site | none |

Not proposed: `FAQPage` (no DITA construct, no consumer), `SiteNavigationElement` (no consumer), `SearchAction` (withdrawn), `Person` for authors by default (Section 8), and the `govuk:*` platform tags.

## 6. Serialisation and constraints

- **JSON-LD in `<head>`**, one block per page, matching GOV.UK and NHS practice and Google's recommendation; it leaves the visible markup untouched and survives the print document's merging (which does not carry it).
- **Determinism (FR-B6).** Nothing derived from the clock; property order fixed by building the JSON in the stylesheet rather than serialising an XPath map (map key order is not guaranteed); strings escaped with a small JSON-escape function; absolute URLs only from `govuk.site.url`.
- **Content-Security-Policy.** `application/ld+json` is a data block: browsers do not execute it and `script-src` does not gate it, so `govuk.csp=meta` needs no change (CI's CSP check will prove it).
- **Validity and weight.** Nu accepts the block; one page's structured data is one to three kilobytes, well inside NFR-P2.
- **Localisation.** `inLanguage`/`og:locale` from `@xml:lang` (`en-GB` → `en_GB`); labels are not rendered, so no new strings.
- **Where the values come from, in order:** a parameter, then bookmeta, then the map's topicmeta, then the topic's prolog; a value that is missing is omitted, never invented — the same rule as the footer credits (#42) and the dates line (#61).

## 7. Prior art

The html5 base's metadata stylesheet (the `DC`-flavoured metas above); a registry plugin that adds Open Graph tags to DITA HTML output (`fox.jason.open-graph`, at 1.1.0), which shows the demand and the field set but is separate from any design-system template; a registry plugin producing `llms.txt` (`fox.jason.llms.txt`); GOV.UK's machine-readable metadata and meta-tags components (Section 3); commercial documentation platforms and help systems emit Open Graph and, increasingly, JSON-LD `TechArticle`/`Article` as a matter of course.

## 8. Risks and governance

- **Wrong dates published with confidence.** The ORUK corpus showed batch-stamped `modified` values. Dates enter structured data only when the publisher has turned `govuk.dates` on (#61) — one switch, one meaning.
- **People's names.** Prolog `author` may name individuals; GOV.UK attributes to organisations. Default `author`/`publisher` to the organisation (bookmeta `organization`, else `govuk.organisation`, else the service name); personal authors only under an explicit `govuk.metadata.persons=yes`.
- **A missing or wrong social image.** `og:image` must be an absolute URL to a real 1200×630 image; emit it only when `govuk.og.image` names a file (copied into `govuk/`) and `govuk.site.url` is set; the build warns when one is set without the other.
- **Licence claims.** `license` is a legal statement: OGL v3 by default only for `govuk.branding=official` (the footer already says so), otherwise only from `govuk.licence.url`; text-only footer licences produce no `license` property.
- **Duplicate content for scrapers.** JSON-LD carries headline and description, not body text; the print document stays `noindex` and without structured data.
- **Imitating GOV.UK's platform tags** would mislead consumers that key on them; not emitted.
- **Silent wrongness.** Every block is parsed in CI and checked for the properties each type needs; the manual states what is derived from where so a publisher can predict the output.

## 9. Recommended shape

**Parameters** (all optional, the plugin's usual pattern):

| Parameter | Values | Effect |
|---|---|---|
| `govuk.metadata` | `basic` (default) \| `full` \| `no` | `basic`: canonical, Open Graph, social card, `prev`/`next`, Dublin Core; `full`: adds the JSON-LD of Section 5 |
| `govuk.organisation`, `govuk.organisation.url`, `govuk.organisation.logo` | text, URL, file | publisher identity; defaults from bookmeta, then the service name |
| `govuk.og.image` | file | site-wide social image, copied into `govuk/`; needs `govuk.site.url` |
| `govuk.licence.url` | URL | `license` for non-official builds |
| `govuk.metadata.persons` | `no` (default) \| `yes` | allow prolog authors as `Person` |
| `govuk.site.url` (existing) | URL | absolute URLs; without it, URL-bearing tags are omitted and the rest still emitted |
| `govuk.dates` (existing) | | gates every date |

**By page** as in Section 5; `TechArticle` for every topic type, `HowTo` for tasks, `DefinedTermSet` for the glossary, `WebSite`+`Organization` on the cover, `BreadcrumbList` everywhere below the cover, `Dataset` on opt-in.

**Verification.** A small checker in `tools/` parses every `application/ld+json` block in a built site, validates it is JSON, confirms `@context`/`@type`, and asserts the properties each type must carry (headline, isPartOf, inLanguage; itemListElement positions contiguous; DefinedTerm names non-empty); Nu and the CSP check run unchanged; a fixture with bookmeta, prolog dates, a task, a glossary and an opted-in dataset; determinism double-build. Google's Rich Results Test and the schema.org validator remain manual spot checks, since they need the network.

**Documentation.** A manual topic, *Metadata and social sharing*: what is emitted at each level, where each value comes from, the dates and persons rules, and how to check a page. Parameter rows.

**Effort.** `basic`: **S** (two to three days including fixture, checker, manual). `full`: **M** (one to two weeks: JSON-LD builders per type, breadcrumbs from the map, glossary set, dataset opt-in, checker rules). Suggested order: `basic` first — the largest visible benefit at the smallest risk — then `TechArticle` + `BreadcrumbList` + `Organization`, then `HowTo`, `DefinedTermSet` and `Dataset`. `llms.txt` is a separate small item if wanted (R9 notes).

## 10. Decisions needed (OQ-13)

1. Default level: `basic` on by default (recommended — it changes no visible page and only adds tags derived from existing content), or off until asked.
2. Whether personal authors may ever appear (recommended: only under `govuk.metadata.persons=yes`).
3. Whether to emit `HowTo` and `DefinedTermSet` at all now that no search feature rewards them (recommended: yes — cheap, valid, and read by other consumers; skip `FAQPage`).
4. How a publication declares itself a `Dataset` (bookmeta `data`, an outputclass on the map, or a parameter).
5. Whether `llms.txt` joins this work or follows separately.

## 11. Sources checked (September 2026)

GOV.UK guidance and NHS condition pages (head metadata observed directly); GOV.UK Publishing Components guide — *machine readable metadata* and *meta tags* components; Google Search Central — structured data introduction (JSON-LD recommendation), Article, Breadcrumb, Dataset and Organization documentation, and the search updates log (HowTo deprecation, FAQ restriction and deprecation, sitelinks search box withdrawal); schema.org type pages for `TechArticle`, `DefinedTermSet`, `DefinedTerm`, `HowTo`, `BreadcrumbList`, `Dataset`, `GovernmentOrganization`; the Open Graph protocol; the DITA-OT registry entries for the Open Graph and `llms.txt` plugins; the html5 base `get-meta.xsl`; this plugin's built output.

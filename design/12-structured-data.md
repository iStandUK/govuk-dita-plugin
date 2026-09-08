# 12 — Structured data and machine-readable metadata from DITA

**Status:** proposed 2026-09-07; defaults and scope decided 2026-09-08 as **D-24**, with one question open — how a publication declares its data assets, at map level ([OQ-13](06-open-questions.md)); no code · **Question:** what schema.org structured data and other machine-readable tags — Open Graph, social cards, Dublin Core, DCAT catalogue records, canonical and pagination links — can the plugin generate from DITA for its static GOV.UK Design System sites, what is worth generating in 2026, and how should it be controlled? · **Feeds:** roadmap item R9 in [02](02-requirements.md); a future FR-D requirement group; the manual.

## 1. Answer in brief

Yes, and most of it is already in the DITA. A map or bookmap carries a title, an abstract, an author, an organisation, copyright and dates; every topic has a title, a short description, a type (concept, task, reference, troubleshooting, glossary entry), a place in the map, and optionally keywords, audience, category and its own dates. That is enough for a complete set of **Open Graph and social-card tags**, a **canonical URL**, and **schema.org JSON-LD** for the site, each page, its breadcrumb trail, the publisher and the glossary — without asking authors for anything new.

What has changed since structured data was fashionable is the payoff. In 2026 the search-engine rich results that once rewarded `HowTo` and `FAQPage` markup are gone (Sections 4 and 8), so the case rests on three durable things: **link previews** wherever a page is shared (that is Open Graph, the single most visible gain for a government publisher), **discoverability and attribution** (Article dates and publisher, breadcrumbs, `Dataset` for data-dictionary publications, and a licence statement machines can read), and **honest ingestion by search and AI crawlers** that read JSON-LD and, increasingly, `llms.txt`. For the publications this plugin was built for — a data dictionary, a data standard — there is a fourth: a **DCAT record** (Section 5a), the vocabulary UK government catalogues harvest, generated from the same bookmap so the catalogue entry and the documentation never disagree. The recommendation (Section 9) is a `govuk.metadata` parameter with a `basic` default that emits the Open Graph and canonical set, a `full` level that adds JSON-LD by page type, and the same rule as the rest of the plugin: derived from the source, publisher-controlled, never inventing a date or a person, and validated in CI. Effort is small for `basic` and medium for `full`.

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

## 5a. DCAT — the record UK government catalogues harvest

**What it is.** The W3C Data Catalog Vocabulary (DCAT 3, Recommendation of 22 August 2024) is the RDF vocabulary for describing catalogues, datasets, data services and their distributions, built on Dublin Core Terms, FOAF and vCard. It is what data portals exchange: data.gov.uk harvests DCAT feeds (its documented field list covers `dct:title`, `dct:description`, `dct:identifier`, `dct:publisher`, `dct:license`, `dct:issued`/`dct:modified`, `dct:language`, `dcat:keyword`, `dcat:theme`, `dcat:landingPage`, `dct:conformsTo`, `dct:spatial`/`dct:temporal`, `dct:accrualPeriodicity`, `dcat:distribution` with `dcat:downloadURL`/`dcat:accessURL`/`dcat:mediaType`, and a `foaf:Organization` publisher — with title, description, a stable identifier and a licence mandatory); the Cabinet Office's **Cross-Government Metadata Exchange Model** (2024–26, LinkML with generated JSON Schema and SHACL) is a DCAT-based profile for describing data assets between departments; and Google's Dataset Search accepts DCAT in a page alongside schema.org `Dataset`.

**Why it belongs here.** Two of the corpora the plugin was built against *are* data: the NHS Data Dictionary (definitions of data sets, elements and classes) and Open Referral UK (a data standard with JSON schemas and an API specification). Their sites are the authoritative documentation of data assets; the catalogue entry for those assets lives elsewhere and is typed by hand. Generating the DCAT record from the same bookmap that builds the site makes the two agree by construction and gives data.gov.uk or a departmental catalogue something to harvest.

**Modelling honestly.** A documentation site describes data; it is not the data. DCAT 3 provides for that: a data standard or dictionary is a **`dct:Standard`** (the thing datasets `dct:conformsTo`), an API is a **`dcat:DataService`**, and only a publication that documents a real dataset and links its files is a **`dcat:Dataset`** with `dcat:Distribution`s. A publication that documents many data sets — the data dictionary — is a **`dcat:Catalog`** whose members are the standards it defines. The type is the publisher's declaration, never inferred.

**Declared in the maps, not the book (D-24).** One publication commonly holds several assets: the Dictionary's data set specifications, or Open Referral UK's standard, its taxonomies and its feed register. A declaration is therefore a property of a **branch of the map** — a submap, or the topicref heading a section — not of the publication. Each declared branch becomes a member of the publication's catalogue with its own type, title, description, identifier, landing page (the branch's first page) and distributions; `bookmeta` supplies the publication-wide properties (publisher, licence, version, contact) that members inherit unless they override them. A publication that declares exactly one asset is that asset, with no catalogue wrapper. The mechanism — `data` in a map's or topicref's `topicmeta`, an `outputclass` token, a `subjectScheme` binding, or a manifest map — is the open half of OQ-13.

**Where the values come from** (the plugin's usual order — parameter, then bookmeta, then the map; nothing invented):

| DCAT / DCTERMS | Source |
|---|---|
| `dct:title`, `dct:description` | `mainbooktitle`, `booktitlealt` or map title and abstract |
| `dct:publisher` (`foaf:Organization` — `foaf:name`, `foaf:homepage`) | bookmeta `organization`, else `govuk.organisation` and `govuk.organisation.url` |
| `dct:identifier` | a stable URI: `govuk.site.url` by default, or bookmeta `bookid` / a `data name="dct:identifier"` |
| `dct:issued`, `dct:modified`, `dcat:version`, `dcat:previousVersion` | bookmeta `critdates`, `vrm` and `bookchangehistory` — publication-level dates only, never topic stamps |
| `dct:license` | OGL v3 URI for `govuk.branding=official`; otherwise `govuk.licence.url` (a URI, as harvesters require) |
| `dct:language`, `dcat:keyword` | `@xml:lang`; bookmeta `keywords` |
| `dcat:landingPage` | `govuk.site.url` |
| `dcat:theme`, `dct:spatial`, `dct:temporal`, `dct:accrualPeriodicity`, `dct:conformsTo` | bookmeta `data` elements with those names — DITA's own extension point — carrying the URIs the target catalogue expects (for example a UK statistical geography for `dct:spatial`) |
| `dcat:contactPoint` (`vcard:Kind` with `vcard:hasEmail`) | `govuk.contact.email`, an organisational mailbox — never a person by default |
| `dcat:distribution` (`dcat:downloadURL`, `dcat:mediaType`, `dct:format`, `dct:title`) | the map's resource-only references to schema, CSV, JSON and OpenAPI files that ship with the site (Open Referral's specifications are exactly this) |

**Serialisation.** One record per publication — a catalogue with its members, or a single asset — as `dcat.jsonld` at the site root (JSON-LD with the DCAT context), the same block embedded in the cover page's head (so Dataset Search sees it), and `<link rel="alternate" type="application/ld+json" href="dcat.jsonld">` on the cover; Turtle (`dcat.ttl`) as a second serialisation for harvesters that prefer RDF — both are plain text a stylesheet writes deterministically. The record is excluded when `govuk.site.url` is absent, since every property that matters is a URI.

**Validation.** The mandatory-field set of the target harvester (data.gov.uk's list; the exchange model's required properties) as a checker in `tools/`, warning per missing field; optionally SHACL validation with the exchange model's published shapes through a Python SHACL library in CI — offline, pinned, and no addition to the publisher's build.

**Parameters.** `govuk.dcat` = `no` (default) | `yes` — build the record from the declarations the maps carry (D-24: the type belongs in the DITA, not in a build parameter; the switch's final shape follows the open half of OQ-13); `govuk.contact.email`; the existing `govuk.site.url`, `govuk.organisation*`, `govuk.licence.url`; bookmeta `data` for the catalogue-specific properties. A missing mandatory field is a warning naming it (the record is still written; the harvester will say the same thing), never a failed build.

**Effort.** **S–M**: two to four days — one stylesheet writing the two files and the head link, a fixture (the ORUK mini bookmap with `data` properties and its schema files as distributions), the checker, a manual section. It shares the organisation, licence and URL parameters with the schema.org work, and the schema.org `Dataset` (Section 5) and the DCAT record map one-to-one, so a publisher who opts into one gets the other from the same values.

## 5b. Worked examples: a data dictionary, reference data, master data — and all three at once

Three kinds of thing get published through the plugin, and they need three vocabularies that fit together. Section 5a's DCAT record describes the *publication and its assets*; two more W3C vocabularies describe what is inside them: **ADMS** (the Asset Description Metadata Schema, a DCAT profile for "semantic assets" — data models, schemas, code lists, taxonomies) for the things a standard is made of, and **SKOS** for terms, codes and taxonomies. Entities — organisations, places — take the **Organization Ontology** (`org:`) or `schema:Organization`. None of this is invented for the plugin; it is what UK and EU catalogues already expect.

### The NHS Data Model and Dictionary: one specification, two kinds of asset, no data

The Dictionary is one publication (one bookmap, one `dcat:Catalog`, NHS England as `dct:publisher`, OGL as `dct:license`, its release as `dcat:version` with `dcat:previousVersion` from the change history). Inside it are two kinds of asset, and neither is a dataset:

| Part of the Dictionary | Catalogue class | What the record carries | The definitions inside |
|---|---|---|---|
| The common logical model — classes, attributes, data elements | one `adms:Asset` (a `dct:Standard`), `dct:type` *domain model* | title, description, version, status, `dcat:distribution`s: the model's pages, and any machine-readable export (schema, model interchange file) the publisher ships | every class, attribute and data element is a **`skos:Concept`** in one of three `skos:ConceptScheme`s (classes, attributes, data elements): `skos:prefLabel` from the title, `skos:definition` from the short description, `skos:altLabel` from `searchtitle`/abbreviations, `skos:notation` from any code, `skos:related`/`dct:isPartOf` between an attribute and its class, and **`adms:status` retired** for the items marked retired (the same signal that demotes them in search, D-18) |
| Each data set specification (a maternity data set, a mental-health data set…) | one `adms:Asset` per specification, `dct:type` *data set specification*, `dct:conformsTo` the logical model | title, description, version, status, `dct:references` the data elements it uses, `dcat:distribution`s: the specification pages and any technical output specification or schema files | the elements it lists are the concepts above, referenced, not redefined |

What the Dictionary never publishes is a `dcat:Dataset`, because it never publishes the data: the collections themselves are catalogued elsewhere by the bodies that hold them, and *their* records say `dct:conformsTo <the specification's URI>`. That is the structural point — the Dictionary publishes the targets that other catalogues point at, so its specification URIs must be stable (the site URL plus the topic path, or an identifier the generator supplies through `resourceid`).

### Reference data: code lists and vocabularies

A controlled list — the Local Government Association's standards lists that Open Referral UK already uses for service and circumstance taxonomies, or any code list — is a `skos:ConceptScheme`: one `skos:Concept` per entry with `skos:notation` (the code), `skos:prefLabel`, `skos:definition`, `skos:broader`/`skos:narrower` for hierarchies, and `skos:exactMatch`/`skos:closeMatch` where one list is mapped to another. In the catalogue it is an `adms:Asset` of type *code list* or *taxonomy*, with `dcat:distribution`s in CSV, JSON and RDF and the site as `dcat:landingPage`.

### Master data: a register of organisations

A list of organisations is the one case that *is* data: a `dcat:Dataset` with `dcat:distribution`s (CSV, JSON) and the site as its landing page, and each entry an `org:Organization` (or `schema:Organization`) with `org:identifier`s from the identifier systems that matter (an ODS code, a company number, a URI in a national register), `org:subOrganizationOf`, sites and addresses. For a register of any size the source of truth is the machine-readable file, the DITA pages are generated from it, and the plugin's job is to link the register as the distribution and type the pages — not to reconstruct rows from prose.

### Open Referral UK: the three together

Open Referral UK is a standard (a logical model of services, organisations and locations, with JSON schemas and an API specification), uses reference data (taxonomies for service type, eligibility and circumstance — the LGA lists), and needs master data (the register of organisations publishing conformant feeds, which its dashboard already lists). One site, one `dcat:Catalog`, three kinds of member:

- the **standard** — an `adms:Asset`/`dct:Standard` per major version (`dcat:hasVersion`), its classes and attributes as SKOS concepts, its JSON schemas and API specification as `dcat:distribution`s;
- the **taxonomies** — `skos:ConceptScheme`s of its own with `skos:exactMatch` to the LGA lists, catalogued as code-list assets;
- the **feeds** — the register as a `dcat:Dataset`, and each live feed a **`dcat:DataService`** with `dcat:endpointURL`, `dct:conformsTo` the standard's URI and its `dct:publisher` organisation.

That last part is the payoff: a harvestable catalogue of conformant services that aggregators, the LGA and data.gov.uk can read, generated from the same source as the documentation.

### Which DITA constructs carry this

Existing constructs, with a small documented convention, before any specialisation:

| Need | DITA construct | Why it is the right one |
|---|---|---|
| publication-level catalogue properties (type, identifier, theme, spatial, temporal, frequency, status) | bookmap `bookmeta` with `data name="dct:…"`/`"dcat:…"`/`"adms:…"` | `data` is DITA's typed-metadata extension point; generators write it trivially; no DTD change |
| what kind of thing a topic describes (class, attribute, data element, data set specification, code list, organisation) | `prolog/metadata/category`, as the Dictionary's generator already emits for search filters (D-18) | one value drives search filters and the catalogue type |
| a term with a definition, a code with a label | `glossentry` (`glossterm` → prefLabel, `glossdef` → definition, `glossAlt`/`glossAbbreviation`/`glossAcronym` → altLabel and notation), grouped by `glossgroup` per scheme | already harvested for the A–Z glossary (FR-G1); SKOS falls out of the same harvest |
| a hierarchy or classification scheme | a `subjectScheme` map (`subjectdef` nesting → `skos:broader`/`narrower`; `navtitle` → prefLabel; `enumerationdef` binding to attribute values) | DITA 1.3's own controlled-vocabulary construct, designed for exactly this |
| an entity's typed fields (an organisation's identifiers, addresses) or a specification's element list | a `reference` topic with a `properties` table (`proptype`/`propvalue`/`propdesc`) or a `simpletable`, with the machine-readable register keyed from the map | tables stay readable on the page; the register is the distribution |
| identifiers in other systems, stable URIs | `resourceid` (`appid`, `appname`) | the DITA element for "this thing's identifier elsewhere" |
| relationships (attribute ↔ class, data set → elements, standard → taxonomy) | `related-links`, `reltable`, `xref` with `@type`/`@role` | become `dct:references`, `dct:isPartOf`, `skos:related` |
| dates, versions, status | `critdates`, bookmeta `vrm`/`bookchangehistory`, `importance="obsolete"`/outputclass `retired` | already used for the dates line and search demotion |
| the files that are the distributions | resource-only `keydef`s with `format="json"`, `"csv"`, `"ttl"` | copied to the output, linked as `dcat:downloadURL` |

A DITA **specialisation** (a `dcat`/`adms` metadata domain with named elements instead of `data`) would be cleaner to author and validate, and can follow if the convention proves itself; it costs every generator and author a DTD dependency, so it should not come first. Lightweight DITA (MDITA) cannot carry most of this and is out of scope for these use cases.

### What the plugin would emit for them

Beyond Section 5a's `dcat.jsonld`/`dcat.ttl`: one SKOS file per concept scheme (`vocab/<scheme>.ttl` and `.jsonld`) harvested the way the glossary already is; `schema:DefinedTermSet` JSON-LD in the glossary page and `schema:DefinedTerm` per definition page for web search; `org:Organization` records in the register's JSON-LD; `<link rel="alternate">` from each page to the RDF that describes it. A static site cannot negotiate content, but stable file paths and alternate links are enough for harvesters and for people. Estimated effort on top of 5a: SKOS from glossary and subjectScheme **S**; ADMS typing from categories **S**; register and `DataService` catalogue **M** — each a separate, opt-in step once the DCAT record exists.

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
| `govuk.dcat`, `govuk.contact.email` | `no` (default) \| `yes`; an organisational mailbox | the DCAT catalogue record of Section 5a, as `dcat.jsonld` + `dcat.ttl` and in the cover's head; the assets and their types are declared in the maps (D-24), with `bookmeta` and map `data` supplying theme, spatial, temporal, frequency and identifier |

**By page** as in Section 5; `TechArticle` for every topic type, `HowTo` for tasks, `DefinedTermSet` for the glossary, `WebSite`+`Organization` on the cover, `BreadcrumbList` everywhere below the cover, `Dataset` on opt-in.

**Verification.** A small checker in `tools/` parses every `application/ld+json` block in a built site, validates it is JSON, confirms `@context`/`@type`, and asserts the properties each type must carry (headline, isPartOf, inLanguage; itemListElement positions contiguous; DefinedTerm names non-empty); Nu and the CSP check run unchanged; a fixture with bookmeta, prolog dates, a task, a glossary and an opted-in dataset; determinism double-build. Google's Rich Results Test and the schema.org validator remain manual spot checks, since they need the network.

**Documentation.** A manual topic, *Metadata and social sharing*: what is emitted at each level, where each value comes from, the dates and persons rules, and how to check a page. Parameter rows.

**Effort.** `basic`: **S** (two to three days including fixture, checker, manual). `full`: **M** (one to two weeks: JSON-LD builders per type, breadcrumbs from the map, glossary set, dataset opt-in, checker rules). Suggested order: `basic` first — the largest visible benefit at the smallest risk — then `TechArticle` + `BreadcrumbList` + `Organization`, then `HowTo`, `DefinedTermSet` and `Dataset`. `llms.txt` is a separate small item if wanted (R9 notes).

## 10. Decisions (OQ-13 → D-24, 2026-09-08)

1. ✅ **`basic` on by default.**
2. ✅ **No personal authors by default** — only under `govuk.metadata.persons=yes`.
3. ✅ **`HowTo` and `DefinedTermSet` emitted; `FAQPage` not.**
4. ⬜ **Open: how a publication declares its data assets.** Because one publication may hold several datasets, standards, services or code lists, the declaration must work **at map level** — a submap, or the topicref heading a branch — not at book level. Options: `data name="dcat:type"` in `topicmeta` (the natural companion to decision 7), an `outputclass` token, a `subjectScheme` binding, or a manifest map. Blocks the DCAT work and the `Dataset` and ADMS halves of the typing and vocabulary work.
5. ✅ **`llms.txt` follows separately**, as epic [#116](https://github.com/iStandUK/govuk-dita-plugin/issues/116).
6. ✅ **DCAT keeps its own switch** (not part of `full`); the checker enforces **data.gov.uk's mandatory set** by default, with the Cross-Government Metadata Exchange Model's SHACL shapes as an optional **CI-only** validation.
7. ✅ **Conventions first, specialisation later** (`data`, `category`, `glossentry`, `subjectScheme`, `resourceid`, `properties`, `related-links`). Which concept schemes the Dictionary's generator marks, and whether the Open Referral UK feed register is a `DataService` catalogue in the first step, are sequencing choices for the epic rather than design decisions.

## 11. Sources checked (September 2026)

GOV.UK guidance and NHS condition pages (head metadata observed directly); GOV.UK Publishing Components guide — *machine readable metadata* and *meta tags* components; Google Search Central — structured data introduction (JSON-LD recommendation), Article, Breadcrumb, Dataset and Organization documentation, and the search updates log (HowTo deprecation, FAQ restriction and deprecation, sitelinks search box withdrawal); schema.org type pages for `TechArticle`, `DefinedTermSet`, `DefinedTerm`, `HowTo`, `BreadcrumbList`, `Dataset`, `GovernmentOrganization`; the Open Graph protocol; the DITA-OT registry entries for the Open Graph and `llms.txt` plugins; the html5 base `get-meta.xsl`; this plugin's built output; W3C DCAT 3 (Recommendation, 22 August 2024); data.gov.uk guidance — *Accepted DCAT and data.json fields*; the Cabinet Office Cross-Government Metadata Exchange Model repository (LinkML model, SHACL and JSON Schema outputs); Google Dataset Search documentation (DCAT accepted alongside schema.org); W3C ADMS (Asset Description Metadata Schema) and its DCAT-AP profile; W3C SKOS Reference and the Organization Ontology; the DITA 1.3 specification (`subjectScheme`, `data`, `resourceid`, `glossentry`, `properties`).

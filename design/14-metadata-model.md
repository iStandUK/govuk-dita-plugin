# 14 — One metadata model: harvest once, map by table, write by syntax

**Status:** decided 2026-10-05 as **D-26**, after a design review of [12](12-structured-data.md) before any code; amends 12 §6 and §9 and closes OQ-13. · **Question:** epic [#97](https://github.com/iStandUK/govuk-dita-plugin/issues/97) names Open Graph, Dublin Core, schema.org, DCAT, SKOS and ADMS. Must each be its own transform, or can the DITA content carry metadata generically? · **Feeds:** FR-D1–D4 in [02](02-requirements.md); issues #99–#103, #122, #123; the manual.

## 1. Answer in brief

Each scheme must not be its own transform. The plugin reads the DITA **once** into a neutral record per thing (publication, branch, page, term), using one small vocabulary. Each scheme is then a **mapping table** (data, not code), and output is written by three **writers**, one per syntax: HTML `meta`/`link`, JSON-LD and Turtle.

Code grows with DITA's constructs, which the standard fixes. Schemes are open-ended, and each one costs a table.

The DITA content carries metadata generically through `<data>`, DITA's own typed extension point. A property written as `<data name="dct:spatial" value="…"/>` reaches every scheme whose table knows the term, with no change to any stylesheet. A branch of a map declares itself a data asset the same way, which settles the open half of OQ-13.

## 2. What the review found

**The epic as written builds about ten emitters.** Open Graph, Dublin Core, four JSON-LD shapes, `Dataset`, DCAT in two syntaxes, SKOS in two syntaxes, and ADMS.

- Each restates the same rules: parameter, then bookmeta, then topicmeta, then prolog; dates only with `govuk.dates`; no persons by default; licence only where it is known.
- Three need their own checker.
- #122 asks CI to assert that `Dataset` and the DCAT record "agree field for field". That test exists only because two transforms would compute the same values separately.

**The plugin already harvests in six places.** Book and prolog metadata are read separately by the footer, the cover, the print cover, the books step, the dates line and the search tags. Every new reader repeats the precedence rules.

**The real content is sparse** (checked 2026-10-05):

- The NHS Data Dictionary source has 9,895 topics whose only prolog metadata is `keywords`. There is no `category`, `critdates`, `author`, `data` or `resourceid`. Design 12 §5b assumed its generator emits `category`; this source does not. Type and status are carried by `title/@outputclass` (`element retired`).
- Those keywords are the title split into words ("6", "-", "8", "week"). Published as tags, they would be noise on ten thousand pages.
- The Open Referral UK fixture's bookmeta carries an author and an owner, nothing else.
- Pages built today carry no Dublin Core tags: DITA-OT 4.4.1's HTML5 output does not emit the ones 12 §7 refers to.

A missing value is therefore the normal case, and a generator that can write standard metadata elements is worth more than a plugin that learns one corpus's conventions (Section 9).

## 3. The three layers

| Layer | What it is | Grows with |
|---|---|---|
| 1. Harvest | One module (`xsl/metadata.xsl`) reads the merged map, the topic and the parameters, and applies the precedence and the gates once. It yields `govuk:record` elements: a neutral description of each thing. | DITA constructs |
| 2. Mapping tables | One XML file per scheme (`resource/metadata/*.xml`): which record kinds it covers, the type each becomes, neutral property to scheme property, value format, required or not. | Schemes: a file each |
| 3. Writers | One per syntax: `meta`/`link` elements, JSON-LD, Turtle. A writer knows nothing about any scheme; it walks a table. | Nothing |

The same records serve the page's head (written by the topic transform) and the site-level files (`dcat.jsonld`, `vocab/*.ttl`, written by the map transform). They can later serve `llms.txt` (#118), and the footer, the covers and the dates line, whose own harvests can move over when there is a reason to touch them. Their output is tested byte for byte, so they are not rewritten now.

## 4. The record

A record has a **kind**, an **identifier** (the thing's URL, when `govuk.site.url` is set), **properties** and **relations** to other records.

| Kind | One per | Becomes, for example |
|---|---|---|
| `publication` | build | `WebSite`; `dcat:Catalog`, or the single asset it declares |
| `asset` | branch of the map that declares a type (Section 6) | `dcat:Dataset`, `dct:Standard`, `dcat:DataService`, `adms:Asset`, `Dataset` |
| `page` | topic page; cover and utility pages | `TechArticle`, `WebPage`; Open Graph and Dublin Core tags |
| `scheme` | `glossgroup`, `subjectScheme` map | `skos:ConceptScheme`, `DefinedTermSet` |
| `term` | `glossentry`, `subjectdef` | `skos:Concept`, `DefinedTerm` |
| `step` | task step | `HowToStep` |
| `file` | resource-only reference to a data file | `dcat:Distribution` |
| `agent` | organisation (a person only under `govuk.metadata.persons=yes`) | `Organization`, `foaf:Organization` |

**Properties use Dublin Core terms as the neutral vocabulary.** DCAT and ADMS are built on them, and schema.org, Open Graph and SKOS map onto them cleanly. The core set, with the standard DITA source of each (first found wins, in the order shown):

| Property | From the DITA |
|---|---|
| `dct:title` | topic `title`; map `title` / `mainbooktitle`; `navtitle`; `glossterm` |
| `dct:description` | `shortdesc` / `abstract`; `booktitlealt`; map `topicmeta/shortdesc`; `glossdef` |
| `dct:language` | `@xml:lang` |
| `dct:publisher`, `dct:creator` | parameter `govuk.organisation`; bookmeta `organization`, `publisherinformation`; `author` (persons gated) |
| `dct:rights`, `dct:license` | `bookrights`; the Open Government Licence for official branding; `govuk.licence.url` |
| `dct:issued`, `dct:modified` | `critdates` `created` / `revised` (dates gated) |
| `dct:identifier` | `resourceid`; `bookid`; else the URL |
| `dct:subject` | `category`; `keywords` (filtered, Section 5) |
| `dct:audience` | `audience` |
| `dct:type` | topic type (task, concept, reference, glossentry); a declared type (Section 6) |
| `dcat:version` | bookmeta `vrm`; `edition` |
| `adms:status` | `importance="obsolete"`; outputclass token `retired` |
| *any prefixed name* | `<data name="prefix:term" value="…"/>` in bookmeta, topicmeta or prolog (Section 6) |

**Relations** come from structure, not from properties: `isPartOf` (the page's ancestors in the map, and the publication), `previous`/`next` (reading order), `hasPart` (a scheme's terms, a task's steps, an asset's files), `broader`/`narrower` (nesting), `related` (related links, relationship tables).

## 5. Rules applied once, in the harvest

These were restated in every issue; they now live in one place, and every scheme inherits them.

- **Order of sources:** a parameter, then bookmeta, then the map's topicmeta (which DITA cascades down the branch), then the topic's prolog. A missing value is omitted, never invented.
- **Dates** enter a record only when `govuk.dates` is on (#61).
- **Persons** enter only under `govuk.metadata.persons=yes`; otherwise the creator is the organisation (D-24.2).
- **Licence** is a URL or nothing: the Open Government Licence for official branding, else `govuk.licence.url`.
- **URLs:** identifiers and every URL-valued property need `govuk.site.url`. Without it they are omitted and the rest is still written. Nothing points at another origin unless the publisher wrote that URL.
- **Keywords as tags:** a keyword that is only a word of the page's own title is dropped, and duplicates are removed. A tag that repeats the title is not a tag. (Found in the Dictionary source, Section 2.)
- **The print document** carries no records (it is `noindex`).
- **Determinism:** records, properties and relations are in document order; nothing comes from the clock.

## 6. Carried by the DITA: `data`, and declaring an asset

**Any property.** `<data name="prefix:term" value="…"/>`, or with the value as content, is read from bookmeta, from the topicmeta of a map or topicref, and from a topic's prolog. The name is a prefixed term. The prefixes the shipped tables declare are `dct`, `dcat`, `adms`, `skos`, `foaf`, `org`, `vcard`, `schema`, `og` and `rdf`.

```xml
<topicmeta>
  <data name="dct:spatial" value="http://statistics.data.gov.uk/id/statistical-geography/E92000001"/>
  <data name="dct:accrualPeriodicity" value="http://publications.europa.eu/resource/authority/frequency/ANNUAL"/>
</topicmeta>
```

- A property reaches each scheme whose table maps it. A name that is not a term of a declared vocabulary is reported once per build as a warning and left out, so a misspelt name is not silent. A correct term that no enabled table maps is left out quietly (Section 12).
- The table says whether a property's value is a URI, a date or text. Authors do not mark it.
- This is the convention the toolkit already follows for `othermeta`, which it copies to `<meta>` tags unchanged.

**Declaring a data asset (OQ-13, decision 4).** A branch declares itself with `rdf:type` in the topicmeta of the submap or of the topicref that heads the branch:

```xml
<topicref href="maternity/overview.dita">
  <topicmeta>
    <data name="rdf:type" value="dct:Standard"/>
    <data name="dct:conformsTo" value="https://example.org/model"/>
  </topicmeta>
  …
</topicref>
```

- The value is a prefixed class (`dcat:Dataset`, `dcat:DataService`, `dct:Standard`, `adms:Asset`, `skos:ConceptScheme`) or a full URI.
- The branch becomes an `asset` record. Its landing page is the branch's first page. Its title and description come from that topicref. Properties it does not state are inherited from the publication.
- A publication with several declared branches is a catalogue of them. With exactly one, it is that asset. With none, nothing catalogue-shaped is written.
- The type is the publisher's statement and is never inferred.

**Why `data` and not the alternatives.** It is the carrier every other property already uses, so the declaration needs no mechanism of its own. An `outputclass` token is untyped and collides with styling. A `subjectScheme` binding cannot carry identifiers or other properties, so it would need `data` beside it; it remains the right tool for controlled values later. A manifest map would be a second source of truth.

## 7. A mapping table

One file per scheme. The shipped ones: `opengraph`, `dublincore`, `links` (canonical, `prev`/`next`, `alternate`), `schemaorg`, `dcat`, `skos`, `adms`.

```xml
<scheme id="schemaorg" syntax="json-ld" context="https://schema.org">
  <kind record="page" type="TechArticle">
    <property term="dct:title"       as="headline"      required="yes"/>
    <property term="dct:description" as="description"/>
    <property term="dct:language"    as="inLanguage"    required="yes"/>
    <property term="dct:modified"    as="dateModified"  format="date"/>
    <property term="dct:publisher"   as="publisher"     nested="agent"/>
    <relation name="isPartOf"        as="isPartOf"      target="publication" required="yes"/>
  </kind>
  <kind record="page" when="dct:type = 'task'" type="HowTo" as="mainEntity">
    <relation name="hasPart" as="step" target="step"/>
  </kind>
</scheme>
```

- **Row order is output order**, which gives JSON-LD a fixed property order without relying on map ordering.
- **`format`** names one of a few converters: `date`, `uri`, `locale` (`en-GB` to `en_GB`), `text`. A new converter is the only reason a table change needs code.
- **`required`** drives one checker for every scheme, in the build (a warning naming the record and the term) and in CI. It replaces the separate structured-data and DCAT checkers in #100 and #102.
- **`Dataset` and DCAT agree by construction**: both tables read the same `asset` record.

**Parameters select tables; they do not change.** `govuk.metadata=basic` enables `links`, `opengraph` and `dublincore`; `full` adds `schemaorg`; `govuk.dcat=yes` adds `dcat` and `adms`, and writes the catalogue files (D-24.6 stands). The switch for the SKOS files is settled in #103.

**A publisher's own table** is a later step, not part of the first delivery: for a departmental profile, say, or the Cross-Government Metadata Exchange Model. The format is designed for it, with a parameter naming the file, as `args.css` names a stylesheet.

## 8. What stays specific

Structure cannot be reduced to a property table, so there is a harvester per DITA structure, shared by every scheme:

| Harvester | Reads | Serves |
|---|---|---|
| Hierarchy | the map's nesting and reading order | `BreadcrumbList`, `isPartOf`, `prev`/`next`, `skos:broader` |
| Steps | `task` steps (`cmd`, `info`) | `HowTo` |
| Terms | `glossentry`, `glossgroup`, `subjectScheme` | `DefinedTermSet`, SKOS |
| Files | resource-only references with a data `format` | `dcat:Distribution`, `Dataset.distribution` |
| Assets | branches declaring `rdf:type` | DCAT, ADMS, `Dataset` |

The writers hold the syntax rules once each: JSON string escaping and nesting; Turtle prefixes and literals; which `meta` attribute a scheme uses (`property` for Open Graph, `name` for Dublin Core).

## 9. What a generator should write

The full guide for the developer of a source system, with a worked example that CI builds, is [docs/SOURCE-SYSTEMS.md](../docs/SOURCE-SYSTEMS.md). In brief:

A corpus produced by a tool gains most from the tool writing standard elements. For a data dictionary, per topic:

- `prolog/metadata/category`: the kind of thing (Class, Attribute, Data Element, Data Set). It already drives search filters (D-18) and now also `dct:subject`.
- `<data name="adms:status" value="retired"/>`, or `importance="obsolete"`, for retired items. A token on the title's `outputclass` is styling, not metadata.
- `resourceid` for an identifier that is stable across releases.
- `keywords` only for real synonyms and alternative names; never the title's own words.
- `critdates` only where the dates are true.

And in the maps:

- on the root map: the organisation, the rights and licence, the version;
- on each branch that is an asset (a data set specification, a model, a code list): `rdf:type` and its properties, as in Section 6.

## 10. Effect on the issues

| Issue | Was | Becomes |
|---|---|---|
| #99 `basic` | Open Graph, Dublin Core and link tags, coded | The harvest (publication, page, agent; hierarchy), the `meta`/`link` writer, the checker, and the tables `links`, `opengraph`, `dublincore`. S becomes M. |
| #100 `full` | four JSON-LD builders, own checker | The JSON-LD writer and the `schemaorg` table for the cover, pages and breadcrumbs. M becomes S–M. |
| #101 topic types | two more builders | The steps and terms harvesters; rows in `schemaorg`. S. |
| #102 DCAT | a stylesheet writing two files, own checker | The assets and files harvesters, the Turtle writer, the `dcat` table. No longer blocked. S–M. |
| #103 SKOS | a stylesheet writing two files per scheme | The `skos` table over the terms harvester; `subjectScheme` reading. S. |
| #122 `Dataset` | a builder, and a CI assertion that it agrees with DCAT | Rows in `schemaorg` over the `asset` record. XS. No longer blocked. |
| #123 ADMS | typing coded | The `adms` table. XS–S. No longer blocked. |
| #104 docs | per scheme | Also documents `data`, declaring an asset, and Section 9's guidance. |

Order: #99, #100, #101, then #102 with #122, then #103 with #123.

## 11. Risks

- **A table language that grows into a programming language.** Kept to kinds, properties, relations, four formats and one `when` test on a property's value. Anything more is a harvester, in code, with a test.
- **Generic output that is valid but meaningless.** The `required` rows and the fixtures hold each scheme to what its consumers need (12 §4); the manual states what comes from where.
- **Publisher-supplied `data` reaching the page head.** Values are escaped by the writer for its syntax, URI-typed values must parse as absolute URIs, and nothing is fetched. The content policy (#77) is unchanged.
- **Up-front cost.** #99 is larger than it was. The whole epic is smaller, and scheme eight costs a table.

## 12. As built: the foundation (#99)

What building `basic` settled, where the sections above left it open or a real build showed otherwise:

- **Misspelt, not merely unused.** `resource/metadata/vocabularies.xml` declares each prefix, its namespace and, for a closed vocabulary (`dct`, `dcat`, `adms`, `skos`, `rdf`), every term. A `data` name outside them is the warning (`GOVK011W`, once per name per build). A correct term that no enabled table maps, such as `rdf:type` before #102, is left out quietly. Warning on those would have made the worked example in `fixtures/source-system` warn for writing exactly what the guide asks for. The namespaces serve the Turtle writer and JSON-LD contexts later.
- **A page's own facts first.** A page record takes its properties from the entries above it in the map (nearest first), then from its prolog. It takes the remaining properties from the publication record, except those that describe one thing only: title, description, alternative title, identifier, type, subject, dates, version, landing page and status. The publication record reads parameters, then bookmeta, then the root map's topicmeta.
- **A topic's own dates only.** DITA-OT replaces a topic's `critdates` with bookmeta's. The harvest uses `critdates` only when they came from the topic's own file (their `xtrf`), so a page never claims the book's dates. Recovering the topic's own dates, for the dates line and the sitemap too, is #189.
- **The table language** has three row types: `property` (a term, or `@id` for the record's address, or `@type` for the kind's type), `relation` (to a related record's address, or with `term` to one of its properties) and `value` (a constant). A row can say `format` (`uri`, `date`, `locale`, `text`), `required`, `repeat` (else the first value only), and for `meta`, the `attribute` (`property` for Open Graph, `name` otherwise). A kind's `when` tests `@role` (`cover`, `topic`, `utility`) or a property. `schemes.xml` lists the tables in output order, with the levels that enable each.
- **Relations** built now: `isPartOf` (the publication, then the entries above, outermost first), `section` (the top-level entry, for `article:section`), `previous` and `next`.
- **Two additions to the tables of #99:** `DC.creator`, which makes `govuk.metadata.persons` visible, and `rel="license"`.
- **`govuk.metadata` takes `basic` or `no`** until `full` has a table (#100); a level that enables nothing is refused rather than accepted silently.
- **The checks.** The cover's transform harvests every page once, and groups any warning by name or by table row, so a 10,000-page publication gets one warning per problem, not one per page. `tools/check_metadata.py` reads the same tables to check a built site, so it names no scheme either. CI proves the point by adding a row to an installed table and finding the tag.

# Writing DITA from a source system

A guide for the developer of a system that **generates** DITA for this plugin: a data dictionary tool, a modelling tool, a content database, a conversion script. It says how to shape the maps and topics, and what metadata to write, so that the website, the search, the print version, the PDF and the machine-readable metadata all come out right without anyone editing the output by hand.

Everything here is standard DITA 1.3. There is no specialisation and no DTD to install.

**A complete worked example** is in [`fixtures/source-system/`](../fixtures/source-system/). CI builds it on every change, so it is known to be valid and to build without warnings. Copy from it.

Each rule is marked:

- **Now**: the plugin acts on it today (v1.2.0, or the next release where it says so).
- **Planned**: designed and decided ([design 14](../design/14-metadata-model.md), D-26), not yet built. Write it now: it is valid DITA, it is ignored until then, and nothing will need regenerating.

## 1. The ten things that matter most

1. One root map. Include submaps with `<mapref href="…">`, never by key.
2. Put every topic a reader should find in the **navigation**: the map's hierarchy, not only a list of keys.
3. Give every topic a `title`, a one-sentence `shortdesc` and `xml:lang`.
4. Keep file names and topic ids **stable between releases**. They become the URLs.
5. Use the topic type that fits: `task` for steps, `glossentry` for a definition, `reference` or `concept` otherwise.
6. Say what kind of thing a topic is with `category`, not with a styling class.
7. Give every image alternative text.
8. Write `keywords` only for real alternative names. Never the title's own words.
9. Put publication details in the root map's `bookmeta`: organisation, dates, edition, rights.
10. Write dates only where they are true.

## 2. Files and identifiers

| Rule | Why |
|---|---|
| UTF-8, with an XML declaration and a standard DITA 1.3 `DOCTYPE` | The toolkit validates every file. |
| One topic per file, in folders that mean something (`elements/`, `classes/`) | The path is the page's URL: `elements/person-birth-date.dita` becomes `elements/person-birth-date.html`. |
| File names in lower case, with hyphens, no spaces | They are URLs. |
| **File names and topic `id`s do not change between releases** | Other sites, catalogues and bookmarks point at them. Do not put a status in a name: `…_retired` changes the URL on the day the item is retired. |
| A topic's `id` unique across the publication where you can | Ids need only be unique within a file, and the plugin copes with repeats, but unique ids give simpler links in print. |
| `xml:lang` on every map and topic | Sets the page language for browsers, screen readers and the PDF. |
| Images and data files inside the publication's folder | Files outside it are not inlined, and are reported. |

## 3. Maps

### One root map, submaps by `href`

```xml
<map id="dictionary" xml:lang="en-GB">
  <title>Example data dictionary</title>
  <mapref href="maps/elements.ditamap"/>
  <mapref href="maps/classes.ditamap"/>
</map>
```

**Never include a submap by key** (`<mapref keyref="elements"/>`), and do not define keys that name maps. DITA-OT 4.4 does not resolve keys inside a submap included that way: its sections appear in the navigation as plain text with nothing beneath them. The plugin warns (`GOVK001W`), but the fix belongs in the source. (**Now**)

### The navigation is the publication

The map's hierarchy is what a reader sees: the sidebar, the home page, the contents list, and the order of the print version and the PDF.

- **Nest entries beneath the page that lists them.** A reference work usually has index pages (an A to Z, a list by type) and thousands of entries. Put each entry in the map as a child of its index page:

  ```xml
  <topicref href="elements/index.dita" keys="elements">
    <topicref href="elements/person-birth-date.dita" keys="person-birth-date"/>
    <topicref href="elements/person-death-date.dita" keys="person-death-date"/>
  </topicref>
  ```

- **If entries cannot be in the navigation** (they would swamp the sidebar), they may be key definitions in a resource-only map, reached by links. They still get a page each. The publisher then builds with `govuk.print.scope=linked` so that the print version and PDF include them. Each entry is printed beneath the first page that links to it, so make sure an index page links to every entry. (**Now**)
- `toc="no"` keeps a topic out of the navigation; `processing-role="resource-only"` keeps it out of the reading order.
- Give a title-only grouping a `navtitle`:
  `<topichead navtitle="Guidance">…</topichead>`.

### Keys

Define each topic's key **on its own topicref in the navigation** (`keys="person-birth-date"`), and link with `keyref`. A separate map of key definitions is fine for topics that are not in the navigation, images and external links.

### Merged pages (`chunk`)

Avoid `chunk="to-content"` unless a merged page is really wanted. Where it is used, every toolkit that builds the publication needs `compatibility.chunk.v2-for-v1=false` in its `config/configuration.properties` (it cannot be passed on the command line), and chunked submaps must be included by `href`. (**Now**)

### Map or bookmap

Use a **bookmap** when the publication is a document: it has a cover, an edition, rights, and perhaps parts, appendices, a glossary and an index. Use a plain **map** for a simple site.

| Bookmap element | Use |
|---|---|
| `booktitle/mainbooktitle`, `booktitlealt` | Title and one-sentence summary: the home page, the cover, every page's site name |
| `chapter`, `part`, `appendix` | Top-level structure. Each starts a new page in print. |
| `frontmatter`, `backmatter` | Notices, preface; the glossary and index lists |
| `glossarylist` with the glossary entries; `indexlist` | Generates the glossary and index pages |

A bookmap does not allow `keydef` or `mapref` at its top level. Put keys on the chapters and their children, and a resource-only map inside `frontmatter` or `backmatter`.

### Several books from one source

- A **map that references several bookmaps** gives one website, and a print version and PDF per bookmap as well as for the whole. Give each bookmap an `id`: it names the files (`print-<id>.html`).
- A **bookmap with parts** can give a book per part (`govuk.print.books=parts`). Give each `part` an `id` and a title.

Links between books work, because it is one site. (**Now**)

## 4. Topics

| Element | Rule | Used for |
|---|---|---|
| `title` | Plain words; no status or type suffix that is not part of the name | Page heading, navigation, search result, metadata title |
| `shortdesc` | **One sentence saying what this is.** Always write it. | Page summary, home page, search (weighted four times body text), link previews, metadata description |
| `titlealts/searchtitle` | Optional: a fuller title for search results | Search result title (**Now**) |
| Topic type | `task` with `steps` for a procedure; `glossentry` for a term and its definition; `reference` for an entry with properties; `concept` for explanation | Rendering today; typed metadata (`HowTo`, defined terms) (**Planned**) |
| `image` | Always with `<alt>`. An SVG also carries a `<title>`. | Accessibility. A PDF with an undescribed image fails PDF/UA (`DSPDF009W`). (**Now**) |
| `table` | A `thead` row for column headings; a `title` | Accessible tables; repeated headings across pages in the PDF |
| `xref`, `link` | By `keyref`, or a relative `href` to the `.dita` file | Links that resolve on the site and become page references in the PDF |
| `indexterm` | In `prolog/metadata/keywords` or in the text | The generated index |
| `fn` | Footnotes | End of the topic on the site; foot of the page in the PDF |

**Classes carry styling, not meaning.** Do not record a topic's type or status in `outputclass`. The classes the plugin does act on:

| `outputclass` | On | Effect |
|---|---|---|
| `search-ignore` | any element | Shown on the page, left out of search. Use it for "where used" lists. |
| `search-demote` | a topic or its title | Ranks below live items in search |
| `landscape` | a table or figure | Its own landscape page in the PDF |

**Right-to-left text** (Arabic, Hebrew) is correct on the website and in a browser's print, and is not yet rendered correctly in the PDF. Mark such publications so the publisher can build with `govuk.pdf=no`.

## 5. Metadata in a topic

Metadata goes in the topic's `prolog`. The order of the elements is fixed by the DTD; follow the example.

```xml
<reference id="person-birth-date" xml:lang="en-GB">
  <title>Person birth date</title>
  <shortdesc>The date on which a person was born or is officially deemed to have been born.</shortdesc>
  <prolog>
    <critdates>
      <created date="2024-04-01"/>
      <revised modified="2026-06-12"/>
    </critdates>
    <metadata>
      <audience type="user" job="using"/>
      <category>Data element</category>
      <keywords>
        <keyword>date of birth</keyword>
        <keyword>DOB</keyword>
      </keywords>
    </metadata>
    <resourceid appname="dictionary" appid="DE-000123"/>
    <data name="dct:conformsTo" value="https://www.iso.org/standard/70907.html"/>
  </prolog>
  …
</reference>
```

| Element | Write | Now | Planned |
|---|---|---|---|
| `category` | The kind of thing: *Data element*, *Class*, *Attribute*, *Data set*, *Guidance*. One controlled list per publication. | A search filter; a tag in the page's metadata (next release) | The page's subject in the catalogue schemes |
| `keywords/keyword` | Real alternative names, abbreviations and former names. **Never the title split into words**: that adds nothing to search and pollutes the tags. | Searchable aliases; tags in the page's metadata, where a keyword that only repeats a word of the title is dropped (next release) | Subjects in the catalogue schemes |
| `audience` | Who it is for, if the publication distinguishes | A search filter | Audience |
| `critdates` | `created` and `revised`, **only if true**. A batch-stamped date on every topic is worse than none. See the caution below on dates in `bookmeta`. | The dates line, when the publisher sets `govuk.dates`; published and modified dates in the page's metadata, on the same switch (next release) | — |
| `resourceid` | The identifier the source system uses, stable across releases | — | The page's identifier in catalogue records |
| `importance="obsolete"` (on the topic) | Retired or superseded items | Demoted in search | Status |
| `<data name="adms:status" value="retired"/>` | The same fact for catalogues | — | `adms:status` |
| `author` | An organisation. A person's name is published only if the publisher opts in. | Footer credits (from the map); the creator in the page's metadata, when the publisher sets `govuk.metadata.persons=yes` (next release) | — |
| `<data name="prefix:term" value="…"/>` | Any other property (Section 7) | Read; written where a table maps the term (next release) | More schemes that know the term |

## 6. Metadata in the root map

Publication-wide facts go in `bookmeta` (or the `topicmeta` of a plain map). Topics inherit them.

```xml
<bookmeta>
  <publisherinformation>
    <organization>Example Standards Body</organization>
  </publisherinformation>
  <critdates>
    <created date="2026-01-15"/>
    <revised modified="2026-09-30"/>
  </critdates>
  <bookid>
    <edition>Release 4.2</edition>
  </bookid>
  <bookrights>
    <copyrfirst><year>2026</year></copyrfirst>
    <bookowner><organization>Example Standards Body</organization></bookowner>
  </bookrights>
  <data name="dct:accrualPeriodicity" value="http://publications.europa.eu/resource/authority/frequency/QUARTERLY"/>
</bookmeta>
```

| Element | Now | Planned |
|---|---|---|
| `organization` (publisher, owner), `author` | Footer credits; the home page; the print cover; the publisher in every page's metadata (next release) | — |
| `critdates` | "Published" and "Last updated" on the print cover | Issued and modified |
| `bookid/edition`, `isbn`, `booknumber` | Edition and reference on the print cover | Version, identifier |
| `bookrights` (`copyrfirst`, `bookowner`, `summary`) | Copyright line; the rights statement in the imprint; rights in every page's metadata (next release) | — |
| `data` | Read, and taken by every page that does not state the property itself (next release) | Catalogue properties (Section 7) |

The licence, the site's address and the organisation's URL are the **publisher's** build parameters, not the source system's. Do not hard-code them in the DITA.

**Caution: dates in `bookmeta` replace the topics' own.** DITA-OT copies `bookmeta`'s `critdates` into every topic, over the topic's own. The page metadata then gives those pages no dates rather than the book's, but the dates line shows the book's dates on every page (#189). Until that is fixed, a source system with true dates per topic should choose one: per-topic dates (leave `critdates` out of `bookmeta`), or publication dates on the print cover.

## 7. Any other property: `data` (**Now**, from the next release; the catalogue schemes that read most terms are **Planned**)

`<data name="…" value="…"/>` is DITA's own extension point. It is allowed in `bookmeta`, in the `topicmeta` of a map or topicref, and in a topic's `prolog`. Write the name as a **prefixed term** from a standard vocabulary:

| Prefix | Vocabulary | Typical terms |
|---|---|---|
| `dct:` | Dublin Core terms | `dct:identifier`, `dct:conformsTo`, `dct:spatial`, `dct:temporal`, `dct:accrualPeriodicity`, `dct:references`, `dct:type` |
| `dcat:` | Data Catalog Vocabulary | `dcat:theme`, `dcat:keyword`, `dcat:endpointURL` |
| `adms:` | Asset Description Metadata Schema | `adms:status`, `adms:versionNotes` |
| `skos:` | Simple Knowledge Organization System | `skos:notation`, `skos:exactMatch` |
| `rdf:` | | `rdf:type` (Section 8) |

- Where the value is a thing with a URI (a place, a frequency, a standard, a licence), write the **URI**, not a label.
- One `data` element per value. Repeat the element for several values.
- A name that is not a term of these vocabularies is reported as a warning (`GOVK011W`) and left out, so a misspelling is not silent. A correct term that no enabled table writes yet is kept quietly for the schemes to come.
- Values are published. Do not write anything internal, and do not name people.

## 8. Declaring a data asset (**Planned**)

A publication often holds several catalogue-worthy things: a logical model, each data set specification, a code list, an API. The **branch of the map** that documents one declares it, in the `topicmeta` of the submap or of the topicref that heads the branch:

```xml
<chapter href="elements/index.dita" keys="elements">
  <topicmeta>
    <data name="rdf:type" value="dct:Standard"/>
    <data name="dct:identifier" value="https://example.org/dictionary/elements"/>
  </topicmeta>
  …
</chapter>
```

| The branch documents | `rdf:type` |
|---|---|
| A data standard, a logical model, a data set **specification** | `dct:Standard` |
| A code list, a taxonomy, a vocabulary | `skos:ConceptScheme` |
| An API or feed | `dcat:DataService` |
| Actual data, with the files in the publication | `dcat:Dataset` |

- **Be honest about the type.** Documentation of data is a standard, not a dataset. Declare `dcat:Dataset` only where the publication ships or links the data itself.
- The branch's title and description come from its first topic. Other properties it does not state are inherited from the root map.
- The files that are the asset's distributions (a schema, a CSV, an OpenAPI file) are referenced from the branch as resource-only, with their `format`:
  `<keydef keys="schema" href="schemas/return.schema.json" format="json" processing-role="resource-only"/>`.
- Declare nothing where nothing applies. The type is a statement the publisher stands behind, and it is never inferred.

## 9. Terms and code lists

- **A term with a definition** is a `glossentry`: `glossterm`, `glossdef`, and `glossAlt` with `glossAcronym` or `glossAbbreviation` for short forms. Reference the entries from the map (in a bookmap, inside `glossarylist`). The glossary page is generated; a `<term keyref="…"/>` in the text links to the definition. (**Now**)
- **A code list or taxonomy** is a `subjectScheme` map: a `subjectdef` per value, nested for a hierarchy, with a `navtitle` for the label. (**Planned**: published as a SKOS vocabulary.)
- Group the entries of one scheme together (one `glossgroup`, one `subjectScheme` map), so each scheme can be published as one vocabulary.

### A concept system

A concept system (a model of concepts with definitions, a hierarchy and named associations, such as ISO 13940) needs more than a glossary can hold: each concept has its own page, with its associations, a diagram and links. Write it as follows.

| What | Write | Mark |
|---|---|---|
| The scheme | A bookmap for it, whose `bookmeta` says `<data name="rdf:type" value="skos:ConceptScheme"/>` and gives the scheme's IRI as `<data name="dct:identifier" value="https://…/"/>`. Make that IRI resolve: it can be the site's home page. | **Planned** (#103) |
| A concept | A `concept` topic, one per file, named after the concept (`concept/care_plan.dita`), with `<data name="rdf:type" value="skos:Concept"/>` in its prolog. A `glossentry` cannot hold the association table or the diagram. | Page **Now**; term **Planned** (#103) |
| Its IRI | `<data name="dct:identifier" value="https://example.org/concept/care_plan"/>` when the concept already has an IRI. It is then the concept's identifier in SKOS and JSON-LD, and the page is its web page. | **Planned** (#103) |
| Preferred label | The topic's `title`. | **Now** |
| Definition | The `shortdesc`. Links to other concepts inside it are fine. | **Now** |
| Alternative labels | `keyword` elements: synonyms, former names and plural forms, if readers search for them. Never a placeholder such as "N/A". | **Now** (search, tags); SKOS **Planned** |
| Broader concept | `<data name="skos:broader" value="IRI"/>`. The navigation is for reading, and it rarely is the hierarchy: a concept may be placed under an overview page, or under a concept it is not a kind of. State the hierarchy; do not rely on nesting. | **Planned** (#103) |
| Associations | A table for readers, with the multiplicities. Named relations for machines wait for the publisher's own vocabulary (#191); until then, the related concepts are `related-links`. | Table **Now**; named relations **Planned** |
| Alignment to an upper ontology | `<data name="skos:broadMatch" value="IRI"/>`, or `skos:exactMatch` where it is the same concept. | **Planned** (#103) |
| The ontology itself | Its own file (Turtle, RDF/XML, OWL), published beside the pages and referenced from the map as a resource-only `topicref` with its `format`. Multiplicities and OWL restrictions belong there, not in page metadata. | **Planned** (#102) |
| Tool-internal properties | Leave them out of the DITA (an "is abstract" flag, export-plugin namespaces). | — |

## 10. Size

The plugin has been run on a publication of 10,000 topics, with a PDF of 11,700 pages. For a publication that large, tell the publisher to:

- raise `govuk.print.max-topics` (default 500), or the print version and PDF are skipped with a warning;
- give the PDF generator memory (`DESIGNSYSTEMPDF_OPTS=-Xmx16g` for ten thousand topics), and use DesignSystemPDF 0.1.1 or later.

On the source system's side: keep the navigation's top level short (tens of entries, not thousands), and nest.

## 11. Checklist for a release of the source system

- [ ] The root map builds with the plugin with **no warnings**. A `GOVK` or `DOTX` warning names the file and line.
- [ ] No `mapref keyref`; no keys that name maps.
- [ ] Every topic has a `title`, a `shortdesc`, `xml:lang`, and a `category`.
- [ ] File names and ids are unchanged from the last release, apart from real additions and removals.
- [ ] Every image has `alt`. The PDF passes PDF/UA: the build shows no `DSPDF009W`.
- [ ] No keyword repeats a word of its topic's title.
- [ ] Dates are true or absent.
- [ ] Retired items carry `importance="obsolete"` and `adms:status`, and keep their file names.
- [ ] The root map's `bookmeta` has the organisation, the dates, the edition and the rights.
- [ ] Each branch that is a data asset declares `rdf:type` and an identifier.
- [ ] Nothing internal and no person's name is in any metadata.

## 12. Where this comes from

| Topic | Source |
|---|---|
| Keys in submaps, chunking, large publications | The manual's *Troubleshooting* topic; a 10,000-topic trial (October 2026) |
| Search conventions | The manual's *Site search* topic (D-18) |
| The print cover and the imprint | The manual's *Printing and PDF* topic (#150) |
| Topics outside the navigation; several books | #176, #178 |
| The metadata model, `data`, declaring assets | [Design 14](../design/14-metadata-model.md) (D-26); [design 12](../design/12-structured-data.md) for the schemes and their consumers |

When a **Planned** item is built, its mark here changes to **Now** in the same pull request.

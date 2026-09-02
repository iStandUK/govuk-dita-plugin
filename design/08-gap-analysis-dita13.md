# 08 — Gap analysis: DITA 1.3 specification coverage

**Date:** 2026-09-03 · **Purpose:** define what a **comprehensive 1.0 release for the DITA
community** requires, beyond the iStandUK use cases that shaped v0.1–v0.2.

## Method

1. **Grammar inventory** — the DITA 1.3 DTD modules shipped in DITA-OT 4.4.1
   (`org.oasis-open.dita.v1_3`) declare **612 elements**. The core scope for this analysis —
   base + technical content + bookmap + subjectScheme — is **~430 elements**; the Learning
   & Training package (~180 elements) is a separately-packaged edition assessed only for
   scope (below).
2. **Architecture floor** — the plugin imports the full `html5` rendering chain at lower
   precedence, so **every element it does not override keeps a working default rendering**.
   The gap question is therefore rarely "does it render?" and usually "does it render to
   GOV.UK standard, validly, and with the processing the spec promises?"
3. **Empirical verification** — a spec-coverage fixture,
   [fixtures/dita13-kitchen](../fixtures/dita13-kitchen/), exercises the areas v0.2 never
   touched: full task and troubleshooting markup, definition/parameter lists, the hazard,
   utilities, math, programming, software, UI, markup and XML domains, image maps, syntax
   diagrams, conref (direct, key-based, and range), composite chunking, key scopes,
   reltables, sequence collections, and DITAVAL flagging/filtering/revisions. It was built
   twice (plain, and with `flags.ditaval`), Nu-validated, and inspected checkpoint by
   checkpoint. Every ✅/⚠️ below marked *(verified)* is an observation, not a reading of
   the code.

Legend: ✅ styled and/or verified working · ◐ inherited rendering, acceptable under GOV.UK
typography · ⚠️ **1.0 gap** (styling or correctness) · ⬜ untested, needs investigation ·
✖ out of scope for 1.0.

## Scope decisions for 1.0

| Package / feature | Decision |
|---|---|
| Learning & Training edition (~180 elements) | ✖ Out of scope: separately-packaged edition with no GOV.UK presentation conventions; base rendering still functions for anyone who tries |
| Machinery task (taskreq domain) | ◐ In scope as inherited rendering; no dedicated styling planned |
| xNAL bookmeta (author details) | ◐ Metadata-only; not rendered beyond what bookmeta already contributes |
| subjectScheme / classification | ⬜ Processing-side (controlled values, classification filtering) is toolkit territory; verify it passes through, no rendering needed |
| Cross-deliverable linking (1.3 keyscopes across deliverables) | ✖ Limited support upstream in DITA-OT; document as not supported |

## Dispositions

### Topic types

| Feature | Status |
|---|---|
| `topic`, `concept` | ✅ |
| `reference` — `properties` table | ✅ `govuk-table`, valid HTML (legacy attributes dropped, #27) |
| `reference` — `refsyn`, `refbodydiv` | ◐ *(verified render)* |
| `task` — `steps`/`substeps`/`choices`/`stepxmp`/`stepresult` | ◐ steps get GOV.UK numbered lists; inner structure unstyled *(verified)* |
| `task` — section labels (Prerequisites, Procedure, Results…) | ⚠️ none rendered *(verified)*; the toolkit generates them behind `args.gen.task.lbl=YES` — adopt as default and route through our string files (FR-R6) |
| `task` — `choicetable` | ✅ modern `govuk-table` markup, valid HTML *(#27)* |
| `task` — `steptroubleshooting`, `tasktroubleshooting` | ◐ content renders *(verified)*, unlabeled — cover with task labels work |
| `troubleshooting` topic (1.3) | ⚠️ builds and renders *(verified)* but `condition`/`cause`/`remedy` appear as unlabeled prose; deserves a deliberate GOV.UK treatment (a natural fit: bold labels or inset structure) |
| `glossentry`, glossary page, `abbreviated-form`, `term` | ✅ (v0.2) |
| `glossgroup` | ◐ same class family as glossentry; verify when touched |

### Blocks

| Feature | Status |
|---|---|
| `p`, `ul`, `ol`, `sl`, `section`, `title` hierarchy | ✅ |
| `note` (all types incl. fastpath/restriction/trouble) | ✅ *(verified)* |
| **`hazardstatement`** | ✅ dedicated safety panel (banner label + framed hazard/consequence/avoidance); valid HTML *(#27)* |
| `dl` (+ `dlhead`) | ⚠️ unstyled browser defaults *(verified)*; map to GOV.UK-styled definition list |
| `parml` | ⚠️ renders as `dl` *(verified)* — covered by the `dl` work |
| `lq` | ⚠️ unstyled blockquote *(verified)*; style (inset-text-like treatment) |
| `pre`, `lines`, `msgblock`, `screen` | ✅ *(verified: all carry the `pre` class token our styling targets)* |
| `codeblock`, `codeph` | ✅ |
| `example` | ◐ *(verified render; title styled as section title)* |
| `div` (1.3) | ✅ transparent *(verified)* |
| `fig` + `desc`, captions | ✅ (v0.2) |
| `fn` (numbered and `@callout`) | ✅ *(verified: markers + endnotes)*; endnote styling ◐ |
| `draft-comment`, `required-cleanup` | ✅ suppressed by default *(verified)* |

### Inline and domains

| Feature | Status |
|---|---|
| hi-d: `b i u sup sub tt line-through overline` | ◐→✅ all render *(verified)* |
| sw-d: `msgph msgnum cmdname filepath userinput systemoutput varname` | ◐ *(verified)* |
| ui-d: `uicontrol`, `menucascade`, `wintitle`, `shortcut`, `screen` | ⚠️ render but unstyled *(verified)* — the designed bold-uicontrol/menucascade treatment (C-06) was never applied |
| pr-d inline: `option parmname apiname synph` | ◐ *(verified)* |
| markup-d + xml-d: `xmlelement xmlatt textentity numcharref …` | ⚠️ render as plain spans *(verified)*; should join the monospace family |
| `keyword term ph text cite q state data tm` | ◐ *(verified)* |
| `syntaxdiagram` | ✅ *(verified: the toolkit renders it as inline SVG)* |
| `coderef` | ⬜ untested |

### Tables, media, math

| Feature | Status |
|---|---|
| CALS tables incl. spans, header scoping | ✅ (v0.1) |
| `simpletable`, `properties` | ✅ *(verified)* |
| `image` inline and `placement="break"`, `alt` | ✅/◐ *(verified)* |
| svg-d (`svg-container`/`svgref`) | ✅ local `svgref` inlined as native SVG so links inside diagrams work; `govuk.svg.inline=no` keeps the img rendering *(#37)*; inline `svg-container` already native |
| ut-d `imagemap`/`area` | ✅ works *(verified: map/area/usemap emitted with alt and titles)*; styling ◐ |
| `object` (media embed) | ⬜ untested |
| **equation-d + mathml-d (1.3)** | ✅ MathML passed through natively (equation-inline/-block render the `m:math` markup, browsers render it) *(#28)* |

### Map features and processing

| Feature | Status |
|---|---|
| Keys, `keyref`, `keydef`, resource-only maprefs | ✅ (ORUK-verified at scale) |
| **Key scopes (1.3)** | ✅ scoped resolution works *(verified in a control build)* — but ⚠️ the canonical **keyscope + `copy-to`** reuse pattern left keyrefs unresolved *(verified)*; investigate (likely upstream) |
| `conref`, `conkeyref`, `conref`+`conrefend` range | ✅ *(all three verified)* |
| conref push (`@conaction`) | ⬜ untested |
| `chunk="to-content"` | ✅ (v0.1; upstream xref limitation documented in 07) |
| `chunk="by-topic"` on composite documents | ✅ split into per-topic pages; the split children's `$PATH2PROJ` comes out empty upstream (breaks asset links in plain html5 too) — the plugin derives asset paths from `get-path2map-dir` instead, so CSS/JS/home links resolve correctly *(fixed)* |
| `copy-to` | ✅ *(verified: copies produced)* — see keyscope caveat |
| `topichead`/`topicgroup` | ✅ sidebar group labels; also drive the grouped landing layout so their children are linked from the home page *(auto-layout fix)* |
| Reltables → related links | ✅ *(verified: "Related information" section with styled links)* |
| `collection-type="sequence"` | ⚠️ no previous/next links generated *(verified)*; fold into FR-N5 pagination so sequences and reading order both produce the GOV.UK pagination component |
| DITAVAL filtering | ✅ *(verified: exclude honoured)* |
| DITAVAL flagging (styles) | ✅ *(verified: flag style applied)*; start/end flag images ⬜ |
| DITAVAL revisions (`revprop`, changebars) | ⚠️ no revision styling appeared in the flagged build *(verified)*; investigate |
| Branch filtering (`ditavalref`, 1.3) | ⬜ untested (toolkit supports) |
| `@cascade`, `@print`, `@deliveryTarget` | ◐ |
| `anchor`/`navref` (runtime map integration) | ✖ niche; document as unsupported |

### Bookmap

| Feature | Status |
|---|---|
| `chapter`, `part` | ✅ (nav groups + layout grouping) |
| `appendix`/`appendices` | ◐ builds; ⚠️ not counted as a group by the `auto` layout heuristic — trivial fix alongside layouts |
| `frontmatter`/`backmatter` content (preface, notices, bookabstract, colophon…) | ⬜ untested |
| `booklists`: `toc` | ✅ |
| `booklists`: `indexlist` | ⚠️ should wire to the existing index page rather than being ignored |
| `booklists`: `figurelist`, `tablelist`, `abbrevlist` | ⚠️ not generated; candidates for the utility-page machinery |
| `bookmeta` (title, author, organization) | ✅ (home page) — deeper metadata ◐ |

### Internationalisation and accessibility

| Feature | Status |
|---|---|
| `@xml:lang` flow-through; UI strings localisable | ✅ (v0.2) |
| Right-to-left (`@dir`) | ⬜ untested; govuk-frontend ships an RTL stylesheet question — investigate before claiming |
| Table header associations, image alt, landmarks, single-h1 | ✅ (CI-enforced) |

## The 1.0 gap list

**P1 — correctness** (wrong or invalid output today):
1. ~~`hazardstatement` dedicated rendering~~ — **done (#27)**: safety panel, valid HTML
2. ~~`choicetable` modern markup~~ + `properties` table — **done (#27)**: `govuk-table`, valid HTML
3. ~~MathML/equation passthrough~~ — **done (#28)**: native MathML, browsers render it
4. DITAVAL revision flagging investigation (no changebars/styles applied)
5. Keyscope + `copy-to` resolution failure investigation (report upstream if confirmed)

**P2 — styling parity** (renders, but below GOV.UK standard):
6. `dl`/`dlhead`/`parml` styling
7. `lq` styling
8. Task experience: generated section labels (localised), step inner structure, troubleshooting-topic labels
9. ui-d styling (`uicontrol` bold, `menucascade` separators, `shortcut`)
10. markup-d/xml-d into the monospace family

**P3 — completeness** (spec features not yet surfaced):
11. Sequence/reading-order previous-next links = FR-N5 GOV.UK pagination
12. Bookmap booklists: `indexlist` → existing index page; `figurelist`/`tablelist` generators; appendix grouping in `auto` layout
13. Verification fixtures for the ⬜ set: conref push, `ditavalref` branch filtering, flag images, `object`, frontmatter/backmatter topics, RTL, `coderef`, `glossgroup`

The kitchen-sink fixture now passes **full Nu validation** in CI (the #27 correctness fixes
removed the last invalid-HTML blockers), with assertions for the hazard panel and
choicetable/properties markup.

## Conclusion

The extend-`html5` architecture means **functional coverage of the core DITA 1.3 scope is
already effectively complete** — of everything tested, only MathML fails to render at all —
and the reuse/addressing machinery (keys, scopes, conref in all forms, chunking, DITAVAL)
works as specified with two investigable exceptions. What separates v0.2 from a
community-credible 1.0 is a bounded list: **five correctness items, five styling-parity
items, and three completeness workstreams**, each verified here with a reproducible fixture.
Per decision D-15 this list targets **v0.9** (epic #26), together with official branding
(#20) and the verification NFRs (#35); the registry listing (#21) follows at 1.0 only after
0.9 has proven robust in live use.

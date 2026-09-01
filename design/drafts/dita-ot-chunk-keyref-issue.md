# Upstream report — dita-ot chunk cross-reference bug

**Outcome (2026-09-01):** an existing upstream issue already covered this —
[dita-ot/dita-ot#4465](https://github.com/dita-ot/dita-ot/issues/4465) (open since April
2024; regression 4.1.2 → 4.2.1). Rather than filing a duplicate, this material was posted as
a [confirming comment](https://github.com/dita-ot/dita-ot/issues/4465#issuecomment-5496533798)
adding the 4.4.1 confirmation, the inline minimal reproduction, the keyref route, real-world
impact, and the workaround. The draft below is retained for the record.

**Proposed title:** `Cross-references to a topic merged by chunk="to-content" become broken links to temp-file hash names`

---

## Description

When a topic is merged into its parent's page by `chunk="to-content"`, cross-references to
that topic from *outside* the chunk are not redirected to the merged location. This affects
both addressing routes — `<xref href="child.dita"/>` and `<xref keyref="..."/>` alike. The
output contains an anchor whose `@href` is the *temporary-file hash name* (which does not
exist in the output directory) and whose link text is that same hash filename.

## Expected

The reference resolves to the chunked location — `parent.html#child` — with link text pulled
from the target topic's title, as happens when the target is not chunked.

## Actual

```
Warning: test.ditamap:5:71: [DOTX023W]: Unable to retrieve navtitle from target: 'aabad55e76022829aeccc999e2e3e3e4e37d534e.dita'.
Warning: test.ditamap:5:71: [DOTX027W]: Unable to retrieve linktext from target: 'aabad55e76022829aeccc999e2e3e3e4e37d534e.dita'.
Error: other.dita:3:85: [DOTX031E]: The 'aabad55e76022829aeccc999e2e3e3e4e37d534e.dita' resource is not available to resolve link information.
```

and in `other.html` (both the keyref and the href reference render the same way):

```html
<a class="xref" href="aabad55e76022829aeccc999e2e3e3e4e37d534e.html">aabad55e76022829aeccc999e2e3e3e4e37d534e.html</a>
```

No file with that name exists in the output, so the reader gets a dead link labelled with a
hash. The build still exits 0.

## Steps to reproduce

Four files:

`test.ditamap`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map>
  <title>Chunk and cross-reference interaction</title>
  <keydef keys="child" href="child.dita" format="dita" scope="local"/>
  <topicref href="parent.dita" chunk="to-content">
    <topicref href="child.dita" toc="no"/>
  </topicref>
  <topicref href="other.dita"/>
</map>
```

`parent.dita`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE topic PUBLIC "-//OASIS//DTD DITA Topic//EN" "topic.dtd">
<topic id="parent"><title>Parent</title><body><p>Parent body.</p></body></topic>
```

`child.dita`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE topic PUBLIC "-//OASIS//DTD DITA Topic//EN" "topic.dtd">
<topic id="child"><title>Child</title><body><p>Child body.</p></body></topic>
```

`other.dita`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE topic PUBLIC "-//OASIS//DTD DITA Topic//EN" "topic.dtd">
<topic id="other"><title>Other</title><body><p>By key: <xref keyref="child"/>. By href: <xref href="child.dita"/>.</p></body></topic>
```

Build:

```
dita --input=test.ditamap --format=html5 --output=out
```

Both references break identically. Removing `chunk="to-content"` makes both resolve
correctly (`<a href="child.html">Child</a>`) — verified with the same file set.

## Environment

- DITA-OT 4.4.1 (also reproduced through a transtype extending `html5`; error sets are
  identical, so this is preprocessing, not rendering)
- Temurin/OpenJDK 21, macOS 15 (also observed on ubuntu-latest CI with Temurin 17)

## Real-world impact

A generated documentation set (Open Referral UK / HSDS) uses one key-definition map with 530
`keydef`s and addresses every cross-reference by key; one of its publications merges related
topics with `chunk="to-content"`. Building it produces 287 `DOTX031E` errors, which surface
as 287 dead hash-named links across 11 of its 73 pages.

---

## Notes for us (not part of the issue)

- The failure is **not** keyref-specific (direct `@href` references break identically) —
  broader than first characterised in issue #11.
- Reproduction lives in scratch space only; `fixtures/oruk-mini/chapter.dita` deliberately
  avoids the failing pattern so CI stays green. Flipping its xref to `Echild1` reproduces.
- Authoring workaround for the ORUK generator: define keys for chunked children as
  `parent.dita#child-id`, or emit a per-publication key map.
- Check for an existing upstream issue before filing (search: `chunk to-content xref
  DOTX031E`).

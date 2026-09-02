# Upstream issue — FILED as dita-ot/dita-ot#4788

(Originally drafted here before filing; retained for the record.)

Verified against DITA-OT 4.4.1 on 2026-09-02. Searched the tracker first
(`keyscope copy-to`, `copy-to keyref`, `key not resolved copy-to`) — no existing issue found.
File at <https://github.com/dita-ot/dita-ot/issues/new> when approved; everything between the
rules is the proposed issue body.

**Proposed title:** `keyref not resolved in a copy-to topic when the key is bound by the topicref's keyscope`

---

## Description

When a `topicref` carries **both** `keyscope` and `copy-to`, and defines a scope-local key
(via a child `keydef`), `keyref`s inside the copied topic are **not resolved** — the copied
topic in the temp directory still contains the unresolved `<ph keyref="…"/>`, and the output
renders an empty element.

Removing `copy-to` (keeping `keyscope`) resolves the key correctly, so the scope binding
itself works — the failure is specific to the combination with `copy-to`. This is the
canonical "one source topic, published once per scope with a scope-local product name / value"
reuse pattern.

## Steps to reproduce

`copyto.ditamap`

```xml
<?xml version="1.0"?>
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map>
  <title>keyscope with copy-to</title>
  <topicref href="a.dita" copy-to="a-alpha.dita" keyscope="alpha">
    <keydef keys="pn"><topicmeta><keywords><keyword>Alpha</keyword></keywords></topicmeta></keydef>
  </topicref>
</map>
```

`a.dita`

```xml
<?xml version="1.0"?>
<!DOCTYPE topic PUBLIC "-//OASIS//DTD DITA Topic//EN" "topic.dtd">
<topic id="a"><title>A</title><body><p>Product: <ph keyref="pn"/>.</p></body></topic>
```

```
dita --input=copyto.ditamap --format=html5 --output=out
```

## Expected

`a-alpha.html` contains `Product: Alpha.` (the `pn` key's keyword resolved into the `ph`).

## Actual

`a-alpha.html` contains `Product: <span class="ph"></span>.` — the keyref is unresolved. The
temp file `a-alpha.dita` still shows `<ph keyref="pn" .../>` with no resolved content.

Removing `copy-to="a-alpha.dita"` from the topicref (and keeping `keyscope="alpha"`) produces
the expected `Product: Alpha.`.

## Environment

- DITA-OT 4.4.1
- Temurin/OpenJDK 21, macOS 15
- Transformation type: HTML5 (reproduced through a plugin extending html5; the temp file shows
  the keyref unresolved, so it is preprocessing, not rendering)

## Real-world impact

Blocks the standard per-variant single-source pattern (publish one topic once per key scope,
each scope binding a different product name / edition), where each variant is produced with
`copy-to` and distinguished by a scope-local key.

---

## Notes for us (not part of the issue)

- The `fixtures/dita13-kitchen` map exercises this (`shared.dita` copied to
  `shared-alpha.dita`/`shared-beta.dita` under `keyscope="alpha"`/`"beta"`); the pages show an
  empty `ph` where the edition name should be. Documented in design/08.
- No plugin-side fix is possible (preprocessing owns key resolution).
- Authoring workaround: separate source topics per variant, or move the varying value off the
  scoped-key mechanism.

# keyref-nest fixture

Three topics and a submap that references everything by key. The submap is included
twice over from the root: `root-keyref.ditamap` uses `<mapref keyref="k-sub">` (the key is
defined in a resource-only links map), `root-href.ditamap` uses `<mapref href>`.

DITA-OT 4.4.1 resolves no key inside a submap that was itself included with
`<mapref keyref>`, so `root-keyref` yields a navigation entry with no link and no children,
and the plugin must warn (`GOVK001W`); `root-href` resolves everything and must not warn.
Both are built and asserted in CI (#51).

# Upstream issue — NOT YET FILED: keys inside a submap included with `<mapref keyref>` are never resolved

Verified against DITA-OT 4.4.1 on 2026-09-03 during the NHS Data Dictionary trial. Tracker
searched (`mapref keyref nested`, `keyref referenced map`): the nearest issues are
[dita-ot#4013](https://github.com/dita-ot/dita-ot/issues/4013) (keyscope on mapref and map)
and [#3815](https://github.com/dita-ot/dita-ot/issues/3815) (`@keys` on mapref), neither the
same. File at <https://github.com/dita-ot/dita-ot/issues/new> when approved; everything between
the rules is the proposed issue body. The reproduction is the plugin's `fixtures/keyref-nest`
(root-keyref.ditamap fails, root-href.ditamap succeeds).

---

## Summary

When a submap is included with `<mapref keyref="k"/>` (the key defined by a
`<keydef keys="k" href="…ditamap" format="ditamap"/>` in a resource-only links map), no key
*inside* that submap is resolved:

- a `<topicset keyref="…">` (or `<topicref keyref>`) container gets no `@href` and renders as
  plain text;
- a nested `<mapref keyref="…"/>` is not included at all;
- a `<topicref keyref="…"/>` child is dropped from the tree.

The identical submap included with `<mapref href="maps/sub.ditamap"/>` resolves completely.
No message is logged.

## Steps to reproduce

`maps/sub.ditamap`

```xml
<map id="sub"><title>Sub</title>
  <topicset id="grp" keyref="k-ov" navtitle="Group">
    <mapref keyref="k-sub2" toc="yes"/>
    <topicref keyref="k-t1"/>
  </topicset>
</map>
```

`maps/deep/sub2.ditamap`: `<map id="sub2"><title>Sub2</title><topicref href="../../c.dita"/></map>`

`links/keys.ditamap`

```xml
<map><title>Keys</title>
  <keydef keys="k-sub"  href="../maps/sub.ditamap" format="ditamap"/>
  <keydef keys="k-sub2" href="../maps/deep/sub2.ditamap" format="ditamap"/>
  <keydef keys="k-ov"   href="../ov.dita" processing-role="normal" toc="no"/>
  <keydef keys="k-t1"   href="../t1.dita" processing-role="normal" toc="no"/>
</map>
```

`root-keyref.ditamap`

```xml
<map><title>Root</title>
  <mapref keyref="k-sub" toc="yes"/>
  <mapref href="links/keys.ditamap" processing-role="resource-only"/>
</map>
```

`root-href.ditamap` is the same with `<mapref href="maps/sub.ditamap" toc="yes"/>`.
`ov.dita`, `t1.dita`, `c.dita` are trivial topics.

    dita -i root-keyref.ditamap -f html5 -o out-keyref
    dita -i root-href.ditamap   -f html5 -o out-href

## Actual behaviour (4.4.1, html5, no warnings)

`out-keyref/index.html` TOC:

    <li class="topicref topicset">Group <ul></ul> </li>

`out-href/index.html` TOC:

    <li class="topicref topicset"><a href="ov.html">Overview T</a>
      <ul><li class="topicref"><a href="c.html">Child C</a></li>
          <li class="topicref"><a href="t1.html">Topic One</a></li></ul></li>

## Expected behaviour

Both roots produce the second tree. Keys defined in the root map's key space should resolve
inside a submap regardless of whether that submap arrived by `href` or by `keyref`.

## Impact

On a 10,000-topic corpus whose root includes seven submaps by key, two top-level sections
(one containing a tree of nested keyref'd maprefs) rendered as dead headings with no children,
and — because the same pattern also includes each submap a second time through the keydef — the
chunk module failed on five index pages (separate report). Converting the 22 keyref'd maprefs
to `href` fixed both.

---

The plugin now warns (`GOVK001W`) for each navigation entry whose key never resolved, since
the toolkit is silent; the manual's Troubleshooting topic documents the `<mapref href>` remedy.

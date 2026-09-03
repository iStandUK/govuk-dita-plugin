# Upstream issue — NOT YET FILED: chunk="to-content" fails when a chunked submap is included twice

Verified against DITA-OT 4.4.1 on 2026-09-02 during the NHS Data Dictionary trial. Tracker
searched first (`chunk copy-to`, `Failed to move chunk`, `chunk to-content`): the nearest
existing issue is [dita-ot#4755](https://github.com/dita-ot/dita-ot/issues/4755) (chunk +
`copy-to` in compatibility mode; its fix PR #4756 was closed unmerged for a missing DCO
sign-off), which covers a *different* defect in the same module. File at
<https://github.com/dita-ot/dita-ot/issues/new> when approved; everything between the rules
is the proposed issue body. The three-topic reproduction lives inline below.

---

## Summary

A DITA 1.3 submap containing a `chunk="to-content"` topicref is referenced twice from the
root: once as a normal `<mapref>` (or `<mapref keyref>`), and once as the target of a
`<keydef … format="ditamap"/>` in a resource-only links map (the usual way to back keyref'd
maprefs). The DITA 2.0 chunk module, running in `compatibility.chunk.v2-for-v1` mode, collects
chunk operations from **both** copies, generates the same chunk twice to one temp file, and the
second move fails. The merged page is never produced.

## Steps to reproduce

    dita -i root-href.ditamap   -f html5 -o out1     # href mapref  + keydef  -> FAILS
    dita -i root-keyref.ditamap -f html5 -o out2     # keyref mapref + keydef -> FAILS
    dita -i root-single.ditamap -f html5 -o out3     # single inclusion       -> OK (control)

`maps/sub.ditamap`

```xml
<map id="sub"><title>Elements</title>
  <topicref href="overview.dita" chunk="to-content" navtitle="Elements">
    <topicref href="a.dita"/><topicref href="b.dita"/>
  </topicref>
</map>
```

`links.ditamap`

```xml
<map><title>Links</title><keydef keys="sub" href="maps/sub.ditamap" format="ditamap"/></map>
```

`root-href.ditamap` (root-keyref uses `<mapref keyref="sub" toc="yes"/>` instead; root-single
omits the links mapref)

```xml
<map><title>T</title>
  <mapref href="maps/sub.ditamap" toc="yes"/>
  <mapref href="links.ditamap" processing-role="resource-only"/>
</map>
```

`maps/overview.dita`, `maps/a.dita`, `maps/b.dita`: trivial topics (`<topic id="overview">`,
`el_a`, `el_b`) with a title and one paragraph.

## Actual behaviour (4.4.1, macOS, `dita` command, html5)

    Error: Failed to move chunk <hash>_tmp.dita to <hash>.dita
    Warning: maps/sub.ditamap:3:73: [DOTX061W]: The @href attribute value 'overview' contains a fragment identifier, but it does not reference a topic element.
    Warning: maps/sub.ditamap:3:73: [DOTX026W]: Unable to retrieve linktext from target ...
    (java.io.FileNotFoundException: Source '<hash>_tmp.dita' does not exist — StreamStore.move via ChunkModule.generateChunks)

`dita -v` shows the duplicate operations:

    Generate chunk <hash>.dita  to <hash>_tmp.dita
    Generate chunk <hash>1.dita to <hash>1_tmp.dita
    Generate chunk <hash>.dita  to <hash>_tmp.dita      <- same destination again
    Moving <hash>_tmp.dita to <hash>.dita
    Moving <hash>1_tmp.dita to <hash>1.dita
    Moving <hash>_tmp.dita to <hash>.dita              <- source already moved
    Error: Failed to move chunk ...

Result: `maps/overview.html` contains only the overview; `a` and `b` are not merged.

## Expected behaviour

One merged `overview.html` containing `a` and `b`, as `out3` produces and as DITA-OT 4.3.x
produces for the same input. With `compatibility.chunk.v2-for-v1=false` (legacy chunker) the
page merges correctly, although the resource-only duplicate still yields orphan
`Chunk<n>.html` files.

## Additional observation on a large corpus (not reduced)

On a 10,000-topic corpus with five chunked A–Z index submaps, after removing the double
inclusion and `copy-to` so the compatibility-mode module runs without errors, it still
silently failed to merge two of the five chunks: all five were generated as `<hash>1.dita`
(the suffix because each chunk root is also the target of a normal keydef) and moved without
error, yet only three of the five overview files ended up containing the merged topics. The
outcome is deterministic across runs and identical with `--parallel=false`. The legacy chunker
merges all five.

## Suggested fix

`org.dita.dost.chunk.ChunkModule.collectChunkOperations` should skip topicrefs whose effective
`processing-role` is `resource-only`, and/or `generateChunks` should de-duplicate operations by
destination before writing.

---

Impact recorded in the plugin manual's Troubleshooting topic; the remedy publishers use today
is `compatibility.chunk.v2-for-v1=false` plus `<mapref href>` for chunked submaps.

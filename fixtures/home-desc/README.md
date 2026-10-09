# home-desc fixture

Short descriptions that hold cross-references with no text of their own, as a generator
writes them when the text should come from the key (#200). DITA-OT fills such a reference
in with its target's title when it renders the topic, but the copy of the short description
that the map carries is taken before that happens, so the home page works the text out the
same way.

- `state.dita`: empty `<xref keyref>`s. One key's definition has `<linktext>`; DITA-OT still
  shows the target's title, and so must the home page.
- `matter.dita`: an empty `<xref href>` to a topic in a subfolder, an `<xref>` with its own
  text, a `<draft-comment>` (never shown) and an empty `<keyword keyref>`.
- `concepts/actor.dita`: in a subfolder, an empty `<xref keyref>` to a topic beside the map.
- `subject.dita`: an empty `<xref>` to another site, shown as its address.

The last three sit under a `<topichead>`, so their descriptions are the list hints.

CI builds it with the grid and grouped layouts and asserts that every description on the
home page reads the same as on that topic's own page.

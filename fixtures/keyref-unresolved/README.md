# keyref-unresolved

Key references in topic content, resolved and not (#244, GOVK015W).

`keys.ditamap` defines `k-word`, `k-ui`, `k-img` and `k-topic`. `topics/refs.dita` uses each
correctly, then misspells each of a `keyword`, a `uicontrol`, a `ph`, an `xref` and an `image`,
and gives two broken keys fallback text of the author's own. A build at the default log level
must report exactly the five empty ones, once each, and name the keys; the two with fallback
text are rendered as written and are not reported. The unresolved image is left out, so the
page and the print document stay valid HTML.

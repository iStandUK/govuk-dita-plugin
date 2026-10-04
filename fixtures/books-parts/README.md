# Book per part fixture

For `govuk.print.books` (#178). A bookmap of two parts, *Planning* (with a
topic of its own) and *Building* (titled only), with a preface, an appendix,
a glossary entry and index terms.

- `whole` (the default): one print document, `print.html`, as for any
  bookmap.
- `parts`: also `print-planning.html` and `print-building.html`. Each takes
  its cover title from the part and the publisher information from the
  bookmap, and holds only the part's chapters: no preface, no appendix, no
  glossary or index. Part one's link to part two goes to the website.

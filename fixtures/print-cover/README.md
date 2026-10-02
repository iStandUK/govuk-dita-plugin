# print-cover fixture

Two bookmaps over one topic, for the details and imprint the print document's cover takes
from the map's metadata (#150).

- `cover.ditamap` carries everything: `critdates` (created and two revisions), `bookid`
  (a numeric edition, an ISBN, a book number) and `bookrights` (years, owner and a rights
  summary). CI builds it with `govuk.phase` and `govuk.site.url` for the status and the
  address, and again in official branding for the Crown copyright imprint.
- `published.ditamap` gives the publication date the bookmap's own way
  (`publisherinformation/published/completed`) and an edition written in words, and carries
  no rights, so its cover has details and no imprint.

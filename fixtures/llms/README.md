# llms fixture

`llms.txt` (#118, D-30) from a small map that exercises each of its rules:

- `start.dita` and `close.dita` are top-level pages with nothing beneath them, so they share
  the one Contents section, in reading order.
- `Planning` is a `<topichead>`: a section with no page of its own.
- `building.dita` has pages beneath it, so it heads its own section and is listed first in it.
- `survey.dita` is referenced twice and listed once, where it first appears. Its title holds
  brackets, which are escaped in the link text.
- `hidden.dita` (`toc="no"`) and `library.dita` (resource-only) are left out, as from the
  sitemap.
- `walls.dita` has no short description, so its entry has no `: description`.

CI builds it with `govuk.site.url=https://example.org/llms/` and compares the result with
`expected-llms.txt` byte for byte. The map has no glossary, index or lists, so the file has no
Optional section; the manual's build checks that one.

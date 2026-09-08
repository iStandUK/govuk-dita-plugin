# markdown-mini fixture

Three Markdown topics (`format="markdown"`, org.lwdita) whose headings repeat: each contributes
nested topics with ids `about`, `benefits` and `get-started`. That is unique per page and
collides in the merged print document — the defect #121 found on a converted website.

The fixture also carries cross-references between the topics, so the print document's link
rewriting has to follow the same prefixes it gives the colliding ids.

# search-semantics fixture

Three topics exercising the search attributes the plugin derives from DITA (#54):
`shortdesc` weight, `outputclass="search-ignore"` on a table, demotion by
`outputclass="search-demote"` on a title and by `importance="obsolete"` on a topic,
prolog `keywords` as searchable metadata, `searchtitle` as the result title, and
`category` / `audience` as filters. CI builds it with `govuk.search.ranking=reference`
and asserts each attribute, then checks a JSON ranking value and an invalid one.

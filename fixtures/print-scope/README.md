# Print scope fixture

For `govuk.print.scope` (#176). The navigation is two topics, `index` and
`intro`. The items are reached only by key and link, through the
resource-only `links.ditamap`, as in a reference work whose index pages list
its entries.

With `govuk.print.scope=linked` the print document holds, in order:

1. Index of items
   1. Item A (claimed by the index)
      1. Item C (second round: only item A links to it)
   2. Item B (claimed by the index, before the introduction links to it)
2. Introduction

Item D is linked from nowhere and is never printed. With `navigation`, the
default, only the index and the introduction are printed, and their links
to the items go to the website.

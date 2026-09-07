# inline-scope fixture

One topic whose `svgref` points outside the map's own directory (at a sibling fixture's
SVG). Exercises `govuk.inline.scope` (#80): by default the file is not inlined and the build
warns `GOVK005W`; with `govuk.inline.scope=any` it is inlined and the build still warns.
The fallback `<img>` points outside the output, so this fixture is deliberately kept out of
the internal-link check.

# Vendored asset: govuk-frontend

This directory contains an unmodified subset of the compiled
[govuk-frontend](https://github.com/alphagov/govuk-frontend) release
**v6.5.0** (see `VERSION.txt`), © Crown Copyright (Government Digital Service),
distributed under the MIT licence (`LICENSE.txt` in this directory).

## What is included

- `govuk-frontend-6.5.0.min.css` (+ source map)
- `govuk-frontend-6.5.0.min.js` (+ source map)

## What is deliberately excluded

- **`assets/fonts/`** — the GDS Transport typeface is *not* MIT licensed; its
  use is restricted to official GOV.UK services. It is not redistributed here.
- **`assets/images/`** — the crown, crest, and GOV.UK favicon imagery are
  protected marks reserved for official GOV.UK services and are not
  redistributed here.

The plugin's neutral branding mode (`govuk.branding=neutral`, the default)
never references these assets: `overlay-neutral.css` aliases the font stack to
system fonts and suppresses crest/crown rules, so no request for a restricted
asset is ever made. Support for official GOV.UK services
(`govuk.branding=official`) will source the restricted assets at build time
from the publisher's own govuk-frontend copy rather than from this repository —
tracked in issue #3.

## Upgrading

Replace the four files and `VERSION.txt` with those from a newer
[govuk-frontend release](https://github.com/alphagov/govuk-frontend/releases),
update the `$govuk-frontend-version` variable in `xsl/template.xsl`, and re-run
the fixture build and checks (NFR-M2).

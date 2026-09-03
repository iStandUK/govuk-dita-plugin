# Vendored asset: govuk-frontend

This directory contains a subset of the compiled
[govuk-frontend](https://github.com/alphagov/govuk-frontend) release
**v6.5.0** (see `VERSION.txt`), © Crown Copyright (Government Digital Service),
distributed under the MIT licence (`LICENSE.txt` in this directory).

## What is included

- `govuk-frontend-6.5.0.min.css` (+ source map) — the release's compiled stylesheet,
  unmodified
- `govuk-frontend-6.5.0.min.js` (+ source map) — the release's compiled script, unmodified
- `govuk-frontend-6.5.0-nhs.min.css` — the same release recompiled from its Sass against the
  NHS Design System palette by `tools/branding` (design/09, D-17). A derivative work of
  govuk-frontend under the same MIT licence and Crown copyright attribution; it carries
  colours and metrics only

## What is deliberately excluded

- **`assets/fonts/`** — the GDS Transport typeface is *not* MIT licensed; its use is
  restricted to official GOV.UK services. It is not redistributed here. Frutiger, the NHS
  brand font, is licensed to NHS organisations and is likewise not redistributed.
- **`assets/images/`** — the crown crest and GOV.UK favicon imagery are protected marks
  reserved for official GOV.UK services and are not redistributed here.

## How the branding modes use this

- `govuk.branding=neutral` (the default) and `istanduk` load the unmodified stylesheet with
  `overlay-neutral.css`, which aliases the font stack to system fonts and suppresses
  crest/crown rules, so no request for a restricted asset is ever made.
- `govuk.branding=official` loads the unmodified stylesheet with `overlay-official.css` and
  renders the crown-and-wordmark inline from govuk-frontend's MIT-licensed SVG; the footer's
  Open Government Licence logo is inline and the crown crest image is not shipped. GDS
  Transport is not supplied; an entitled service adds it through `args.css`.
- `govuk.branding=nhs` loads the recompiled stylesheet with `overlay-nhs.css` and renders the
  NHS logo inline from `nhsuk-frontend`'s MIT-licensed SVG; Frutiger is not supplied, so the
  typeface falls back to Arial.

The MIT licence grants no right to the GOV.UK or NHS brands. Both restricted modes emit a
warning in the build log each time they are used; selecting one asserts entitlement to that
identity (GOV.UK services on the gov.uk domain; NHS organisations, or others with permission
from NHS England or the Department of Health and Social Care).

## Upgrading

Replace the compiled CSS/JS files and their source maps and `VERSION.txt` with those from a
newer [govuk-frontend release](https://github.com/alphagov/govuk-frontend/releases), update
the `$govuk-frontend-version` variable in `xsl/template.xsl` and `xsl/map2govuk-cover.xsl`,
bump the dependency in `tools/branding/package.json` and rebuild the NHS recompile
(`npm run build` there), then re-run the fixture builds and checks (NFR-M2).

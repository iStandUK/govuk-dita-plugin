# iStandUK theme assets

`istanduk-logo.svg` is taken from the iStandUK
[adoption-tracker](https://github.com/iStandUK/adoption-tracker) repository
(`client/src/assets/istanduk-logo.svg`), whose `design/brand/README.md`
documents its construction: the wordmark and tagline are **outlined to static
vector paths** (originally set in Rockwell Bold and Arial), so the file ships
artwork shapes only and requires no fonts to render — safe to redistribute.

Palette (per the same brand reference; guideline is the iNetwork Brand
Guidelines, which iStandUK's dot device reuses):

| Element | Hex |
|---|---|
| Brand blue (Pantone 072) — wordmark, header rule, footer band | `#003888` |
| Grey — "UK" and tagline | `#A7A9AC` |
| Dots | `#5BAC26` `#EC008C` `#A44299` `#F05722` `#00ADEE` |

Text uses an Arial stack (the guideline's body face); Rockwell is proprietary
and appears only inside the outlined logo. The theme is applied with
`govuk.branding=istanduk` and layers `overlay-istanduk.css` on top of the
neutral overlay, so the no-restricted-assets guarantees are unchanged.

# Bundled fonts

DesignSystemPDF embeds these faces in the PDFs it writes when the publisher supplies none of their own (decision D-25 in the project's design record). They are the unmodified files the Noto project publishes, under the SIL Open Font License 1.1 (`OFL.txt`).

| File | Family | Version | Source |
|---|---|---|---|
| `NotoSans-Regular.ttf`, `NotoSans-Bold.ttf`, `NotoSans-Italic.ttf`, `NotoSans-BoldItalic.ttf` | Noto Sans | 2.015 | `fonts/NotoSans/hinted/ttf/` |
| `NotoSansMono-Regular.ttf`, `NotoSansMono-Bold.ttf` | Noto Sans Mono | 2.014 | `fonts/NotoSansMono/hinted/ttf/` |
| `OFL.txt` | licence | — | [notofonts/latin-greek-cyrillic](https://github.com/notofonts/latin-greek-cyrillic) |

The font files were taken from [notofonts/notofonts.github.io](https://github.com/notofonts/notofonts.github.io) at commit `1eb09fb315562c7e07d738691870e52c39b45b39`, the repository that serves the Noto project's built fonts. `SHA256SUMS` lists the SHA-256 of every file; CI checks the files against it and against that commit, so a font cannot change without the change being seen.

## Updating

1. Download the new hinted TrueType files from the same paths at a newer commit.
2. Replace the files, update the versions and the commit above, and regenerate the checksums: `sha256sum *.ttf OFL.txt > SHA256SUMS`.
3. Update `NOTO_FONTS_COMMIT` in `.github/workflows/build.yml`.
4. Build and run the tests; the page counts in the integration tests show whether the metrics moved.

No restricted typeface is ever added here. A publisher entitled to a brand font supplies it at run time with `--fonts`.

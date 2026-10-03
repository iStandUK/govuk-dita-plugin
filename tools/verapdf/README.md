# veraPDF in CI

CI checks every PDF the `designsystempdf` job makes against PDF/UA-1 with
[veraPDF](https://verapdf.org)'s own command line (#164). These PDFs come from
the integration tests and from the plugin's builds through `govuk.pdf.command`
and `govuk.pdf=auto`. The reports are uploaded as the `pdf-ua-reports`
artifact, with a summary on the run's page. The `pdf-ua-negative` fixture
proves the check still fails when it should.

- **Pinned.** `VERAPDF_VERSION` and `VERAPDF_SHA256` in
  `.github/workflows/build.yml` name the greenfield installer from
  `software.verapdf.org/releases/<major.minor>/`. Releases are signed by the
  veraPDF Consortium (key `13DD 102B 4DD6 9354 D12D E5A8 3184 8632 78B1 7FE7`).
- **In step with the tests.** The version must equal `verapdf.version` in
  `designsystempdf/pom.xml`, and CI fails if they differ. When Dependabot
  bumps the library, move the CLI pin in the same pull request: download the
  new installer and its `.asc`, verify the signature, and record the new
  checksum.
- **Installed headless.** `auto-install.xml` selects the command line only.
- **Never shipped.** veraPDF is GPL-3.0-or-later / MPL-2.0. It is a CI tool
  here, as it is a test dependency of DesignSystemPDF.

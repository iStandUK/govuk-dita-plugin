# veraPDF in CI

This action installs [veraPDF](https://verapdf.org)'s own command line and puts
it on the `PATH` as `verapdf` (#164). Three workflows use it:

- **build.** The `designsystempdf` job checks every PDF it makes. These come
  from the integration tests, from the plugin's builds through
  `govuk.pdf.command` and `govuk.pdf=auto`, in every branding, with a
  publisher stylesheet and with the generator's options.
  - PDF/UA-1 is required.
  - PDF/UA-2 is reported as advisory, to show what a later move would take.
  - The reports are uploaded as the `pdf-ua-reports` artifact, with a summary
    on the run's page.
  - The `pdf-ua-negative` fixture proves the check still fails when it should.
- **release.** The released manual's PDF must pass PDF/UA-1.
- **release-pdf.** The PDF that the released DesignSystemPDF zip renders must
  pass PDF/UA-1.

How it is set up:

- **Pinned, in one place.** `action.yml` names the greenfield installer from
  `software.verapdf.org/releases/<major.minor>/` by version and SHA-256. The
  cache key repeats both. Releases are signed by the veraPDF Consortium (key
  `13DD 102B 4DD6 9354 D12D E5A8 3184 8632 78B1 7FE7`).
- **In step with the tests.** The version must equal `verapdf.version` in
  `designsystempdf/pom.xml`, and the action fails if they differ. When
  Dependabot bumps the library, move the pin in the same pull request:
  1. Download the new installer and its `.asc`.
  2. Verify the signature.
  3. Record the new version and checksum in `action.yml`, in the step's
     environment and in the cache key.
- **Installed headless.** `auto-install.xml` selects the command line only.
- **Never shipped.** veraPDF is GPL-3.0-or-later / MPL-2.0. It is a CI tool
  here, as it is a test dependency of DesignSystemPDF.

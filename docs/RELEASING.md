# Releasing

The steps that cut a release, following the Gitflow model in
[CONTRIBUTING.md](../CONTRIBUTING.md) (decision D-22). Copy the checklist into the
release pull request.

## Before starting

- [ ] `dev` is green (`ci`) and holds everything the release should carry; the issues
      it closes are closed or ready to close
- [ ] The manual describes every parameter and message in the release; the design
      record's status columns are current
- [ ] Decide the version: point release (`1.0.x`) for fixes, minor (`1.x.0`) for features
      — semantic versioning, as the registry expects

## Release branch

- [ ] `git switch dev && git pull && git switch -c release/x.y.z`
- [ ] Bump the version everywhere it appears — one commit, `Release vx.y.z: …`:
  - `org.istanduk.gov-uk/plugin.xml` (`version="x.y.z"`)
  - `docs/manual/topics/install.dita` (asset URL)
  - `docs/manual/manual.ditamap` (`<edition>Version x.y.z</edition>`, and the
    `<revised modified="…"/>` date set to the release date; CI fails if the edition and
    `plugin.xml` disagree)
  - `README.md` (status paragraph, "Try it" URL)
  - `design/README.md` (status line, progress-table row)
  - `design/05-decision-log.md` if the release changes scope or process
- [ ] Draft the release notes (what changed since the last release, install/upgrade
      commands, what comes next) — they become the GitHub release body
- [ ] Open a pull request `release/x.y.z` → `main`, titled `Release vx.y.z`, with this
      checklist; wait for `ci`

## Publish

- [ ] Merge the release pull request with a **merge commit** (not squash)
- [ ] Tag the merge commit and push the tag:
      `git switch main && git pull && git tag -a vx.y.z -m "vx.y.z" && git push origin vx.y.z`
- [ ] The tag push runs the **`release` workflow**: it builds `org.istanduk.gov-uk-x.y.z.zip`
      from the tagged tree, checks that `plugin.xml`'s version matches the tag and sits at the
      zip root, installs it into DITA-OT and builds a fixture, publishes a build-provenance
      attestation, and attaches the zip and `org.istanduk.gov-uk-x.y.z.zip.sha256` to the
      GitHub release — creating the release as a **draft** if it does not exist yet. Wait for
      it (Actions → release). Nothing is built by hand.
- [ ] The same run releases **the manual at the same version** (#167). With that plugin
      zip, in iStandUK branding, it builds the manual from the tagged tree, with
      DesignSystemPDF built from the same tag and the pinned Pagefind. It checks that the
      cover says `Version x.y.z`, that the build gave no `GOVK008W` or `DSPDF` warning, and
      that the PDF passes veraPDF PDF/UA-1. It attests and attaches:
  - `org.istanduk.gov-uk-manual-x.y.z.pdf`: the whole manual as a page-numbered,
    tagged PDF
  - `org.istanduk.gov-uk-manual-x.y.z.zip`: the manual as a website, with search, the
    print version and the PDF
  - a `.sha256` for each

  Their dates come from the tagged commit, so the same tag gives the same files. The
  manual's edition is the version bump above; CI already fails if it and `plugin.xml`
  disagree.
- [ ] Open the draft release, paste the release notes, set it as the latest release, publish
- [ ] Verify from the public URL in a clean toolkit: `dita install <asset URL>`, build a
      fixture, and confirm the downloaded asset's SHA-256 matches the `.sha256` file and
      `gh attestation verify org.istanduk.gov-uk-x.y.z.zip --repo iStandUK/govuk-dita-plugin`
      succeeds
- [ ] Do the same for the manual: check both files against their `.sha256` and
      `gh attestation verify`, open the PDF (cover edition, page numbers in the contents),
      unzip the site and open `index.html`

## Registry

- [ ] In a fork of [dita-ot/registry](https://github.com/dita-ot/registry), **append** an
      entry to `org.istanduk.gov-uk.json` (the file is an array — one entry per version):
      `name`, `vers`, `url` (the asset), `cksum` (the SHA-256 from the `.sha256` file), `deps` (`org.dita.base >=4.4.1`),
      `description`, `keywords`, `homepage`, `license`
- [ ] Commit with `git commit -s` (the registry requires a sign-off) and open one pull
      request per version against `master`
- [ ] Note the registry pull request on the release's issue or epic

## Afterwards

- [ ] Merge `main` back into `dev` (pull request `main` → `dev`, merge commit) so `dev`
      carries the version bump and the tag's history
- [ ] Delete the release branch
- [ ] Close the issues the release delivered; update epic checklists

## Hotfixes

Branch `hotfix/x.y.z` from `main`, make the minimal fix with its test, bump the version as
above, pull request to `main`, then the same publish, registry and back-merge steps.

## Trying the release build without releasing

Run the `release` workflow by hand from `dev` with **dry-run** ticked (Actions → release →
Run workflow): it builds and verifies the plugin asset and the manual and keeps them as a
run artifact, but attests and publishes nothing.

# Releasing DesignSystemPDF

DesignSystemPDF (`designsystempdf/`) is the second product in this repository (D-23). It
is released **on its own line**: its own version number, `pdf-v*` tags, the `release-pdf`
workflow, and no DITA-OT registry entry — it is not a plugin. A plugin release does not
need one of these, nor the other way round; when the print contract changes, release both.

## Before starting

- [ ] `dev` is green (`ci`) and `designsystempdf/CHANGELOG.md` lists what a publisher
      would notice since the last `pdf-v*` release
- [ ] Decide the version (semantic versioning): a point release for fixes and library
      upgrades, a minor for new options or a new print contract understood
- [ ] If the print contract moved: the contracts table in `designsystempdf/README.md` and
      `PrintContract.UNDERSTOOD` agree, and the plugin release that writes the new
      contract is ready

## Release branch

- [ ] `git switch dev && git pull && git switch -c release/pdf-x.y.z`
- [ ] One commit, `Release DesignSystemPDF x.y.z: …`:
  - `designsystempdf/pom.xml` — `<version>x.y.z</version>` and
    `project.build.outputTimestamp` (the release date; it keeps the build reproducible)
  - `designsystempdf/CHANGELOG.md` — the heading becomes `## x.y.z — YYYY-MM-DD` (the
    workflow refuses a tag whose version has no dated entry)
  - `designsystempdf/THIRD-PARTY-NOTICES` — versions and copyright years still true for
    every jar in `lib/` (CI checks each jar is named)
- [ ] Draft the release notes: what changed, the print contracts understood, the engine
      and font versions, install and verify commands, the plugin versions it works with
- [ ] Open a pull request `release/pdf-x.y.z` → `main`, titled
      `Release DesignSystemPDF x.y.z`, with this checklist; wait for `ci`

## Publish

- [ ] Merge the release pull request with a **merge commit** (not squash)
- [ ] Tag the merge commit and push the tag:
      `git switch main && git pull && git tag -a pdf-vx.y.z -m "DesignSystemPDF x.y.z" && git push origin pdf-vx.y.z`
- [ ] The tag push runs the **`release-pdf` workflow**: it checks the version against the
      tag, builds `designsystempdf-x.y.z.zip` from the tagged tree, runs the tests
      (veraPDF included), unpacks the zip and renders with it, publishes a
      build-provenance attestation, and attaches the zip, `designsystempdf-x.y.z.zip.sha256`
      and the four `openhtmltopdf-*-sources.jar` files (the LGPL engine's source) to the
      GitHub release — creating it as a **draft** if it does not exist yet. Wait for it
      (Actions → release-pdf). Nothing is built by hand.
- [ ] Open the draft release, paste the release notes, and publish it with **"Set as the
      latest release" unticked** — the plugin's releases stay the repository's latest
- [ ] Verify from the public URL on a machine with Java only: download the zip, check
      `sha256sum -c designsystempdf-x.y.z.zip.sha256` and
      `gh attestation verify designsystempdf-x.y.z.zip --repo iStandUK/govuk-dita-plugin`,
      unzip, run `bin/designsystempdf --version`, and render a print document

## Afterwards

- [ ] Merge `main` back into `dev` (pull request `main` → `dev`, merge commit)
- [ ] Where the plugin's CI pins a DesignSystemPDF release (version and SHA-256 in
      `.github/workflows/build.yml`), move the pin to the new release in a pull request of
      its own, so the join is proved against what publishers will install
- [ ] Start the next changelog entry (`## x.y.z — unreleased`) with the first change that
      needs one; delete the release branch; close the issues the release delivered

## Trying the DesignSystemPDF release build without releasing

Run the `release-pdf` workflow by hand from `dev` with **dry-run** ticked (Actions →
release-pdf → Run workflow): it builds, tests and verifies the assets and keeps them as a
run artifact, but attests and publishes nothing.

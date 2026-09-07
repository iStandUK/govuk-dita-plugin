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
- [ ] Release asset. Until the CI release build lands (#69), build it from the tagged
      tree and record its checksum:
      ```bash
      git switch --detach vx.y.z
      (cd org.istanduk.gov-uk && zip -qr ../org.istanduk.gov-uk-x.y.z.zip . -x '.DS_Store' '*/.DS_Store')
      shasum -a 256 org.istanduk.gov-uk-x.y.z.zip
      ```
      `plugin.xml` must sit at the root of the zip.
- [ ] `gh release create vx.y.z org.istanduk.gov-uk-x.y.z.zip --title vx.y.z --notes-file notes.md --latest`
- [ ] Verify from the public URL in a clean toolkit: `dita install <asset URL>`, build a
      fixture, and confirm the downloaded asset's SHA-256 matches the recorded value

## Registry

- [ ] In a fork of [dita-ot/registry](https://github.com/dita-ot/registry), **append** an
      entry to `org.istanduk.gov-uk.json` (the file is an array — one entry per version):
      `name`, `vers`, `url` (the asset), `cksum` (the SHA-256), `deps` (`org.dita.base >=4.4.1`),
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

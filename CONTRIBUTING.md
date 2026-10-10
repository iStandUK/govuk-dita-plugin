# Contributing

Thank you for helping. This repository follows the iStandUK exemplar for Git and GitHub
practice ([iStandUK/hello-world](https://github.com/iStandUK/hello-world)): work starts
from an issue, flows through a short-lived branch and a small, linked, reviewed pull
request, and reaches `main` only as a release. Decision **D-22** in
[design/05-decision-log.md](design/05-decision-log.md) records the choices below.

## Branches (Gitflow)

| Branch | Purpose | Branch from | Merges into |
|---|---|---|---|
| `main` | Released code only; every commit on it is a tagged release | — | — |
| `dev` | Integration branch and the default; the next release takes shape here | `main` (once) | `main` via a release branch |
| `feature/<name>` | One change — a feature, a fix, a document | `dev` | `dev` |
| `release/x.y.z` | Version bump and release notes for one release | `dev` | `main` **and** `dev` |
| `hotfix/x.y.z` | An urgent fix to the released code | `main` | `main` **and** `dev` |

Dependabot's update pull requests also target `dev`. Pull requests that touch only documentation — the design record, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `docs/RELEASING.md`, the issue and pull-request templates — skip the build; `ci` still reports, so the rules are satisfied. The manual under `docs/manual/` is built and tested and does not count as documentation here. A pull request that changes only `designsystempdf/` runs that product's job and skips the plugin's build; one that touches the workflows runs both. Nobody commits directly to `main` or `dev` — both are protected: a pull request and a
green `ci` status are required, and history is never rewritten. Use descriptive branch
names (`feature/print-document`, `hotfix/1.0.1`).

## Making a change

1. **Start from an issue.** Open one if it does not exist (templates are provided); an
   epic's sub-issue is the usual starting point. Check `design/` first — many decisions
   are recorded with their rationale, and the requirements carry per-item status.
2. **Branch from `dev`**: `git switch dev && git pull && git switch -c feature/<name>`.
3. **Keep it small.** One change per pull request. Documentation-only and build-only
   changes are welcome on their own.
4. **Cover it.** A fixture and a CI assertion for behaviour; the manual for anything a
   publisher sees (parameters, messages, output); the design record when scope or a
   decision changes.
5. **Open the pull request to `dev`** (release and hotfix branches target `main`). Use
   the template: link the issue with `Closes #n`, say what changed and why, tick the
   checklist. Open it as a draft while work is in progress.
6. **Review and merge.** Code owners are requested automatically. Feature branches are
   squash-merged (one commit per change); release and hotfix branches are merged with a
   merge commit so `main` and `dev` share history. With a single active maintainer the
   maintainer may merge their own pull request once `ci` is green; the repository rules
   record any bypass of the review requirement.

## Commits

Write the message for the reader of `git log`: what changed and why, in the imperative.
Reference the issue. Where an AI assistant contributed, keep the `Co-Authored-By`
trailer that names it. By contributing you agree that your contribution is licensed
under the Apache License 2.0 that covers the project.

## Ground rules for the code

- **Vendor-neutral.** Describe commercial products generically; name no vendor.
- **No restricted assets.** The GOV.UK crown, GDS Transport, the NHS logo files and
  Frutiger are never added to the repository or the plugin (see the manual's legal topic).
- **Node-free builds.** A publisher needs DITA-OT and Java only; anything else is
  optional and degrades gracefully (search without Pagefind, print without a browser).
- **Publisher choice, warnings not errors.** New behaviour that touches content risk is
  parameterised with a safe default, and the build reports what it found as a `GOVK`
  warning; it does not fail the publisher's build.
- **Accessible and valid.** Output stays WCAG 2.2 AA and valid HTML5; CI enforces it.
- **Inclusive language** throughout, in code and prose.

## Running the checks locally

CI runs these; running them before a pull request saves a round trip.

```bash
# install the working tree into a DITA-OT 4.4.1 and build the manual
(cd org.istanduk.gov-uk && zip -qr ../org.istanduk.gov-uk.zip .)
dita uninstall org.istanduk.gov-uk; dita install "$PWD/org.istanduk.gov-uk.zip"
dita --input docs/manual/manual.ditamap --format govuk --output out/manual -Dgovuk.print=yes

# validity, links, page weight
java -jar vnu.jar --errors-only --skip-non-html out/manual
python3 tools/check_links.py out/manual
python3 tools/page_weight.py --report --budget-kb 300 out/manual

# accessibility and the print smoke (Playwright, tools/a11y)
(cd tools/a11y && npm ci && npx playwright install chromium)
node tools/a11y/run.mjs out/manual
node tools/a11y/print-smoke.mjs out/manual/print.html out/manual.pdf --paper A4

# the workflows: actionlint runs ShellCheck over every run: block when it is on the PATH
actionlint
```

On Windows, run the toolkit's `dita.bat` rather than the `dita` shell script, even from a
Unix-style shell: started by the script, Java loads no plugin library, so the Markdown
fixture builds without its topics (the manual's Troubleshooting topic has the detail).
Where there is no `zip` command, `jar cMf ../org.istanduk.gov-uk.zip .` makes the same
archive.

The fixtures under `fixtures/` exercise bookmaps, keys, chunking, the SVG domain, search
semantics and unresolved keys; `.github/workflows/build.yml` lists every assertion.

## Keeping in step with govuk-frontend

The plugin vendors one release of govuk-frontend (`org.istanduk.gov-uk/resource/govuk-frontend`),
and the aim is to follow upstream release by release. Dependabot opens a pull request when
a new one appears; it cannot pass on its own, because the vendored files have to move with
it. To make the uplift, on a feature branch:

```bash
tools/branding/upgrade.sh 6.5.1      # the new version; needs curl, unzip, sha256sum and npm
```

It fetches the release, replaces the vendored stylesheet and script, records the checksum CI
holds the release to, pins `tools/branding` to the same version and recompiles the NHS
stylesheet. The version is written once, in `VERSION.txt`; the stylesheets and CI read it
from there. Then:

- read upstream's release notes for anything that touches the components the plugin uses,
  its Sass settings (the NHS recompile), the inline body-class script (the
  Content-Security-Policy hash) or the print rules (the print document and the PDF);
- build the manual in each branding mode and look at it, and at the PDF;
- open the pull request, closing Dependabot's; CI must pass, and its `visual-snapshots`
  artifact is there to be looked at before merging (NFR-M2).

A patch or minor release should be routine. A major release is a change to plan, with an
issue of its own.

## DesignSystemPDF — the second product

`designsystempdf/` holds **DesignSystemPDF**, the generator that renders the plugin's
print document as a page-numbered, tagged PDF (decisions D-23 and D-25). It lives in this
repository beside the plugin but is a separate product: its own version number, its own
changelog and releases (`pdf-v*` tags), not a DITA-OT plugin, and never bundled with one.
The two meet only through the print document and its `govuk-print-contract` marker.

```bash
# Java 17+ and Maven 3.9+; produces target/designsystempdf-<version>.zip
(cd designsystempdf && mvn -B verify)
```

Its ground rules, on top of the ones above:

- **The plugin stays Apache-only.** Nothing from `designsystempdf/` — code, jars or
  fonts — is copied into `org.istanduk.gov-uk/`, and the plugin never requires the
  generator: a build without it is complete, without a PDF.
- **The engine is used, not changed.** The LGPL layout engine and the other libraries
  come from Maven Central as published and ship as separate, unmodified jars in `lib/`;
  none of their source is copied into the tree. A change needed in the engine goes
  upstream.
- **Notices travel with the code.** A new or upgraded dependency updates
  `THIRD-PARTY-NOTICES` in the same pull request; a font change updates
  `fonts/README.md` and `fonts/SHA256SUMS`. No restricted typeface is ever added.
- **Java only**, as for the plugin: no other runtime, and no network request at run time.
- **Its own changelog.** What a publisher would notice goes in
  `designsystempdf/CHANGELOG.md`.

## Where CI runs

The `build` workflow runs on GitHub's `ubuntu-latest` unless the repository variable `CI_RUNS_ON` names a self-hosted runner by its labels, as JSON:

```bash
gh variable set CI_RUNS_ON --body '["self-hosted","Linux","X64"]'
gh variable delete CI_RUNS_ON
```

The first switches to the self-hosted runner; the second falls back to GitHub's runners at once. Pull requests from forks always run on GitHub's runners, because this repository is public. The release workflows stay on GitHub's runners, so release assets are built on a clean machine.

A self-hosted runner needs:

- **Registration where this repository can use it:** at the organisation level, in a runner group that allows this repository and public repositories, or on this repository. A runner registered to another repository takes only that repository's jobs.
- **Linux x64, Ubuntu 22.04 or later,** with `git` and `sha256sum`. The jobs install `curl`, `zip`, `unzip`, `python3` and `fontconfig` themselves when they are missing. The DesignSystemPDF job fetches Maven 3.9 when the runner has none.
- **Passwordless `sudo` for the runner's user,** for its `apt-get` installs: any of those tools that are missing, and Chromium's libraries for the accessibility checks. Java, Node, Maven and DITA-OT are fetched by the workflow.
- **Room for about 3 GB** under the runner's work folder.
- **Nothing it should not share.** Its jobs run this repository's code with the runner user's rights. Keep it separate from runners of private repositories, and from any credentials on the machine.

## Releases

See [docs/RELEASING.md](docs/RELEASING.md): a `release/x.y.z` branch from `dev`, the
version bump, a pull request to `main`, the tag, the release asset and its checksum, the
DITA-OT registry entry, and the merge back to `dev`. DesignSystemPDF is released on its
own line, with `pdf-v*` tags.

## Security

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

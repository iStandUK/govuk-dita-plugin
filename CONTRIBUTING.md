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

Nobody commits directly to `main` or `dev` — both are protected: a pull request and a
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
```

The fixtures under `fixtures/` exercise bookmaps, keys, chunking, the SVG domain, search
semantics and unresolved keys; `.github/workflows/build.yml` lists every assertion.

## Releases

See [docs/RELEASING.md](docs/RELEASING.md): a `release/x.y.z` branch from `dev`, the
version bump, a pull request to `main`, the tag, the release asset and its checksum, the
DITA-OT registry entry, and the merge back to `dev`.

## Security

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

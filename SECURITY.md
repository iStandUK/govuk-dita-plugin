# Security policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x (latest release) | Yes — fixes ship as 1.x point releases and go to the DITA-OT plugin registry |
| 0.9.x and earlier | No — please upgrade |

## Reporting a vulnerability

Use GitHub's private reporting form:
**<https://github.com/iStandUK/govuk-dita-plugin/security/advisories/new>**.
Please do not open a public issue for a security problem.

You will get an acknowledgement within five working days. We aim to fix problems that
put readers or publishers at risk in the next point release, and to publish an advisory
with credit to the reporter unless you prefer otherwise.

## What is in scope

The plugin and everything it produces:

- the plugin's stylesheets, build logic, CSS and JavaScript (`org.istanduk.gov-uk/`);
- the websites and print documents it generates — what reaches a reader's browser;
- the build and release chain in this repository (`.github/`, `tools/`, release assets,
  the registry entry).

Generated sites are static: no server-side code, no cookies, no analytics, and no
requests to other origins at runtime (asserted in CI). Restricted brand assets are never
bundled. What the plugin cannot control — hosting headers, and content authored in DITA
(diagrams, embeds, links) — is the publisher's responsibility; the manual's guidance and
the build's `GOVK` warnings exist to make those choices visible.

## What is out of scope here

Report these to their own projects:

- **DITA Open Toolkit** — XML parsing, DTD and catalog resolution, key and chunk
  processing: <https://github.com/dita-ot/dita-ot/security>
- **govuk-frontend** (vendored, pinned): <https://github.com/alphagov/govuk-frontend/security>
- **Pagefind** (optional, installed by the publisher): <https://github.com/CloudCannon/pagefind/security>

If you are unsure where a problem belongs, report it here and we will route it.

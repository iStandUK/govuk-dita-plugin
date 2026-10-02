#!/usr/bin/env bash
# Uplift the vendored govuk-frontend release (NFR-M2, #162).
#
#   tools/branding/upgrade.sh 6.5.1
#
# Fetches the named release from govuk-frontend's GitHub releases, replaces the
# vendored stylesheet and script and their source maps, records the release's
# checksum where CI checks it, pins tools/branding to the same version and
# recompiles the brand stylesheets from its Sass. The version is written in one
# place, VERSION.txt; the stylesheets and the CI assertions read it from there.
#
# Needs curl, unzip, sha256sum and npm. Nothing is committed: read the release
# notes, review the diff, and look at the visual snapshots CI uploads before
# merging (CONTRIBUTING.md, "Keeping in step with govuk-frontend").
set -euo pipefail

v="${1:?usage: upgrade.sh <govuk-frontend version, for example 6.5.1>}"
case "$v" in
  *[!0-9.]* | '') echo "not a version number: $v" >&2; exit 2 ;;
esac

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
vendored="$root/org.istanduk.gov-uk/resource/govuk-frontend"
workflow="$root/.github/workflows/build.yml"
old="$(tr -d '[:space:]' < "$vendored/VERSION.txt")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "govuk-frontend $old -> $v"

# The release, as published; CI downloads the same file and checks the same sum
curl -fsSL -o "$tmp/release.zip" \
  "https://github.com/alphagov/govuk-frontend/releases/download/v${v}/release-v${v}.zip"
sum="$(sha256sum "$tmp/release.zip" | cut -d' ' -f1)"
unzip -q "$tmp/release.zip" -d "$tmp/release"
files="govuk-frontend-${v}.min.css govuk-frontend-${v}.min.css.map govuk-frontend-${v}.min.js govuk-frontend-${v}.min.js.map"
for f in $files; do
  test -f "$tmp/release/$f" || { echo "release v${v} has no $f" >&2; exit 1; }
done

# Out with the old release's files, the brand recompiles included; the licence
# and the notice stay. No font or image is taken from the release (see NOTICE.md).
rm -f "$vendored"/govuk-frontend-*.min.css "$vendored"/govuk-frontend-*.min.css.map \
      "$vendored"/govuk-frontend-*.min.js "$vendored"/govuk-frontend-*.min.js.map
for f in $files; do
  cp "$tmp/release/$f" "$vendored/$f"
done
printf '%s\n' "$v" > "$vendored/VERSION.txt"

# The checksum CI holds the release zip to
grep -q 'GOVUK_FRONTEND_SHA256: "[0-9a-f]\{64\}"' "$workflow" \
  || { echo "no GOVUK_FRONTEND_SHA256 in $workflow" >&2; exit 1; }
sed -i -E "s/(GOVUK_FRONTEND_SHA256: \")[0-9a-f]{64}(\")/\1${sum}\2/" "$workflow"

# The same release's Sass, recompiled against the brand palettes
(cd "$here" && npm install --save-exact --no-audit --no-fund "govuk-frontend@${v}" && npm run build)

cat <<EOF

govuk-frontend is now ${v} (release zip sha256 ${sum}).

Before committing:
  - read the release notes: https://github.com/alphagov/govuk-frontend/releases/tag/v${v}
  - git status: four stock files, VERSION.txt, the brand stylesheets,
    the checksum in build.yml, and tools/branding's package files
  - build the manual in each branding mode and look at it
After pushing:
  - CI must pass, and its "visual-snapshots" artifact is there to be looked at
EOF

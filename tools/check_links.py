#!/usr/bin/env python3
"""Internal link checker for the generated GOV.UK sites (#35 / NFR).

For every .html file under the given output directories, resolve each local
href/src and verify the target file exists; when the link carries a #fragment,
verify an element with that id (or an <a name>) exists in the target. External
links (http, https, protocol-relative, mailto, tel, javascript, data) are not
checked. Exits non-zero and prints every broken link found.

This is the check that would have caught the glossary dead links fixed in #34.
"""
import html.parser
import os
import sys
import urllib.parse


class Collector(html.parser.HTMLParser):
    """Collect internal link targets and the ids/anchors present in a page."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links = []   # (attr, value) for href/src style references
        self.ids = set()  # element ids and <a name> anchors

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if a.get("id"):
            self.ids.add(a["id"])
        if tag == "a" and a.get("name"):
            self.ids.add(a["name"])
        for key in ("href", "src", "xlink:href", "data"):
            if key in a and a[key] is not None:
                self.links.append(a[key])


SKIP_PREFIXES = ("http://", "https://", "//", "mailto:", "tel:",
                 "javascript:", "data:")


def is_external(target):
    return target.startswith(SKIP_PREFIXES)


def collect(path):
    parser = Collector()
    with open(path, encoding="utf-8") as fh:
        parser.feed(fh.read())
    return parser


def main(argv):
    roots = argv[1:]
    if not roots:
        print("usage: check_links.py <output-dir> [<output-dir> ...]", file=sys.stderr)
        return 2

    html_files = []
    for root in roots:
        for dirpath, _dirs, files in os.walk(root):
            for name in files:
                if name.endswith(".html"):
                    html_files.append(os.path.join(dirpath, name))

    # Cache the ids present in each html file so fragment checks are cheap.
    id_cache = {}
    broken = []
    checked = 0

    for path in html_files:
        page = collect(path)
        id_cache[os.path.realpath(path)] = page.ids

    for path in html_files:
        page = id_cache_source = collect(path)
        base = os.path.dirname(path)
        for raw in page.links:
            target = raw.strip()
            if not target or is_external(target):
                continue
            parsed = urllib.parse.urlparse(target)
            frag = parsed.fragment
            filepart = parsed.path

            if filepart == "":
                # same-page fragment (e.g. href="#id")
                if frag and frag not in page.ids:
                    broken.append((path, raw, "missing anchor in same page"))
                checked += 1
                continue

            # Resolve the file part relative to the current page.
            tgt = os.path.normpath(os.path.join(base, urllib.parse.unquote(filepart)))
            checked += 1
            if not os.path.exists(tgt):
                broken.append((path, raw, "target file not found"))
                continue
            if frag and tgt.endswith(".html"):
                ids = id_cache.get(os.path.realpath(tgt))
                if ids is None:
                    ids = collect(tgt).ids
                    id_cache[os.path.realpath(tgt)] = ids
                if frag not in ids:
                    broken.append((path, raw, "missing anchor in target page"))

    print(f"checked {checked} internal links across {len(html_files)} pages")
    if broken:
        print(f"\n{len(broken)} broken link(s):")
        for src, link, why in broken:
            print(f"  {src}: {link}  ({why})")
        return 1
    print("no broken internal links")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

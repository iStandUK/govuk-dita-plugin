#!/usr/bin/env python3
"""Page-weight budget check for the generated sites (#35 / NFR-P2).

For every .html page, sum the uncompressed size of the page shell — the HTML
itself plus the local CSS and JS it links — and compare against the budget
(NFR-P2: HTML+CSS+JS for a typical page under ~300 KB uncompressed, excluding
content images). Content images are reported separately and are not budgeted (a
page may legitimately embed large screenshots). The gzipped shell is printed too,
for information.

Usage: page_weight.py [--budget-kb N] [--report] <output-dir> [...]
"""
import gzip
import html.parser
import os
import sys
import urllib.parse


class Refs(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.css, self.js, self.img = [], [], []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "link" and "stylesheet" in (a.get("rel") or "") and a.get("href"):
            self.css.append(a["href"])
        elif tag == "script" and a.get("src"):
            self.js.append(a["src"])
        elif tag == "img" and a.get("src"):
            self.img.append(a["src"])
        elif tag == "object" and a.get("data"):
            self.img.append(a["data"])


def local(ref):
    return ref and not ref.startswith(
        ("http://", "https://", "//", "data:", "mailto:", "tel:", "javascript:", "#"))


def raw_size(path):
    try:
        return os.path.getsize(path)
    except OSError:
        return 0


def gz_size(path):
    try:
        with open(path, "rb") as fh:
            return len(gzip.compress(fh.read(), 9))
    except OSError:
        return 0


def resolve(base, ref):
    return os.path.normpath(os.path.join(base, urllib.parse.unquote(
        urllib.parse.urlparse(ref).path)))


def main(argv):
    args = argv[1:]
    budget_kb = 300.0
    report = False
    roots = []
    i = 0
    while i < len(args):
        if args[i] == "--budget-kb":
            budget_kb = float(args[i + 1]); i += 2
        elif args[i] == "--report":
            report = True; i += 1
        else:
            roots.append(args[i]); i += 1

    budget = budget_kb * 1024
    rows = []
    for root in roots:
        for dirpath, _dirs, files in os.walk(root):
            for name in files:
                if not name.endswith(".html"):
                    continue
                path = os.path.join(dirpath, name)
                refs = Refs()
                with open(path, encoding="utf-8") as fh:
                    refs.feed(fh.read())
                base = os.path.dirname(path)
                css = [resolve(base, r) for r in dict.fromkeys(refs.css) if local(r)]
                js = [resolve(base, r) for r in dict.fromkeys(refs.js) if local(r)]
                img = [resolve(base, r) for r in dict.fromkeys(refs.img) if local(r)]
                shell = raw_size(path) + sum(map(raw_size, css)) + sum(map(raw_size, js))
                shell_gz = gz_size(path) + sum(map(gz_size, css)) + sum(map(gz_size, js))
                img_raw = sum(map(raw_size, img))
                rows.append((shell, shell_gz, img_raw, path))

    rows.sort(reverse=True)
    if report:
        print(f"{'shell':>9} {'shell_gz':>9} {'img':>9}  page (uncompressed bytes; gzip shown)")
        for shell, shell_gz, img_raw, path in rows[:12]:
            print(f"{shell:9} {shell_gz:9} {img_raw:9}  {path}")

    # NFR-P2 budgets a "typical topic page"; the search page is exempt — it
    # carries the third-party Pagefind UI bundle, not the plugin's own shell.
    over = [r for r in rows if r[0] > budget and os.path.basename(r[3]) != "search.html"]
    worst = rows[0] if rows else (0, 0)
    print(f"\nheaviest shell: {worst[0] / 1024:.1f} KB uncompressed / {worst[1] / 1024:.1f} KB gzipped "
          f"(budget {budget_kb:.0f} KB uncompressed) across {len(rows)} pages")
    if over:
        print(f"{len(over)} page(s) over budget:")
        for shell, _gz, _img, path in over:
            print(f"  {shell / 1024:.1f} KB  {path}")
        return 1
    print("all pages within the shell budget")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

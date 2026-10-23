#!/usr/bin/env python3
"""Page metadata checker for the generated sites (#99, design 14).

Reads the mapping tables the plugin ships (resource/metadata) and checks each
page of a built site against the tables a govuk.metadata level enables, so it
names no scheme of its own:

  - every required row is present, except a URL-valued row when no site URL
    was given (those are omitted by rule);
  - a row that does not repeat appears at most once;
  - URL values are absolute; the page's own address and its neighbours' are
    under the site URL, and the page's own is the page's path beneath it;
  - without a site URL, no page carries its own address or its neighbours';
  - dates are ISO dates and locales are language_TERRITORY;
  - a print document (print*.html) carries none of it.

A kind with a test on a property's value cannot be decided from the page, so
only its "@role" tests are evaluated; a page's role is cover (index.html at
the root), utility (the generated pages at the root) or topic.

Exits non-zero and prints every finding.
"""
import argparse
import html.parser
import json
import os
import re
import shutil
import sys
import xml.etree.ElementTree as ET

PLUGIN = "org.istanduk.gov-uk"
TABLES = ("resource", "metadata")

UTILITY = {"glossary.html", "index-page.html", "figurelist.html", "tablelist.html", "search.html"}


class Head(html.parser.HTMLParser):
    """Collect the meta and link elements of a page."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.metas = []   # (attribute, name, content)
        self.links = []   # (rel, href)
        self.jsonld = []  # the text of each application/ld+json block
        self._in_jsonld = False

    def handle_endtag(self, tag):
        if tag == "script":
            self._in_jsonld = False

    def handle_data(self, data):
        if self._in_jsonld:
            self.jsonld[-1] += data

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "script" and (a.get("type") or "").strip().lower() == "application/ld+json":
            self._in_jsonld = True
            self.jsonld.append("")
        if tag == "meta":
            for attr in ("property", "name"):
                if a.get(attr):
                    self.metas.append((attr, a[attr], a.get("content") or ""))
        elif tag == "link" and a.get("rel"):
            for rel in a["rel"].split():
                self.links.append((rel, a.get("href") or ""))


def has_tables(directory):
    return bool(directory) and os.path.isfile(os.path.join(directory, "schemes.xml"))


def find_tables(explicit, dita_dir):
    """Where the mapping tables are, wherever the checker itself is kept (#243).

    In order: --tables; the plugin installed in --dita-dir; this repository's
    layout (the checker sits in tools/ beside the plugin); the plugin installed
    in DITA_HOME; the plugin installed in the toolkit the `dita` command on the
    PATH belongs to. Returns (directory, places looked in).
    """
    here = os.path.dirname(os.path.abspath(__file__))
    installed = lambda home: os.path.join(home, "plugins", PLUGIN, *TABLES)
    candidates = []
    if explicit:
        # a path the caller named is the only one used
        return explicit, [explicit]
    if dita_dir:
        candidates.append(installed(dita_dir))
    candidates.append(os.path.join(here, "..", PLUGIN, *TABLES))
    if os.environ.get("DITA_HOME"):
        candidates.append(installed(os.environ["DITA_HOME"]))
    command = shutil.which("dita")
    if command:
        candidates.append(installed(os.path.dirname(os.path.dirname(os.path.realpath(command)))))
    for directory in candidates:
        if has_tables(directory):
            return directory, candidates
    return None, candidates


def load_tables(directory, level):
    index = ET.parse(os.path.join(directory, "schemes.xml")).getroot()
    tables = []
    for entry in index.findall("scheme"):
        if level in (entry.get("levels") or "").split():
            tables.append(ET.parse(os.path.join(directory, entry.get("href"))).getroot())
    return tables


def all_names(directory):
    """Every name any shipped table writes, for the print document check."""
    index = ET.parse(os.path.join(directory, "schemes.xml")).getroot()
    names = set()
    for entry in index.findall("scheme"):
        table = ET.parse(os.path.join(directory, entry.get("href"))).getroot()
        for row in table.iter():
            if row.get("as"):
                names.add((table.get("syntax"), row.get("as")))
    return names


def applies(kind, role):
    when = (kind.get("when") or "").strip()
    if not when:
        return True
    m = re.fullmatch(r"@role\s*(!?=)\s*'([^']*)'", when)
    if not m:
        return False
    return (role == m.group(2)) == (m.group(1) == "=")


def is_uri(row):
    return (row.get("format") == "uri" or row.get("term") == "@id"
            or (row.tag == "relation" and not row.get("term")))


def own_address(row):
    """Rows whose value is the address of this page or of a neighbour."""
    return row.get("term") == "@id" or (row.tag == "relation" and not row.get("term"))


def values(head, table, row):
    if table.get("syntax") == "link":
        return [h for rel, h in head.links if rel == row.get("as")]
    attr = row.get("attribute") or table.get("attribute") or "name"
    return [c for a, n, c in head.metas if a == attr and n == row.get("as")]


def jsonld_objects(head, rel, found):
    """The objects of a page's JSON-LD block, in order. One block at most; it
    must parse; an object is found in @graph or is the block itself."""
    if len(head.jsonld) > 1:
        found.append(f"{rel}: {len(head.jsonld)} JSON-LD blocks, not one")
    objects = []
    for text in head.jsonld:
        try:
            data = json.loads(text)
        except ValueError as e:
            found.append(f"{rel}: JSON-LD does not parse: {e}")
            continue
        graph = data.get("@graph", [data]) if isinstance(data, dict) else data
        objects += [o for o in graph if isinstance(o, dict)]
    return objects


def jsonld_values(obj, key):
    """A key's values as strings: a node reference is its @id."""
    v = obj.get(key)
    if v is None:
        return []
    return [(x.get("@id", "") if isinstance(x, dict) else str(x)) for x in (v if isinstance(v, list) else [v])]


def check_jsonld(rel, head, table, role, site_url):
    found = []
    objects = jsonld_objects(head, rel, found)
    label = table.get("id")
    for kind in table.findall("kind"):
        if kind.get("record") != "page" or not applies(kind, role):
            continue
        rows = [r for r in kind if r.tag != "kind"]
        needs = [r for r in rows if r.tag == "list" and site_url
                 or r.get("required") == "yes" and (site_url or not is_uri(r))]
        mine = [o for o in objects if o.get("@type") == kind.get("type")]
        if not mine:
            if needs:
                found.append(f"{rel}: no {label} {kind.get('type')}")
            continue
        for obj in mine:
            for row in needs:
                if not jsonld_values(obj, row.get("as")):
                    found.append(f"{rel}: no {label} {kind.get('type')} {row.get('as')}")
            for row in rows:
                key = row.get("as")
                for v in jsonld_values(obj, key):
                    if row.tag == "list":
                        continue
                    if is_uri(row) and not re.match(r"^[A-Za-z][A-Za-z0-9+.\-]*:\S+$", v):
                        found.append(f"{rel}: {label} {kind.get('type')} {key} is not an absolute URL: {v}")
                    if own_address(row):
                        if not site_url:
                            found.append(f"{rel}: {label} {kind.get('type')} {key} written without a site URL")
                        elif not v.startswith(site_url):
                            found.append(f"{rel}: {label} {kind.get('type')} {key} is not under the site URL: {v}")
                        elif row.get("term") == "@id" and v != site_url + rel:
                            found.append(f"{rel}: {label} {kind.get('type')} {key} is {v}, not this page")
                    if row.get("format") == "date" and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", v):
                        found.append(f"{rel}: {label} {kind.get('type')} {key} is not an ISO date: {v}")
            for row in rows:
                if row.tag != "list":
                    continue
                items = obj.get(row.get("as")) or []
                positions = [i.get("position") for i in items if isinstance(i, dict)]
                if positions != list(range(1, len(items) + 1)):
                    found.append(f"{rel}: {label} {kind.get('type')} positions are {positions}, not 1 to {len(items)}")
                for i in items:
                    if not i.get("name") or (site_url and not str(i.get("item", "")).startswith(site_url)):
                        found.append(f"{rel}: {label} {kind.get('type')} has an item with no name or an address outside the site")
                if items and site_url and items[-1].get("item") != site_url + rel:
                    found.append(f"{rel}: {label} {kind.get('type')} does not end at this page")
    return found


def check_page(path, rel, tables, site_url):
    head = Head()
    with open(path, encoding="utf-8") as f:
        head.feed(f.read())
    role = "cover" if rel == "index.html" else "utility" if rel in UTILITY else "topic"
    found = []
    for table in tables:
        if table.get("syntax") == "json-ld":
            found += check_jsonld(rel, head, table, role, site_url)
            continue
        for kind in table.findall("kind"):
            if kind.get("record") != "page" or not applies(kind, role):
                continue
            for row in kind:
                got = values(head, table, row)
                label = f"{table.get('id')} {row.get('as')}"
                if not got:
                    if row.get("required") == "yes" and (site_url or not is_uri(row)):
                        found.append(f"{rel}: no {label}")
                    continue
                if row.get("repeat") != "yes" and len(got) > 1:
                    found.append(f"{rel}: {label} written {len(got)} times")
                for v in got:
                    if is_uri(row) and not re.match(r"^[A-Za-z][A-Za-z0-9+.\-]*:\S+$", v):
                        found.append(f"{rel}: {label} is not an absolute URL: {v}")
                    if own_address(row):
                        if not site_url:
                            found.append(f"{rel}: {label} written without a site URL")
                        elif not v.startswith(site_url):
                            found.append(f"{rel}: {label} is not under the site URL: {v}")
                        elif row.get("term") == "@id" and v != site_url + rel:
                            found.append(f"{rel}: {label} is {v}, not this page")
                    if row.get("format") == "date" and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", v):
                        found.append(f"{rel}: {label} is not an ISO date: {v}")
                    if row.get("format") == "locale" and not re.fullmatch(r"[a-z]{2,3}(_[A-Z]{2}|_[A-Za-z0-9]{3,8})*", v):
                        found.append(f"{rel}: {label} is not a locale: {v}")
    return found


def check_print(path, rel, names, what="the print document"):
    head = Head()
    with open(path, encoding="utf-8") as f:
        head.feed(f.read())
    written = {("meta", n) for _, n, _ in head.metas} | {("link", r) for r, _ in head.links}
    if head.jsonld:
        return [f"{rel}: {what} carries a JSON-LD block"] + [f"{rel}: {what} carries {name}" for syntax, name in sorted(names)
                if (syntax, name) in written]
    return [f"{rel}: {what} carries {name}" for syntax, name in sorted(names)
            if (syntax, name) in written]


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--tables", default="",
                        help="the plugin's resource/metadata folder; found for you when the checker "
                             "is in a checkout of the repository or the plugin is installed")
    parser.add_argument("--dita-dir", default="",
                        help="a DITA-OT installation to take the plugin's tables from "
                             "(else DITA_HOME, else the toolkit of the dita command on the PATH)")
    parser.add_argument("--level", default="basic", help="the govuk.metadata level the sites were built with")
    parser.add_argument("--site-url", default="", help="the govuk.site.url the sites were built with")
    parser.add_argument("sites", nargs="+")
    args = parser.parse_args()
    site_url = args.site_url
    if site_url and not site_url.endswith("/"):
        site_url += "/"
    directory, looked = find_tables(args.tables, args.dita_dir)
    if not has_tables(directory):
        print("check_metadata: cannot find the plugin's mapping tables (schemes.xml)"
              + (f": there is none in {args.tables}." if args.tables
                 else ". Looked in:\n  " + "\n  ".join(os.path.normpath(d) for d in looked))
              + "\nGive the folder with --tables, usually "
              f"<DITA-OT>/plugins/{PLUGIN}/resource/metadata, or the toolkit with --dita-dir.",
              file=sys.stderr)
        return 2
    tables = load_tables(directory, args.level) if args.level != "no" else []
    names = all_names(directory)
    findings, pages = [], 0
    for site in args.sites:
        for root, _, files in os.walk(site):
            for name in sorted(files):
                if not name.endswith(".html"):
                    continue
                path = os.path.join(root, name)
                rel = os.path.relpath(path, site).replace(os.sep, "/")
                if rel.startswith(("pagefind/", "govuk/")):
                    continue
                pages += 1
                if re.fullmatch(r"print(-[^/]*)?\.html", rel):
                    findings += [f"{site}/{x}" for x in check_print(path, rel, names)]
                elif tables:
                    findings += [f"{site}/{x}" for x in check_page(path, rel, tables, site_url)]
                else:
                    findings += [f"{site}/{x}" for x in check_print(path, rel, names, f"a page built with level {args.level}")]
    for f in findings:
        print(f)
    print(f"check_metadata: {pages} pages, {len(findings)} findings ({args.level}"
          f"{', ' + site_url if site_url else ', no site URL'})")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

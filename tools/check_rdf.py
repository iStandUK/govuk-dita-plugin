#!/usr/bin/env python3
"""RDF checker for the files the plugin writes (#102).

Parses each Turtle (.ttl) and JSON-LD (.jsonld) file with an independent RDF
library, so a file that is merely well-formed text but not RDF is found, and
compares the two serialisations of one record, which are written from the same
graph and must be the same graph:

  check_rdf.py out/site/dcat.ttl out/site/dcat.jsonld

Files are paired by name without the extension; a pair must give isomorphic
graphs. Needs rdflib (tools/ci/requirements-rdf.txt pins it, with hashes); the
plugin's build does not.

  --expect-type TYPE   every file must hold a subject of this type, written as
                       a full IRI or as dcat:Dataset-style (dcat, dct, foaf,
                       vcard, adms, skos, rdf)

Prints one line a file and exits non-zero on any finding.
"""
import argparse
import os
import sys

try:
    from rdflib import Graph, URIRef
    from rdflib.compare import isomorphic
except ImportError:
    sys.exit("check_rdf: rdflib is not installed (tools/ci/requirements-rdf.txt)")

PREFIXES = {
    "dcat": "http://www.w3.org/ns/dcat#", "dct": "http://purl.org/dc/terms/",
    "foaf": "http://xmlns.com/foaf/0.1/", "vcard": "http://www.w3.org/2006/vcard/ns#",
    "adms": "http://www.w3.org/ns/adms#", "skos": "http://www.w3.org/2004/02/skos/core#",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
}
RDF_TYPE = URIRef(PREFIXES["rdf"] + "type")
FORMATS = {".ttl": "turtle", ".jsonld": "json-ld"}


def expand(name):
    prefix, _, local = name.partition(":")
    return URIRef(PREFIXES[prefix] + local) if prefix in PREFIXES and local else URIRef(name)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--expect-type", action="append", default=[])
    parser.add_argument("files", nargs="+")
    args = parser.parse_args()
    findings, graphs = [], {}
    for path in args.files:
        stem, ext = os.path.splitext(path)
        if ext not in FORMATS:
            findings.append(f"{path}: not a .ttl or .jsonld file")
            continue
        try:
            g = Graph().parse(path, format=FORMATS[ext])
        except Exception as e:  # rdflib raises many kinds
            findings.append(f"{path}: does not parse as {FORMATS[ext]}: {e}")
            continue
        graphs.setdefault(stem, {})[ext] = g
        print(f"{path}: {len(g)} triples, {len(set(g.subjects()))} subjects")
        for want in args.expect_type:
            if (None, RDF_TYPE, expand(want)) not in g:
                findings.append(f"{path}: no subject of type {want}")
    for stem, by_ext in sorted(graphs.items()):
        if len(by_ext) == 2 and not isomorphic(by_ext[".ttl"], by_ext[".jsonld"]):
            only_ttl = len(set(by_ext[".ttl"]) - set(by_ext[".jsonld"]))
            only_json = len(set(by_ext[".jsonld"]) - set(by_ext[".ttl"]))
            findings.append(f"{stem}: the Turtle and the JSON-LD are different graphs "
                            f"({only_ttl} triples only in Turtle, {only_json} only in JSON-LD)")
    for f in findings:
        print(f)
    print(f"check_rdf: {len(args.files)} files, {len(findings)} findings")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentCatalog;
import org.apache.pdfbox.pdmodel.documentinterchange.logicalstructure.PDAttributeObject;
import org.apache.pdfbox.pdmodel.documentinterchange.logicalstructure.PDStructureElement;
import org.apache.pdfbox.pdmodel.documentinterchange.logicalstructure.PDStructureNode;
import org.apache.pdfbox.pdmodel.documentinterchange.logicalstructure.Revisions;
import org.apache.pdfbox.pdmodel.interactive.documentnavigation.outline.PDOutlineItem;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 * What a reader with assistive technology relies on in the PDF, compared with
 * the print document it was made from (#164). veraPDF checks that the PDF is
 * well formed for PDF/UA; this checks that it says what the source says:
 *
 * <ul>
 * <li>the document's language, and every other language a passage is marked with;
 * <li>the title the reader announces: the cover's heading, shown in place of the file name;
 * <li>the headings, level for level and in order;
 * <li>every figure, with the alternative text its source gives;
 * <li>every table, and every header cell with the scope a screen reader needs;
 * <li>the bookmarks, one for each chapter heading, with its words.
 * </ul>
 */
final class PdfStructure {

  private static final String XHTML = "http://www.w3.org/1999/xhtml";

  private PdfStructure() {
  }

  /** Where the PDF and its print document disagree; empty when they agree. */
  static List<String> problems(Path printDocument, Path pdf) throws Exception {
    Source source = new Source(Renderer.parse(Files.readAllBytes(printDocument)));
    List<String> problems = new ArrayList<>();
    try (PDDocument document = Loader.loadPDF(pdf.toFile())) {
      PDDocumentCatalog catalog = document.getDocumentCatalog();
      Tree tree = new Tree();
      tree.walk(catalog.getStructureTreeRoot());

      same(problems, "the document's language", source.language, catalog.getLanguage());
      TreeSet<String> languages = new TreeSet<>(source.otherLanguages);
      languages.removeAll(tree.languages);
      if (!languages.isEmpty()) {
        problems.add("passages marked in the source as " + languages + " have no language in the PDF");
      }

      same(problems, "the title", source.title, document.getDocumentInformation().getTitle());
      if (catalog.getViewerPreferences() == null || !catalog.getViewerPreferences().displayDocTitle()) {
        problems.add("a reader shows the file name, not the title: DisplayDocTitle is not set");
      }

      same(problems, "the headings, level by level", source.headings, tree.headings);

      List<String> wanted = sorted(source.alternatives);
      List<String> found = sorted(tree.alternatives);
      same(problems, "the figures' alternative text", wanted, found);

      same(problems, "the number of tables", source.tables, tree.tables);
      same(problems, "the number of header cells", source.headerCells, tree.headerCells);
      if (tree.headerCellsWithoutScope > 0) {
        problems.add(tree.headerCellsWithoutScope + " header cell(s) without a scope");
      }

      List<String> bookmarks = new ArrayList<>();
      if (catalog.getDocumentOutline() != null) {
        for (PDOutlineItem item : catalog.getDocumentOutline().children()) {
          bookmarks.add(normalise(item.getTitle()));
        }
      }
      same(problems, "the bookmarks for the chapters", source.chapters, bookmarks);
    }
    return problems;
  }

  private static void same(List<String> problems, String what, Object wanted, Object found) {
    if (!wanted.equals(found)) {
      problems.add(what + ": the source has " + wanted + " but the PDF has " + found);
    }
  }

  private static List<String> sorted(List<String> list) {
    List<String> copy = new ArrayList<>(list);
    Collections.sort(copy);
    return copy;
  }

  static String normalise(String s) {
    return s == null ? "" : s.replace(' ', ' ').replaceAll("\\s+", " ").trim();
  }

  /** What the print document says, as the generator reads it. */
  private static final class Source {
    final String language;
    final Set<String> otherLanguages = new TreeSet<>();
    String title = "";
    final List<String> headings = new ArrayList<>();
    final List<String> alternatives = new ArrayList<>();
    final List<String> chapters = new ArrayList<>();
    int tables;
    int headerCells;

    Source(Document html) {
      Element root = html.getDocumentElement();
      language = lang(root);
      String headTitle = "";
      for (Element e : elements(root)) {
        String name = e.getLocalName();
        String lang = lang(e);
        if (!lang.isEmpty() && !lang.equals(language) && !inHead(e)) {
          otherLanguages.add(lang);
        }
        if (name.equals("title") && inHead(e) && headTitle.isEmpty()) {
          headTitle = normalise(e.getTextContent());
        }
        if (name.matches("h[1-6]") && XHTML.equals(e.getNamespaceURI())) {
          headings.add("H" + name.charAt(1));
          if (name.equals("h1") && title.isEmpty() && insideClass(e, "app-print-cover")) {
            title = normalise(e.getTextContent());
          }
          if (name.equals("h2")) {
            chapters.add(normalise(e.getTextContent()));
          }
        }
        if (name.equals("table")) {
          tables++;
        }
        if (name.equals("th")) {
          headerCells++;
        }
        alternative(e);
      }
      if (title.isEmpty()) {
        title = headTitle;
      }
    }

    /** As the generator gives it: alt; or an inline drawing's aria-label, title or desc; or a formula's alttext. */
    private void alternative(Element e) {
      String name = e.getLocalName();
      boolean drawing = name.equals("svg") || name.equals("math");
      if (!name.equals("img") && !drawing || drawing && nested(e, name)) {
        return;
      }
      // an image on another origin is not fetched (DSPDF008W), so it is not in the PDF
      if (name.equals("img") && e.getAttribute("src").matches("(?i)^(https?:)?//.*")) {
        return;
      }
      String alt = e.getAttribute("alt");
      if (alt.isBlank()) {
        alt = e.getAttribute("aria-label");
      }
      if (alt.isBlank() && name.equals("math")) {
        alt = e.getAttribute("alttext");
      }
      if (alt.isBlank() && name.equals("svg")) {
        for (Node c = e.getFirstChild(); c != null && alt.isBlank(); c = c.getNextSibling()) {
          if (c instanceof Element child && (child.getLocalName().equals("title") || child.getLocalName().equals("desc"))) {
            alt = child.getTextContent();
          }
        }
      }
      alternatives.add(normalise(alt));
    }

    private static String lang(Element e) {
      String lang = e.getAttribute("lang");
      return lang.isEmpty() ? e.getAttributeNS("http://www.w3.org/XML/1998/namespace", "lang") : lang;
    }

    private static boolean inHead(Element e) {
      for (Node p = e.getParentNode(); p instanceof Element; p = p.getParentNode()) {
        if ("head".equals(p.getLocalName())) {
          return true;
        }
      }
      return false;
    }

    private static boolean nested(Element e, String name) {
      for (Node p = e.getParentNode(); p instanceof Element; p = p.getParentNode()) {
        if (name.equals(p.getLocalName())) {
          return true;
        }
      }
      return false;
    }

    private static boolean insideClass(Element e, String cls) {
      for (Node p = e; p instanceof Element; p = p.getParentNode()) {
        for (String c : ((Element) p).getAttribute("class").split("\\s+")) {
          if (c.equals(cls)) {
            return true;
          }
        }
      }
      return false;
    }

    private static List<Element> elements(Element root) {
      List<Element> all = new ArrayList<>();
      collect(root, all);
      return all;
    }

    private static void collect(Element e, List<Element> all) {
      all.add(e);
      for (Node c = e.getFirstChild(); c != null; c = c.getNextSibling()) {
        if (c instanceof Element child) {
          collect(child, all);
        }
      }
    }
  }

  /** What the PDF's structure tree says. */
  private static final class Tree {
    final Set<String> languages = new TreeSet<>();
    final List<String> headings = new ArrayList<>();
    final List<String> alternatives = new ArrayList<>();
    int tables;
    int headerCells;
    int headerCellsWithoutScope;

    void walk(PDStructureNode node) {
      if (node == null) {
        return;
      }
      for (Object kid : node.getKids()) {
        if (kid instanceof PDStructureElement e) {
          visit(e);
          walk(e);
        }
      }
    }

    private void visit(PDStructureElement e) {
      String type = e.getStructureType();
      if (e.getLanguage() != null) {
        languages.add(e.getLanguage());
      }
      if (type.matches("H[1-6]")) {
        headings.add(type);
      }
      switch (type) {
        case "Figure" -> alternatives.add(normalise(e.getAlternateDescription()));
        case "Table" -> tables++;
        case "TH" -> {
          headerCells++;
          if (!scoped(e.getAttributes())) {
            headerCellsWithoutScope++;
          }
        }
        default -> {
        }
      }
    }

    private static boolean scoped(Revisions<PDAttributeObject> attributes) {
      for (int i = 0; i < attributes.size(); i++) {
        if (attributes.getObject(i).getCOSObject().containsKey(COSName.getPDFName("Scope"))) {
          return true;
        }
      }
      return false;
    }
  }
}

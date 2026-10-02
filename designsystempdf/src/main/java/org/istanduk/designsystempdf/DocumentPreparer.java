/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Works on the parsed print document in memory, before layout. The file on
 * disk is never rewritten, and nothing is added that the document does not
 * already say: footnote bodies move from the end of their topic to where they
 * are called, so the engine can float them to the page foot; the publication
 * and chapter titles are repeated as running elements for the page margins;
 * the headings become the PDF outline; the cover supplies the PDF's title,
 * author and subject.
 */
final class DocumentPreparer {

  static final String XHTML = "http://www.w3.org/1999/xhtml";

  private final Document doc;
  private final Log log;

  DocumentPreparer(Document doc, Log log) {
    this.doc = doc;
    this.log = log;
  }

  void prepare(int outlineDepth, String css) {
    Element head = first(doc.getDocumentElement(), "head");
    Element body = first(doc.getDocumentElement(), "body");
    if (head == null || body == null) {
      return;
    }
    List<Element> all = descendants(body);
    footnotesToCallSites(all);
    alternativeText(all);
    metadata(head, all);
    runningElements(body, all);
    outline(head, descendants(body), outlineDepth);
    stylesheets(head, css);
  }

  /**
   * The plugin writes each topic's footnotes as endnotes: a call
   * {@code <a name="X-fnsrc_N" href="#X-fntarg_N">} in the text and the body in
   * {@code div.app-print-endnotes > div.fn} opening with the reverse link. A
   * paged engine floats a footnote from where it stands, so each body that has
   * a call moves to it. A footnote that is only referenced from elsewhere
   * (DITA's use-by-reference) has no call of its own and stays an endnote.
   */
  private void footnotesToCallSites(List<Element> all) {
    Map<String, Element> named = new HashMap<>();
    for (Element e : all) {
      if (e.getLocalName().equals("a") && e.hasAttribute("name")) {
        named.putIfAbsent(e.getAttribute("name"), e);
      }
    }
    int moved = 0;
    for (Element endnotes : all) {
      if (!hasClass(endnotes, "app-print-endnotes")) {
        continue;
      }
      for (Element fn : childElements(endnotes)) {
        Element back = firstChildElement(fn);
        if (back == null || !back.getLocalName().equals("a") || !back.getAttribute("href").startsWith("#")) {
          continue;
        }
        Element call = named.get(back.getAttribute("href").substring(1));
        if (call == null || isInside(call, endnotes)) {
          continue;
        }
        Element note = doc.createElementNS(XHTML, "div");
        note.setAttribute("class", "app-pdf-footnote");
        while (fn.getFirstChild() != null) {
          note.appendChild(fn.getFirstChild());
        }
        call.getParentNode().insertBefore(note, call.getNextSibling());
        endnotes.removeChild(fn);
        moved++;
      }
      if (firstChildElement(endnotes) == null) {
        endnotes.getParentNode().removeChild(endnotes);
      }
    }
    if (moved > 0) {
      log.info(moved + " footnote(s) placed at the page foot");
    }
  }

  /**
   * A tagged PDF takes a figure's alternative text from an alt attribute. Inline
   * diagrams and formulas carry theirs as aria-label, a title child or alttext,
   * so that is copied across; a figure with none is reported, never given
   * invented words.
   */
  private void alternativeText(List<Element> all) {
    Map<String, Integer> without = new TreeMap<>();
    for (Element e : all) {
      String name = e.getLocalName();
      boolean drawing = name.equals("svg") || name.equals("math");
      if (!drawing && !name.equals("img")) {
        continue;
      }
      if (drawing && isNested(e, name)) {
        continue;
      }
      if (!e.getAttribute("alt").isBlank()) {
        continue;
      }
      String alt = e.getAttribute("aria-label");
      if (alt.isBlank() && name.equals("math")) {
        alt = e.getAttribute("alttext");
      }
      if (alt.isBlank() && name.equals("svg")) {
        for (Element child : childElements(e)) {
          if (child.getLocalName().equals("title") || child.getLocalName().equals("desc")) {
            alt = text(child);
            if (!alt.isBlank()) {
              break;
            }
          }
        }
      }
      if (alt.isBlank()) {
        without.merge(name.equals("img") ? "image" : name.equals("svg") ? "diagram" : "formula", 1, Integer::sum);
      } else {
        e.setAttribute("alt", alt.trim());
      }
    }
    if (!without.isEmpty()) {
      List<String> kinds = new ArrayList<>();
      without.forEach((kind, n) -> kinds.add(n + " " + kind + (n == 1 ? "" : "s")));
      log.warn(Log.ALT, String.join(", ", kinds) + " with no alternative text, so the PDF will not meet PDF/UA."
          + " Give each one alternative text in the source: alt on an image, a title in an SVG diagram,"
          + " alttext on a MathML formula.");
    }
  }

  private static boolean isNested(Element e, String name) {
    for (Node p = e.getParentNode(); p instanceof Element; p = p.getParentNode()) {
      if (name.equals(p.getLocalName())) {
        return true;
      }
    }
    return false;
  }

  /** The PDF's title, author and subject come from the cover; the head's own values are the fallback. */
  private void metadata(Element head, List<Element> all) {
    Element cover = firstWithClass(all, "app-print-cover");
    if (cover == null) {
      return;
    }
    for (Element e : descendants(cover)) {
      String text = text(e);
      if (text.isEmpty()) {
        continue;
      }
      if (e.getLocalName().equals("h1")) {
        Element title = first(head, "title");
        if (title == null) {
          title = (Element) head.appendChild(doc.createElementNS(XHTML, "title"));
        }
        title.setTextContent(text);
      } else if (hasClass(e, "app-attribution")) {
        meta(head, "author", text);
      } else if (hasClass(e, "govuk-body-l")) {
        meta(head, "subject", text);
        meta(head, "description", text);
      }
    }
  }

  private void meta(Element head, String name, String content) {
    for (Element m : childElements(head)) {
      if (m.getLocalName().equals("meta") && name.equals(m.getAttribute("name"))) {
        return;
      }
    }
    Element m = doc.createElementNS(XHTML, "meta");
    m.setAttribute("name", name);
    m.setAttribute("content", content);
    head.appendChild(m);
  }

  /**
   * The engine has running elements but not string-set, so the titles the page
   * margins show are repeated as elements: the publication title once, and
   * each chapter-level part's title where the part begins.
   */
  private void runningElements(Element body, List<Element> all) {
    Element title = first(first(doc.getDocumentElement(), "head"), "title");
    if (title != null && !text(title).isEmpty()) {
      body.insertBefore(running("app-pdf-running-title", text(title)), body.getFirstChild());
    }
    for (Element part : all) {
      if (!hasClass(part, "app-print-chapter") && !hasClass(part, "app-print-part")) {
        continue;
      }
      for (Element e : descendants(part)) {
        if (headingLevel(e) > 0) {
          part.insertBefore(running("app-pdf-running-section", text(e)), part.getFirstChild());
          break;
        }
      }
    }
  }

  private Element running(String cls, String text) {
    Element e = doc.createElementNS(XHTML, "div");
    e.setAttribute("class", "app-pdf-running " + cls);
    e.setTextContent(text);
    return e;
  }

  /** Headings below the cover become the outline, nested by heading level down to the depth asked for. */
  private void outline(Element head, List<Element> all, int depth) {
    Element bookmarks = doc.createElementNS(XHTML, "bookmarks");
    Deque<Element> parents = new ArrayDeque<>();
    Deque<Integer> levels = new ArrayDeque<>();
    TreeSet<String> ids = new TreeSet<>();
    for (Element e : all) {
      if (e.hasAttribute("id")) {
        ids.add(e.getAttribute("id"));
      }
    }
    int generated = 0;
    int count = 0;
    for (Element e : all) {
      int level = headingLevel(e);
      // h1 is the cover; the outline starts at the parts beneath it
      if (level < 2 || level > depth + 1 || text(e).isEmpty()
          || hasAncestorWithClass(e, "app-print-screen-only") || hasAncestorWithClass(e, "app-pdf-footnote")) {
        continue;
      }
      if (!e.hasAttribute("id")) {
        String id;
        do {
          id = "app-pdf-h" + (++generated);
        } while (!ids.add(id));
        e.setAttribute("id", id);
      }
      while (!levels.isEmpty() && levels.peek() >= level) {
        levels.pop();
        parents.pop();
      }
      Element bookmark = doc.createElementNS(XHTML, "bookmark");
      bookmark.setAttribute("name", text(e));
      bookmark.setAttribute("href", "#" + e.getAttribute("id"));
      (parents.isEmpty() ? bookmarks : parents.peek()).appendChild(bookmark);
      parents.push(bookmark);
      levels.push(level);
      count++;
    }
    if (count > 0) {
      head.appendChild(bookmarks);
    }
  }

  /** The product's stylesheet and the page rules from the command line follow the document's own. */
  private void stylesheets(Element head, String css) {
    Element style = doc.createElementNS(XHTML, "style");
    style.setAttribute("type", "text/css");
    style.setTextContent(css);
    head.appendChild(style);
  }

  /** Characters in the document's text, for the missing-glyph report. */
  static TreeSet<Integer> codePoints(Document doc) {
    TreeSet<Integer> found = new TreeSet<>();
    Element body = first(doc.getDocumentElement(), "body");
    collect(body == null ? doc.getDocumentElement() : body, found);
    return found;
  }

  private static void collect(Node n, TreeSet<Integer> found) {
    for (Node c = n.getFirstChild(); c != null; c = c.getNextSibling()) {
      if (c.getNodeType() == Node.TEXT_NODE || c.getNodeType() == Node.CDATA_SECTION_NODE) {
        c.getNodeValue().codePoints().filter(cp -> !Character.isWhitespace(cp) && !Character.isISOControl(cp))
            .forEach(found::add);
      } else if (c.getNodeType() == Node.ELEMENT_NODE) {
        String name = c.getLocalName() == null ? c.getNodeName() : c.getLocalName();
        // drawings carry their own text handling; scripts and styles are not shown
        if (!name.equals("svg") && !name.equals("math") && !name.equals("script") && !name.equals("style")) {
          collect(c, found);
        }
      }
    }
  }

  // --- small DOM helpers; the print document is XHTML, so names are compared without prefixes ---

  private static int headingLevel(Element e) {
    String n = e.getLocalName();
    if (n.length() == 2 && n.charAt(0) == 'h' && n.charAt(1) >= '1' && n.charAt(1) <= '6') {
      // nesting beyond six levels keeps the h6 element with the true level in aria-level
      String aria = e.getAttribute("aria-level");
      return aria.matches("[0-9]{1,2}") ? Integer.parseInt(aria) : n.charAt(1) - '0';
    }
    if ("heading".equals(e.getAttribute("role")) && e.getAttribute("aria-level").matches("[0-9]{1,2}")) {
      return Integer.parseInt(e.getAttribute("aria-level"));
    }
    return 0;
  }

  static boolean hasClass(Element e, String cls) {
    String c = e.getAttribute("class");
    return !c.isEmpty() && (" " + c + " ").contains(" " + cls + " ");
  }

  private static boolean hasAncestorWithClass(Element e, String cls) {
    for (Node p = e; p instanceof Element; p = p.getParentNode()) {
      if (hasClass((Element) p, cls)) {
        return true;
      }
    }
    return false;
  }

  private static boolean isInside(Node n, Element ancestor) {
    for (Node p = n; p != null; p = p.getParentNode()) {
      if (p == ancestor) {
        return true;
      }
    }
    return false;
  }

  private static Element firstWithClass(List<Element> all, String cls) {
    for (Element e : all) {
      if (hasClass(e, cls)) {
        return e;
      }
    }
    return null;
  }

  static Element first(Element parent, String localName) {
    if (parent == null) {
      return null;
    }
    for (Element e : childElements(parent)) {
      if (e.getLocalName().equals(localName)) {
        return e;
      }
    }
    return null;
  }

  private static Element firstChildElement(Element parent) {
    List<Element> c = childElements(parent);
    return c.isEmpty() ? null : c.get(0);
  }

  private static List<Element> childElements(Element parent) {
    List<Element> out = new ArrayList<>();
    for (Node c = parent.getFirstChild(); c != null; c = c.getNextSibling()) {
      if (c.getNodeType() == Node.ELEMENT_NODE) {
        out.add((Element) c);
      }
    }
    return out;
  }

  /** Every element beneath the parent, in document order (a snapshot, safe to edit the tree against). */
  private static List<Element> descendants(Element parent) {
    NodeList live = parent.getElementsByTagNameNS("*", "*");
    List<Element> out = new ArrayList<>(live.getLength());
    for (int i = 0; i < live.getLength(); i++) {
      out.add((Element) live.item(i));
    }
    return out;
  }

  private static String text(Element e) {
    return e.getTextContent().replaceAll("\\s+", " ").trim();
  }
}

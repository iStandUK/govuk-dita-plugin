/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

class DocumentPreparerTest {

  private Document doc;
  private ByteArrayOutputStream messages;

  @BeforeEach
  void prepare() throws Exception {
    try (InputStream is = DocumentPreparerTest.class.getResourceAsStream("sample-print.html")) {
      doc = Renderer.parse(is.readAllBytes());
    }
    messages = new ByteArrayOutputStream();
    new DocumentPreparer(doc, new Log(new PrintStream(messages, true, StandardCharsets.UTF_8), false))
        .prepare(3, "/* product css */");
  }

  @Test
  void aFootnoteWithACallMovesToItsCall() {
    List<Element> notes = withClass("app-pdf-footnote");
    assertEquals(1, notes.size());
    Element note = notes.get(0);
    assertTrue(note.getTextContent().contains("The text of the footnote."));
    // straight after the call, inside the paragraph that makes it
    Node before = note.getPreviousSibling();
    assertEquals("a", before.getLocalName());
    assertEquals("t1-fnsrc_1", ((Element) before).getAttribute("name"));
    assertEquals("p", note.getParentNode().getLocalName());
  }

  @Test
  void aFootnoteUsedOnlyByReferenceStaysAnEndnote() {
    List<Element> endnotes = withClass("app-print-endnotes");
    assertEquals(1, endnotes.size());
    assertTrue(endnotes.get(0).getTextContent().contains("A footnote used only by reference."));
    assertFalse(endnotes.get(0).getTextContent().contains("The text of the footnote."));
  }

  @Test
  void thePdfTakesItsTitleAuthorAndSubjectFromTheCover() {
    Element head = DocumentPreparer.first(doc.getDocumentElement(), "head");
    assertEquals("Sample publication", DocumentPreparer.first(head, "title").getTextContent());
    assertEquals("Example Organisation", meta("author"));
    assertEquals("A short publication used to test the generator.", meta("subject"));
    assertEquals("A short publication used to test the generator.", meta("description"));
  }

  @Test
  void titlesAreRepeatedAsRunningElements() {
    List<Element> title = withClass("app-pdf-running-title");
    assertEquals(1, title.size());
    assertEquals("Sample publication", title.get(0).getTextContent());
    assertEquals("body", title.get(0).getParentNode().getLocalName());
    List<String> sections = new ArrayList<>();
    for (Element e : withClass("app-pdf-running-section")) {
      sections.add(e.getTextContent());
      // the first thing in its part, so the part's first page shows it
      assertEquals(e, firstElement(e.getParentNode()));
    }
    assertEquals(List.of("The first chapter", "The second chapter", "Glossary", "Index"), sections);
  }

  @Test
  void headingsBecomeTheOutline() {
    Element head = DocumentPreparer.first(doc.getDocumentElement(), "head");
    Element bookmarks = DocumentPreparer.first(head, "bookmarks");
    assertNotNull(bookmarks);
    List<String> top = new ArrayList<>();
    for (Node n = bookmarks.getFirstChild(); n != null; n = n.getNextSibling()) {
      top.add(((Element) n).getAttribute("name"));
    }
    // the cover's h1 is not in the outline; the parts beneath it are
    assertEquals(List.of("Contents", "The first chapter", "The second chapter", "Glossary", "Index"), top);
    Element first = (Element) bookmarks.getChildNodes().item(1);
    assertEquals("#t1-title", first.getAttribute("href"));
    assertEquals("A section", ((Element) first.getFirstChild()).getAttribute("name"));
    // a heading with no id is given one to point at
    Element second = (Element) bookmarks.getChildNodes().item(2);
    String href = second.getAttribute("href");
    assertTrue(href.startsWith("#app-pdf-h"), href);
    assertNotNull(byId(href.substring(1)));
  }

  @Test
  void theOutlineStopsAtTheDepthAsked() throws Exception {
    try (InputStream is = DocumentPreparerTest.class.getResourceAsStream("sample-print.html")) {
      doc = Renderer.parse(is.readAllBytes());
    }
    new DocumentPreparer(doc, new Log(new PrintStream(messages), false)).prepare(1, "");
    Element bookmarks = DocumentPreparer.first(DocumentPreparer.first(doc.getDocumentElement(), "head"), "bookmarks");
    for (Node n = bookmarks.getFirstChild(); n != null; n = n.getNextSibling()) {
      assertFalse(n.hasChildNodes(), ((Element) n).getAttribute("name"));
    }
  }

  @Test
  void anInlineDiagramCarriesItsLabelAsAlternativeText() {
    Element svg = (Element) doc.getElementsByTagNameNS("http://www.w3.org/2000/svg", "svg").item(0);
    assertEquals("A box labelled Start", svg.getAttribute("alt"));
    assertEquals("", messages.toString(StandardCharsets.UTF_8));
  }

  @Test
  void aFigureWithNoAlternativeTextIsReportedNotInvented() throws Exception {
    String xhtml = "<html xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>t</title></head><body>"
        + "<img src=\"a.png\"/><img src=\"b.png\" alt=\"\"/>"
        + "<math xmlns=\"http://www.w3.org/1998/Math/MathML\"><mi>x</mi></math>"
        + "<math xmlns=\"http://www.w3.org/1998/Math/MathML\" alttext=\"x squared\"><mi>x</mi></math>"
        + "<svg xmlns=\"http://www.w3.org/2000/svg\"><title>A titled diagram</title></svg></body></html>";
    Document d = Renderer.parse(xhtml.getBytes(StandardCharsets.UTF_8));
    new DocumentPreparer(d, new Log(new PrintStream(messages, true, StandardCharsets.UTF_8), false)).prepare(3, "");
    String out = messages.toString(StandardCharsets.UTF_8);
    assertTrue(out.startsWith("[DSPDF009W]: 1 formula, 2 images with no alternative text"), out);
    NodeList maths = d.getElementsByTagNameNS("http://www.w3.org/1998/Math/MathML", "math");
    assertFalse(((Element) maths.item(0)).hasAttribute("alt"));
    assertEquals("x squared", ((Element) maths.item(1)).getAttribute("alt"));
    assertEquals("A titled diagram", ((Element) d.getElementsByTagNameNS("http://www.w3.org/2000/svg", "svg").item(0)).getAttribute("alt"));
  }

  @Test
  void theProductStylesheetFollowsTheDocumentsOwn() {
    Element head = DocumentPreparer.first(doc.getDocumentElement(), "head");
    Element last = null;
    for (Node n = head.getFirstChild(); n != null; n = n.getNextSibling()) {
      if (n instanceof Element) {
        last = (Element) n;
      }
    }
    assertNotNull(last);
    assertEquals("style", last.getLocalName());
    assertEquals("/* product css */", last.getTextContent());
  }

  @Test
  void theTextsCharactersAreCollectedForTheGlyphReport() {
    assertTrue(DocumentPreparer.codePoints(doc).contains((int) 'ŵ'));
    assertTrue(DocumentPreparer.codePoints(doc).contains(0x2192));
    // white space needs no glyph
    assertFalse(DocumentPreparer.codePoints(doc).contains((int) ' '));
  }

  private String meta(String name) {
    NodeList metas = doc.getElementsByTagNameNS("*", "meta");
    for (int i = 0; i < metas.getLength(); i++) {
      Element m = (Element) metas.item(i);
      if (name.equals(m.getAttribute("name"))) {
        return m.getAttribute("content");
      }
    }
    return null;
  }

  private List<Element> withClass(String cls) {
    List<Element> out = new ArrayList<>();
    NodeList all = doc.getElementsByTagNameNS("*", "*");
    for (int i = 0; i < all.getLength(); i++) {
      if (DocumentPreparer.hasClass((Element) all.item(i), cls)) {
        out.add((Element) all.item(i));
      }
    }
    return out;
  }

  private Element byId(String id) {
    NodeList all = doc.getElementsByTagNameNS("*", "*");
    for (int i = 0; i < all.getLength(); i++) {
      if (id.equals(((Element) all.item(i)).getAttribute("id"))) {
        return (Element) all.item(i);
      }
    }
    return null;
  }

  private static Element firstElement(Node parent) {
    for (Node n = parent.getFirstChild(); n != null; n = n.getNextSibling()) {
      if (n instanceof Element) {
        return (Element) n;
      }
    }
    return null;
  }
}

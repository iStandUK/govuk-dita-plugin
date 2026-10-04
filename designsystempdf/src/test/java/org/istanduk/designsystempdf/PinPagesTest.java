/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.openhtmltopdf.pdfboxout.PdfBoxRenderer;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;

/**
 * The contents page numbers written in for a long document (#182) are the
 * numbers target-counter paints: read from the layout, the page where each
 * target's content starts.
 */
class PinPagesTest {

  @Test
  void theNumbersWrittenInAreTheOnesTargetCounterPaints() throws Exception {
    Document doc;
    try (InputStream is = PinPagesTest.class.getResourceAsStream("sample-print.html")) {
      doc = Renderer.parse(is.readAllBytes());
    }

    // the numbers target-counter paints, read back from the contents page of an ordinary PDF
    ByteArrayOutputStream ordinary = new ByteArrayOutputStream();
    try (PdfBoxRenderer r = builder(doc, ordinary).buildPdfRenderer()) {
      r.layout();
      r.createPDF();
    }
    String contents;
    try (PDDocument pdf = Loader.loadPDF(ordinary.toByteArray())) {
      PDFTextStripper text = new PDFTextStripper();
      text.setStartPage(2);
      text.setEndPage(2);
      contents = text.getText(pdf);
    }

    // the numbers written in, from the layout alone
    boolean changed;
    try (PdfBoxRenderer r = builder(doc, new ByteArrayOutputStream()).buildPdfRenderer()) {
      r.layout();
      changed = Renderer.pinContentsPages(doc, r);
      assertFalse(Renderer.pinContentsPages(doc, r), "a second pass over the same layout moves nothing");
    }
    assertTrue(changed, "the contents entries take numbers");

    List<String> pinned = new ArrayList<>();
    NodeList links = doc.getElementsByTagNameNS(DocumentPreparer.XHTML, "a");
    for (int i = 0; i < links.getLength(); i++) {
      Element a = (Element) links.item(i);
      if (a.hasAttribute("data-pdf-page")) {
        String title = PdfStructure.normalise(a.getTextContent());
        pinned.add(title);
        String page = a.getAttribute("data-pdf-page");
        assertTrue(page.matches("[1-9][0-9]*"), title + ": " + page);
        // the contents line that target-counter painted ends in the same number
        assertTrue(contents.lines().anyMatch(line -> PdfStructure.normalise(line).startsWith(title)
                                                     && PdfStructure.normalise(line).endsWith(" " + page)),
            title + " should read page " + page + " in:\n" + contents);
      }
    }
    assertTrue(pinned.size() >= 3, "every contents entry with a page reference: " + pinned);
  }

  private static PdfRendererBuilder builder(Document doc, java.io.OutputStream os) {
    PdfRendererBuilder builder = new PdfRendererBuilder();
    builder.withW3cDocument(doc, PinPagesTest.class.getResource("sample-print.html").toString());
    builder.toStream(os);
    return builder;
  }
}

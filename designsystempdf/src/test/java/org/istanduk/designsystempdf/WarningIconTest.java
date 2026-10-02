/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * The Design System's warning text puts its icon beside the first line by
 * absolute positioning with no offset, which the engine places far higher
 * than a browser does; pdf.css corrects it. The rules below are the Design
 * System's own for the component, with the print document's text size.
 */
class WarningIconTest {

  private static final String DESIGN_SYSTEM = ""
      + ".govuk-warning-text { font-family: sans-serif; font-weight: 700; font-size: 12pt; line-height: 1.15;"
      + "  position: relative; margin-bottom: 20px; padding: 10px 0 }"
      + ".govuk-warning-text__icon { box-sizing: border-box; display: inline-block; position: absolute; left: 0;"
      + "  min-width: 35px; min-height: 35px; margin-top: -7px; border: 3px solid #0b0c0c; border-radius: 50%;"
      + "  color: #fff; background: #0b0c0c; font-size: 30px; line-height: 29px; text-align: center }"
      + ".govuk-warning-text__text { display: block; padding-left: 45px }"
      + "p { font-family: sans-serif; font-size: 12pt; line-height: 1.15; margin: 0 0 15px }";

  @TempDir
  Path dir;

  /** Where each character was drawn: its baseline, measured down the page, and its size. */
  private static final class Glyphs extends PDFTextStripper {
    final List<TextPosition> seen = new ArrayList<>();

    @Override
    protected void writeString(String text, List<TextPosition> positions) throws IOException {
      seen.addAll(positions);
      super.writeString(text, positions);
    }

    TextPosition first(String character, boolean large) {
      for (TextPosition p : seen) {
        if (p.getUnicode().equals(character) && (p.getFontSizeInPt() > 20) == large) {
          return p;
        }
      }
      throw new AssertionError("no " + (large ? "large " : "") + "'" + character + "' on the page");
    }
  }

  @Test
  void theIconIsLevelWithTheFirstLineOfItsWarning() throws IOException {
    Path doc = dir.resolve("warning.html");
    Files.writeString(doc, "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\"><head><title>Warning</title>"
        + "<meta name=\"description\" content=\"Warning\"/><style>" + DESIGN_SYSTEM + "</style></head><body>"
        + "<p>A paragraph before the warning.</p>"
        + "<div class=\"govuk-warning-text\"><span class=\"govuk-warning-text__icon\" aria-hidden=\"true\">!</span>"
        + "<strong class=\"govuk-warning-text__text\">Zero tolerance: the first line of a warning that runs on to a"
        + " second line, so that the icon has two lines to be level with the first of.</strong></div>"
        + "<p>A paragraph after it.</p></body></html>");
    Path pdf = dir.resolve("warning.pdf");
    ByteArrayOutputStream err = new ByteArrayOutputStream();
    assertEquals(Main.OK, Main.run(new String[] {"--in", doc.toString(), "--out", pdf.toString()},
        new PrintStream(new ByteArrayOutputStream(), true, StandardCharsets.UTF_8),
        new PrintStream(err, true, StandardCharsets.UTF_8)));
    assertEquals("", err.toString(StandardCharsets.UTF_8));

    try (PDDocument rendered = Loader.loadPDF(pdf.toFile())) {
      Glyphs glyphs = new Glyphs();
      glyphs.getText(rendered);
      TextPosition mark = glyphs.first("!", true);
      TextPosition line = glyphs.first("Z", false);
      TextPosition before = glyphs.first("A", false);
      // The mark is nearly twice the size of the text, so centred on the first
      // line its baseline falls a little below the line's; set where the engine
      // would put it unaided, it stands above the line altogether.
      float below = mark.getYDirAdj() - line.getYDirAdj();
      assertTrue(below > 3 && below < 12, "the mark's baseline is " + below + "pt below the first line's");
      // and the icon keeps clear of the paragraph before it
      float markTop = mark.getYDirAdj() - mark.getFontSizeInPt();
      assertTrue(markTop > before.getYDirAdj(), "the mark starts " + (before.getYDirAdj() - markTop) + "pt into the paragraph before");
    }
  }
}

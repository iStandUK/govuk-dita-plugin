/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Paths;
import java.time.Instant;

import org.junit.jupiter.api.Test;

class OptionsTest {

  private static Options parse(String... args) {
    return Options.parse(args, null);
  }

  @Test
  void namedInputAndOutput() {
    Options o = parse("--in", "print.html", "--out", "book.pdf");
    assertEquals(Paths.get("print.html"), o.in);
    assertEquals(Paths.get("book.pdf"), o.out);
    assertTrue(o.pdfUa);
    assertFalse(o.doubleSided);
    assertEquals("standard", o.margins);
    assertEquals(3, o.tocDepth);
    assertNull(o.paper);
    assertNull(o.fixedDate);
  }

  @Test
  void theLastTwoArgumentsAreTheDocumentAndThePdf() {
    // how the plugin's govuk.pdf.command passes them
    Options o = parse("--paper", "A4", "out/print.html", "out/book.pdf");
    assertEquals(Paths.get("out/print.html"), o.in);
    assertEquals(Paths.get("out/book.pdf"), o.out);
    assertEquals("A4", o.paper);
  }

  @Test
  void everyOption() {
    Options o = parse("--in", "a", "--out", "b", "--paper", "Letter", "--orientation", "landscape",
        "--margins", "10mm 12mm", "--sides", "double", "--fonts", "brand", "--no-pdf-ua",
        "--fixed-date", "2026-10-01T09:30:00Z", "--toc-depth", "2", "--verbose");
    assertEquals("Letter", o.paper);
    assertTrue(o.namedPaper());
    assertEquals("landscape", o.orientation);
    assertEquals("10mm 12mm", o.margins);
    assertTrue(o.doubleSided);
    assertEquals(Paths.get("brand"), o.fonts);
    assertFalse(o.pdfUa);
    assertEquals(Instant.parse("2026-10-01T09:30:00Z"), o.fixedDate);
    assertEquals(2, o.tocDepth);
    assertTrue(o.verbose);
  }

  @Test
  void paperAsTwoLengths() {
    Options o = parse("--in", "a", "--out", "b", "--paper", "210mm 280mm");
    assertEquals("210mm 280mm", o.paper);
    assertFalse(o.namedPaper());
  }

  @Test
  void aDateWithoutATimeIsMidnightUtc() {
    assertEquals(Instant.parse("2026-10-01T00:00:00Z"), parse("--in", "a", "--out", "b", "--fixed-date", "2026-10-01").fixedDate);
  }

  @Test
  void sourceDateEpochIsTheDateWhenNoneIsGiven() {
    assertEquals(Instant.ofEpochSecond(1790000000L), Options.parse(new String[] {"--in", "a", "--out", "b"}, "1790000000").fixedDate);
    assertEquals(Instant.parse("2026-10-01T00:00:00Z"),
        Options.parse(new String[] {"--in", "a", "--out", "b", "--fixed-date", "2026-10-01"}, "1790000000").fixedDate);
  }

  @Test
  void versionAndHelpNeedNoFiles() {
    assertTrue(parse("--version").version);
    assertTrue(parse("--help").help);
  }

  @Test
  void whatIsWrongIsSaid() {
    assertUsage("both the print document", "--in", "a");
    assertUsage("unknown option: --bogus", "--bogus", "a", "b");
    assertUsage("--paper must be one of", "--in", "a", "--out", "b", "--paper", "A9");
    assertUsage("--orientation must be", "--in", "a", "--out", "b", "--paper", "A4", "--orientation", "sideways");
    assertUsage("--orientation needs --paper", "--in", "a", "--out", "b", "--orientation", "landscape");
    assertUsage("--margins must be", "--in", "a", "--out", "b", "--margins", "big");
    assertUsage("--sides must be", "--in", "a", "--out", "b", "--sides", "both");
    assertUsage("--toc-depth must be", "--in", "a", "--out", "b", "--toc-depth", "9");
    assertUsage("--fixed-date must be", "--in", "a", "--out", "b", "--fixed-date", "yesterday");
    assertUsage("--out needs a value", "--in", "a", "--out");
    assertUsage("unexpected argument", "a", "b", "c");
    UsageException e = assertThrows(UsageException.class, () -> Options.parse(new String[] {"--in", "a", "--out", "b"}, "soon"));
    assertTrue(e.getMessage().contains("SOURCE_DATE_EPOCH"));
  }

  private static void assertUsage(String expected, String... args) {
    UsageException e = assertThrows(UsageException.class, () -> parse(args));
    assertTrue(e.getMessage().contains(expected), e.getMessage());
  }
}

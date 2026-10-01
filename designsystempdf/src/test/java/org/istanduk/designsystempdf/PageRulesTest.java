/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class PageRulesTest {

  private static String css(String... args) {
    String[] all = new String[args.length + 4];
    System.arraycopy(new String[] {"--in", "a", "--out", "b"}, 0, all, 0, 4);
    System.arraycopy(args, 0, all, 4, args.length);
    return PageRules.css(Options.parse(all, null));
  }

  @Test
  void theDocumentsOwnPageRulesStandWhenNothingIsAsked() {
    assertEquals("", css());
  }

  @Test
  void aNamedPaperAndItsTurnedPage() {
    String css = css("--paper", "A5");
    assertTrue(css.contains("@page { size: A5 portrait; }"), css);
    assertTrue(css.contains("@page app-pdf-landscape { size: A5 landscape; }"), css);
    // the turned measure: 210 mm less the two 18 mm side margins
    assertTrue(css.contains(".landscape { width: 174.0mm; }"), css);
  }

  @Test
  void aLandscapePublicationNeedsNoTurnedMeasure() {
    String css = css("--paper", "A4", "--orientation", "landscape");
    assertTrue(css.contains("@page { size: A4 landscape; }"), css);
    assertTrue(css.contains(".landscape { width: auto; }"), css);
  }

  @Test
  void explicitLengthsSwapForTheTurnedPage() {
    String css = css("--paper", "210mm 280mm");
    assertTrue(css.contains("@page { size: 210mm 280mm; }"), css);
    assertTrue(css.contains("@page app-pdf-landscape { size: 280mm 210mm; }"), css);
    assertTrue(css.contains(".landscape { width: 244.0mm; }"), css);
  }

  @Test
  void doubleSidedMirrorsTheMarginsWithRoomForBinding() {
    String css = css("--sides", "double");
    assertTrue(css.contains("@page { margin: 20mm 18mm 22mm 18mm; }"), css);
    assertTrue(css.contains("@page :right { margin-left: 25mm; margin-right: 18mm; }"), css);
    assertTrue(css.contains("@page :left { margin-left: 18mm; margin-right: 25mm; }"), css);
    // A4 by default: 297 mm less the inner and outer margins
    assertTrue(css.contains(".landscape { width: 254.0mm; }"), css);
  }

  @Test
  void marginsExpandAsTheCssShorthandDoes() {
    assertArrayEquals(new String[] {"10mm", "10mm", "10mm", "10mm"}, PageRules.margins("10mm"));
    assertArrayEquals(new String[] {"10mm", "12mm", "10mm", "12mm"}, PageRules.margins("10mm 12mm"));
    assertArrayEquals(new String[] {"10mm", "12mm", "14mm", "12mm"}, PageRules.margins("10mm 12mm 14mm"));
    assertArrayEquals(new String[] {"10mm", "12mm", "14mm", "16mm"}, PageRules.margins("10mm 12mm 14mm 16mm"));
    assertTrue(css("--margins", "1in").contains("@page { margin: 1in 1in 1in 1in; }"));
  }

  @Test
  void lengthsConvertToMillimetres() {
    assertEquals(25.4, PageRules.mm("1in"), 1e-9);
    assertEquals(20, PageRules.mm("2cm"), 1e-9);
    assertEquals(25.4, PageRules.mm("72pt"), 1e-9);
    assertEquals(12.5, PageRules.mm("12.5mm"), 1e-9);
  }
}

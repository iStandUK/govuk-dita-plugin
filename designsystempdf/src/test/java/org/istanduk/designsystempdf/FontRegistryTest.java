/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.List;

import org.junit.jupiter.api.Test;

/** Which faces stand in for a character its own font lacks, and what they cover. */
class FontRegistryTest {

  private static FontRegistry bundled() throws IOException {
    FontRegistry fonts = new FontRegistry(new Log(new PrintStream(new ByteArrayOutputStream(), true, StandardCharsets.UTF_8), false));
    fonts.addBundledFonts(Path.of(System.getProperty("designsystempdf.home"), "fonts"));
    return fonts;
  }

  @Test
  void oneUprightRegularFaceOfEachFamilyIsAFallback() throws IOException {
    List<FontRegistry.Face> fallback = bundled().fallbackFaces();
    assertEquals(2, fallback.size());
    assertEquals(FontRegistry.SANS, fallback.get(0).family);
    assertEquals(FontRegistry.MONO, fallback.get(1).family);
    for (FontRegistry.Face f : fallback) {
      assertEquals(400, f.weight, f.file.toString());
      assertFalse(f.italic, f.file.toString());
    }
  }

  @Test
  void coverageIsWhatTheFallbackFacesCanDraw() throws IOException {
    FontRegistry fonts = bundled();
    assertTrue(fonts.covers('A'));
    assertTrue(fonts.covers(0x03B1), "Greek small alpha");
    assertFalse(fonts.covers(0x0645), "Arabic meem: no bundled font has it");
  }
}

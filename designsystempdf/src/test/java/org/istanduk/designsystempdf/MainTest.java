/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;

class MainTest {

  private final ByteArrayOutputStream out = new ByteArrayOutputStream();
  private final ByteArrayOutputStream err = new ByteArrayOutputStream();

  private int run(String... args) {
    return Main.run(args, new PrintStream(out, true, StandardCharsets.UTF_8), new PrintStream(err, true, StandardCharsets.UTF_8));
  }

  @Test
  void versionIsFilledInByTheBuild() {
    assertEquals(Main.OK, run("--version"));
    String line = out.toString(StandardCharsets.UTF_8).trim();
    assertTrue(line.matches("DesignSystemPDF [0-9]+\\.[0-9]+\\.[0-9]+.*"), line);
    assertFalse(line.contains("${"), line);
  }

  @Test
  void helpIsTheUsageSummary() {
    assertEquals(Main.OK, run("--help"));
    assertTrue(out.toString(StandardCharsets.UTF_8).startsWith("Usage: designsystempdf"));
  }

  @Test
  void anythingElseIsAUsageError() {
    assertEquals(Main.USAGE, run("--in", "print.html", "--out", "book.pdf"));
    assertTrue(err.toString(StandardCharsets.UTF_8).startsWith("[DSPDF001E]: "));
  }
}

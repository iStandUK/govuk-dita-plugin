/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;
import org.verapdf.gf.foundry.VeraGreenfieldFoundryProvider;
import org.verapdf.pdfa.Foundries;
import org.verapdf.pdfa.PDFAParser;
import org.verapdf.pdfa.PDFAValidator;
import org.verapdf.pdfa.flavours.PDFAFlavour;
import org.verapdf.pdfa.results.TestAssertion;
import org.verapdf.pdfa.results.ValidationResult;

/**
 * Whole documents through the generator, with the output validated as
 * PDF/UA-1 by veraPDF. The bundled sample always runs. CI adds the print
 * documents the plugin builds from its manual and fixtures:
 *
 * <pre>
 * mvn verify -Ddesignsystempdf.it.documents=out/manual/print.html:out/kitchen/print.html
 * </pre>
 *
 * (entries separated by the platform's path separator), and may hand over
 * PDFs made elsewhere — by a toolkit build through the plugin — to be
 * validated only: {@code -Ddesignsystempdf.it.pdfs=out/manual/manual.pdf}.
 */
class RenderIT {

  private static Path output;

  @BeforeAll
  static void setUp() throws IOException {
    VeraGreenfieldFoundryProvider.initialise();
    output = Paths.get(System.getProperty("designsystempdf.it.output", "target/it"));
    Files.createDirectories(output);
  }

  @Test
  void theSampleIsValidPdfUa() throws Exception {
    Path sample = output.resolve("sample-print.html");
    try (InputStream is = RenderIT.class.getResourceAsStream("sample-print.html")) {
      Files.write(sample, is.readAllBytes());
    }
    Path pdf = output.resolve("sample.pdf");
    assertEquals("", render(sample, pdf));
    assertEquals(List.of(), failures(pdf));
    assertEquals(List.of(), PdfStructure.problems(sample, pdf), "the PDF says what the print document says");
  }

  /** The structure check is not a formality: a source that says something else is told apart (#164). */
  @Test
  void theStructureCheckNoticesADifference() throws Exception {
    Path sample = output.resolve("sample-print.html");
    try (InputStream is = RenderIT.class.getResourceAsStream("sample-print.html")) {
      Files.write(sample, is.readAllBytes());
    }
    Path pdf = output.resolve("sample-structure.pdf");
    render(sample, pdf);
    String html = Files.readString(sample, StandardCharsets.UTF_8);
    // one heading a level deeper, one figure described differently, the document in another language
    String other = html.replaceFirst("<h4", "<h5").replaceFirst("</h4>", "</h5>")
        .replaceFirst("aria-label=\"[^\"]+\"", "aria-label=\"Something else\"")
        .replaceFirst("lang=\"en-GB\"", "lang=\"cy\"");
    Path changed = output.resolve("sample-changed.html");
    Files.writeString(changed, other, StandardCharsets.UTF_8);
    List<String> problems = PdfStructure.problems(changed, pdf);
    assertTrue(problems.stream().anyMatch(p -> p.startsWith("the headings")), problems.toString());
    assertTrue(problems.stream().anyMatch(p -> p.startsWith("the figures' alternative text")), problems.toString());
    assertTrue(problems.stream().anyMatch(p -> p.startsWith("the document's language")), problems.toString());
    Files.delete(changed);
    Files.delete(pdf);
  }

  @TestFactory
  List<DynamicTest> printDocumentsRenderValidAndRepeatable() {
    List<DynamicTest> tests = new ArrayList<>();
    for (Path document : paths("designsystempdf.it.documents")) {
      String name = document.toAbsolutePath().getParent().getFileName() + "-" + document.getFileName();
      tests.add(DynamicTest.dynamicTest(name, () -> {
        Path first = output.resolve(name + ".pdf");
        Path second = output.resolve(name + ".again.pdf");
        String warnings = render(document, first);
        render(document, second);
        assertArrayEquals(Files.readAllBytes(first), Files.readAllBytes(second), "two runs must be byte-identical");
        Files.delete(second);
        try (PDDocument pdf = Loader.loadPDF(first.toFile())) {
          assertTrue(pdf.getNumberOfPages() >= 3, "cover, contents and content: " + pdf.getNumberOfPages() + " page(s)");
          assertNotNull(pdf.getDocumentCatalog().getDocumentOutline(), "the headings become an outline");
          assertNotNull(pdf.getDocumentCatalog().getDocumentOutline().getFirstChild());
          System.out.println(name + ": " + pdf.getNumberOfPages() + " pages");
        }
        assertEquals(List.of(), failures(first), "veraPDF PDF/UA-1" + (warnings.isEmpty() ? "" : "; the generator warned: " + warnings));
        assertEquals(List.of(), PdfStructure.problems(document, first), "the PDF says what the print document says");
      }));
    }
    return tests;
  }

  @TestFactory
  List<DynamicTest> pdfsMadeElsewhereAreValid() {
    List<DynamicTest> tests = new ArrayList<>();
    for (Path pdf : paths("designsystempdf.it.pdfs")) {
      tests.add(DynamicTest.dynamicTest(pdf.getFileName().toString(), () -> assertEquals(List.of(), failures(pdf), "veraPDF PDF/UA-1")));
    }
    return tests;
  }

  /**
   * Runs the generator as a publisher does — its own Java process, with the
   * built jar and the distribution's lib/ as the whole class path, so none of
   * the test libraries are there to change its behaviour — and returns what it
   * reported on standard error.
   */
  private static String render(Path document, Path pdf) throws IOException, InterruptedException {
    String classPath = System.getProperty("designsystempdf.it.jar") + File.pathSeparator
        + System.getProperty("designsystempdf.it.lib") + File.separator + "*";
    Path log = Files.createTempFile(output, "render", ".log");
    Process process = new ProcessBuilder(
        Paths.get(System.getProperty("java.home"), "bin", "java").toString(),
        "-Djava.awt.headless=true",
        "-Ddesignsystempdf.home=" + System.getProperty("designsystempdf.home"),
        "-cp", classPath, "org.istanduk.designsystempdf.Main",
        "--in", document.toString(), "--out", pdf.toString())
        .redirectOutput(ProcessBuilder.Redirect.DISCARD)
        .redirectError(log.toFile())
        .start();
    int exit = process.waitFor();
    String messages = Files.readString(log, StandardCharsets.UTF_8).trim();
    Files.delete(log);
    assertEquals(Main.OK, exit, messages);
    return messages;
  }

  /** The PDF/UA-1 rules the file breaks, each with a count and the first place it happens; empty when it conforms. */
  private static List<String> failures(Path pdf) throws Exception {
    PDFAFlavour flavour = PDFAFlavour.PDFUA_1;
    try (InputStream is = Files.newInputStream(pdf);
        PDFAParser parser = Foundries.defaultInstance().createParser(is, flavour);
        PDFAValidator validator = Foundries.defaultInstance().createValidator(flavour, false)) {
      ValidationResult result = validator.validate(parser);
      Map<String, Integer> counts = new TreeMap<>();
      Map<String, String> first = new TreeMap<>();
      for (TestAssertion assertion : result.getTestAssertions()) {
        if (assertion.getStatus() == TestAssertion.Status.FAILED) {
          String rule = assertion.getRuleId().getClause() + "-" + assertion.getRuleId().getTestNumber();
          counts.merge(rule, 1, Integer::sum);
          first.putIfAbsent(rule, assertion.getMessage());
        }
      }
      List<String> failures = new ArrayList<>();
      counts.forEach((rule, n) -> failures.add("rule " + rule + " x" + n + ": " + first.get(rule)));
      if (failures.isEmpty() && !result.isCompliant()) {
        failures.add("not compliant");
      }
      return failures;
    }
  }

  private static List<Path> paths(String property) {
    List<Path> paths = new ArrayList<>();
    String value = System.getProperty(property, "");
    for (String entry : value.split(File.pathSeparator)) {
      if (!entry.isBlank()) {
        Path p = Paths.get(entry.trim());
        assertTrue(Files.isRegularFile(p), property + " names a file that does not exist: " + p);
        paths.add(p);
      }
    }
    return paths;
  }
}

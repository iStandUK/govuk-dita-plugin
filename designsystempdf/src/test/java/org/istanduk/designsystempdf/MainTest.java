/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;

import org.apache.fontbox.ttf.TTFParser;
import org.apache.fontbox.ttf.TrueTypeFont;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.io.RandomAccessReadBufferedFile;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDResources;
import org.apache.pdfbox.pdmodel.interactive.documentnavigation.outline.PDOutlineItem;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** The command line end to end: exit codes, messages, and the PDF it writes. */
class MainTest {

  @TempDir
  Path dir;

  private Path sample;
  private final ByteArrayOutputStream out = new ByteArrayOutputStream();
  private final ByteArrayOutputStream err = new ByteArrayOutputStream();

  @BeforeEach
  void copySample() throws IOException {
    sample = dir.resolve("print.html");
    try (InputStream is = MainTest.class.getResourceAsStream("sample-print.html")) {
      Files.write(sample, is.readAllBytes());
    }
  }

  private int run(String... args) {
    out.reset();
    err.reset();
    return Main.run(args, new PrintStream(out, true, StandardCharsets.UTF_8), new PrintStream(err, true, StandardCharsets.UTF_8));
  }

  private String out() {
    return out.toString(StandardCharsets.UTF_8);
  }

  private String err() {
    return err.toString(StandardCharsets.UTF_8);
  }

  private Path write(String name, String xhtml) throws IOException {
    Path p = dir.resolve(name);
    Files.writeString(p, xhtml);
    return p;
  }

  @Test
  void versionListsTheContractsUnderstood() {
    assertEquals(Main.OK, run("--version"));
    assertTrue(out().startsWith("DesignSystemPDF "), out());
    assertFalse(out().contains("${"), "the version is filled in by the build: " + out());
    assertTrue(out().contains("print contracts understood: 1"), out());
  }

  @Test
  void helpIsTheUsageSummary() {
    assertEquals(Main.OK, run("--help"));
    assertTrue(out().contains("Usage: designsystempdf --in print.html --out publication.pdf"), out());
    assertTrue(out().contains("Exit codes"), out());
  }

  @Test
  void aWrongCommandLineIsExitCodeTwo() {
    assertEquals(Main.USAGE, run("--paper", "A9", sample.toString(), dir.resolve("x.pdf").toString()));
    assertTrue(err().startsWith("[DSPDF001E]: --paper must be one of"), err());
    assertTrue(err().contains("Usage:"), err());
    assertFalse(Files.exists(dir.resolve("x.pdf")));
  }

  @Test
  void aDocumentThatCannotBeReadIsExitCodeOne() throws IOException {
    assertEquals(Main.FAILED, run("--in", dir.resolve("absent.html").toString(), "--out", dir.resolve("x.pdf").toString()));
    assertTrue(err().startsWith("[DSPDF003E]: cannot read the print document"), err());
    Path broken = write("broken.html", "<html><body><p>unclosed</body></html>");
    assertEquals(Main.FAILED, run("--in", broken.toString(), "--out", dir.resolve("x.pdf").toString()));
    assertTrue(err().startsWith("[DSPDF003E]: "), err());
    assertTrue(err().contains("not well-formed XHTML"), err());
    assertFalse(Files.exists(dir.resolve("x.pdf")));
  }

  @Test
  void anUnknownContractIsRefusedWithExitCodeThree() throws IOException {
    Path future = write("future.html", Files.readString(sample).replace("govuk-print-contract\" content=\"1\"", "govuk-print-contract\" content=\"2\""));
    Path pdf = dir.resolve("future.pdf");
    assertEquals(Main.REFUSED, run("--in", future.toString(), "--out", pdf.toString()));
    assertTrue(err().startsWith("[DSPDF002E]: the print document declares govuk-print-contract '2'"), err());
    assertTrue(err().contains("org.istanduk.gov-uk 1.0.1"), err());
    assertFalse(Files.exists(pdf), "a refused document writes nothing");
  }

  @Test
  void theSampleRendersToAPageNumberedTaggedPdf() throws IOException {
    Path pdf = dir.resolve("nested").resolve("sample.pdf");
    assertEquals(Main.OK, run("--in", sample.toString(), "--out", pdf.toString()));
    assertEquals("", err());
    assertTrue(out().contains("tagged PDF/UA-1"), out());
    try (PDDocument doc = Loader.loadPDF(pdf.toFile())) {
      // cover, contents, two chapters, glossary, index
      assertEquals(6, doc.getNumberOfPages());
      assertTrue(out().contains("6 pages"), out());
      assertEquals("Sample publication", doc.getDocumentInformation().getTitle());
      assertEquals("Example Organisation", doc.getDocumentInformation().getAuthor());
      assertTrue(doc.getDocumentInformation().getProducer().startsWith("DesignSystemPDF "));
      assertNull(doc.getDocumentInformation().getCreationDate(), "no clock in the file");
      assertEquals("en-GB", doc.getDocumentCatalog().getLanguage());
      assertTrue(doc.getDocumentCatalog().getMarkInfo().isMarked());
      assertNotNull(doc.getDocumentCatalog().getStructureTreeRoot());

      PDOutlineItem first = doc.getDocumentCatalog().getDocumentOutline().getFirstChild();
      assertEquals("Contents", first.getTitle());
      assertEquals("The first chapter", first.getNextSibling().getTitle());
      assertEquals("A section", first.getNextSibling().getFirstChild().getTitle());

      // every font is embedded, and none is a system font
      for (PDPage page : doc.getPages()) {
        PDResources resources = page.getResources();
        for (COSName name : resources.getFontNames()) {
          assertTrue(resources.getFont(name).isEmbedded(), resources.getFont(name).getName());
          assertTrue(resources.getFont(name).getName().contains("NotoSans"), resources.getFont(name).getName());
        }
      }

      String contents = page(doc, 2);
      assertTrue(contents.matches("(?s).*The first chapter[ .]*3\\b.*"), contents);
      assertTrue(contents.matches("(?s).*A topic in the second chapter[ .]*4\\b.*"), contents);
      // the glossary and index carry no page label in the document; pdf.css numbers them all the same
      assertTrue(contents.matches("(?s).*Glossary[ .]*5\\b.*"), contents);
      assertTrue(contents.matches("(?s).*Index[ .]*6\\b.*"), contents);

      String chapter = page(doc, 3);
      assertTrue(chapter.contains("A topic in the second chapter (page 4)") || chapter.contains("A topic in the second chapter (page 4)"), chapter);
      // the footnote is on the page that calls it; the one used only by reference stays an endnote
      assertTrue(chapter.contains("The text of the footnote."), chapter);
      assertTrue(chapter.contains("A footnote used only by reference."), chapter);
      // running heads: the publication on every page after the cover, the chapter beside it
      assertTrue(chapter.contains("Sample publication"), chapter);
      assertFalse(page(doc, 1).contains("The first chapter"), "the cover carries no running head");
      assertTrue(page(doc, 4).contains("The first chapter (page"), page(doc, 4));
      assertTrue(page(doc, 6).matches("(?s).*A topic in the second chapter\\s*4\\b.*"), page(doc, 6));
    }
  }

  @Test
  void twoRunsAreByteIdentical() throws IOException {
    Path a = dir.resolve("a.pdf");
    Path b = dir.resolve("b.pdf");
    assertEquals(Main.OK, run("--in", sample.toString(), "--out", a.toString()));
    assertEquals(Main.OK, run("--in", sample.toString(), "--out", b.toString()));
    assertArrayEquals(Files.readAllBytes(a), Files.readAllBytes(b));
    assertEquals(Main.OK, run("--in", sample.toString(), "--out", a.toString(), "--fixed-date", "2026-10-01T09:30:00Z"));
    assertEquals(Main.OK, run("--in", sample.toString(), "--out", b.toString(), "--fixed-date", "2026-10-01T09:30:00Z"));
    assertArrayEquals(Files.readAllBytes(a), Files.readAllBytes(b));
    try (PDDocument doc = Loader.loadPDF(a.toFile())) {
      assertEquals(Instant.parse("2026-10-01T09:30:00Z"), doc.getDocumentInformation().getCreationDate().toInstant());
      assertEquals(Instant.parse("2026-10-01T09:30:00Z"), doc.getDocumentInformation().getModificationDate().toInstant());
      String xmp = new String(doc.getDocumentCatalog().getMetadata().toByteArray(), StandardCharsets.UTF_8);
      assertTrue(xmp.contains("<xmp:CreateDate>2026-10-01T09:30:00+00:00</xmp:CreateDate>"), xmp);
    }
  }

  @Test
  void paperAndUntaggedOutputFollowTheCommandLine() throws IOException {
    Path pdf = dir.resolve("a5.pdf");
    assertEquals(Main.OK, run("--paper", "A5", "--no-pdf-ua", sample.toString(), pdf.toString()));
    assertTrue(out().contains("untagged"), out());
    try (PDDocument doc = Loader.loadPDF(pdf.toFile())) {
      assertEquals(148, doc.getPage(0).getMediaBox().getWidth() / 72 * 25.4, 0.5);
      assertEquals(210, doc.getPage(0).getMediaBox().getHeight() / 72 * 25.4, 0.5);
      assertNull(doc.getDocumentCatalog().getStructureTreeRoot());
    }
  }

  @Test
  void aTableMarkedLandscapeTakesATurnedPage() throws IOException {
    Path turned = write("turned.html", Files.readString(sample).replace("<table class=\"govuk-table\">", "<table class=\"govuk-table landscape\">"));
    Path pdf = dir.resolve("turned.pdf");
    assertEquals(Main.OK, run("--in", turned.toString(), "--out", pdf.toString()));
    try (PDDocument doc = Loader.loadPDF(pdf.toFile())) {
      int landscape = 0;
      for (PDPage page : doc.getPages()) {
        if (page.getMediaBox().getWidth() > page.getMediaBox().getHeight()) {
          landscape++;
        }
      }
      assertEquals(1, landscape);
    }
  }

  @Test
  void whatCannotBeDoneIsAWarningAndThePdfIsStillWritten() throws IOException {
    Path doc = write("warnings.html", "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\"><head><title>Warnings</title>"
        + "<meta name=\"description\" content=\"Warnings\"/></head><body>"
        + "<p>Arabic مرحبا has no glyph in the bundled fonts.</p>"
        + "<p><img src=\"https://example.org/remote.png\" alt=\"a remote image\"/></p>"
        + "<p><img src=\"missing.png\" alt=\"a missing image\"/></p></body></html>");
    Path pdf = dir.resolve("warnings.pdf");
    assertEquals(Main.OK, run("--in", doc.toString(), "--out", pdf.toString(), "--fonts", dir.resolve("no-such-fonts").toString()));
    String messages = err();
    assertTrue(messages.contains("[DSPDF005W]: --fonts "), messages);
    assertTrue(messages.contains("[DSPDF004W]: 5 character(s)"), messages);
    assertTrue(messages.contains("U+0645 ARABIC LETTER MEEM"), messages);
    // right-to-left text is reported for what it is, not only for its missing glyphs
    assertTrue(messages.contains("[DSPDF010W]: the document has text in a right-to-left script (5 different character(s)"), messages);
    assertTrue(messages.contains("[DSPDF008W]: a resource on another origin was not fetched"), messages);
    assertTrue(messages.contains("https://example.org/remote.png"), messages);
    assertTrue(messages.contains("[DSPDF006W]: "), messages);
    assertTrue(Files.size(pdf) > 0);
    assertTrue(out().contains("warnings"), out());
    assertFalse(Files.exists(dir.resolve("warnings.pdf.part")));
  }

  /**
   * A font given with --fonts draws the characters the stylesheet's own fonts
   * lack, although no stylesheet names it, and the missing-glyph warning is
   * given exactly when a replacement mark is printed. The installation here
   * bundles the sans family alone, and the publisher supplies the monospace
   * one, which has characters the sans does not.
   */
  @Test
  void aSuppliedFontFillsTheGapsAndTheWarningSaysWhatIsPrinted() throws IOException {
    Path bundled = Path.of(System.getProperty("designsystempdf.home"), "fonts");
    // under target/, not the temporary directory: the PDF library keeps a font
    // file open for the life of the process, and Windows will not delete one
    Path work = Files.createTempDirectory(Files.createDirectories(Path.of("target", "test-fonts")), "gaps");
    Path home = Files.createDirectories(work.resolve("home"));
    Path homeFonts = Files.createDirectories(home.resolve("fonts"));
    Path supplied = Files.createDirectories(work.resolve("supplied"));
    try (var files = Files.list(bundled)) {
      for (Path f : (Iterable<Path>) files::iterator) {
        String name = f.getFileName().toString();
        if (name.startsWith("NotoSans-")) {
          Files.copy(f, homeFonts.resolve(name));
        } else if (name.equals("NotoSansMono-Regular.ttf")) {
          Files.copy(f, supplied.resolve(name));
        }
      }
    }
    int only = onlyIn(supplied.resolve("NotoSansMono-Regular.ttf"), homeFonts.resolve("NotoSans-Regular.ttf"));
    String character = new String(Character.toChars(only));
    String code = String.format("U+%04X", only);
    Path doc = write("gaps.html", "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\"><head><title>Gaps</title>"
        + "<meta name=\"description\" content=\"Gaps\"/><style>p { font-family: sans-serif }</style></head><body>"
        + "<p>before " + character + " after</p></body></html>");

    String previous = System.getProperty("designsystempdf.home");
    System.setProperty("designsystempdf.home", home.toString());
    try {
      // nothing has the character: a replacement mark, and the warning
      Path without = dir.resolve("without.pdf");
      assertEquals(Main.OK, run("--in", doc.toString(), "--out", without.toString()));
      assertTrue(err().contains("[DSPDF004W]: 1 character(s)"), err());
      assertTrue(err().contains(code), err());
      assertTrue(err().contains("Supply a TrueType font that covers them with --fonts."), err());
      try (PDDocument pdf = Loader.loadPDF(without.toFile())) {
        assertFalse(page(pdf, 1).contains(character), page(pdf, 1));
      }

      // the supplied font has it: the character itself, from that font, and no warning
      Path with = dir.resolve("with.pdf");
      assertEquals(Main.OK, run("--in", doc.toString(), "--out", with.toString(), "--fonts", supplied.toString()));
      assertEquals("", err());
      try (PDDocument pdf = Loader.loadPDF(with.toFile())) {
        assertTrue(page(pdf, 1).contains("before " + character + " after"), page(pdf, 1));
        boolean mono = false;
        PDResources resources = pdf.getPage(0).getResources();
        for (COSName name : resources.getFontNames()) {
          assertTrue(resources.getFont(name).isEmbedded(), resources.getFont(name).getName());
          mono |= resources.getFont(name).getName().contains("NotoSansMono");
        }
        assertTrue(mono, "the supplied font draws the character");
      }
    } finally {
      System.setProperty("designsystempdf.home", previous);
    }
  }

  /** The first symbol the one font has a glyph for and the other has not. */
  private static int onlyIn(Path has, Path lacks) throws IOException {
    try (TrueTypeFont a = new TTFParser().parse(new RandomAccessReadBufferedFile(has.toFile()));
        TrueTypeFont b = new TTFParser().parse(new RandomAccessReadBufferedFile(lacks.toFile()))) {
      for (int cp = 0x2190; cp <= 0x25FF; cp++) {
        if (a.getUnicodeCmapLookup().getGlyphId(cp) != 0 && b.getUnicodeCmapLookup().getGlyphId(cp) == 0) {
          return cp;
        }
      }
    }
    throw new IllegalStateException("the bundled monospace font no longer has a symbol the sans lacks");
  }

  private static String page(PDDocument doc, int number) throws IOException {
    PDFTextStripper stripper = new PDFTextStripper();
    stripper.setStartPage(number);
    stripper.setEndPage(number);
    return stripper.getText(doc);
  }
}

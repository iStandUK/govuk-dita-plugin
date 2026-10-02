/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.apache.fontbox.ttf.CmapLookup;
import org.apache.fontbox.ttf.OS2WindowsMetricsTable;
import org.apache.fontbox.ttf.TTFParser;
import org.apache.fontbox.ttf.TrueTypeFont;
import org.apache.pdfbox.io.RandomAccessReadBufferedFile;

import com.openhtmltopdf.outputdevice.helper.BaseRendererBuilder.FSFontUseCase;
import com.openhtmltopdf.outputdevice.helper.BaseRendererBuilder.FontStyle;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;

/**
 * The fonts a PDF may embed: the bundled open family, and any TrueType files
 * the publisher supplies. A tagged PDF must embed every font it uses, and the
 * generator ships no restricted typeface, so the bundled family also answers
 * to the generic and system names stylesheets ask for (sans-serif, arial,
 * monospace ...) — the same fallback the web output makes — unless a
 * publisher font claims the name first.
 *
 * <p>The engine sets each character in the first font of its text's stack
 * that can draw it, then tries the fallback fonts registered here: one face
 * of each family, the bundled ones first and then the publisher's. So a font
 * given with --fonts fills the gaps of whatever the stylesheet chose, without
 * the stylesheet having to name it — the print stylesheet names only
 * sans-serif — and {@link #covers(int)} asks exactly those faces, so the
 * missing-glyph warning is given when, and only when, a character will print
 * as a replacement mark.
 */
final class FontRegistry {

  /** The bundled families (D-25). */
  static final String SANS = "Noto Sans";
  static final String MONO = "Noto Sans Mono";

  // The engine looks the CSS generic families up as SansSerif, Serif and Monospaced;
  // every other name is matched without regard to case.
  private static final String[] SANS_ALIASES = {
      "SansSerif", "Serif", "arial", "helvetica", "helvetica neue", "system-ui", "ui-sans-serif"};
  private static final String[] MONO_ALIASES = {
      "Monospaced", "ui-monospace", "courier", "courier new", "consolas", "menlo", "sf mono", "liberation mono"};

  /**
   * Text in the page, in inline SVG diagrams and in MathML all draws from the
   * same fonts, so a diagram looks the same on every machine instead of
   * borrowing whatever the operating system has installed.
   */
  private static final Set<FSFontUseCase> EVERYWHERE =
      EnumSet.of(FSFontUseCase.DOCUMENT, FSFontUseCase.SVG, FSFontUseCase.MATHML);

  /** One font file, described by its own name and metrics tables. */
  static final class Face {
    final Path file;
    final String family;
    final int weight;
    final boolean italic;
    final boolean bundled;
    final CmapLookup cmap;

    Face(Path file, String family, int weight, boolean italic, boolean bundled, CmapLookup cmap) {
      this.file = file;
      this.family = family;
      this.weight = weight;
      this.italic = italic;
      this.bundled = bundled;
      this.cmap = cmap;
    }
  }

  private final List<Face> faces = new ArrayList<>();
  private final Log log;

  FontRegistry(Log log) {
    this.log = log;
  }

  /** Publisher fonts first, so their family names win over the bundled aliases. */
  void addPublisherFonts(Path dir) {
    if (!Files.isDirectory(dir)) {
      log.warn(Log.FONT, "--fonts " + dir + " is not a directory; only the bundled fonts are used.");
      return;
    }
    int before = faces.size();
    scan(dir, false);
    if (faces.size() == before) {
      log.warn(Log.FONT, "--fonts " + dir + " holds no usable TrueType (.ttf) font; only the bundled fonts are used.");
    }
  }

  void addBundledFonts(Path dir) throws IOException {
    if (!Files.isDirectory(dir)) {
      throw new IOException("the bundled fonts are missing from " + dir + ": is the installation complete?");
    }
    scan(dir, true);
  }

  private void scan(Path dir, boolean bundled) {
    List<Path> files = new ArrayList<>();
    try (DirectoryStream<Path> stream = Files.newDirectoryStream(dir)) {
      for (Path p : stream) {
        String name = p.getFileName().toString().toLowerCase(Locale.ROOT);
        if (name.endsWith(".ttf") || name.endsWith(".otf")) {
          files.add(p);
        }
      }
    } catch (IOException e) {
      log.warn(Log.FONT, "cannot list fonts in " + dir + ": " + e.getMessage());
      return;
    }
    // directory order is the file system's; sort so equal input gives equal output
    files.sort(Comparator.comparing(p -> p.getFileName().toString()));
    for (Path p : files) {
      try (TrueTypeFont ttf = new TTFParser().parse(new RandomAccessReadBufferedFile(p.toFile()))) {
        if (!ttf.getTableMap().containsKey("glyf")) {
          log.warn(Log.FONT, p.getFileName() + " has no TrueType outlines (an OpenType CFF font cannot be"
              + " embedded in a tagged PDF by this engine); skipped. Convert it to TrueType.");
          continue;
        }
        String family = ttf.getNaming() == null ? null : ttf.getNaming().getFontFamily();
        if (family == null || family.isBlank()) {
          log.warn(Log.FONT, p.getFileName() + " names no font family; skipped.");
          continue;
        }
        OS2WindowsMetricsTable os2 = ttf.getOS2Windows();
        int weight = os2 == null ? 400 : os2.getWeightClass();
        boolean italic = (os2 != null && (os2.getFsSelection() & 1) != 0)
            || (ttf.getHeader() != null && (ttf.getHeader().getMacStyle() & 2) != 0);
        faces.add(new Face(p, family, weight, italic, bundled, ttf.getUnicodeCmapLookup()));
        log.info("font: " + family + " " + weight + (italic ? " italic" : "") + " from " + p.getFileName());
      } catch (IOException | RuntimeException e) {
        log.warn(Log.FONT, p.getFileName() + " could not be read as a TrueType font (" + e.getMessage() + "); skipped.");
      }
    }
  }

  /**
   * True when a fallback font has a glyph for the character, so that it is
   * drawn whatever font its text was set in.
   */
  boolean covers(int codePoint) {
    for (Face f : fallbackFaces()) {
      if (f.cmap != null && f.cmap.getGlyphId(codePoint) != 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * The faces tried for a character its own font lacks: one per family — the
   * upright regular where there is one, else the upright face nearest it,
   * else the first — with the bundled families first, so what they already
   * draw does not change when a publisher adds fonts. A bundled family the
   * publisher has replaced under the same name is left out, as it is from the
   * document.
   */
  List<Face> fallbackFaces() {
    Set<String> publisherFamilies = publisherFamilies();
    List<Face> chosen = new ArrayList<>();
    for (boolean bundled : new boolean[] {true, false}) {
      Set<String> done = new HashSet<>();
      for (Face f : faces) {
        String key = f.family.toLowerCase(Locale.ROOT);
        if (f.bundled != bundled || done.contains(key) || (bundled && publisherFamilies.contains(key))) {
          continue;
        }
        done.add(key);
        Face best = f;
        for (Face g : faces) {
          if (g.bundled == bundled && g.family.equalsIgnoreCase(f.family) && better(g, best)) {
            best = g;
          }
        }
        chosen.add(best);
      }
    }
    return chosen;
  }

  /** An upright face beats an italic one; then the weight nearer regular wins. */
  private static boolean better(Face candidate, Face current) {
    if (candidate.italic != current.italic) {
      return !candidate.italic;
    }
    return Math.abs(candidate.weight - 400) < Math.abs(current.weight - 400);
  }

  private Set<String> publisherFamilies() {
    Set<String> families = new HashSet<>();
    for (Face f : faces) {
      if (!f.bundled) {
        families.add(f.family.toLowerCase(Locale.ROOT));
      }
    }
    return families;
  }

  boolean hasFamily(String family) {
    return faces.stream().anyMatch(f -> f.family.equalsIgnoreCase(family));
  }

  List<Face> faces() {
    return faces;
  }

  void registerWith(PdfRendererBuilder builder) {
    Set<String> publisherFamilies = publisherFamilies();
    for (Face f : faces) {
      FontStyle style = f.italic ? FontStyle.ITALIC : FontStyle.NORMAL;
      if (!f.bundled) {
        builder.useFont(f.file.toFile(), f.family, f.weight, style, true, EVERYWHERE);
        continue;
      }
      if (publisherFamilies.contains(f.family.toLowerCase(Locale.ROOT))) {
        continue;
      }
      builder.useFont(f.file.toFile(), f.family, f.weight, style, true, EVERYWHERE);
      String[] aliases = f.family.equals(SANS) ? SANS_ALIASES : f.family.equals(MONO) ? MONO_ALIASES : new String[0];
      for (String alias : aliases) {
        if (!publisherFamilies.contains(alias)) {
          builder.useFont(f.file.toFile(), alias, f.weight, style, true, EVERYWHERE);
        }
      }
    }
    // A character the chosen font lacks is looked for in these faces before
    // the engine gives up on it: the bundled monospace carries arrows and
    // mathematical operators the sans does not, and a publisher's font may
    // carry a script neither has.
    for (Face f : fallbackFaces()) {
      builder.useFont(f.file.toFile(), f.family + " fallback", f.weight,
          f.italic ? FontStyle.ITALIC : FontStyle.NORMAL, true, EnumSet.of(FSFontUseCase.FALLBACK_PRE));
    }
  }
}

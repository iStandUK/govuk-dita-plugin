/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/** The command line, parsed and validated. Every value is the caller's choice; nothing is guessed. */
final class Options {

  static final String USAGE = String.join(System.lineSeparator(),
      "Usage: designsystempdf --in print.html --out publication.pdf [options]",
      "       designsystempdf [options] print.html publication.pdf",
      "",
      "Renders an XHTML print document as a paged, tagged PDF.",
      "",
      "  --in FILE            the print document (XHTML)",
      "  --out FILE           the PDF to write",
      "  --paper SIZE         A5, A4, A3, B5, B4, JIS-B5, JIS-B4, Letter, Legal, Ledger,",
      "                       or a width and height such as \"210mm 280mm\"",
      "                       (default: the size the document's own stylesheet sets)",
      "  --orientation O      portrait or landscape (with a named --paper size)",
      "  --margins M          standard (default), narrow, wide, or one to four CSS",
      "                       lengths such as \"20mm 18mm 22mm 18mm\"",
      "  --sides S            single (default) or double: mirrored margins for binding",
      "  --fonts DIR          TrueType fonts the publisher supplies, used where the",
      "                       document's stylesheets name them and for characters",
      "                       the other fonts lack",
      "  --no-pdf-ua          write an untagged PDF instead of PDF/UA-1",
      "  --fixed-date ISO     the document date, such as 2026-10-01 or",
      "                       2026-10-01T09:30:00Z (default: SOURCE_DATE_EPOCH if set,",
      "                       else no date is written, so equal input gives equal bytes)",
      "  --toc-depth N        depth of the PDF outline (bookmarks), 1-6 (default 3)",
      "  --verbose            report the engine's own diagnostics",
      "  --version            print the version and the print contracts understood",
      "  --help               print this text",
      "",
      "Exit codes: 0 PDF written; 1 rendering failed; 2 the command line is wrong;",
      "3 the print document is not one this version understands.");

  private static final Pattern NAMED_PAPER =
      Pattern.compile("(?i)^(A5|A4|A3|B5|B4|JIS-B5|JIS-B4|letter|legal|ledger)$");
  private static final String LENGTH = "[0-9]+(\\.[0-9]+)?(mm|cm|in|pt|pc|px)";
  private static final Pattern PAPER_LENGTHS = Pattern.compile("^" + LENGTH + " " + LENGTH + "$");
  private static final Pattern MARGIN_LENGTHS = Pattern.compile("^" + LENGTH + "( " + LENGTH + "){0,3}$");

  Path in;
  Path out;
  String paper;
  String orientation;
  String margins = "standard";
  boolean doubleSided;
  Path fonts;
  boolean pdfUa = true;
  Instant fixedDate;
  int tocDepth = 3;
  boolean verbose;
  boolean version;
  boolean help;

  static Options parse(String[] args) {
    return parse(args, System.getenv("SOURCE_DATE_EPOCH"));
  }

  static Options parse(String[] args, String sourceDateEpoch) {
    Options o = new Options();
    List<String> positional = new ArrayList<>();
    for (int i = 0; i < args.length; i++) {
      String a = args[i];
      switch (a) {
        case "--in": o.in = Paths.get(value(args, ++i, a)); break;
        case "--out": o.out = Paths.get(value(args, ++i, a)); break;
        case "--paper": o.paper = value(args, ++i, a).trim(); break;
        case "--orientation": o.orientation = value(args, ++i, a).toLowerCase(Locale.ROOT); break;
        case "--margins": o.margins = value(args, ++i, a).trim(); break;
        case "--sides": {
          String s = value(args, ++i, a).toLowerCase(Locale.ROOT);
          if (!s.equals("single") && !s.equals("double")) {
            throw new UsageException("--sides must be 'single' or 'double', was: " + s);
          }
          o.doubleSided = s.equals("double");
          break;
        }
        case "--fonts": o.fonts = Paths.get(value(args, ++i, a)); break;
        case "--no-pdf-ua": o.pdfUa = false; break;
        case "--fixed-date": o.fixedDate = date(value(args, ++i, a)); break;
        case "--toc-depth": {
          String s = value(args, ++i, a);
          if (!s.matches("[1-6]")) {
            throw new UsageException("--toc-depth must be a single digit 1-6, was: " + s);
          }
          o.tocDepth = Integer.parseInt(s);
          break;
        }
        case "--verbose": o.verbose = true; break;
        case "--version": o.version = true; break;
        case "--help": case "-h": o.help = true; break;
        default:
          if (a.startsWith("--")) {
            throw new UsageException("unknown option: " + a);
          }
          positional.add(a);
      }
    }
    if (o.help || o.version) {
      return o;
    }
    // The plugin's govuk.pdf.command appends the print document and the PDF path
    // as the last two arguments, so both spellings are accepted.
    if (positional.size() == 2 && o.in == null && o.out == null) {
      o.in = Paths.get(positional.get(0));
      o.out = Paths.get(positional.get(1));
    } else if (!positional.isEmpty()) {
      throw new UsageException("unexpected argument: " + positional.get(0)
          + " (give the print document and the PDF either as --in and --out or as the last two arguments)");
    }
    if (o.in == null || o.out == null) {
      throw new UsageException("both the print document (--in) and the PDF to write (--out) are needed");
    }
    if (o.paper != null && !NAMED_PAPER.matcher(o.paper).matches() && !PAPER_LENGTHS.matcher(o.paper).matches()) {
      throw new UsageException("--paper must be one of A5, A4, A3, B5, B4, JIS-B5, JIS-B4, Letter, Legal, Ledger,"
          + " or a width and height such as '210mm 297mm', was: " + o.paper);
    }
    if (o.orientation != null && !o.orientation.equals("portrait") && !o.orientation.equals("landscape")) {
      throw new UsageException("--orientation must be 'portrait' or 'landscape', was: " + o.orientation);
    }
    if (o.orientation != null && o.paper == null) {
      throw new UsageException("--orientation needs --paper: the document's own stylesheet sets the page otherwise");
    }
    if (!o.margins.matches("standard|narrow|wide") && !MARGIN_LENGTHS.matcher(o.margins).matches()) {
      throw new UsageException("--margins must be standard, narrow, wide, or one to four CSS lengths such as"
          + " '20mm 18mm', was: " + o.margins);
    }
    if (o.fixedDate == null && sourceDateEpoch != null && !sourceDateEpoch.isBlank()) {
      try {
        o.fixedDate = Instant.ofEpochSecond(Long.parseLong(sourceDateEpoch.trim()));
      } catch (NumberFormatException e) {
        throw new UsageException("SOURCE_DATE_EPOCH must be a whole number of seconds, was: " + sourceDateEpoch);
      }
    }
    return o;
  }

  /** True when the paper is a keyword, which CSS lets an orientation follow. */
  boolean namedPaper() {
    return paper != null && NAMED_PAPER.matcher(paper).matches();
  }

  private static String value(String[] args, int i, String option) {
    if (i >= args.length) {
      throw new UsageException(option + " needs a value");
    }
    return args[i];
  }

  private static Instant date(String s) {
    try {
      return OffsetDateTime.parse(s).toInstant();
    } catch (DateTimeParseException e) {
      try {
        return LocalDate.parse(s).atStartOfDay(ZoneOffset.UTC).toInstant();
      } catch (DateTimeParseException e2) {
        throw new UsageException("--fixed-date must be an ISO 8601 date or date-time such as 2026-10-01 or"
            + " 2026-10-01T09:30:00Z, was: " + s);
      }
    }
  }
}

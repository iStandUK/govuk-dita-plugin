/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.util.Locale;
import java.util.Map;

/**
 * The page rules the command line asks for, as CSS that follows the document's
 * own stylesheets and the product's pdf.css. Without --paper the document's
 * stylesheet keeps its page size (the plugin writes it from govuk.pdf.paper),
 * and pdf.css assumes A4 for the turned pages of wide tables and figures.
 */
final class PageRules {

  // CSS margin order: top right bottom left
  private static final String[] STANDARD = {"20mm", "18mm", "22mm", "18mm"};
  private static final String[] NARROW = {"14mm", "12mm", "16mm", "12mm"};
  private static final String[] WIDE = {"25mm", "25mm", "28mm", "25mm"};
  /** The inner margin when printing on both sides leaves room for binding (design 10, section 4). */
  private static final String BINDING_STANDARD = "25mm";
  private static final String BINDING_NARROW = "18mm";
  private static final String BINDING_WIDE = "32mm";

  /** The CSS page-size keywords, as width and height in millimetres. */
  private static final Map<String, double[]> PAPER = Map.of(
      "a5", new double[] {148, 210},
      "a4", new double[] {210, 297},
      "a3", new double[] {297, 420},
      "b5", new double[] {176, 250},
      "b4", new double[] {250, 353},
      "jis-b5", new double[] {182, 257},
      "jis-b4", new double[] {257, 364},
      "letter", new double[] {215.9, 279.4},
      "legal", new double[] {215.9, 355.6},
      "ledger", new double[] {279.4, 431.8});

  private PageRules() {
  }

  static String css(Options o) {
    StringBuilder css = new StringBuilder();
    String[] m = margins(o.margins);
    String inner = o.doubleSided ? binding(o.margins, m) : m[3];
    String outer = m[1];
    boolean margined = !o.margins.equals("standard") || o.doubleSided;
    if (o.paper != null || margined) {
      css.append("@page {");
      if (o.paper != null) {
        css.append(" size: ").append(size(o, false)).append(";");
      }
      if (margined) {
        css.append(" margin: ").append(String.join(" ", m)).append(";");
      }
      css.append(" }\n");
    }
    if (o.doubleSided) {
      // a right-hand page binds on its left
      css.append("@page :right { margin-left: ").append(inner).append("; margin-right: ").append(outer).append("; }\n");
      css.append("@page :left { margin-left: ").append(outer).append("; margin-right: ").append(inner).append("; }\n");
    }
    if (o.paper != null || margined) {
      double[] paper = dimensions(o);
      boolean portrait = paper[0] < paper[1];
      if (o.paper != null) {
        css.append("@page app-pdf-landscape { size: ").append(size(o, true)).append("; }\n");
      }
      if (portrait) {
        // The engine lays every page out to the first page's measure, so a
        // turned page's wider measure has to be given to the element itself.
        double measure = paper[1] - mm(inner) - mm(outer);
        css.append(String.format(Locale.ROOT, ".landscape { width: %.1fmm; }\n", measure));
      } else {
        css.append(".landscape { width: auto; }\n");
      }
    }
    return css.toString();
  }

  /** The page size; turned is the landscape page a wide table or figure asks for. */
  private static String size(Options o, boolean turned) {
    if (o.namedPaper()) {
      boolean landscape = turned || "landscape".equals(o.orientation);
      return o.paper + (landscape ? " landscape" : " portrait");
    }
    String[] wh = o.paper.split(" ");
    // explicit lengths are width then height already; the turned page swaps
    // them unless the publication is itself wider than tall
    boolean swap = turned && mm(wh[0]) < mm(wh[1]);
    return swap ? wh[1] + " " + wh[0] : o.paper;
  }

  /** The publication's page as width and height in millimetres; A4 when the document's stylesheet decides. */
  private static double[] dimensions(Options o) {
    double[] wh;
    if (o.paper == null) {
      wh = PAPER.get("a4");
    } else if (o.namedPaper()) {
      wh = PAPER.get(o.paper.toLowerCase(Locale.ROOT));
    } else {
      String[] lengths = o.paper.split(" ");
      return new double[] {mm(lengths[0]), mm(lengths[1])};
    }
    return "landscape".equals(o.orientation) ? new double[] {wh[1], wh[0]} : wh;
  }

  static double mm(String cssLength) {
    double n = Double.parseDouble(cssLength.replaceAll("[a-z]+$", ""));
    switch (cssLength.replaceAll("^[0-9.]+", "")) {
      case "cm": return n * 10;
      case "in": return n * 25.4;
      case "pt": return n * 25.4 / 72;
      case "pc": return n * 25.4 / 6;
      case "px": return n * 25.4 / 96;
      default: return n;
    }
  }

  /** One to four lengths, expanded as the CSS margin shorthand expands them. */
  static String[] margins(String margins) {
    switch (margins) {
      case "standard": return STANDARD;
      case "narrow": return NARROW;
      case "wide": return WIDE;
      default:
        String[] v = margins.split(" ");
        switch (v.length) {
          case 1: return new String[] {v[0], v[0], v[0], v[0]};
          case 2: return new String[] {v[0], v[1], v[0], v[1]};
          case 3: return new String[] {v[0], v[1], v[2], v[1]};
          default: return v;
        }
    }
  }

  private static String binding(String margins, String[] m) {
    switch (margins) {
      case "standard": return BINDING_STANDARD;
      case "narrow": return BINDING_NARROW;
      case "wide": return BINDING_WIDE;
      // explicit lengths: the fourth (left) is the inner margin of a right-hand page
      default: return m[3];
    }
  }
}

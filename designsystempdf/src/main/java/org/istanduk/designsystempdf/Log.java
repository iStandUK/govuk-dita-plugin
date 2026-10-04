/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.io.PrintStream;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Coded messages in the style of the plugin's GOVK messages, so a build that
 * calls the generator can surface them unchanged: {@code [DSPDF004W]: ...}.
 * The last letter is the severity: I information, W warning, E error.
 */
final class Log {

  /** The command line is wrong. */
  static final String USAGE = "DSPDF001E";
  /** The print document's contract is not one this version understands. */
  static final String CONTRACT = "DSPDF002E";
  /** The print document cannot be read as XHTML. */
  static final String INPUT = "DSPDF003E";
  /** Characters with no glyph in any available font. */
  static final String GLYPHS = "DSPDF004W";
  /** A publisher font was skipped. */
  static final String FONT = "DSPDF005W";
  /** A stylesheet or image the document names could not be loaded. */
  static final String RESOURCE = "DSPDF006W";
  /** Rendering failed. */
  static final String RENDER = "DSPDF007E";
  /** A resource on another origin was not fetched. */
  static final String REMOTE = "DSPDF008W";
  /** A figure has no alternative text, so the PDF cannot meet PDF/UA. */
  static final String ALT = "DSPDF009W";
  /** Text in a right-to-left script, which this version does not shape or order. */
  static final String RTL = "DSPDF010W";
  /** The engine could not lay out a leader, so the contents was rendered without its dots (#182). */
  static final String LEADER = "DSPDF011W";
  /** Progress, shown with --verbose. */
  static final String INFO = "DSPDF000I";

  private final PrintStream err;
  private final boolean verbose;
  private final Set<String> seen = new LinkedHashSet<>();
  private int warnings;

  Log(PrintStream err, boolean verbose) {
    this.err = err;
    this.verbose = verbose;
  }

  void error(String code, String message) {
    err.println("[" + code + "]: " + message);
  }

  /** Each distinct warning is reported once, however often the engine meets its cause. */
  void warn(String code, String message) {
    if (seen.add(code + message)) {
      warnings++;
      err.println("[" + code + "]: " + message);
    }
  }

  void info(String message) {
    if (verbose) {
      err.println("[" + INFO + "]: " + message);
    }
  }

  boolean verbose() {
    return verbose;
  }

  int warnings() {
    return warnings;
  }
}

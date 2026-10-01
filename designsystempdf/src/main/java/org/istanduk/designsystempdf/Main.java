/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.Properties;

/**
 * The command line. This is the product scaffold: the launcher, the build and
 * the distribution are in place, and the entry point answers --version and
 * --help. Rendering follows.
 */
public final class Main {

  static final int OK = 0;
  static final int USAGE = 2;

  private static final String USAGE_TEXT = String.join(System.lineSeparator(),
      "Usage: designsystempdf --in print.html --out publication.pdf [options]",
      "",
      "Renders an XHTML print document as a paged, tagged PDF.",
      "",
      "  --version            print the version",
      "  --help               print this text");

  private Main() {
  }

  public static void main(String[] args) {
    System.exit(run(args, System.out, System.err));
  }

  static int run(String[] args, PrintStream out, PrintStream err) {
    if (args.length == 1 && args[0].equals("--version")) {
      out.println("DesignSystemPDF " + version());
      return OK;
    }
    if (args.length == 1 && (args[0].equals("--help") || args[0].equals("-h"))) {
      out.println(USAGE_TEXT);
      return OK;
    }
    err.println("[DSPDF001E]: this build of DesignSystemPDF " + version() + " does not render yet; it answers --version and --help.");
    err.println();
    err.println(USAGE_TEXT);
    return USAGE;
  }

  static String version() {
    try (InputStream is = Main.class.getResourceAsStream("version.properties")) {
      Properties p = new Properties();
      if (is != null) {
        p.load(is);
      }
      return p.getProperty("version", "unknown");
    } catch (IOException e) {
      return "unknown";
    }
  }
}

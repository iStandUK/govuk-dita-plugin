/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Properties;

/**
 * The command line: {@code designsystempdf --in print.html --out publication.pdf}.
 * Exit codes: 0 the PDF was written; 1 rendering failed; 2 the command line
 * is wrong; 3 the print document is not one this version understands.
 */
public final class Main {

  static final int OK = 0;
  static final int FAILED = 1;
  static final int USAGE = 2;
  static final int REFUSED = 3;

  private Main() {
  }

  public static void main(String[] args) {
    System.exit(run(args, System.out, System.err));
  }

  static int run(String[] args, PrintStream out, PrintStream err) {
    String version = version();
    Options options;
    try {
      options = Options.parse(args);
    } catch (UsageException e) {
      new Log(err, false).error(Log.USAGE, e.getMessage());
      err.println();
      err.println(Options.USAGE);
      return USAGE;
    }
    if (options.help) {
      out.println(Options.USAGE);
      return OK;
    }
    if (options.version) {
      out.println("DesignSystemPDF " + version);
      out.println("print contracts understood: " + String.join(", ", PrintContract.UNDERSTOOD));
      return OK;
    }
    Log log = new Log(err, options.verbose);
    try {
      long started = System.nanoTime();
      int pages = new Renderer(options, log, home().resolve("fonts"), version).render();
      out.println("DesignSystemPDF " + version + ": " + options.out + " written, " + pages + " page"
          + (pages == 1 ? "" : "s") + (options.pdfUa ? ", tagged PDF/UA-1" : ", untagged")
          + (log.warnings() > 0 ? ", " + log.warnings() + " warning" + (log.warnings() == 1 ? "" : "s") : ""));
      log.info(String.format("rendered in %.1f s", (System.nanoTime() - started) / 1e9));
      return OK;
    } catch (Renderer.ContractException e) {
      log.error(Log.CONTRACT, e.getMessage());
      return REFUSED;
    } catch (Renderer.InputException e) {
      log.error(Log.INPUT, e.getMessage());
      return FAILED;
    } catch (IOException | RuntimeException e) {
      log.error(Log.RENDER, "no PDF was written: " + (e.getMessage() == null ? e.toString() : e.getMessage()));
      if (options.verbose) {
        e.printStackTrace(err);
      }
      return FAILED;
    } catch (OutOfMemoryError e) {
      log.error(Log.RENDER, "no PDF was written: the document needs more memory than Java was given. Raise the limit,"
          + " for example DESIGNSYSTEMPDF_OPTS=-Xmx2g, and run again.");
      return FAILED;
    }
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

  /**
   * The installation directory, which holds fonts/ beside lib/: the launcher
   * scripts pass it as designsystempdf.home; otherwise it is the parent of the
   * directory this jar sits in.
   */
  static Path home() {
    String home = System.getProperty("designsystempdf.home");
    if (home != null && !home.isBlank()) {
      return Paths.get(home);
    }
    try {
      Path jar = Paths.get(Main.class.getProtectionDomain().getCodeSource().getLocation().toURI());
      Path parent = jar.getParent();
      return parent == null || parent.getParent() == null ? Paths.get(".") : parent.getParent();
    } catch (URISyntaxException | RuntimeException e) {
      return Paths.get(".");
    }
  }
}

/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.TreeSet;
import java.util.logging.Level;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.pdmodel.common.PDMetadata;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import com.openhtmltopdf.layout.Layer;
import com.openhtmltopdf.render.RenderingContext;
import com.openhtmltopdf.mathmlsupport.MathMLDrawer;
import com.openhtmltopdf.render.Box;
import com.openhtmltopdf.render.displaylist.PagedBoxCollector;
import com.openhtmltopdf.outputdevice.helper.ExternalResourceControlPriority;
import com.openhtmltopdf.pdfboxout.PDFCreationListener;
import com.openhtmltopdf.pdfboxout.PdfBoxRenderer;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import com.openhtmltopdf.svgsupport.BatikSVGDrawer;
import com.openhtmltopdf.util.Diagnostic;
import com.openhtmltopdf.util.XRLog;
import com.openhtmltopdf.util.XRLogger;

/** Reads the print document, prepares it in memory and lays it out as a PDF. */
final class Renderer {

  /** The document is not one this version renders; the message says what to install. */
  static final class ContractException extends Exception {
    private static final long serialVersionUID = 1L;

    ContractException(String message) {
      super(message);
    }
  }

  /** The print document cannot be read. */
  static final class InputException extends Exception {
    private static final long serialVersionUID = 1L;

    InputException(String message, Throwable cause) {
      super(message, cause);
    }
  }

  private final Options options;
  private final Log log;
  private final Path fontsDir;
  private final String version;

  Renderer(Options options, Log log, Path fontsDir, String version) {
    this.options = options;
    this.log = log;
    this.fontsDir = fontsDir;
    this.version = version;
  }

  /** Writes the PDF and returns its page count. */
  int render() throws IOException, ContractException, InputException {
    byte[] source;
    Document doc;
    try {
      source = Files.readAllBytes(options.in);
      doc = parse(source);
    } catch (IOException e) {
      throw new InputException("cannot read the print document " + options.in + ": " + e.getMessage(), e);
    } catch (SAXException e) {
      throw new InputException("the print document " + options.in + " is not well-formed XHTML: " + e.getMessage(), e);
    }
    String contract = PrintContract.read(doc);
    String refusal = PrintContract.refusal(contract, version);
    if (refusal != null) {
      throw new ContractException(refusal);
    }
    log.info(contract == null
        ? "no " + PrintContract.META_NAME + " marker: rendering the document as ordinary XHTML"
        : "print contract " + contract);

    FontRegistry fonts = new FontRegistry(log);
    if (options.fonts != null) {
      fonts.addPublisherFonts(options.fonts);
    }
    fonts.addBundledFonts(fontsDir);

    new DocumentPreparer(doc, log).prepare(options.tocDepth, productCss() + "\n" + PageRules.css(options));
    reportMissingGlyphs(doc, fonts);
    reportRightToLeft(doc);

    quietLibraries();
    XRLog.setLoggerImpl(new EngineLog());

    Path out = options.out.toAbsolutePath();
    if (out.getParent() != null) {
      Files.createDirectories(out.getParent());
    }
    long seed = seed(source);
    try {
      return write(doc, fonts, out, seed);
    } catch (RuntimeException e) {
      if (!inLeader(e)) {
        throw e;
      }
      // The engine could not fit a leader even so (#182): the contents again
      // without dots, rather than no PDF at all
      log.warn(Log.LEADER, "the contents could not be laid out with dots between the titles and the page numbers,"
          + " so it has the page numbers alone. The rest of the PDF is as usual.");
      Element root = doc.getDocumentElement();
      root.setAttribute("class", (root.getAttribute("class") + " app-pdf-no-leaders").trim());
      return write(doc, fonts, out, seed);
    }
  }

  /**
   * The engine lays a contents line out with "999" standing in for each
   * target-counter and paints the real number (#182). Up to 999 pages that
   * is never too narrow. From a thousand pages, each contents entry's number
   * is read from the layout and written into the entry (data-pdf-page, which
   * pdf.css draws in place of target-counter), and the document is laid out
   * again; until the numbers stand still, at most three times. A shorter
   * document is laid out once, as it always was. (Tests move the threshold
   * with -Ddesignsystempdf.pin-from-pages to reach the fallback below.)
   */
  static final int PIN_FROM_PAGES = Integer.getInteger("designsystempdf.pin-from-pages", 1000);

  private int write(Document doc, FontRegistry fonts, Path out, long seed) throws IOException {
    // written beside the target and moved into place, so a failed run leaves no half-written PDF
    Path partial = out.resolveSibling(out.getFileName() + ".part");
    int[] pages = new int[1];
    try {
      try (OutputStream os = Files.newOutputStream(partial)) {
        PdfBoxRenderer renderer = builder(doc, fonts, os).buildPdfRenderer();
        try {
          renderer.layout();
          for (int pass = 0; pass < 3 && pageCount(renderer) >= PIN_FROM_PAGES && pinContentsPages(doc, renderer); pass++) {
            log.info("contents page numbers written in for a document of " + pageCount(renderer) + " pages; laying it out again");
            renderer.close();
            renderer = builder(doc, fonts, os).buildPdfRenderer();
            renderer.layout();
          }
          renderer.setListener(new PDFCreationListener() {
            @Override
            public void preOpen(PdfBoxRenderer r) {
            }

            @Override
            public void preWrite(PdfBoxRenderer r, int pageCount) {
              pages[0] = pageCount;
            }

            @Override
            public void onClose(PdfBoxRenderer r) {
              settle(r.getPdfDocument(), seed);
            }
          });
          renderer.createPDF();
        } finally {
          renderer.close();
        }
      }
      Files.move(partial, out, StandardCopyOption.REPLACE_EXISTING);
    } finally {
      Files.deleteIfExists(partial);
    }
    return pages[0];
  }

  private PdfRendererBuilder builder(Document doc, FontRegistry fonts, OutputStream os) {
    PdfRendererBuilder builder = new PdfRendererBuilder();
    builder.withW3cDocument(doc, options.in.toAbsolutePath().toUri().toString());
    builder.useSVGDrawer(new BatikSVGDrawer());
    builder.useMathMLDrawer(new MathMLDrawer());
    builder.usePdfUaAccessibility(options.pdfUa);
    builder.withProducer("DesignSystemPDF " + version);
    // The generator makes no request to another origin: a stylesheet, image or
    // font that is not a local file is reported and left out.
    builder.useExternalResourceAccessControl((uri, type) -> local(uri), ExternalResourceControlPriority.RUN_BEFORE_RESOLVING_URI);
    builder.useExternalResourceAccessControl((uri, type) -> local(uri), ExternalResourceControlPriority.RUN_AFTER_RESOLVING_URI);
    fonts.registerWith(builder);
    builder.toStream(os);
    return builder;
  }

  private static int pageCount(PdfBoxRenderer renderer) {
    return renderer.getRootBox().getLayer().getPages().size();
  }

  /**
   * Writes each contents entry's page number, as target-counter would paint
   * it (the page where the target's content starts), into data-pdf-page;
   * true when any number was new or has moved.
   */
  static boolean pinContentsPages(Document doc, PdfBoxRenderer renderer) {
    RenderingContext c = renderer.getSharedContext().newRenderingContextInstance();
    Layer root = renderer.getRootBox().getLayer();
    boolean changed = false;
    for (Element a : contentsLinks(doc)) {
      String href = a.getAttribute("href");
      if (!a.hasAttribute("data-page-label") || !href.startsWith("#")) {
        continue;
      }
      Box target = renderer.getSharedContext().getBoxById(href.substring(1));
      if (target == null) {
        continue;
      }
      String page = Integer.toString(root.getRelativePageNo(c, PagedBoxCollector.findContentStartY(target)) + 1);
      if (!page.equals(a.getAttribute("data-pdf-page"))) {
        a.setAttribute("data-pdf-page", page);
        changed = true;
      }
    }
    return changed;
  }

  /**
   * The links in the contents lists, gathered once. The document can be
   * tens of megabytes: a live NodeList over all of it is walked again after
   * every attribute set, so only the contents is walked, and only once.
   */
  private static List<Element> contentsLinks(Document doc) {
    List<Element> links = new ArrayList<>();
    collectContentsLinks(doc.getDocumentElement(), false, links);
    return links;
  }

  private static void collectContentsLinks(Element e, boolean inContents, List<Element> links) {
    boolean here = inContents || DocumentPreparer.hasClass(e, "app-print-contents__list");
    if (here && "a".equals(e.getLocalName())) {
      links.add(e);
    }
    // below the contents nothing else is wanted: topics are not walked
    if (!here && DocumentPreparer.hasClass(e, "app-print-topic")) {
      return;
    }
    for (org.w3c.dom.Node c = e.getFirstChild(); c != null; c = c.getNextSibling()) {
      if (c instanceof Element child) {
        collectContentsLinks(child, here, links);
      }
    }
  }

  /** Whether the engine failed while sizing a leader (#182). */
  static boolean inLeader(Throwable e) {
    for (Throwable t = e; t != null; t = t.getCause()) {
      for (StackTraceElement f : t.getStackTrace()) {
        if (f.getClassName().contains("LeaderFunction")) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Equal input gives equal bytes: the engine stamps the clock into the
   * document information and the XMP packet, and the PDF library seeds the
   * file identifier from the time. The date becomes the one the caller gave,
   * or is left out; the identifier is seeded from the source and the options.
   */
  private void settle(PDDocument pdf, long seed) {
    PDDocumentInformation info = pdf.getDocumentInformation();
    info.setCreator("DesignSystemPDF " + version);
    String xmpDate = null;
    if (options.fixedDate != null) {
      GregorianCalendar when = new GregorianCalendar(TimeZone.getTimeZone("UTC"), Locale.ROOT);
      when.setTimeInMillis(options.fixedDate.toEpochMilli());
      info.setCreationDate(when);
      info.setModificationDate(when);
      xmpDate = DateTimeFormatter.ISO_OFFSET_DATE_TIME.format(
          options.fixedDate.atOffset(ZoneOffset.UTC).withNano(0)).replace("Z", "+00:00");
    } else {
      info.getCOSObject().removeItem(COSName.CREATION_DATE);
      info.getCOSObject().removeItem(COSName.MOD_DATE);
    }
    PDMetadata metadata = pdf.getDocumentCatalog().getMetadata();
    if (metadata != null) {
      try {
        String xmp = new String(metadata.toByteArray(), StandardCharsets.UTF_8);
        for (String property : new String[] {"xmp:CreateDate", "xmp:ModifyDate", "xmp:MetadataDate"}) {
          String element = "<" + property + ">[^<]*</" + property + ">";
          xmp = xmpDate == null
              ? xmp.replaceAll("[ \\t]*" + element + "\\r?\\n?", "")
              : xmp.replaceAll(element, "<" + property + ">" + xmpDate + "</" + property + ">");
        }
        if (xmpDate != null && !xmp.contains("<xmp:CreateDate>")) {
          // a PDF/UA-only packet carries no dates of its own; the document information's are mirrored
          xmp = xmp.replace("</rdf:RDF>", "  <rdf:Description xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\" rdf:about=\"\">\n"
              + "      <xmp:CreateDate>" + xmpDate + "</xmp:CreateDate>\n"
              + "      <xmp:ModifyDate>" + xmpDate + "</xmp:ModifyDate>\n"
              + "    </rdf:Description>\n  </rdf:RDF>");
        }
        PDMetadata settled = new PDMetadata(pdf, new ByteArrayInputStream(xmp.getBytes(StandardCharsets.UTF_8)));
        pdf.getDocumentCatalog().setMetadata(settled);
      } catch (IOException e) {
        log.info("the XMP packet could not be rewritten (" + e.getMessage() + "); its dates are the engine's");
      }
    }
    pdf.setDocumentId(seed);
  }

  private long seed(byte[] source) {
    try {
      MessageDigest sha = MessageDigest.getInstance("SHA-256");
      sha.update(source);
      sha.update((version + "|" + options.paper + "|" + options.orientation + "|" + options.margins + "|"
          + options.doubleSided + "|" + options.pdfUa + "|" + options.tocDepth + "|" + options.fixedDate)
          .getBytes(StandardCharsets.UTF_8));
      byte[] d = sha.digest();
      long seed = 0;
      for (int i = 0; i < 8; i++) {
        seed = (seed << 8) | (d[i] & 0xff);
      }
      return seed;
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException(e);
    }
  }

  private static boolean local(String uri) {
    String u = uri == null ? "" : uri.trim().toLowerCase(Locale.ROOT);
    return !(u.startsWith("http:") || u.startsWith("https:") || u.startsWith("ftp:") || u.startsWith("//"));
  }

  /** A namespace-aware parse that fetches nothing: no DTD, no external entity. */
  static Document parse(byte[] source) throws IOException, SAXException {
    try {
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      factory.setNamespaceAware(true);
      factory.setXIncludeAware(false);
      factory.setExpandEntityReferences(false);
      factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
      factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
      factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
      factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
      DocumentBuilder builder = factory.newDocumentBuilder();
      // the print document's doctype is the HTML5 legacy-compat one; nothing is behind it
      builder.setEntityResolver((publicId, systemId) -> new InputSource(new StringReader("")));
      builder.setErrorHandler(null);
      return builder.parse(new ByteArrayInputStream(source));
    } catch (ParserConfigurationException e) {
      throw new IOException("no XML parser is available: " + e.getMessage(), e);
    }
  }

  private String productCss() throws IOException {
    try (InputStream is = Renderer.class.getResourceAsStream("pdf.css")) {
      if (is == null) {
        throw new IOException("pdf.css is missing from the generator's jar");
      }
      return new String(is.readAllBytes(), StandardCharsets.UTF_8);
    }
  }

  private void reportMissingGlyphs(Document doc, FontRegistry fonts) {
    TreeSet<Integer> used = DocumentPreparer.codePoints(doc);
    List<String> missing = new ArrayList<>();
    for (int cp : used) {
      if (!fonts.covers(cp)) {
        String name = Character.getName(cp);
        missing.add(String.format("U+%04X", cp) + (name == null ? "" : " " + name));
      }
    }
    if (!missing.isEmpty()) {
      int shown = Math.min(missing.size(), 6);
      log.warn(Log.GLYPHS, missing.size() + " character(s) in the document have no glyph in the bundled fonts"
          + " or in --fonts and will print as a replacement mark: " + String.join(", ", missing.subList(0, shown))
          + (missing.size() > shown ? ", ..." : "")
          + ". Supply a TrueType font that covers them with --fonts.");
    }
  }

  /**
   * Text in a right-to-left script is drawn letter by letter from the left,
   * unjoined: a font that has the letters makes the marks go and leaves the
   * text unreadable. The publisher is told, whatever the fonts.
   */
  private void reportRightToLeft(Document doc) {
    List<String> found = new ArrayList<>();
    for (int cp : DocumentPreparer.codePoints(doc)) {
      byte direction = Character.getDirectionality(cp);
      if (direction == Character.DIRECTIONALITY_RIGHT_TO_LEFT
          || direction == Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC) {
        String name = Character.getName(cp);
        found.add(String.format("U+%04X", cp) + (name == null ? "" : " " + name));
      }
    }
    if (!found.isEmpty()) {
      int shown = Math.min(found.size(), 3);
      log.warn(Log.RTL, "the document has text in a right-to-left script (" + found.size() + " different character(s): "
          + String.join(", ", found.subList(0, shown)) + (found.size() > shown ? ", ..." : "")
          + "). This version neither joins its letters nor sets it from the right, so it will not read correctly"
          + " in the PDF, whatever fonts are supplied. Print the print document from a browser instead.");
    }
  }

  /** The PDF, font and SVG libraries log through java.util.logging; their chatter is for --verbose. */
  private void quietLibraries() {
    java.util.logging.Logger root = java.util.logging.Logger.getLogger("");
    root.setLevel(log.verbose() ? Level.INFO : Level.SEVERE);
    for (java.util.logging.Handler h : root.getHandlers()) {
      h.setLevel(log.verbose() ? Level.INFO : Level.SEVERE);
    }
  }

  /**
   * The engine's diagnostics. A stylesheet written for browsers is full of
   * rules a paged engine skips, so its CSS reports are for --verbose; a
   * resource that cannot be loaded is a warning the publisher should see.
   */
  private final class EngineLog implements XRLogger {
    @Override
    public void log(String where, Level level, String msg) {
      log(where, level, msg, null);
    }

    @Override
    public void log(String where, Level level, String msg, Throwable th) {
      if (level.intValue() < Level.WARNING.intValue()) {
        return;
      }
      String text = (th == null || th.getMessage() == null ? msg : msg + " (" + th.getMessage() + ")")
          .replaceAll("\\s+", " ").trim();
      if (XRLog.LOAD.equals(where) || XRLog.EXCEPTION.equals(where)) {
        boolean remote = text.contains("http:") || text.contains("https:");
        log.warn(remote ? Log.REMOTE : Log.RESOURCE, remote
            ? "a resource on another origin was not fetched (the generator makes no network request): " + text
            : text);
      } else {
        log.info(where + ": " + text);
      }
    }

    @Override
    public void setLevel(String logger, Level level) {
    }

    @Override
    public boolean isLogLevelEnabled(Diagnostic diagnostic) {
      return diagnostic.getLevel().intValue() >= Level.WARNING.intValue();
    }
  }
}

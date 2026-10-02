/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import java.util.Set;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

/**
 * The interface between the plugin and the generator (design 13, section 7):
 * the plugin writes {@code <meta name="govuk-print-contract" content="N">} into
 * the print document, and N changes only when the structure a paged renderer
 * relies on changes. A document with a contract this version does not know is
 * refused rather than rendered wrongly; a document with no marker is ordinary
 * XHTML and is rendered as it stands.
 */
final class PrintContract {

  static final String META_NAME = "govuk-print-contract";

  /** Contracts this version renders. Contract 1 is written by org.istanduk.gov-uk 1.0.1 and later 1.x. */
  static final Set<String> UNDERSTOOD = Set.of("1");

  private PrintContract() {
  }

  /** The marker's value, or null when the document carries none. */
  static String read(Document document) {
    NodeList metas = document.getElementsByTagNameNS("*", "meta");
    for (int i = 0; i < metas.getLength(); i++) {
      Element meta = (Element) metas.item(i);
      if (META_NAME.equals(meta.getAttribute("name"))) {
        return meta.getAttribute("content").trim();
      }
    }
    return null;
  }

  /** Null when the document can be rendered; otherwise the reason it is refused. */
  static String refusal(String contract, String generatorVersion) {
    if (contract == null || UNDERSTOOD.contains(contract)) {
      return null;
    }
    return "the print document declares " + META_NAME + " '" + contract + "', which DesignSystemPDF "
        + generatorVersion + " does not understand (it understands: " + String.join(", ", UNDERSTOOD) + "). "
        + "Contract 1 is written by org.istanduk.gov-uk 1.0.1 and later 1.x releases: build the print document "
        + "with one of those, or install a DesignSystemPDF release that lists contract '" + contract
        + "' (designsystempdf --version).";
  }
}

/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;

class PrintContractTest {

  private static Document document(String head) throws Exception {
    String xhtml = "<html xmlns=\"http://www.w3.org/1999/xhtml\"><head>" + head + "<title>t</title></head><body/></html>";
    return Renderer.parse(xhtml.getBytes(StandardCharsets.UTF_8));
  }

  @Test
  void theMarkerIsRead() throws Exception {
    assertEquals("1", PrintContract.read(document("<meta name=\"govuk-print-contract\" content=\"1\"/>")));
    assertEquals("2", PrintContract.read(document("<meta name=\"robots\" content=\"noindex\"/><meta name=\"govuk-print-contract\" content=\" 2 \"/>")));
    assertNull(PrintContract.read(document("<meta name=\"robots\" content=\"noindex\"/>")));
  }

  @Test
  void aKnownContractAndAnUnmarkedDocumentAreRendered() {
    assertNull(PrintContract.refusal("1", "0.1.0"));
    assertNull(PrintContract.refusal(null, "0.1.0"));
  }

  @Test
  void anUnknownContractIsRefusedNamingWhatToInstall() {
    String refusal = PrintContract.refusal("2", "0.1.0");
    assertNotNull(refusal);
    assertTrue(refusal.contains("govuk-print-contract '2'"), refusal);
    assertTrue(refusal.contains("DesignSystemPDF 0.1.0"), refusal);
    assertTrue(refusal.contains("org.istanduk.gov-uk 1.0.1"), refusal);
    assertNotNull(PrintContract.refusal("", "0.1.0"));
  }
}

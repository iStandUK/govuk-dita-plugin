/*
 * This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 */
package org.istanduk.designsystempdf;

/** The command line cannot be acted on; the message says why. */
final class UsageException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  UsageException(String message) {
    super(message);
  }
}

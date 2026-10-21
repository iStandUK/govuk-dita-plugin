<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Key references in topic content (#244). A keyref that names no key leaves no
trace at DITA-OT's default log level (its only report, DOTJ047I, is an
information message), and the element is written empty: a ph or uicontrol with
nothing in it, an img with neither src nor alt. The plugin already warns when a
navigation entry's key never resolved (GOVK001W); this is the counterpart for
content (GOVK015W), one warning per element, naming the key.

What the preprocessed topic shows, and so what counts as unresolved: a key that
resolved has put its text into the element or an href on it; one that did not
leaves the element as the author wrote it. Content the author wrote inside the
element is DITA's fallback for a missing key and is rendered, so it is not
reported. That leaves three cases, all certain: an element of a kind that
shows its key's text and is empty, a link with no target and no text, and an
image with no source. An image with no source cannot be shown, so it is left
out rather than written as an <img> with no src, which would make the page
invalid HTML (and, in a PDF, an image with no alternative text).
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- yes: report each one. The print document is made from the same topics, so
       map2govuk-print.xsl sets this to no: each element is reported once. -->
  <xsl:variable name="govuk-keyref-report" as="xs:string" select="'yes'"/>

  <xsl:function name="govuk:unresolved-keyref" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="exists($e/@keyref) and not($e/@href)
                          and (some $c in tokenize($e/@class) satisfies
                                 $c = ('topic/image', 'topic/keyword', 'topic/ph', 'topic/term',
                                       'topic/cite', 'topic/xref', 'topic/link'))
                          and (if (contains($e/@class, ' topic/image '))
                               then true()
                               else empty($e/node()[self::* or (self::text() and normalize-space(.) ne '')]))"/>
  </xsl:function>

  <xsl:template match="*[govuk:unresolved-keyref(.)]" priority="30">
    <xsl:if test="$govuk-keyref-report = 'yes'">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK015W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate(string(@keyref), ';', ',')"/>;%2=<xsl:value-of select="name()"/>;%3=<xsl:value-of select="if (contains(@class, ' topic/image ')) then 'left out' else 'written empty'"/></xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <!-- an image with no source cannot be shown; everything else renders as the toolkit would -->
    <xsl:if test="not(contains(@class, ' topic/image '))">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

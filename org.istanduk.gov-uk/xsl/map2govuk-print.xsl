<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Entry point of the govuk.print Ant target (FR-P2, D-20): the same map
transformation as the cover, with the topic-rendering stylesheets the site
pages use, whose whole output is the print document. Kept out of the cover
run so builds without govuk.print load no topics twice.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="3.0">

  <xsl:import href="map2govuk-cover.xsl"/>
  <xsl:import href="blocks.xsl"/>
  <xsl:import href="foreign.xsl"/>
  <xsl:import href="print-document.xsl"/>

  <xsl:output method="xhtml"
              html-version="5.0"
              encoding="UTF-8"
              include-content-type="no"
              omit-xml-declaration="yes"
              indent="no"/>

  <xsl:template name="chapter-setup">
    <xsl:call-template name="govuk-print-document"/>
  </xsl:template>

</xsl:stylesheet>

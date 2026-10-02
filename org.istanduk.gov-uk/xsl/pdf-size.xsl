<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

A file size for a link's text (#146): "356 KB", "1.2 MB". Run by the
govuk.pdf Ant target, which has the generated PDF's length in bytes but no
arithmetic of its own; the input document is not read.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="BYTES" select="'0'"/>

  <xsl:template match="/">
    <xsl:variable name="bytes" select="number($BYTES)"/>
    <xsl:choose>
      <!-- anything that would round to 1024 KB or more reads in megabytes -->
      <xsl:when test="$bytes >= 1048064">
        <xsl:value-of select="concat(format-number($bytes div 1048576, '0.0'), ' MB')"/>
      </xsl:when>
      <xsl:when test="$bytes > 1024">
        <xsl:value-of select="concat(format-number($bytes div 1024, '0'), ' KB')"/>
      </xsl:when>
      <xsl:otherwise>1 KB</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

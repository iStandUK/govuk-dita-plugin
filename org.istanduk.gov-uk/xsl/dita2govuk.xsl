<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Shell stylesheet for the govuk transtype: the standard HTML5 processing chain
first, then this plugin's overrides at higher import precedence, so any element
we do not override keeps its default html5 rendering.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="3.0">

  <xsl:import href="plugin:org.dita.html5:xsl/dita2html5.xsl"/>
  <xsl:import href="furniture.xsl"/>
  <xsl:import href="template.xsl"/>
  <xsl:import href="blocks.xsl"/>
  <xsl:import href="foreign.xsl"/>
  <xsl:import href="search.xsl"/>

</xsl:stylesheet>

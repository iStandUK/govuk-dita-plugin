<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Page skeleton: GOV.UK template structure (skip link, masthead, width container,
grid with sidebar navigation and main content, footer) replacing the default
html5 page furniture. Content rendering is inherited; see blocks.xsl for
element-level typography.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="3.0"
                exclude-result-prefixes="xs">

  <!-- Passed from insertParameters.xml -->
  <xsl:param name="GOVUK-BRANDING" select="'neutral'"/>
  <xsl:param name="GOVUK-SERVICE-NAME" select="''"/>
  <xsl:param name="GOVUK-SEARCH" select="'no'"/>
  <xsl:param name="GOVUK-GLOSSARY" select="'no'"/>
  <xsl:param name="GOVUK-INDEX" select="'no'"/>

  <!-- Pinned vendored govuk-frontend release (see resource/govuk-frontend/VERSION.txt) -->
  <xsl:variable name="govuk-frontend-version" select="'6.5.0'" as="xs:string"/>

  <!-- Service name shown in the masthead: explicit parameter, else map title -->
  <xsl:variable name="govuk-service-name" as="xs:string">
    <xsl:choose>
      <xsl:when test="normalize-space($GOVUK-SERVICE-NAME)">
        <xsl:sequence select="normalize-space($GOVUK-SERVICE-NAME)"/>
      </xsl:when>
      <xsl:when test="exists($input.map)">
        <!-- Bookmap titles normalise to a title containing mainbooktitle plus
             booktitlealt (often a long abstract); use the main title alone -->
        <xsl:variable name="map-title" as="element()?"
                      select="$input.map/*[contains(@class, ' map/map ')]/*[contains(@class, ' topic/title ')]"/>
        <xsl:variable name="main-title" as="element()?"
                      select="$map-title//*[contains(@class, ' bookmap/mainbooktitle ')][1]"/>
        <xsl:sequence select="normalize-space(string(($main-title, $map-title)[1]))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Masthead link target: the generated cover (home) page at the site root -->
  <xsl:variable name="govuk-home-href" as="xs:string"
                select="concat($PATH2PROJ, 'index', $OUTEXT)"/>

  <!-- Root element carries the GOV.UK template class -->
  <xsl:template name="chapter-setup">
    <html class="govuk-template">
      <xsl:call-template name="setTopicLanguage"/>
      <xsl:call-template name="chapterHead"/>
      <xsl:call-template name="chapterBody"/>
    </html>
  </xsl:template>

  <!-- Responsive viewport (html5 base emits none) -->
  <xsl:template name="gen-user-head">
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <xsl:apply-templates select="." mode="gen-user-head"/>
  </xsl:template>

  <!-- Stylesheets: vendored govuk-frontend, the neutral overlay (unless the
       publisher opted into official branding), plugin furniture styles, then
       any user stylesheet from args.css so publishers can override (FR-T4). -->
  <xsl:template name="generateCssLinks">
    <link rel="stylesheet"
          href="{concat($PATH2PROJ, 'govuk/govuk-frontend-', $govuk-frontend-version, '.min.css')}"/>
    <xsl:if test="$GOVUK-BRANDING ne 'official'">
      <link rel="stylesheet" href="{concat($PATH2PROJ, 'govuk/overlay-neutral.css')}"/>
    </xsl:if>
    <link rel="stylesheet" href="{concat($PATH2PROJ, 'govuk/plugin.css')}"/>
    <xsl:if test="string-length($CSS) gt 0">
      <link rel="stylesheet" href="{concat($PATH2PROJ, $CSSPATH, $CSS)}"/>
    </xsl:if>
  </xsl:template>

  <!-- Main content region gains the GOV.UK wrapper, the skip-link target, and
       the Pagefind indexing scope (FR-S3: only topic content is searchable;
       pages without the attribute, like the cover, stay out of the index) -->
  <xsl:attribute-set name="main">
    <xsl:attribute name="id">main-content</xsl:attribute>
    <xsl:attribute name="class">govuk-main-wrapper</xsl:attribute>
    <xsl:attribute name="data-pagefind-body"/>
  </xsl:attribute-set>

  <!-- Sidebar navigation keeps the inherited tree markup, restyled -->
  <xsl:attribute-set name="toc">
    <xsl:attribute name="class">toc app-sidebar__nav</xsl:attribute>
    <xsl:attribute name="aria-label">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.contents'"/>
      </xsl:call-template>
    </xsl:attribute>
  </xsl:attribute-set>

  <!-- Page body: GOV.UK template structure around the inherited content and
       navigation modes -->
  <xsl:template match="*" mode="chapterBody">
    <body>
      <xsl:apply-templates select="." mode="addAttributesToHtmlBodyElement"/>
      <xsl:attribute name="class">govuk-template__body</xsl:attribute>
      <script>
        <xsl:text>document.body.className += ('noModule' in HTMLScriptElement.prototype ? ' govuk-frontend-supported' : '');</xsl:text>
      </script>
      <a href="#main-content" class="govuk-skip-link" data-module="govuk-skip-link">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.skip-link'"/>
        </xsl:call-template>
      </a>
      <xsl:call-template name="govuk-masthead">
        <xsl:with-param name="prefix" select="string($PATH2PROJ)"/>
        <xsl:with-param name="name" select="$govuk-service-name"/>
        <xsl:with-param name="home-href" select="$govuk-home-href"/>
        <xsl:with-param name="search-enabled" select="$GOVUK-SEARCH"/>
      </xsl:call-template>
      <div class="govuk-width-container">
        <div class="govuk-grid-row">
          <div class="govuk-grid-column-one-third app-sidebar">
            <xsl:attribute name="data-label-menu">
              <xsl:call-template name="getVariable">
                <xsl:with-param name="id" select="'govuk-dita.menu'"/>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="data-label-toggle">
              <xsl:call-template name="getVariable">
                <xsl:with-param name="id" select="'govuk-dita.toggle-section'"/>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:call-template name="gen-user-sidetoc"/>
          </div>
          <div class="govuk-grid-column-two-thirds">
            <xsl:apply-templates select="." mode="addContentToHtmlBodyElement"/>
          </div>
        </div>
      </div>
      <xsl:call-template name="govuk-site-footer">
        <xsl:with-param name="prefix" select="string($PATH2PROJ)"/>
        <xsl:with-param name="name" select="$govuk-service-name"/>
        <xsl:with-param name="glossary" select="$GOVUK-GLOSSARY"/>
        <xsl:with-param name="index" select="$GOVUK-INDEX"/>
      </xsl:call-template>
      <script src="{concat($PATH2PROJ, 'govuk/plugin.js')}"></script>
      <script type="module">
        <xsl:text>import { initAll } from './</xsl:text>
        <xsl:value-of select="$PATH2PROJ"/>
        <xsl:text>govuk/govuk-frontend-</xsl:text>
        <xsl:value-of select="$govuk-frontend-version"/>
        <xsl:text>.min.js'; initAll();</xsl:text>
      </script>
    </body>
  </xsl:template>

</xsl:stylesheet>

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
                xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
                version="3.0"
                exclude-result-prefixes="xs dita-ot">

  <!-- Passed from insertParameters.xml -->
  <xsl:param name="GOVUK-BRANDING" select="'neutral'"/>
  <xsl:param name="GOVUK-SERVICE-NAME" select="''"/>
  <xsl:param name="GOVUK-SEARCH" select="'no'"/>
  <xsl:param name="GOVUK-GLOSSARY" select="'no'"/>
  <xsl:param name="GOVUK-INDEX" select="'no'"/>
  <xsl:param name="GOVUK-PAGINATION" select="'yes'"/>
  <xsl:param name="GOVUK-FIGURELIST" select="'no'"/>
  <xsl:param name="GOVUK-TABLELIST" select="'no'"/>
  <xsl:param name="GOVUK-PHASE" select="''"/>
  <xsl:param name="GOVUK-FEEDBACK-URL" select="''"/>

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

  <!-- Path from the current page to the output root, for assets and home
       links. The toolkit's $PATH2PROJ comes out empty for topics split by
       chunk="by-topic" (an upstream bug, present in plain html5 too), which
       breaks their CSS/JS; the navigation's own get-path2map-dir is reliable
       there, so we reuse it. Falls back to $PATH2PROJ when no map is in play. -->
  <xsl:variable name="govuk-root" as="xs:string"
                select="if (exists($input.map.url) and normalize-space($input.map.url))
                        then string($pathToMapDir) else string($PATH2PROJ)"/>

  <!-- Masthead link target: the generated cover (home) page at the site root -->
  <xsl:variable name="govuk-home-href" as="xs:string"
                select="concat($govuk-root, 'index', $OUTEXT)"/>

  <!-- Previous/next pagination (FR-N5, #32): adjacent navigable topics in the
       map's linear reading order, which also surfaces collection-type=sequence. -->
  <xsl:template name="govuk-pagination">
    <xsl:variable name="reading" as="element()*"
                  select="$input.map//*[contains(@class, ' map/topicref ')]
                          [normalize-space(@href)]
                          [not(@processing-role = 'resource-only')]
                          [not(@scope = 'external')]
                          [not(@format) or @format = 'dita']"/>
    <!-- Match the current page by its resolved href rather than nav.xsl's
         $current-topicref, which for keyref maps can resolve to the
         resource-only keydef (excluded from $reading). -->
    <xsl:variable name="pos" as="xs:integer*"
                  select="for $i in 1 to count($reading)
                          return $i[dita-ot:get-path($PATH2PROJ, $reading[$i]) = $current-file]"/>
    <xsl:if test="exists($pos)">
      <xsl:variable name="i" select="$pos[1]" as="xs:integer"/>
      <xsl:variable name="prev" select="$reading[$i - 1]" as="element()?"/>
      <xsl:variable name="next" select="$reading[$i + 1]" as="element()?"/>
      <xsl:if test="exists($prev) or exists($next)">
        <nav class="govuk-pagination govuk-pagination--block" aria-label="Pagination">
          <xsl:if test="exists($prev)">
            <div class="govuk-pagination__prev">
              <a class="govuk-pagination__link" rel="prev">
                <xsl:attribute name="href"><xsl:apply-templates select="$prev" mode="govuk-page-href"/></xsl:attribute>
                <svg class="govuk-pagination__icon govuk-pagination__icon--prev" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">
                  <path d="m6.5938-0.0078125-6.7266 6.7266 6.7441 6.4062 1.377-1.449-4.1856-3.9768h12.896v-2h-12.984l4.2931-4.293-1.3888-1.3852z"></path>
                </svg>
                <span class="govuk-pagination__link-title govuk-pagination__link-title--decorated">
                  <xsl:apply-templates select="$prev" mode="get-navtitle"/>
                </span>
              </a>
            </div>
          </xsl:if>
          <xsl:if test="exists($next)">
            <div class="govuk-pagination__next">
              <a class="govuk-pagination__link" rel="next">
                <xsl:attribute name="href"><xsl:apply-templates select="$next" mode="govuk-page-href"/></xsl:attribute>
                <svg class="govuk-pagination__icon govuk-pagination__icon--next" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">
                  <path d="m8.107-0.0078125-1.4136 1.414 4.3021 4.2949h-12.986v2h12.896l-4.1855 3.9766 1.377 1.4492 6.7441-6.4062-6.7295-6.7285z"></path>
                </svg>
                <span class="govuk-pagination__link-title govuk-pagination__link-title--decorated">
                  <xsl:apply-templates select="$next" mode="get-navtitle"/>
                </span>
              </a>
            </div>
          </xsl:if>
        </nav>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Output page href for a topicref, relative to the current page -->
  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="govuk-page-href">
    <xsl:variable name="target">
      <xsl:call-template name="replace-extension">
        <xsl:with-param name="filename" select="if (@copy-to) then @copy-to else @href"/>
        <xsl:with-param name="extension" select="$OUTEXT"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="concat($govuk-root, $target)"/>
  </xsl:template>

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

  <!-- Brand-recoloured base stylesheet: NHS uses a Sass-recompiled govuk-frontend
       palette (#47, D-17); every other brand uses the stock build. -->
  <xsl:variable name="govuk-frontend-css" as="xs:string"
                select="if ($GOVUK-BRANDING = 'nhs')
                        then concat('govuk-frontend-', $govuk-frontend-version, '-nhs.min.css')
                        else concat('govuk-frontend-', $govuk-frontend-version, '.min.css')"/>

  <!-- Stylesheets: the (brand-specific) govuk-frontend base, plugin furniture,
       then a font/brand overlay, then any args.css user stylesheet (FR-T4).
       The neutral overlay aliases GDS Transport to system fonts; official ships
       GDS Transport and NHS bakes its own font stack into the recompiled CSS,
       so neither takes the neutral overlay. -->
  <xsl:template name="generateCssLinks">
    <link rel="stylesheet"
          href="{concat($govuk-root, 'govuk/', $govuk-frontend-css)}"/>
    <link rel="stylesheet" href="{concat($govuk-root, 'govuk/plugin.css')}"/>
    <xsl:if test="$GOVUK-BRANDING = ('neutral', 'istanduk')">
      <link rel="stylesheet" href="{concat($govuk-root, 'govuk/overlay-neutral.css')}"/>
    </xsl:if>
    <xsl:if test="$GOVUK-BRANDING = 'istanduk'">
      <link rel="stylesheet" href="{concat($govuk-root, 'govuk/overlay-istanduk.css')}"/>
    </xsl:if>
    <xsl:if test="$GOVUK-BRANDING = 'nhs'">
      <link rel="stylesheet" href="{concat($govuk-root, 'govuk/overlay-nhs.css')}"/>
    </xsl:if>
    <xsl:if test="$GOVUK-BRANDING = 'official'">
      <link rel="stylesheet" href="{concat($govuk-root, 'govuk/overlay-official.css')}"/>
    </xsl:if>
    <xsl:if test="string-length($CSS) gt 0">
      <link rel="stylesheet" href="{concat($govuk-root, $CSSPATH, $CSS)}"/>
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
        <xsl:with-param name="prefix" select="$govuk-root"/>
        <xsl:with-param name="name" select="$govuk-service-name"/>
        <xsl:with-param name="home-href" select="$govuk-home-href"/>
        <xsl:with-param name="search-enabled" select="$GOVUK-SEARCH"/>
            <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
      </xsl:call-template>
      <div class="govuk-width-container">
        <xsl:call-template name="govuk-phase-banner">
          <xsl:with-param name="phase" select="$GOVUK-PHASE"/>
          <xsl:with-param name="feedback" select="$GOVUK-FEEDBACK-URL"/>
        </xsl:call-template>
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
            <xsl:if test="$GOVUK-PAGINATION = 'yes'">
              <xsl:call-template name="govuk-pagination"/>
            </xsl:if>
          </div>
        </div>
      </div>
      <xsl:call-template name="govuk-site-footer">
        <xsl:with-param name="prefix" select="$govuk-root"/>
        <xsl:with-param name="name" select="$govuk-service-name"/>
        <xsl:with-param name="glossary" select="$GOVUK-GLOSSARY"/>
        <xsl:with-param name="index" select="$GOVUK-INDEX"/>
        <xsl:with-param name="figurelist" select="$GOVUK-FIGURELIST"/>
        <xsl:with-param name="tablelist" select="$GOVUK-TABLELIST"/>
        <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
      </xsl:call-template>
      <script src="{concat($govuk-root, 'govuk/plugin.js')}"></script>
      <script type="module">
        <xsl:text>import { initAll } from '</xsl:text>
        <xsl:value-of select="if (string-length($govuk-root) gt 0) then $govuk-root else './'"/>
        <xsl:text>govuk/govuk-frontend-</xsl:text>
        <xsl:value-of select="$govuk-frontend-version"/>
        <xsl:text>.min.js'; initAll();</xsl:text>
      </script>
    </body>
  </xsl:template>

</xsl:stylesheet>

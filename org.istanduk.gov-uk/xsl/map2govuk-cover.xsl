<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

GOV.UK cover (home) page for the map: publication title, bookmap abstract and
attribution when present, and a styled contents tree (FR-N8, component C-10;
gap-analysis finding F5). Selected via the args.html5.toc.xsl property.

Note: the toolkit's map-to-cover transformation does not receive the
dita.conductor.html5.param extension parameters, so everything here is derived
from the map document itself. The neutral overlay is linked unconditionally;
revisit when official-mode branding is implemented.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="3.0"
                exclude-result-prefixes="xs">

  <xsl:import href="plugin:org.dita.html5:xsl/map2html5-cover.xsl"/>

  <xsl:output method="html"
              include-content-type="no"
              doctype-system="about:legacy-compat"
              omit-xml-declaration="yes"/>

  <xsl:variable name="govuk-frontend-version" select="'6.5.0'" as="xs:string"/>

  <xsl:variable name="govuk-cover-title" as="xs:string">
    <xsl:variable name="main" as="element()?"
                  select="(/*[contains(@class, ' map/map ')]//*[contains(@class, ' bookmap/mainbooktitle ')])[1]"/>
    <xsl:variable name="title" as="element()?"
                  select="/*[contains(@class, ' map/map ')]/*[contains(@class, ' topic/title ')]"/>
    <xsl:sequence select="normalize-space(string(($main, $title, /*[contains(@class, ' map/map ')]/@title)[1]))"/>
  </xsl:variable>

  <xsl:template name="chapter-setup">
    <html class="govuk-template">
      <xsl:call-template name="setTopicLanguage"/>
      <xsl:call-template name="chapterHead"/>
      <xsl:call-template name="chapterBody"/>
    </html>
  </xsl:template>

  <xsl:template name="gen-user-head">
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <xsl:apply-templates select="." mode="gen-user-head"/>
  </xsl:template>

  <xsl:template name="generateCssLinks">
    <link rel="stylesheet"
          href="{concat('govuk/govuk-frontend-', $govuk-frontend-version, '.min.css')}"/>
    <link rel="stylesheet" href="govuk/overlay-neutral.css"/>
    <link rel="stylesheet" href="govuk/plugin.css"/>
    <xsl:if test="string-length($CSS) gt 0">
      <link rel="stylesheet" href="{concat($CSSPATH, $CSS)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' map/map ')]" mode="chapterBody" priority="10">
    <body class="govuk-template__body">
      <script>
        <xsl:text>document.body.className += ('noModule' in HTMLScriptElement.prototype ? ' govuk-frontend-supported' : '');</xsl:text>
      </script>
      <a href="#main-content" class="govuk-skip-link" data-module="govuk-skip-link">Skip to main content</a>
      <header class="app-masthead">
        <div class="govuk-width-container">
          <a class="app-masthead__title" href="#main-content">
            <xsl:value-of select="$govuk-cover-title"/>
          </a>
        </div>
      </header>
      <div class="govuk-width-container">
        <main class="govuk-main-wrapper" id="main-content">
          <div class="govuk-grid-row">
            <div class="govuk-grid-column-two-thirds">
              <h1 class="govuk-heading-xl">
                <xsl:value-of select="$govuk-cover-title"/>
              </h1>
              <!-- Bookmap abstract (booktitlealt) as the lead -->
              <xsl:for-each select="*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')]">
                <p class="govuk-body-l">
                  <xsl:apply-templates/>
                </p>
              </xsl:for-each>
              <!-- Bookmap attribution -->
              <xsl:variable name="authors" as="xs:string*"
                            select="*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/author ')]/normalize-space()"/>
              <xsl:variable name="orgs" as="xs:string*"
                            select="*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' bookmap/organization ')]/normalize-space()"/>
              <xsl:if test="exists(($authors, $orgs)[. ne ''])">
                <p class="govuk-body app-attribution">
                  <xsl:value-of select="string-join(distinct-values(($authors, $orgs)[. ne '']), ' · ')"/>
                </p>
              </xsl:if>
              <h2 class="govuk-heading-m">Contents</h2>
              <div class="app-contents">
                <xsl:variable name="map" as="element()*">
                  <xsl:apply-templates select="." mode="normalize-map"/>
                </xsl:variable>
                <xsl:apply-templates select="$map" mode="toc"/>
              </div>
            </div>
          </div>
        </main>
      </div>
      <footer class="govuk-footer">
        <div class="govuk-width-container">
          <div class="govuk-footer__meta">
            <div class="govuk-footer__meta-item govuk-footer__meta-item--grow">
              <span class="govuk-footer__licence-description">
                <xsl:value-of select="$govuk-cover-title"/>
              </span>
            </div>
          </div>
        </div>
      </footer>
      <script type="module">
        <xsl:text>import { initAll } from './govuk/govuk-frontend-</xsl:text>
        <xsl:value-of select="$govuk-frontend-version"/>
        <xsl:text>.min.js'; initAll();</xsl:text>
      </script>
    </body>
  </xsl:template>

</xsl:stylesheet>

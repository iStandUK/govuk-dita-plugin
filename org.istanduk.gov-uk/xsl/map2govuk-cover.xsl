<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

GOV.UK cover (home) page for the map (FR-N8, C-10) with the D-13 landing-page
layouts: the layout is chosen automatically from the map's shape, or forced
with govuk.homepage.layout. Also emits the site search page (FR-S2).
Parameters arrive via the govuk.cover Ant target, which re-runs the toolkit's
map transformation with the plugin's values.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="3.0"
                exclude-result-prefixes="xs">

  <xsl:import href="plugin:org.dita.html5:xsl/map2html5-cover.xsl"/>
  <xsl:import href="utility-pages.xsl"/>

  <xsl:output method="html"
              include-content-type="no"
              doctype-system="about:legacy-compat"
              omit-xml-declaration="yes"/>

  <xsl:param name="GOVUK-HOMEPAGE-LAYOUT" select="'auto'"/>
  <xsl:param name="GOVUK-SERVICE-NAME" select="''"/>
  <xsl:param name="GOVUK-SEARCH" select="'no'"/>
  <xsl:param name="GOVUK-BRANDING" select="'neutral'"/>

  <xsl:variable name="govuk-frontend-version" select="'6.5.0'" as="xs:string"/>

  <xsl:variable name="govuk-cover-title" as="xs:string">
    <xsl:variable name="main" as="element()?"
                  select="(/*[contains(@class, ' map/map ')]//*[contains(@class, ' bookmap/mainbooktitle ')])[1]"/>
    <xsl:variable name="title" as="element()?"
                  select="/*[contains(@class, ' map/map ')]/*[contains(@class, ' topic/title ')]"/>
    <xsl:sequence select="normalize-space(string(($main, $title, /*[contains(@class, ' map/map ')]/@title)[1]))"/>
  </xsl:variable>

  <xsl:variable name="govuk-masthead-name" as="xs:string"
                select="if (normalize-space($GOVUK-SERVICE-NAME)) then normalize-space($GOVUK-SERVICE-NAME)
                        else $govuk-cover-title"/>

  <xsl:template name="chapter-setup">
    <html class="govuk-template">
      <xsl:call-template name="setTopicLanguage"/>
      <xsl:call-template name="chapterHead"/>
      <xsl:call-template name="chapterBody"/>
    </html>
    <xsl:call-template name="govuk-search-page"/>
    <xsl:call-template name="govuk-glossary-page"/>
    <xsl:call-template name="govuk-index-page"/>
  </xsl:template>

  <xsl:template name="gen-user-head">
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <xsl:apply-templates select="." mode="gen-user-head"/>
  </xsl:template>

  <xsl:template name="generateCssLinks">
    <link rel="stylesheet"
          href="{concat('govuk/govuk-frontend-', $govuk-frontend-version, '.min.css')}"/>
    <xsl:if test="$GOVUK-BRANDING ne 'official'">
      <link rel="stylesheet" href="govuk/overlay-neutral.css"/>
    </xsl:if>
    <link rel="stylesheet" href="govuk/plugin.css"/>
    <xsl:if test="string-length($CSS) gt 0">
      <link rel="stylesheet" href="{concat($CSSPATH, $CSS)}"/>
    </xsl:if>
  </xsl:template>

  <!-- ===== Entry helpers ===== -->

  <!-- Output href for a topicref, or empty -->
  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="govuk-href">
    <xsl:choose>
      <xsl:when test="normalize-space(@href) and not(@scope = 'external')
                      and (not(@format) or @format = ('dita', 'ditamap'))">
        <xsl:call-template name="replace-extension">
          <xsl:with-param name="filename" select="@href"/>
          <xsl:with-param name="extension" select="$OUTEXT"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="normalize-space(@href)">
        <xsl:value-of select="@href"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="dita-ot:govuk-desc" as="xs:string"
                xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="normalize-space(string(($ref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' map/shortdesc ')])[1]))"/>
  </xsl:function>

  <!-- A linked (or plain) entry heading with optional description -->
  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="govuk-entry">
    <xsl:param name="heading-class" select="'govuk-heading-s'"/>
    <xsl:variable name="title"><xsl:apply-templates select="." mode="get-navtitle"/></xsl:variable>
    <xsl:variable name="href"><xsl:apply-templates select="." mode="govuk-href"/></xsl:variable>
    <xsl:variable name="desc" select="dita-ot:govuk-desc(.)"
                  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"/>
    <h2 class="{$heading-class} app-entry__heading">
      <xsl:choose>
        <xsl:when test="string-length($href) gt 0">
          <a class="govuk-link" href="{$href}"><xsl:value-of select="$title"/></a>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$title"/></xsl:otherwise>
      </xsl:choose>
    </h2>
    <xsl:if test="string-length($desc) gt 0">
      <p class="govuk-body app-entry__desc"><xsl:value-of select="$desc"/></p>
    </xsl:if>
  </xsl:template>

  <!-- A plain child-link list for a group, with hint-styled descriptions -->
  <xsl:template name="govuk-child-list">
    <xsl:param name="children" as="element()*"/>
    <xsl:if test="exists($children)">
      <ul class="govuk-list app-group-list">
        <xsl:for-each select="$children">
          <xsl:variable name="title"><xsl:apply-templates select="." mode="get-navtitle"/></xsl:variable>
          <xsl:variable name="href"><xsl:apply-templates select="." mode="govuk-href"/></xsl:variable>
          <xsl:variable name="desc" select="dita-ot:govuk-desc(.)"
                        xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"/>
          <li>
            <xsl:choose>
              <xsl:when test="string-length($href) gt 0">
                <a class="govuk-link" href="{$href}"><xsl:value-of select="$title"/></a>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="$title"/></xsl:otherwise>
            </xsl:choose>
            <xsl:if test="string-length($desc) gt 0">
              <div class="govuk-hint app-group-list__hint"><xsl:value-of select="$desc"/></div>
            </xsl:if>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>

  <!-- ===== Page body ===== -->

  <xsl:template match="*[contains(@class, ' map/map ')]" mode="chapterBody" priority="10">
    <xsl:variable name="map" select="$govuk-norm-map" as="element()*"/>
    <xsl:variable name="entries" as="element()*"
                  select="$map/*[contains(@class, ' map/topicref ')]
                          [not(@processing-role = 'resource-only')]
                          [not(@toc = 'no')]
                          [not(contains(@class, ' bookmap/frontmatter '))]
                          [not(contains(@class, ' bookmap/backmatter '))]"/>
    <xsl:variable name="chapter-count"
                  select="count($entries[contains(@class, ' bookmap/chapter ') or contains(@class, ' bookmap/part ')])"/>
    <xsl:variable name="layout" as="xs:string">
      <xsl:choose>
        <xsl:when test="$GOVUK-HOMEPAGE-LAYOUT ne 'auto'">
          <xsl:sequence select="$GOVUK-HOMEPAGE-LAYOUT"/>
        </xsl:when>
        <xsl:when test="count($entries) eq 1">start</xsl:when>
        <xsl:when test="$chapter-count ge 2">grouped</xsl:when>
        <xsl:when test="count($entries) le 8">annotated</xsl:when>
        <xsl:otherwise>grouped</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <body class="govuk-template__body">
      <script>
        <xsl:text>document.body.className += ('noModule' in HTMLScriptElement.prototype ? ' govuk-frontend-supported' : '');</xsl:text>
      </script>
      <a href="#main-content" class="govuk-skip-link" data-module="govuk-skip-link">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.skip-link'"/>
        </xsl:call-template>
      </a>
      <header class="app-masthead">
        <div class="govuk-width-container">
          <a class="app-masthead__title" href="#main-content">
            <xsl:value-of select="$govuk-masthead-name"/>
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
              <xsl:for-each select="*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')]">
                <p class="govuk-body-l"><xsl:apply-templates/></p>
              </xsl:for-each>
              <xsl:variable name="authors" as="xs:string*"
                            select="*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/author ')]/normalize-space()"/>
              <xsl:variable name="orgs" as="xs:string*"
                            select="*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' bookmap/organization ')]/normalize-space()"/>
              <xsl:if test="exists(($authors, $orgs)[. ne ''])">
                <p class="govuk-body app-attribution">
                  <xsl:value-of select="string-join(distinct-values(($authors, $orgs)[. ne '']), ' · ')"/>
                </p>
              </xsl:if>
              <xsl:if test="$GOVUK-SEARCH = 'yes' or exists($govuk-gloss) or exists($govuk-ix)">
                <ul class="govuk-list app-utility-nav">
                  <xsl:if test="$GOVUK-SEARCH = 'yes'">
                    <li>
                      <a class="govuk-link" href="search.html">
                        <xsl:call-template name="getVariable">
                          <xsl:with-param name="id" select="'govuk-dita.search-this-site'"/>
                        </xsl:call-template>
                      </a>
                    </li>
                  </xsl:if>
                  <xsl:if test="exists($govuk-gloss)">
                    <li>
                      <a class="govuk-link" href="glossary.html">
                        <xsl:call-template name="getVariable">
                          <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
                        </xsl:call-template>
                      </a>
                    </li>
                  </xsl:if>
                  <xsl:if test="exists($govuk-ix)">
                    <li>
                      <a class="govuk-link" href="index-page.html">
                        <xsl:call-template name="getVariable">
                          <xsl:with-param name="id" select="'govuk-dita.index'"/>
                        </xsl:call-template>
                      </a>
                    </li>
                  </xsl:if>
                </ul>
              </xsl:if>
              <xsl:choose>
                <xsl:when test="$layout = 'start'">
                  <xsl:call-template name="govuk-layout-start">
                    <xsl:with-param name="entries" select="$entries"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="$layout = 'annotated'">
                  <xsl:call-template name="govuk-contents-heading"/>
                  <xsl:apply-templates select="$entries" mode="govuk-entry"/>
                </xsl:when>
                <xsl:when test="$layout = 'grid'">
                  <xsl:call-template name="govuk-contents-heading"/>
                  <div class="govuk-grid-row app-topic-grid">
                    <xsl:for-each select="$entries">
                      <div class="govuk-grid-column-one-third">
                        <xsl:apply-templates select="." mode="govuk-entry"/>
                        <xsl:call-template name="govuk-child-list">
                          <xsl:with-param name="children"
                                          select="*[contains(@class, ' map/topicref ')]
                                                  [not(@processing-role = 'resource-only')][not(@toc = 'no')]"/>
                        </xsl:call-template>
                      </div>
                    </xsl:for-each>
                  </div>
                </xsl:when>
                <xsl:when test="$layout = 'grouped'">
                  <xsl:call-template name="govuk-contents-heading"/>
                  <xsl:for-each select="$entries">
                    <xsl:apply-templates select="." mode="govuk-entry">
                      <xsl:with-param name="heading-class" select="'govuk-heading-m'"/>
                    </xsl:apply-templates>
                    <xsl:call-template name="govuk-child-list">
                      <xsl:with-param name="children"
                                      select="*[contains(@class, ' map/topicref ')]
                                              [not(@processing-role = 'resource-only')][not(@toc = 'no')]"/>
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:when>
                <xsl:when test="$layout = 'accordion'">
                  <xsl:call-template name="govuk-contents-heading"/>
                  <div class="govuk-accordion" data-module="govuk-accordion" id="app-contents-accordion">
                    <xsl:for-each select="$entries">
                      <xsl:variable name="pos" select="position()"/>
                      <div class="govuk-accordion__section">
                        <div class="govuk-accordion__section-header">
                          <h2 class="govuk-accordion__section-heading">
                            <span class="govuk-accordion__section-button" id="app-accordion-heading-{$pos}">
                              <xsl:apply-templates select="." mode="get-navtitle"/>
                            </span>
                          </h2>
                        </div>
                        <div id="app-accordion-content-{$pos}" class="govuk-accordion__section-content">
                          <xsl:variable name="children" as="element()*"
                                        select="*[contains(@class, ' map/topicref ')]
                                                [not(@processing-role = 'resource-only')][not(@toc = 'no')]"/>
                          <xsl:choose>
                            <xsl:when test="exists($children)">
                              <xsl:call-template name="govuk-child-list">
                                <xsl:with-param name="children" select="$children"/>
                              </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:call-template name="govuk-child-list">
                                <xsl:with-param name="children" select="."/>
                              </xsl:call-template>
                            </xsl:otherwise>
                          </xsl:choose>
                        </div>
                      </div>
                    </xsl:for-each>
                  </div>
                </xsl:when>
                <xsl:otherwise>
                  <!-- 'list': the original plain contents tree -->
                  <xsl:call-template name="govuk-contents-heading"/>
                  <div class="app-contents">
                    <xsl:apply-templates select="$map" mode="toc"/>
                  </div>
                </xsl:otherwise>
              </xsl:choose>
            </div>
          </div>
        </main>
      </div>
      <footer class="govuk-footer">
        <div class="govuk-width-container">
          <div class="govuk-footer__meta">
            <div class="govuk-footer__meta-item govuk-footer__meta-item--grow">
              <span class="govuk-footer__licence-description">
                <xsl:value-of select="$govuk-masthead-name"/>
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

  <xsl:template name="govuk-contents-heading">
    <h2 class="govuk-heading-m">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.contents'"/>
      </xsl:call-template>
    </h2>
  </xsl:template>

  <!-- Single-entry publication: hero + Start button + the entry's contents -->
  <xsl:template name="govuk-layout-start">
    <xsl:param name="entries" as="element()*"/>
    <xsl:variable name="entry" select="$entries[1]"/>
    <xsl:variable name="target" as="element()?"
                  select="($entry/descendant-or-self::*[contains(@class, ' map/topicref ')]
                          [normalize-space(@href)]
                          [not(@processing-role = 'resource-only')])[1]"/>
    <xsl:variable name="href"><xsl:apply-templates select="$target" mode="govuk-href"/></xsl:variable>
    <xsl:if test="string-length($href) gt 0">
      <a href="{$href}" role="button" draggable="false"
         class="govuk-button govuk-button--start" data-module="govuk-button">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.start-now'"/>
        </xsl:call-template>
        <svg class="govuk-button__start-icon" xmlns="http://www.w3.org/2000/svg"
             width="17.5" height="19" viewBox="0 0 33 40" aria-hidden="true" focusable="false">
          <path fill="currentColor" d="M0 0h13l20 20-20 20H0l20-20z"/>
        </svg>
      </a>
    </xsl:if>
    <xsl:variable name="children" as="element()*"
                  select="$entry/*[contains(@class, ' map/topicref ')]
                          [not(@processing-role = 'resource-only')][not(@toc = 'no')]"/>
    <xsl:if test="exists($children)">
      <xsl:call-template name="govuk-contents-heading"/>
      <xsl:call-template name="govuk-child-list">
        <xsl:with-param name="children" select="$children"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ===== Search page (FR-S2) ===== -->

  <xsl:template name="govuk-search-page">
    <xsl:variable name="search-label">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.search'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:result-document href="search.html">
      <html class="govuk-template" lang="en">
        <head>
          <meta charset="UTF-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1"/>
          <title><xsl:value-of select="concat($search-label, ' — ', $govuk-cover-title)"/></title>
          <xsl:call-template name="generateCssLinks"/>
          <link rel="stylesheet" href="pagefind/pagefind-ui.css"/>
        </head>
        <body class="govuk-template__body">
          <a href="#main-content" class="govuk-skip-link" data-module="govuk-skip-link">
            <xsl:call-template name="getVariable">
              <xsl:with-param name="id" select="'govuk-dita.skip-link'"/>
            </xsl:call-template>
          </a>
          <header class="app-masthead">
            <div class="govuk-width-container">
              <a class="app-masthead__title" href="index{$OUTEXT}">
                <xsl:value-of select="$govuk-masthead-name"/>
              </a>
            </div>
          </header>
          <div class="govuk-width-container">
            <main class="govuk-main-wrapper" id="main-content">
              <div class="govuk-grid-row">
                <div class="govuk-grid-column-two-thirds">
                  <h1 class="govuk-heading-xl"><xsl:value-of select="$search-label"/></h1>
                  <div id="app-search" class="app-search"></div>
                </div>
              </div>
            </main>
          </div>
          <footer class="govuk-footer">
            <div class="govuk-width-container">
              <div class="govuk-footer__meta">
                <div class="govuk-footer__meta-item govuk-footer__meta-item--grow">
                  <span class="govuk-footer__licence-description">
                    <xsl:value-of select="$govuk-masthead-name"/>
                  </span>
                </div>
              </div>
            </div>
          </footer>
          <script src="pagefind/pagefind-ui.js"></script>
          <script>
            <xsl:text>window.addEventListener('DOMContentLoaded', function () {
  if (window.PagefindUI) {
    new PagefindUI({ element: '#app-search', showSubResults: true });
  } else {
    document.getElementById('app-search').textContent = '</xsl:text>
            <xsl:call-template name="getVariable">
              <xsl:with-param name="id" select="'govuk-dita.search-unavailable'"/>
            </xsl:call-template>
            <xsl:text>';
  }
});</xsl:text>
          </script>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>

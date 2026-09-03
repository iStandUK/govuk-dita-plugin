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
  <xsl:import href="furniture.xsl"/>
  <xsl:import href="utility-pages.xsl"/>

  <xsl:output method="html"
              include-content-type="no"
              doctype-system="about:legacy-compat"
              omit-xml-declaration="yes"/>

  <xsl:param name="GOVUK-HOMEPAGE-LAYOUT" select="'auto'"/>
  <xsl:param name="GOVUK-HOMEPAGE-DEPTH" select="'2'"/>

  <!-- Levels of the map shown on the landing page (D-13); children render
       when this is 2 or more, nesting one list per further level -->
  <xsl:variable name="govuk-homepage-depth" as="xs:integer"
                select="if ($GOVUK-HOMEPAGE-DEPTH castable as xs:integer)
                        then max((1, xs:integer($GOVUK-HOMEPAGE-DEPTH)))
                        else 2"/>
  <xsl:param name="GOVUK-SERVICE-NAME" select="''"/>
  <xsl:param name="GOVUK-SEARCH" select="'no'"/>
  <xsl:param name="GOVUK-BRANDING" select="'neutral'"/>
  <xsl:param name="GOVUK-SEARCH-RANKING" select="'default'"/>
  <xsl:param name="GOVUK-PHASE" select="''"/>
  <xsl:param name="GOVUK-FEEDBACK-URL" select="''"/>
  <xsl:param name="GOVUK-SERVICE-URL" select="''"/>
  <xsl:param name="GOVUK-FAVICON" select="''"/>
  <xsl:param name="GOVUK-FOOTER-LINKS" select="''"/>
  <xsl:param name="GOVUK-FOOTER-LICENCE" select="''"/>

  <xsl:variable name="govuk-frontend-version" select="'6.5.0'" as="xs:string"/>

  <!-- Pagefind ranking options for the search page (#54): a preset name or a
       JSON object passed through. Command lines tend to strip double quotes, so
       bare keys and single quotes are tolerated before validation. An unusable
       value is reported (GOVK002E) and Pagefind's defaults apply; values that are
       plainly wrong are rejected earlier by the Ant build. -->
  <xsl:variable name="govuk-search-ranking-json" as="xs:string">
    <xsl:variable name="value" select="normalize-space($GOVUK-SEARCH-RANKING)"/>
    <xsl:choose>
      <xsl:when test="$value = ('', 'default')">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:when test="$value = 'reference'">
        <xsl:sequence select="'{ &quot;termFrequency&quot;: 0.0, &quot;pageLength&quot;: 0.0 }'"/>
      </xsl:when>
      <xsl:when test="starts-with($value, '{')">
        <xsl:variable name="normalised" as="xs:string"
                      select="replace(replace($value, '''', '&quot;'),
                                      '([\{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:', '$1&quot;$2&quot;:')"/>
        <xsl:try select="if (parse-json($normalised) instance of map(*)) then $normalised else error()">
          <xsl:catch>
            <xsl:call-template name="output-message">
              <xsl:with-param name="id" select="'GOVK002E'"/>
              <xsl:with-param name="msgparams">%1=<xsl:value-of select="$value"/></xsl:with-param>
            </xsl:call-template>
            <xsl:sequence select="''"/>
          </xsl:catch>
        </xsl:try>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="output-message">
          <xsl:with-param name="id" select="'GOVK002E'"/>
          <xsl:with-param name="msgparams">%1=<xsl:value-of select="$value"/></xsl:with-param>
        </xsl:call-template>
        <xsl:sequence select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

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

  <!-- Masthead home link: govuk.service.url if set, else the site home (FR-T3) -->
  <xsl:variable name="govuk-home-href" as="xs:string"
                select="if (normalize-space($GOVUK-SERVICE-URL)) then normalize-space($GOVUK-SERVICE-URL)
                        else concat('index', $OUTEXT)"/>

  <!-- Trial finding (#51): DITA-OT resolves no key inside a submap that was itself
       included with <mapref keyref>, and says nothing; the entry then renders as
       plain text with no children. Run once per build, over the merged map, and
       name each entry whose key never resolved — once per affected branch, since
       everything beneath an unresolved entry is unresolved for the same reason.
       Containers without a link are legitimate (topichead, topicgroup, chapters),
       so the check keys on an unresolved @keyref, never on the absence of @href
       alone. -->
  <xsl:template name="govuk-check-map">
    <xsl:for-each select="//*[contains(@class, ' map/topicref ')]
                          [normalize-space(@keyref)][not(normalize-space(@href))]
                          [not(@processing-role = 'resource-only')]
                          [not(contains(@class, ' mapgroup-d/keydef '))]
                          [not(contains(@class, ' mapgroup-d/topichead '))]
                          [not(contains(@class, ' mapgroup-d/topicgroup '))]
                          [not(ancestor::*[contains(@class, ' map/topicref ')]
                                          [normalize-space(@keyref)][not(normalize-space(@href))])]">
      <xsl:variable name="title" as="xs:string"
                    select="normalize-space(string((*[contains(@class, ' map/topicmeta ')]
                                                     /*[contains(@class, ' topic/navtitle ')],
                                                    @navtitle, @keyref)[1]))"/>
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK001W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate($title, ';', ',')"/>;%2=<xsl:value-of select="@keyref"/></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="chapter-setup">
    <xsl:call-template name="govuk-check-map"/>
    <html class="govuk-template">
      <xsl:call-template name="setTopicLanguage"/>
      <xsl:call-template name="chapterHead"/>
      <xsl:call-template name="chapterBody"/>
    </html>
    <xsl:call-template name="govuk-search-page"/>
    <xsl:call-template name="govuk-glossary-page"/>
    <xsl:call-template name="govuk-index-page"/>
    <xsl:call-template name="govuk-figurelist-page"/>
    <xsl:call-template name="govuk-tablelist-page"/>
  </xsl:template>

  <xsl:template name="gen-user-head">
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <xsl:apply-templates select="." mode="gen-user-head"/>
  </xsl:template>

  <!-- Kept in step with template.xsl's generateCssLinks; the cover is at the site
       root so paths carry no $govuk-root prefix. NHS uses the Sass-recompiled base
       CSS (#47) and its own overlay; the neutral font overlay is for the
       non-identity brands only. -->
  <xsl:template name="generateCssLinks">
    <xsl:call-template name="govuk-favicon-link">
      <xsl:with-param name="favicon" select="$GOVUK-FAVICON"/>
    </xsl:call-template>
    <link rel="stylesheet"
          href="{concat('govuk/', if ($GOVUK-BRANDING = 'nhs')
                                   then concat('govuk-frontend-', $govuk-frontend-version, '-nhs.min.css')
                                   else concat('govuk-frontend-', $govuk-frontend-version, '.min.css'))}"/>
    <link rel="stylesheet" href="govuk/plugin.css"/>
    <xsl:if test="$GOVUK-BRANDING = ('neutral', 'istanduk')">
      <link rel="stylesheet" href="govuk/overlay-neutral.css"/>
    </xsl:if>
    <xsl:if test="$GOVUK-BRANDING = 'istanduk'">
      <link rel="stylesheet" href="govuk/overlay-istanduk.css"/>
    </xsl:if>
    <xsl:if test="$GOVUK-BRANDING = 'nhs'">
      <link rel="stylesheet" href="govuk/overlay-nhs.css"/>
    </xsl:if>
    <xsl:if test="$GOVUK-BRANDING = 'official'">
      <link rel="stylesheet" href="govuk/overlay-official.css"/>
    </xsl:if>
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

  <!-- A plain child-link list for a group, with hint-styled descriptions.
       $levels is how many list levels may still render (govuk.homepage.depth
       minus the entry-heading level); nesting recurses while it exceeds 1. -->
  <xsl:template name="govuk-child-list">
    <xsl:param name="children" as="element()*"/>
    <xsl:param name="levels" as="xs:integer" select="1"/>
    <xsl:if test="exists($children) and $levels ge 1">
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
            <xsl:if test="$levels gt 1">
              <xsl:call-template name="govuk-child-list">
                <xsl:with-param name="children"
                                select="*[contains(@class, ' map/topicref ')]
                                        [not(@processing-role = 'resource-only')][not(@toc = 'no')]"/>
                <xsl:with-param name="levels" select="$levels - 1"/>
              </xsl:call-template>
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
                  select="count($entries[contains(@class, ' bookmap/chapter ') or contains(@class, ' bookmap/part ') or contains(@class, ' bookmap/appendix ') or contains(@class, ' bookmap/appendices ')])"/>
    <!-- Container entries have no link of their own but hold child topicrefs
         (topichead/topicgroup, or a chapter/part). In annotated/grid layouts
         they would be dead-end headings, so their presence forces grouped. -->
    <xsl:variable name="container-count"
                  select="count($entries[not(normalize-space(@href))]
                                        [*[contains(@class, ' map/topicref ')]
                                         [not(@processing-role = 'resource-only')][not(@toc = 'no')]])"/>
    <xsl:variable name="layout" as="xs:string">
      <xsl:choose>
        <xsl:when test="$GOVUK-HOMEPAGE-LAYOUT ne 'auto'">
          <xsl:sequence select="$GOVUK-HOMEPAGE-LAYOUT"/>
        </xsl:when>
        <xsl:when test="count($entries) eq 1 and $container-count eq 0">start</xsl:when>
        <xsl:when test="$chapter-count ge 2 or $container-count ge 1">grouped</xsl:when>
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
      <xsl:call-template name="govuk-masthead">
        <xsl:with-param name="name" select="$govuk-masthead-name"/>
        <xsl:with-param name="home-href" select="$govuk-home-href"/>
        <xsl:with-param name="search-enabled" select="$GOVUK-SEARCH"/>
            <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
      </xsl:call-template>
      <div class="govuk-width-container">
        <xsl:call-template name="govuk-phase-banner">
          <xsl:with-param name="phase" select="$GOVUK-PHASE"/>
          <xsl:with-param name="feedback" select="$GOVUK-FEEDBACK-URL"/>
        </xsl:call-template>
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
                        <!-- Unstyled by default; themes may tint it (D-14) -->
                        <div class="app-tile">
                          <xsl:apply-templates select="." mode="govuk-entry"/>
                          <xsl:call-template name="govuk-child-list">
                            <xsl:with-param name="children"
                                            select="*[contains(@class, ' map/topicref ')]
                                                    [not(@processing-role = 'resource-only')][not(@toc = 'no')]"/>
                            <xsl:with-param name="levels" select="$govuk-homepage-depth - 1"/>
                          </xsl:call-template>
                        </div>
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
                      <xsl:with-param name="levels" select="$govuk-homepage-depth - 1"/>
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
                                <xsl:with-param name="levels" select="$govuk-homepage-depth - 1"/>
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
      <xsl:call-template name="govuk-site-footer">
        <xsl:with-param name="name" select="$govuk-masthead-name"/>
        <xsl:with-param name="glossary" select="if (exists($govuk-gloss)) then 'yes' else 'no'"/>
        <xsl:with-param name="index" select="if (exists($govuk-ix)) then 'yes' else 'no'"/>
        <xsl:with-param name="figurelist" select="if ($govuk-wants-figurelist) then 'yes' else 'no'"/>
        <xsl:with-param name="tablelist" select="if ($govuk-wants-tablelist) then 'yes' else 'no'"/>
        <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
        <xsl:with-param name="footer-links" select="$GOVUK-FOOTER-LINKS"/>
        <xsl:with-param name="footer-licence" select="$GOVUK-FOOTER-LICENCE"/>
      </xsl:call-template>
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
        <xsl:with-param name="levels" select="$govuk-homepage-depth - 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ===== Search page (FR-S2) ===== -->

  <!-- Only emit the search page when search is actually enabled (Pagefind
       present); otherwise nothing links to it and its pagefind/* assets would
       be dead. -->
  <xsl:template name="govuk-search-page">
    <xsl:if test="$GOVUK-SEARCH = 'yes'">
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
          <xsl:call-template name="govuk-masthead">
            <xsl:with-param name="name" select="$govuk-masthead-name"/>
            <xsl:with-param name="home-href" select="$govuk-home-href"/>
            <xsl:with-param name="search-enabled" select="'no'"/>
            <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
          </xsl:call-template>
          <div class="govuk-width-container">
            <xsl:call-template name="govuk-phase-banner">
              <xsl:with-param name="phase" select="$GOVUK-PHASE"/>
              <xsl:with-param name="feedback" select="$GOVUK-FEEDBACK-URL"/>
            </xsl:call-template>
            <main class="govuk-main-wrapper" id="main-content">
              <div class="govuk-grid-row">
                <div class="govuk-grid-column-two-thirds">
                  <h1 class="govuk-heading-xl"><xsl:value-of select="$search-label"/></h1>
                  <div id="app-search" class="app-search"></div>
                </div>
              </div>
            </main>
          </div>
          <xsl:call-template name="govuk-site-footer">
            <xsl:with-param name="name" select="$govuk-masthead-name"/>
            <xsl:with-param name="glossary" select="if (exists($govuk-gloss)) then 'yes' else 'no'"/>
            <xsl:with-param name="index" select="if (exists($govuk-ix)) then 'yes' else 'no'"/>
            <xsl:with-param name="figurelist" select="if ($govuk-wants-figurelist) then 'yes' else 'no'"/>
            <xsl:with-param name="tablelist" select="if ($govuk-wants-tablelist) then 'yes' else 'no'"/>
            <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
            <xsl:with-param name="footer-links" select="$GOVUK-FOOTER-LINKS"/>
            <xsl:with-param name="footer-licence" select="$GOVUK-FOOTER-LICENCE"/>
          </xsl:call-template>
          <script src="pagefind/pagefind-ui.js"></script>
          <script>
            <xsl:text>window.addEventListener('DOMContentLoaded', function () {
  if (window.PagefindUI) {
    new PagefindUI({ element: '#app-search', showSubResults: true</xsl:text><xsl:if test="$govuk-search-ranking-json != ''"><xsl:text>, ranking: </xsl:text><xsl:value-of select="$govuk-search-ranking-json"/></xsl:if><xsl:text> });
    var q = new URLSearchParams(window.location.search).get('q');
    if (q) {
      window.requestAnimationFrame(function () {
        var input = document.querySelector('#app-search input');
        if (input) {
          input.value = q;
          input.dispatchEvent(new Event('input', { bubbles: true }));
        }
      });
    }
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
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

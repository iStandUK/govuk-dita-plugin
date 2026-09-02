<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Generated utility pages: the A-Z glossary (FR-G1, C-08) and the back-of-book
index (FR-X1..X3, C-09). Both are harvested during the cover transformation:
the normalised map supplies the reading structure, and document() loads each
referenced (preprocessed) topic once to collect glossentry content and
indexterm markup. Imported by map2govuk-cover.xsl.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- ===== Shared harvest globals ===== -->

  <xsl:variable name="govuk-map-base" select="base-uri(/*)"/>

  <xsl:variable name="govuk-norm-map" as="element()*">
    <xsl:apply-templates select="/*[contains(@class, ' map/map ')]" mode="normalize-map"/>
  </xsl:variable>

  <!-- Every distinct local DITA target in the map, resource-only included. A
       target is either a glossentry topic or a glossgroup collecting several;
       either way we harvest each glossentry. The glossary page shows the full
       term, acronym and definition inline, so entries are not linked out to a
       per-topic page — those pages do not exist for resource-only glossentries
       or for the members of a glossgroup. -->
  <xsl:variable name="govuk-gloss" as="element()*">
    <xsl:for-each-group select="$govuk-norm-map//*[contains(@class, ' map/topicref ')]
                                [@href][not(@scope = 'external')]
                                [not(@format) or @format = 'dita']"
                        group-by="replace(@href, '#.*$', '')">
      <xsl:variable name="uri" select="resolve-uri(current-grouping-key(), $govuk-map-base)"/>
      <xsl:if test="doc-available($uri)">
        <xsl:variable name="root" select="doc($uri)/*"/>
        <xsl:variable name="glossentries" as="element()*"
                      select="if (contains($root/@class, ' glossentry/glossentry '))
                              then $root
                              else if (contains($root/@class, ' glossgroup/glossgroup '))
                              then $root//*[contains(@class, ' glossentry/glossentry ')]
                              else ()"/>
        <xsl:for-each select="$glossentries">
          <xsl:element name="entry">
            <xsl:attribute name="term"
                           select="normalize-space(string((*[contains(@class, ' glossentry/glossterm ')])[1]))"/>
            <xsl:attribute name="acronym"
                           select="normalize-space(string((.//*[contains(@class, ' glossentry/glossAcronym ')])[1]))"/>
            <xsl:value-of select="normalize-space(string((*[contains(@class, ' glossentry/glossdef ')])[1]))"/>
          </xsl:element>
        </xsl:for-each>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:variable>

  <!-- Whether the bookmap explicitly requests each list of items -->
  <xsl:variable name="govuk-wants-figurelist"
                select="exists($govuk-norm-map//*[contains(@class, ' bookmap/figurelist ')])" as="xs:boolean"/>
  <xsl:variable name="govuk-wants-tablelist"
                select="exists($govuk-norm-map//*[contains(@class, ' bookmap/tablelist ')])" as="xs:boolean"/>

  <!-- Titled figures / tables in reading order, with page + anchor + caption -->
  <xsl:function name="govuk:list-of" as="element()*"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin">
    <xsl:param name="class" as="xs:string"/>
    <xsl:for-each-group select="$govuk-norm-map//*[contains(@class, ' map/topicref ')]
                                [@href][not(@scope = 'external')]
                                [not(@processing-role = 'resource-only')]
                                [not(@format) or @format = 'dita']"
                        group-by="replace(@href, '#.*$', '')">
      <xsl:variable name="uri" select="resolve-uri(current-grouping-key(), $govuk-map-base)"/>
      <xsl:if test="doc-available($uri)">
        <xsl:variable name="page"><xsl:apply-templates select="." mode="govuk-href"/></xsl:variable>
        <xsl:for-each select="doc($uri)//*[contains(@class, $class)][*[contains(@class, ' topic/title ')]]">
          <!-- The html5 output mangles an element id to "{topic-id}__{element-id}";
               without an id of its own the item can only anchor to its topic. -->
          <xsl:variable name="topic-id"
                        select="string((ancestor-or-self::*[contains(@class, ' topic/topic ')])[1]/@id)"/>
          <xsl:element name="item">
            <xsl:attribute name="caption"
                           select="normalize-space(string(*[contains(@class, ' topic/title ')][1]))"/>
            <xsl:attribute name="page" select="string($page)"/>
            <xsl:attribute name="anchor"
                           select="if (@id) then concat($topic-id, '__', @id) else $topic-id"/>
          </xsl:element>
        </xsl:for-each>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:function>

  <xsl:variable name="govuk-figs" as="element()*"
                select="if ($govuk-wants-figurelist)
                        then govuk:list-of(' topic/fig ') else ()"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"/>
  <xsl:variable name="govuk-tables" as="element()*"
                select="if ($govuk-wants-tablelist)
                        then govuk:list-of(' topic/table ') else ()"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"/>

  <!-- Flattened index occurrences: one element per primary or secondary term -->
  <xsl:variable name="govuk-ix" as="element()*">
    <xsl:for-each-group select="$govuk-norm-map//*[contains(@class, ' map/topicref ')]
                                [@href][not(@scope = 'external')]
                                [not(@processing-role = 'resource-only')]
                                [not(@format) or @format = 'dita']"
                        group-by="replace(@href, '#.*$', '')">
      <xsl:variable name="uri" select="resolve-uri(current-grouping-key(), $govuk-map-base)"/>
      <xsl:if test="doc-available($uri)">
        <xsl:variable name="page"><xsl:apply-templates select="." mode="govuk-href"/></xsl:variable>
        <xsl:variable name="ptitle"><xsl:apply-templates select="." mode="get-navtitle"/></xsl:variable>
        <xsl:for-each select="doc($uri)//*[contains(@class, ' topic/indexterm ')]
                              [not(contains(@class, ' indexing-d/index-see '))]
                              [not(contains(@class, ' indexing-d/index-see-also '))]
                              [not(ancestor::*[contains(@class, ' topic/indexterm ')])]">
          <xsl:variable name="anchor"
                        select="string((ancestor::*[contains(@class, ' topic/topic ')])[last()]/@id)"/>
          <xsl:variable name="primary"
                        select="normalize-space(string-join(
                                  (text() | *[not(contains(@class, ' topic/indexterm '))]
                                             [not(contains(@class, ' topic/index-base '))]//text()), ''))"/>
          <xsl:variable name="see" as="xs:string*"
                        select="*[contains(@class, ' indexing-d/index-see ')]/normalize-space()"/>
          <xsl:variable name="seealso" as="xs:string*"
                        select="*[contains(@class, ' indexing-d/index-see-also ')]/normalize-space()"/>
          <xsl:variable name="secondaries" as="element()*"
                        select="*[contains(@class, ' topic/indexterm ')]
                                [not(contains(@class, ' indexing-d/index-see '))]
                                [not(contains(@class, ' indexing-d/index-see-also '))]"/>
          <xsl:if test="$primary ne ''">
            <xsl:choose>
              <xsl:when test="exists($secondaries)">
                <xsl:for-each select="$secondaries">
                  <xsl:element name="ix">
                    <xsl:attribute name="primary" select="$primary"/>
                    <xsl:attribute name="secondary" select="normalize-space()"/>
                    <xsl:attribute name="page" select="string($page)"/>
                    <xsl:attribute name="ptitle" select="string($ptitle)"/>
                    <xsl:attribute name="anchor" select="$anchor"/>
                  </xsl:element>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:element name="ix">
                  <xsl:attribute name="primary" select="$primary"/>
                  <xsl:attribute name="secondary" select="''"/>
                  <xsl:attribute name="page" select="string($page)"/>
                  <xsl:attribute name="ptitle" select="string($ptitle)"/>
                  <xsl:attribute name="anchor" select="$anchor"/>
                  <xsl:attribute name="see" select="string-join($see, '|')"/>
                  <xsl:attribute name="seealso" select="string-join($seealso, '|')"/>
                </xsl:element>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:for-each>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:variable>

  <xsl:function name="govuk:letter" as="xs:string">
    <xsl:param name="term" as="xs:string"/>
    <xsl:variable name="c" select="upper-case(substring(normalize-space($term), 1, 1))"/>
    <xsl:sequence select="if (matches($c, '[A-Z]')) then $c else '#'"/>
  </xsl:function>

  <!-- ===== Shared page shell ===== -->

  <xsl:template name="govuk-utility-shell">
    <xsl:param name="file" as="xs:string"/>
    <xsl:param name="page-title" as="xs:string"/>
    <xsl:param name="content" as="item()*"/>
    <xsl:result-document href="{$file}">
      <html class="govuk-template" lang="en">
        <head>
          <meta charset="UTF-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1"/>
          <title><xsl:value-of select="concat($page-title, ' — ', $govuk-cover-title)"/></title>
          <xsl:call-template name="generateCssLinks"/>
        </head>
        <body class="govuk-template__body">
          <a href="#main-content" class="govuk-skip-link" data-module="govuk-skip-link">
            <xsl:call-template name="getVariable">
              <xsl:with-param name="id" select="'govuk-dita.skip-link'"/>
            </xsl:call-template>
          </a>
          <xsl:call-template name="govuk-masthead">
            <xsl:with-param name="name" select="$govuk-masthead-name"/>
            <xsl:with-param name="home-href" select="concat('index', $OUTEXT)"/>
            <xsl:with-param name="search-enabled" select="$GOVUK-SEARCH"/>
            <xsl:with-param name="branding" select="$GOVUK-BRANDING"/>
          </xsl:call-template>
          <div class="govuk-width-container">
            <main class="govuk-main-wrapper" id="main-content">
              <div class="govuk-grid-row">
                <div class="govuk-grid-column-two-thirds">
                  <h1 class="govuk-heading-xl"><xsl:value-of select="$page-title"/></h1>
                  <xsl:sequence select="$content"/>
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
          </xsl:call-template>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="govuk-letter-nav">
    <xsl:param name="letters" as="xs:string*"/>
    <xsl:param name="prefix" as="xs:string"/>
    <nav class="app-letter-nav" aria-label="A to Z">
      <xsl:for-each select="$letters">
        <a class="govuk-link" href="#{$prefix}-{if (. = '#') then 'other' else .}">
          <xsl:value-of select="."/>
        </a>
      </xsl:for-each>
    </nav>
  </xsl:template>

  <!-- ===== Glossary page (FR-G1) ===== -->

  <xsl:template name="govuk-glossary-page">
    <xsl:if test="exists($govuk-gloss)">
      <xsl:variable name="glossary-label">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="content" as="item()*">
        <xsl:variable name="sorted" as="element()*">
          <xsl:perform-sort select="$govuk-gloss">
            <xsl:sort select="lower-case(@term)" lang="en-GB"/>
          </xsl:perform-sort>
        </xsl:variable>
        <xsl:call-template name="govuk-letter-nav">
          <xsl:with-param name="letters" select="distinct-values($sorted/govuk:letter(@term))"/>
          <xsl:with-param name="prefix" select="'glossary'"/>
        </xsl:call-template>
        <xsl:for-each-group select="$sorted" group-by="govuk:letter(@term)">
          <h2 class="govuk-heading-m app-az-letter"
              id="glossary-{if (current-grouping-key() = '#') then 'other' else current-grouping-key()}">
            <xsl:value-of select="current-grouping-key()"/>
          </h2>
          <xsl:for-each select="current-group()">
            <h3 class="govuk-heading-s app-entry__heading">
              <xsl:value-of select="@term"/>
              <xsl:if test="@acronym ne ''">
                <xsl:text> (</xsl:text><xsl:value-of select="@acronym"/><xsl:text>)</xsl:text>
              </xsl:if>
            </h3>
            <xsl:if test="normalize-space(.) ne ''">
              <p class="govuk-body app-entry__desc"><xsl:value-of select="."/></p>
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:call-template name="govuk-utility-shell">
        <xsl:with-param name="file" select="'glossary.html'"/>
        <xsl:with-param name="page-title" select="string($glossary-label)"/>
        <xsl:with-param name="content" select="$content"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ===== Figure list / table list (booklists, #33) ===== -->

  <xsl:template name="govuk-item-list-page">
    <xsl:param name="items" as="element()*"/>
    <xsl:param name="file" as="xs:string"/>
    <xsl:param name="label-id" as="xs:string"/>
    <xsl:param name="item-label-id" as="xs:string"/>
    <xsl:if test="exists($items)">
      <xsl:variable name="label">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="$label-id"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="item-label">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="$item-label-id"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="content" as="item()*">
        <ol class="govuk-list app-itemlist">
          <xsl:for-each select="$items">
            <li>
              <a class="govuk-link"
                 href="{@page}{if (@anchor ne '') then concat('#', @anchor) else ''}">
                <span class="app-itemlist__num"><xsl:value-of select="$item-label"/><xsl:text> </xsl:text><xsl:value-of select="position()"/></span>
                <xsl:text> — </xsl:text>
                <xsl:value-of select="@caption"/>
              </a>
            </li>
          </xsl:for-each>
        </ol>
      </xsl:variable>
      <xsl:call-template name="govuk-utility-shell">
        <xsl:with-param name="file" select="$file"/>
        <xsl:with-param name="page-title" select="string($label)"/>
        <xsl:with-param name="content" select="$content"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="govuk-figurelist-page">
    <xsl:call-template name="govuk-item-list-page">
      <xsl:with-param name="items" select="$govuk-figs"/>
      <xsl:with-param name="file" select="'figurelist.html'"/>
      <xsl:with-param name="label-id" select="'govuk-dita.figures'"/>
      <xsl:with-param name="item-label-id" select="'Figure'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="govuk-tablelist-page">
    <xsl:call-template name="govuk-item-list-page">
      <xsl:with-param name="items" select="$govuk-tables"/>
      <xsl:with-param name="file" select="'tablelist.html'"/>
      <xsl:with-param name="label-id" select="'govuk-dita.tables'"/>
      <xsl:with-param name="item-label-id" select="'Table'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ===== Index page (FR-X1..X3) ===== -->

  <xsl:template name="govuk-index-locations">
    <xsl:param name="occurrences" as="element()*"/>
    <xsl:for-each-group select="$occurrences" group-by="concat(@page, '#', @anchor)">
      <xsl:if test="position() gt 1"><xsl:text>, </xsl:text></xsl:if>
      <a class="govuk-link"
         href="{@page}{if (@anchor ne '') then concat('#', @anchor) else ''}">
        <xsl:value-of select="@ptitle"/>
      </a>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="govuk-index-page">
    <xsl:if test="exists($govuk-ix)">
      <xsl:variable name="index-label">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.index'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="content" as="item()*">
        <xsl:variable name="sorted" as="element()*">
          <xsl:perform-sort select="$govuk-ix">
            <xsl:sort select="lower-case(@primary)" lang="en-GB"/>
            <xsl:sort select="lower-case(@secondary)" lang="en-GB"/>
          </xsl:perform-sort>
        </xsl:variable>
        <xsl:call-template name="govuk-letter-nav">
          <xsl:with-param name="letters" select="distinct-values($sorted/govuk:letter(@primary))"/>
          <xsl:with-param name="prefix" select="'index'"/>
        </xsl:call-template>
        <xsl:for-each-group select="$sorted" group-by="govuk:letter(@primary)">
          <h2 class="govuk-heading-m app-az-letter"
              id="index-{if (current-grouping-key() = '#') then 'other' else current-grouping-key()}">
            <xsl:value-of select="current-grouping-key()"/>
          </h2>
          <ul class="govuk-list app-index-list">
            <xsl:for-each-group select="current-group()" group-by="lower-case(@primary)">
              <li>
                <span class="app-index-term"><xsl:value-of select="current-group()[1]/@primary"/></span>
                <xsl:variable name="direct" as="element()*"
                              select="current-group()[@secondary = '']"/>
                <xsl:if test="exists($direct[@page ne ''])">
                  <xsl:text> — </xsl:text>
                  <xsl:call-template name="govuk-index-locations">
                    <xsl:with-param name="occurrences" select="$direct"/>
                  </xsl:call-template>
                </xsl:if>
                <xsl:variable name="sees" as="xs:string*"
                              select="distinct-values($direct/@see/tokenize(., '\|')[. ne ''])"/>
                <xsl:variable name="seealsos" as="xs:string*"
                              select="distinct-values($direct/@seealso/tokenize(., '\|')[. ne ''])"/>
                <xsl:if test="exists($sees)">
                  <span class="app-index-see">
                    <xsl:text> — </xsl:text>
                    <xsl:call-template name="getVariable">
                      <xsl:with-param name="id" select="'govuk-dita.see'"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="string-join($sees, '; ')"/>
                  </span>
                </xsl:if>
                <xsl:if test="exists($seealsos)">
                  <span class="app-index-see">
                    <xsl:text> — </xsl:text>
                    <xsl:call-template name="getVariable">
                      <xsl:with-param name="id" select="'govuk-dita.see-also'"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="string-join($seealsos, '; ')"/>
                  </span>
                </xsl:if>
                <xsl:variable name="subs" as="element()*"
                              select="current-group()[@secondary ne '']"/>
                <xsl:if test="exists($subs)">
                  <ul class="govuk-list app-index-sublist">
                    <xsl:for-each-group select="$subs" group-by="lower-case(@secondary)">
                      <li>
                        <span class="app-index-term"><xsl:value-of select="current-group()[1]/@secondary"/></span>
                        <xsl:text> — </xsl:text>
                        <xsl:call-template name="govuk-index-locations">
                          <xsl:with-param name="occurrences" select="current-group()"/>
                        </xsl:call-template>
                      </li>
                    </xsl:for-each-group>
                  </ul>
                </xsl:if>
              </li>
            </xsl:for-each-group>
          </ul>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:call-template name="govuk-utility-shell">
        <xsl:with-param name="file" select="'index-page.html'"/>
        <xsl:with-param name="page-title" select="string($index-label)"/>
        <xsl:with-param name="content" select="$content"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

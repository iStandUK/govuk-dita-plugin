<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

The print document (FR-P2, D-20): one self-contained XHTML file per
publication, print.html beside the cover, written by the govuk.print Ant
target through map2govuk-print.xsl when govuk.print=yes. It holds a cover
block, a hyperlinked contents list, every navigable topic in map reading order
with headings demoted by map depth, per-topic endnotes, and the glossary and
index as final parts. Every id the site uses is preserved, so cross-references
between topics become in-document anchors.

Each topic is rendered by the same html5 and plugin templates as its site page
(doc() on the preprocessed topic, mode child.topic) and then passed through a
fix-up pass that demotes headings, rewrites links and asset paths from the
topic's directory to the document's, scopes the toolkit's per-file generated
ids (ariaid-title*, fnsrc_*, fntarg_*), prefixes every id of a topic whose root
id has already been used (copy-to, chunk), and drops related-links navigation.
The result carries no data-pagefind-body, so Pagefind never indexes it.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs map govuk">

  <xsl:param name="GOVUK-PRINT-TOC-DEPTH" select="'3'"/>

  <xsl:variable name="govuk-print-toc-depth" as="xs:integer"
                select="if ($GOVUK-PRINT-TOC-DEPTH castable as xs:integer)
                        then max((1, xs:integer($GOVUK-PRINT-TOC-DEPTH)))
                        else 3"/>
  <!-- "page", for the page references print.css generates from
       data-page-label and target-counter (#107). Localised like every other
       label; a renderer without target-counter drops the whole declaration,
       so browsers show nothing extra. -->
  <xsl:variable name="govuk-print-page-label" as="xs:string">
    <xsl:for-each select="/*">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.page'"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="govuk-print-max" as="xs:integer"
                select="if ($GOVUK-PRINT-MAX-TOPICS castable as xs:integer)
                        then xs:integer($GOVUK-PRINT-MAX-TOPICS)
                        else 500"/>

  <!-- ===== The plan: which files render, in reading order ===== -->

  <!-- Every topicref that contributes a topic (furniture.xsl), then one entry
       per distinct file at its first reference. A chunked file's later
       references (item.dita#child) contribute nothing of their own: their
       content is inside the file already rendered. -->
  <xsl:variable name="govuk-print-refs" as="element()*"
                select="govuk:print-topicrefs($govuk-norm-map)"/>
  <xsl:variable name="govuk-print-count" as="xs:integer"
                select="govuk:print-topic-count($govuk-norm-map)"/>

  <xsl:variable name="govuk-print-plan" as="element(govuk:entry)*">
    <xsl:variable name="first" as="element()*">
      <xsl:for-each-group select="$govuk-print-refs" group-by="govuk:print-file(.)">
        <xsl:sequence select="."/>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="loaded" as="element(govuk:entry)*">
      <xsl:for-each select="$first">
        <xsl:variable name="file" select="govuk:print-file(.)"/>
        <xsl:variable name="uri" select="resolve-uri($file, $govuk-map-base)"/>
        <xsl:if test="doc-available($uri)">
          <govuk:entry ref="{generate-id(.)}" file="{$file}" uri="{$uri}"
                       page="{govuk:print-page($file)}"
                       dir="{if (contains($file, '/')) then replace($file, '/[^/]*$', '/') else ''}"
                       root="{string((doc($uri)//*[contains(@class, ' topic/topic ')])[1]/@id)}"
                       ids="{string-join(doc($uri)//*[contains(@class, ' topic/topic ')]/@id, ' ')}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <!-- Second pass: the generated-id scope for every file, and a prefix for
         every id of a file that would otherwise collide with one already
         placed (#121). Topic ids need only be unique within their own file:
         copy-to and chunk repeat root ids, and nested topics repeat ids across
         files whenever two topics share a heading — Markdown headings become
         nested topics named after the heading, so "About" and "Benefits" recur
         across a corpus. Element ids inside a topic are already prefixed with
         their topic's id by the html5 base, so the topic ids are the whole of
         the problem. Links into a prefixed file are rewritten to match. -->
    <xsl:for-each select="$loaded">
      <xsl:variable name="n" select="position()"/>
      <xsl:variable name="mine" as="xs:string*" select="tokenize(@ids, ' ')[. ne '']"/>
      <xsl:variable name="placed" as="xs:string*"
                    select="for $e in $loaded[position() lt $n] return tokenize($e/@ids, ' ')[. ne '']"/>
      <xsl:variable name="dup" as="xs:string"
                    select="if (@root = '' or (some $i in $mine satisfies $i = $placed))
                            then concat('p', $n, '-') else ''"/>
      <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:attribute name="scope" select="concat('t', $n, '-')"/>
        <xsl:attribute name="dup" select="$dup"/>
        <xsl:attribute name="anchor"
                       select="if (@root ne '') then concat($dup, @root) else concat('app-print-topic-', $n)"/>
      </xsl:copy>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="govuk-print-by-ref" as="map(xs:string, element(govuk:entry))"
                select="map:merge(for $e in $govuk-print-plan return map:entry(string($e/@ref), $e))"/>
  <xsl:variable name="govuk-print-by-page" as="map(xs:string, element(govuk:entry))"
                select="map:merge(for $e in $govuk-print-plan return map:entry(string($e/@page), $e))"/>

  <!-- The glossary and index parts: no directory, nothing to scope, but their
       links into topics still become in-document anchors -->
  <xsl:variable name="govuk-print-part-entry" as="element(govuk:entry)">
    <govuk:entry ref="" file="" uri="" page="" dir="" root="" scope="" dup="" anchor=""/>
  </xsl:variable>

  <!-- How a topicref takes part: 'topic' renders its file here; 'dup' is a
       later reference to a file already rendered (walk its children only);
       'group' is a heading-only container (topichead, a chapter without a
       topic) with something printable beneath; 'pass' is transparent
       (frontmatter, backmatter, booklists, topicgroup, an empty group);
       'skip' drops the subtree (resource-only, toc="no", non-DITA targets). -->
  <xsl:function name="govuk:print-kind" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:choose>
      <xsl:when test="$ref/@processing-role = 'resource-only' or $ref/@toc = 'no'
                      or contains($ref/@class, ' mapgroup-d/keydef ')">skip</xsl:when>
      <xsl:when test="normalize-space($ref/@href) and not($ref/@scope = 'external')
                      and (not($ref/@format) or $ref/@format = 'dita')">
        <xsl:sequence select="if (map:contains($govuk-print-by-ref, generate-id($ref))) then 'topic' else 'dup'"/>
      </xsl:when>
      <xsl:when test="normalize-space($ref/@href)">skip</xsl:when>
      <xsl:when test="not(normalize-space(string(($ref/*[contains(@class, ' map/topicmeta ')]
                                                        /*[contains(@class, ' topic/navtitle ')],
                                                       $ref/@navtitle)[1])))
                      or contains($ref/@class, ' bookmap/frontmatter ')
                      or contains($ref/@class, ' bookmap/backmatter ')
                      or contains($ref/@class, ' bookmap/booklists ')
                      or contains($ref/@class, ' mapgroup-d/topicgroup ')">pass</xsl:when>
      <xsl:when test="empty($ref//*[contains(@class, ' map/topicref ')][govuk:print-kind(.) = ('topic', 'dup')])">pass</xsl:when>
      <xsl:otherwise>group</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Stable anchor for a heading-only container: its position among the
       map's link-less topicrefs -->
  <xsl:function name="govuk:print-group-id" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="concat('app-print-group-',
                                 count($ref/preceding::*[contains(@class, ' map/topicref ')][not(normalize-space(@href))])
                                 + count($ref/ancestor::*[contains(@class, ' map/topicref ')][not(normalize-space(@href))])
                                 + 1)"/>
  </xsl:function>

  <!-- In-document target for a contents entry, or '' when there is none -->
  <xsl:function name="govuk:print-target" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:variable name="kind" select="govuk:print-kind($ref)"/>
    <xsl:choose>
      <xsl:when test="$kind = 'topic'">
        <xsl:sequence select="concat('#', map:get($govuk-print-by-ref, generate-id($ref))/@anchor)"/>
      </xsl:when>
      <xsl:when test="$kind = 'dup' and contains($ref/@href, '#')">
        <xsl:variable name="page" select="govuk:print-page(govuk:print-file($ref))"/>
        <xsl:variable name="entry" as="element(govuk:entry)?"
                      select="if (map:contains($govuk-print-by-page, $page)) then map:get($govuk-print-by-page, $page) else ()"/>
        <xsl:sequence select="concat('#', $entry/@dup, substring-after($ref/@href, '#'))"/>
      </xsl:when>
      <xsl:when test="$kind = 'group'">
        <xsl:sequence select="concat('#', govuk:print-group-id($ref))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="govuk:print-heading-class" as="xs:string">
    <xsl:param name="level" as="xs:integer"/>
    <xsl:sequence select="if ($level le 1) then 'govuk-heading-xl'
                          else if ($level eq 2) then 'govuk-heading-l'
                          else if ($level eq 3) then 'govuk-heading-m'
                          else 'govuk-heading-s'"/>
  </xsl:function>

  <!-- ===== The document ===== -->

  <!-- Called as the whole output of map2govuk-print.xsl. Above the topic
       ceiling nothing is written (the Ant target removes the empty file) and
       the build warns, since a quiet build shows no info-level messages. -->
  <xsl:template name="govuk-print-document">
    <xsl:choose>
      <xsl:when test="$GOVUK-PRINT != 'yes'"/>
      <xsl:when test="$govuk-print-count gt $govuk-print-max">
        <xsl:call-template name="output-message">
          <xsl:with-param name="id" select="'GOVK003W'"/>
          <xsl:with-param name="msgparams">%1=<xsl:value-of select="$govuk-print-count"/>;%2=<xsl:value-of select="$govuk-print-max"/></xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$govuk-print-count eq 0"/>
      <xsl:otherwise>
        <xsl:variable name="print-label">
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id" select="'govuk-dita.print-page'"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="lang" as="xs:string"
                      select="string((/*/@xml:lang, 'en')[1])"/>
        <xsl:variable name="document" as="element()">
          <html class="govuk-template app-print" lang="{$lang}">
            <xsl:copy-of select="/*/@dir"/>
            <head>
              <meta charset="UTF-8"/>
              <xsl:call-template name="govuk-csp-meta"/>
              <meta name="viewport" content="width=device-width, initial-scale=1"/>
              <!-- the whole publication in one file: not for search engines (#60) -->
              <meta name="robots" content="noindex"/>
              <!-- The structure a paged renderer relies on (#108): the
                   app-print-* wrappers, stable ids, stylesheet order and the
                   page-reference labels. It changes only when that structure
                   changes, independently of the plugin's own version. -->
              <meta name="govuk-print-contract" content="1"/>
              <title><xsl:value-of select="concat($govuk-cover-title, ' — ', $print-label)"/></title>
              <xsl:call-template name="generateCssLinks"/>
            </head>
            <body class="govuk-template__body">
              <a href="#main-content" class="govuk-skip-link">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.skip-link'"/>
                </xsl:call-template>
              </a>
              <div class="govuk-width-container">
                <main class="govuk-main-wrapper" id="main-content">
                  <xsl:call-template name="govuk-print-cover"/>
                  <xsl:call-template name="govuk-print-contents"/>
                  <xsl:apply-templates select="$govuk-norm-map/*[contains(@class, ' map/topicref ')]"
                                       mode="govuk-print-walk"/>
                  <xsl:call-template name="govuk-print-glossary"/>
                  <xsl:call-template name="govuk-print-index"/>
                </main>
              </div>
            </body>
          </html>
        </xsl:variable>
        <xsl:apply-templates select="$document" mode="govuk-print-xhtml"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Cover block: the same title, abstract and attribution as the home page,
       plus a link back to the website (hidden when printed) -->
  <xsl:template name="govuk-print-cover">
    <header class="app-print-cover">
      <h1 class="govuk-heading-xl"><xsl:value-of select="$govuk-cover-title"/></h1>
      <xsl:for-each select="/*[contains(@class, ' map/map ')]/*[contains(@class, ' bookmap/booktitle ')]
                            /*[contains(@class, ' bookmap/booktitlealt ')]">
        <p class="govuk-body-l"><xsl:apply-templates/></p>
      </xsl:for-each>
      <xsl:variable name="authors" as="xs:string*"
                    select="/*[contains(@class, ' map/map ')]/*[contains(@class, ' bookmap/bookmeta ')]
                            //*[contains(@class, ' topic/author ')]/normalize-space()"/>
      <xsl:variable name="orgs" as="xs:string*"
                    select="/*[contains(@class, ' map/map ')]/*[contains(@class, ' bookmap/bookmeta ')]
                            //*[contains(@class, ' bookmap/organization ')]/normalize-space()"/>
      <xsl:if test="exists(($authors, $orgs)[. ne ''])">
        <p class="govuk-body app-attribution">
          <xsl:value-of select="string-join(distinct-values(($authors, $orgs)[. ne '']), ' · ')"/>
        </p>
      </xsl:if>
      <p class="govuk-body app-print-screen-only">
        <a class="govuk-link" href="{concat('index', $OUTEXT)}">
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id" select="'govuk-dita.print-website'"/>
          </xsl:call-template>
        </a>
      </p>
    </header>
  </xsl:template>

  <!-- ===== Contents ===== -->

  <xsl:template name="govuk-print-contents">
    <nav class="app-print-contents" aria-labelledby="app-print-contents-heading">
      <h2 class="govuk-heading-l" id="app-print-contents-heading">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.contents'"/>
        </xsl:call-template>
      </h2>
      <xsl:call-template name="govuk-print-toc-list">
        <xsl:with-param name="refs" select="$govuk-norm-map/*[contains(@class, ' map/topicref ')]"/>
        <xsl:with-param name="level" select="1"/>
      </xsl:call-template>
      <xsl:if test="exists($govuk-gloss) or exists($govuk-ix)">
        <ol class="govuk-list app-print-contents__list">
          <xsl:if test="exists($govuk-gloss)">
            <li><a class="govuk-link" href="#app-print-glossary">
              <xsl:call-template name="getVariable">
                <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
              </xsl:call-template>
            </a></li>
          </xsl:if>
          <xsl:if test="exists($govuk-ix)">
            <li><a class="govuk-link" href="#app-print-index">
              <xsl:call-template name="getVariable">
                <xsl:with-param name="id" select="'govuk-dita.index'"/>
              </xsl:call-template>
            </a></li>
          </xsl:if>
        </ol>
      </xsl:if>
    </nav>
  </xsl:template>

  <xsl:template name="govuk-print-toc-list">
    <xsl:param name="refs" as="element()*"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:variable name="items" as="element()*">
      <xsl:apply-templates select="$refs" mode="govuk-print-toc">
        <xsl:with-param name="level" select="$level"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="exists($items)">
      <ol class="govuk-list app-print-contents__list">
        <xsl:sequence select="$items"/>
      </ol>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="govuk-print-toc">
    <xsl:param name="level" as="xs:integer"/>
    <xsl:variable name="kind" select="govuk:print-kind(.)"/>
    <xsl:variable name="target" select="if ($kind = 'skip') then '' else govuk:print-target(.)"/>
    <xsl:choose>
      <xsl:when test="$kind = 'skip'"/>
      <!-- transparent containers, and later references to a rendered file
           that name no topic inside it, list their children at this level -->
      <xsl:when test="$kind = 'pass' or ($kind = 'dup' and $target = '')">
        <xsl:apply-templates select="*[contains(@class, ' map/topicref ')]" mode="govuk-print-toc">
          <xsl:with-param name="level" select="$level"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$level gt $govuk-print-toc-depth"/>
      <xsl:otherwise>
        <li>
          <a class="govuk-link" href="{$target}">
            <xsl:if test="starts-with($target, '#')">
              <xsl:attribute name="data-page-label" select="$govuk-print-page-label"/>
            </xsl:if>
            <xsl:apply-templates select="." mode="get-navtitle"/>
          </a>
          <xsl:call-template name="govuk-print-toc-list">
            <xsl:with-param name="refs" select="*[contains(@class, ' map/topicref ')]"/>
            <xsl:with-param name="level" select="$level + 1"/>
          </xsl:call-template>
        </li>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ===== Body: the map walk ===== -->

  <!-- $level is the heading level this entry's title takes (the cover title
       is h1, so top-level entries start at h2); $top marks a top-level entry
       (chapter, part, appendix, top topicref), which starts a new page. -->
  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="govuk-print-walk">
    <xsl:param name="level" as="xs:integer" select="2"/>
    <xsl:param name="top" as="xs:boolean" select="true()"/>
    <xsl:variable name="kind" select="govuk:print-kind(.)"/>
    <xsl:variable name="children" as="element()*" select="*[contains(@class, ' map/topicref ')]"/>
    <xsl:variable name="chapter" select="if ($top) then ' app-print-chapter' else ''"/>
    <xsl:choose>
      <xsl:when test="$kind = 'skip'"/>
      <xsl:when test="$kind = ('pass', 'dup')">
        <xsl:apply-templates select="$children" mode="govuk-print-walk">
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="top" select="$top"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$kind = 'group'">
        <section class="app-print-group{$chapter}" id="{govuk:print-group-id(.)}">
          <xsl:call-template name="govuk-print-heading">
            <xsl:with-param name="level" select="$level"/>
            <xsl:with-param name="text">
              <xsl:apply-templates select="." mode="get-navtitle"/>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:apply-templates select="$children" mode="govuk-print-walk">
            <xsl:with-param name="level" select="$level + 1"/>
            <xsl:with-param name="top" select="false()"/>
          </xsl:apply-templates>
        </section>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="entry" as="element(govuk:entry)"
                      select="map:get($govuk-print-by-ref, generate-id(.))"/>
        <section class="app-print-topic{$chapter}">
          <!-- the topic's own article carries its id; a topic without one
               gets the anchor here -->
          <xsl:if test="$entry/@root = ''">
            <xsl:attribute name="id" select="$entry/@anchor"/>
          </xsl:if>
          <xsl:call-template name="govuk-print-topic">
            <xsl:with-param name="entry" select="$entry"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:call-template>
          <xsl:apply-templates select="$children" mode="govuk-print-walk">
            <xsl:with-param name="level" select="$level + 1"/>
            <xsl:with-param name="top" select="false()"/>
          </xsl:apply-templates>
        </section>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="govuk-print-heading">
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="text"/>
    <xsl:variable name="class" select="govuk:print-heading-class($level)"/>
    <xsl:choose>
      <xsl:when test="$level le 6">
        <xsl:element name="h{$level}">
          <xsl:attribute name="class" select="$class"/>
          <xsl:copy-of select="$text"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <div role="heading" aria-level="{$level}" class="{$class}">
          <xsl:copy-of select="$text"/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- One file: its topics as on the site page (nested topics included), then
       its footnotes as endnotes, all through the fix-up pass -->
  <xsl:template name="govuk-print-topic">
    <xsl:param name="entry" as="element(govuk:entry)"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:variable name="doc" select="doc($entry/@uri)"/>
    <xsl:variable name="topics" as="element()*"
                  select="$doc/*[contains(@class, ' topic/topic ')]
                          | $doc/*[self::dita]/*[contains(@class, ' topic/topic ')]"/>
    <xsl:variable name="rendered" as="node()*">
      <xsl:apply-templates select="$topics" mode="child.topic"/>
      <xsl:if test="exists($doc//*[contains(@class, ' topic/fn ')])">
        <div class="app-print-endnotes">
          <xsl:apply-templates select="$doc" mode="gen-endnotes"/>
        </div>
      </xsl:if>
    </xsl:variable>
    <xsl:apply-templates select="$rendered" mode="govuk-print-fix">
      <xsl:with-param name="entry" select="$entry" tunnel="yes"/>
      <xsl:with-param name="offset" select="$level - 1" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- ===== Glossary and index parts ===== -->

  <xsl:template name="govuk-print-glossary">
    <xsl:if test="exists($govuk-gloss)">
      <section class="app-print-part app-print-chapter" id="app-print-glossary">
        <h2 class="govuk-heading-l">
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
          </xsl:call-template>
        </h2>
        <xsl:variable name="content" as="item()*">
          <xsl:call-template name="govuk-glossary-content"/>
        </xsl:variable>
        <xsl:apply-templates select="$content" mode="govuk-print-fix">
          <xsl:with-param name="entry" select="$govuk-print-part-entry" tunnel="yes"/>
          <xsl:with-param name="offset" select="1" tunnel="yes"/>
        </xsl:apply-templates>
      </section>
    </xsl:if>
  </xsl:template>

  <xsl:template name="govuk-print-index">
    <xsl:if test="exists($govuk-ix)">
      <section class="app-print-part app-print-chapter" id="app-print-index">
        <h2 class="govuk-heading-l">
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id" select="'govuk-dita.index'"/>
          </xsl:call-template>
        </h2>
        <xsl:variable name="content" as="item()*">
          <xsl:call-template name="govuk-index-content"/>
        </xsl:variable>
        <xsl:apply-templates select="$content" mode="govuk-print-fix">
          <xsl:with-param name="entry" select="$govuk-print-part-entry" tunnel="yes"/>
          <xsl:with-param name="offset" select="1" tunnel="yes"/>
        </xsl:apply-templates>
      </section>
    </xsl:if>
  </xsl:template>

  <!-- ===== Fix-up pass over rendered content ===== -->

  <xsl:template match="@* | node()" mode="govuk-print-fix">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="govuk-print-fix"/>
    </xsl:copy>
  </xsl:template>

  <!-- A link that resolves inside the document can carry a page number in
       print (#107); print.css generates it, and a renderer without
       target-counter simply drops the rule -->
  <xsl:template match="a[@href]" mode="govuk-print-fix">
    <xsl:param name="entry" as="element(govuk:entry)?" tunnel="yes"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="starts-with(govuk:print-link(string(@href), $entry), '#')">
        <xsl:attribute name="data-page-label" select="$govuk-print-page-label"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- The toolkit's related-links block (child, parent, next/previous and
       relationship-table links): the contents list replaces it -->
  <xsl:template match="nav[tokenize(@class, '\s+') = 'related-links']" mode="govuk-print-fix"/>

  <!-- Headings drop by the topic's map depth; beyond h6 the level is kept
       honest with an ARIA heading. The GOV.UK size class follows the new level. -->
  <xsl:template match="h1 | h2 | h3 | h4 | h5 | h6" mode="govuk-print-fix">
    <xsl:param name="offset" as="xs:integer" tunnel="yes" select="0"/>
    <xsl:variable name="level" as="xs:integer" select="xs:integer(substring(local-name(), 2)) + $offset"/>
    <xsl:variable name="class" as="xs:string?" select="govuk:print-reclass(@class, $level)"/>
    <xsl:choose>
      <xsl:when test="$level le 6">
        <xsl:element name="h{$level}">
          <xsl:apply-templates select="@* except @class" mode="govuk-print-fix"/>
          <xsl:if test="exists($class)">
            <xsl:attribute name="class" select="$class"/>
          </xsl:if>
          <xsl:apply-templates mode="govuk-print-fix"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <div role="heading" aria-level="{$level}">
          <xsl:apply-templates select="@* except @class" mode="govuk-print-fix"/>
          <xsl:if test="exists($class)">
            <xsl:attribute name="class" select="$class"/>
          </xsl:if>
          <xsl:apply-templates mode="govuk-print-fix"/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="govuk:print-reclass" as="xs:string?">
    <xsl:param name="class" as="xs:string?"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:variable name="tokens" as="xs:string*" select="tokenize(normalize-space(string($class)), '\s+')[. ne '']"/>
    <xsl:choose>
      <xsl:when test="empty($tokens)">
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:when test="some $t in $tokens satisfies matches($t, '^govuk-heading-(xl|l|m|s)$')">
        <xsl:sequence select="string-join(for $t in $tokens
                                          return if (matches($t, '^govuk-heading-(xl|l|m|s)$'))
                                                 then govuk:print-heading-class($level) else $t, ' ')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="string($class)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Ids: per-file generated ids get the file's scope; every id gets the
       duplicate-root prefix when the file has one -->
  <xsl:template match="@id | a/@name" mode="govuk-print-fix">
    <xsl:param name="entry" as="element(govuk:entry)?" tunnel="yes"/>
    <xsl:attribute name="{name()}" select="govuk:print-scope-id(string(.), $entry)"/>
  </xsl:template>

  <xsl:template match="@aria-labelledby | @aria-describedby | @aria-controls | @headers | @for" mode="govuk-print-fix">
    <xsl:param name="entry" as="element(govuk:entry)?" tunnel="yes"/>
    <xsl:attribute name="{name()}"
                   select="string-join(for $t in tokenize(normalize-space(.), '\s+')
                                       return govuk:print-scope-id($t, $entry), ' ')"/>
  </xsl:template>

  <xsl:function name="govuk:print-scope-id" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="entry" as="element(govuk:entry)?"/>
    <xsl:sequence select="if (empty($entry)) then $id
                          else if (matches($id, '^(ariaid-title[0-9]+|fnsrc_.*|fntarg_.*)$')) then concat($entry/@scope, $id)
                          else concat($entry/@dup, $id)"/>
  </xsl:function>

  <!-- Links and asset references: same-document fragments follow the id
       rules; relative paths are re-based from the topic's directory to the
       document's, and a path that names a topic in this document becomes an
       in-document anchor (to the named element, or the topic itself) -->
  <xsl:template match="@href | @src | @data | @poster | @longdesc | @xlink:href" mode="govuk-print-fix">
    <xsl:param name="entry" as="element(govuk:entry)?" tunnel="yes"/>
    <xsl:attribute name="{name()}" namespace="{namespace-uri()}"
                   select="govuk:print-link(string(.), $entry)"/>
  </xsl:template>

  <xsl:function name="govuk:print-link" as="xs:string">
    <xsl:param name="ref" as="xs:string"/>
    <xsl:param name="entry" as="element(govuk:entry)?"/>
    <xsl:choose>
      <xsl:when test="$ref = '' or empty($entry)">
        <xsl:sequence select="$ref"/>
      </xsl:when>
      <xsl:when test="starts-with($ref, '#')">
        <xsl:sequence select="concat('#', govuk:print-scope-id(substring($ref, 2), $entry))"/>
      </xsl:when>
      <xsl:when test="matches($ref, '^([a-zA-Z][a-zA-Z0-9+.-]*:|//|/)')">
        <xsl:sequence select="$ref"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="path" as="xs:string"
                      select="govuk:print-normalize(concat($entry/@dir,
                                                           if (contains($ref, '#')) then substring-before($ref, '#') else $ref))"/>
        <xsl:variable name="frag" as="xs:string" select="substring-after($ref, '#')"/>
        <xsl:variable name="target" as="element(govuk:entry)?"
                      select="if (map:contains($govuk-print-by-page, $path)) then map:get($govuk-print-by-page, $path) else ()"/>
        <xsl:choose>
          <xsl:when test="exists($target)">
            <xsl:sequence select="concat('#', if ($frag ne '') then concat($target/@dup, $frag) else $target/@anchor)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="concat($path, if ($frag ne '') then concat('#', $frag) else '')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Collapse . and .. segments of a relative path -->
  <xsl:function name="govuk:print-normalize" as="xs:string">
    <xsl:param name="path" as="xs:string"/>
    <xsl:sequence select="string-join(govuk:print-fold(tokenize($path, '/')[. ne '' and . ne '.'], ()), '/')"/>
  </xsl:function>

  <xsl:function name="govuk:print-fold" as="xs:string*">
    <xsl:param name="segments" as="xs:string*"/>
    <xsl:param name="acc" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="empty($segments)">
        <xsl:sequence select="$acc"/>
      </xsl:when>
      <xsl:when test="$segments[1] = '..' and exists($acc) and $acc[last()] ne '..'">
        <xsl:sequence select="govuk:print-fold(subsequence($segments, 2), $acc[position() lt last()])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="govuk:print-fold(subsequence($segments, 2), ($acc, $segments[1]))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ===== Serialisation as XHTML ===== -->

  <!-- The html5 templates build elements in no namespace; move them into the
       XHTML namespace so the file serialises as well-formed XHTML5 (void
       elements self-closed, nothing else) for any XML-based renderer. SVG
       and MathML keep their own namespaces. -->
  <xsl:template match="*" mode="govuk-print-xhtml">
    <xsl:choose>
      <xsl:when test="namespace-uri() = ''">
        <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates mode="govuk-print-xhtml"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates mode="govuk-print-xhtml"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text() | comment() | processing-instruction()" mode="govuk-print-xhtml">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>

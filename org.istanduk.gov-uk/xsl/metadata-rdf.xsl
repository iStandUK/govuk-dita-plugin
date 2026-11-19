<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

The writer for graphs (design 14 sections 7 and 8, #102), included by
metadata.xsl. A table whose syntax is rdf describes records as subjects of a
graph; the graph is then written twice, as JSON-LD and as Turtle, from one
intermediate form, so the two cannot differ.

  Walk   govuk:md-rdf-graph takes every record reachable from some roots, and
         govuk:md-rdf-subjects describes each by every table with a kind for it,
         as a govuk:s: a subject (its address) holding govuk:v values. A value is a literal
         (lit, with a datatype in dt) or a reference (iri). The type of a
         subject is a value of p="@type".
  Write  govuk:md-rdf-jsonld and govuk:md-rdf-turtle serialise the subjects.
         Each holds the syntax rules of its format once: escaping, prefixes,
         literals and references.

A table row's term says where a value comes from, as for the other writers.
node="yes" makes a value a reference to another thing by address; datatype
types a literal; nested="kind" and a relation make the thing they name part of
the graph. The tables never name the syntax they are written in.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- The tables of syntax rdf that are switched on: not by govuk.metadata, which
       is about page heads, but by their own parameter -->
  <xsl:variable name="govuk-md-rdf-schemes" as="element()*"
                select="if ($GOVUK-DCAT ne 'yes') then ()
                        else for $s in doc(resolve-uri('schemes.xml', $govuk-md-dir))/schemes/scheme
                                       [tokenize(@levels) = 'dcat']
                             return doc(resolve-uri($s/@href, $govuk-md-dir))/scheme[@syntax = 'rdf']"/>

  <!-- The tables of the vocabulary files (#103), switched on by govuk.skos -->
  <xsl:variable name="govuk-md-skos-schemes" as="element()*"
                select="if ($GOVUK-SKOS ne 'yes') then ()
                        else for $s in doc(resolve-uri('schemes.xml', $govuk-md-dir))/schemes/scheme
                                       [tokenize(@levels) = 'skos']
                             return doc(resolve-uri($s/@href, $govuk-md-dir))/scheme[@syntax = 'rdf']"/>

  <!-- ===== Walk ===== -->

  <!-- What one kind of a table says about a record: its values -->
  <xsl:function name="govuk:md-rdf-kind" as="element(govuk:rows)">
    <xsl:param name="kind" as="element()"/>
    <xsl:param name="record" as="element(govuk:record)"/>
    <govuk:rows>
      <xsl:for-each select="tokenize(normalize-space($kind/@type))">
        <govuk:v p="@type" iri="{.}"/>
      </xsl:for-each>
      <xsl:for-each select="$kind/*">
        <xsl:variable name="row" select="."/>
        <xsl:choose>
          <xsl:when test="$row/@nested or local-name($row) = 'relation'">
            <xsl:for-each select="(if ($row/@nested and local-name($row) != 'relation')
                                   then $record/govuk:p[@term = $row/@term]/govuk:record
                                   else $record/govuk:rel[@name = $row/@name]/govuk:record[not($row/@target) or @kind = $row/@target]
                                  )[normalize-space(@id) ne '']">
              <govuk:v p="{$row/@as}" iri="{@id}"/>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="govuk:md-values($row, $kind, $record)">
              <govuk:v p="{$row/@as}">
                <xsl:attribute name="{if ($row/@node = 'yes') then 'iri' else 'lit'}" select="."/>
                <xsl:if test="not($row/@node = 'yes') and ($row/@datatype or $row/@format = 'date')">
                  <xsl:attribute name="dt" select="($row/@datatype, 'xsd:date')[1]"/>
                </xsl:if>
                <xsl:if test="not($row/@node = 'yes') and $row/@lang = 'yes' and normalize-space($record/govuk:p[@term = 'dct:language'][1]/@value) ne ''">
                  <xsl:attribute name="lang" select="normalize-space($record/govuk:p[@term = 'dct:language'][1]/@value)"/>
                </xsl:if>
              </govuk:v>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </govuk:rows>
  </xsl:function>

  <!-- A record as a subject, by every kind of a table that describes it (a table
       may say more about a thing in a second kind, as the ADMS table does of an
       asset the DCAT table has already described). Nothing when no kind applies. -->
  <xsl:function name="govuk:md-rdf-subjects" as="element(govuk:s)?">
    <xsl:param name="scheme" as="element()"/>
    <xsl:param name="record" as="element(govuk:record)"/>
    <xsl:variable name="rows" as="element(govuk:rows)*"
                  select="$scheme/kind[govuk:md-applies(., $record)] ! govuk:md-rdf-kind(., $record)"/>
    <xsl:if test="exists($rows) and normalize-space($record/@id) ne ''">
      <govuk:s id="{$record/@id}">
        <xsl:sequence select="$rows/govuk:v"/>
      </govuk:s>
    </xsl:if>
  </xsl:function>

  <!-- The graph of some root records under every table: every record reachable from
       them (nested or related, at any depth), each described by every table that has
       a kind for it, each subject once, in the order first reached, with the values
       every table gives it. A table need not know how the records are connected. -->
  <xsl:function name="govuk:md-rdf-graph" as="element(govuk:s)*">
    <xsl:param name="schemes" as="element()*"/>
    <xsl:param name="roots" as="element(govuk:record)*"/>
    <xsl:variable name="all" as="element(govuk:s)*"
                  select="for $r in $roots/descendant-or-self::govuk:record, $scheme in $schemes
                          return govuk:md-rdf-subjects($scheme, $r)"/>
    <xsl:for-each-group select="$all" group-by="@id">
      <govuk:s id="{current-grouping-key()}">
        <xsl:for-each-group select="current-group()/govuk:v"
                            group-by="string-join((@p, @iri, @lit, @dt, @lang), '|')">
          <xsl:sequence select="current-group()[1]"/>
        </xsl:for-each-group>
      </govuk:s>
    </xsl:for-each-group>
  </xsl:function>

  <!-- The prefixes of some tables, each once -->
  <xsl:function name="govuk:md-rdf-prefixes" as="element(prefix)*">
    <xsl:param name="schemes" as="element()*"/>
    <xsl:for-each-group select="$schemes/prefix" group-by="@name">
      <xsl:sequence select="current-group()[1]"/>
    </xsl:for-each-group>
  </xsl:function>

  <!-- The required rows a record leaves empty, by their output name -->
  <xsl:function name="govuk:md-rdf-missing" as="xs:string*">
    <xsl:param name="scheme" as="element()"/>
    <xsl:param name="record" as="element(govuk:record)"/>
    <xsl:sequence select="for $kind in $scheme/kind[govuk:md-applies(., $record)],
                              $row in $kind/*[@required = 'yes']
                          return if (empty(govuk:md-values($row, $kind, $record))) then string($row/@as) else ()"/>
  </xsl:function>

  <!-- ===== Shared syntax ===== -->

  <!-- A name with a declared prefix, as written in the table -->
  <xsl:function name="govuk:md-rdf-prefixed" as="xs:boolean">
    <xsl:param name="prefixes" as="element(prefix)*"/>
    <xsl:param name="value" as="xs:string"/>
    <xsl:sequence select="matches($value, '^[A-Za-z][A-Za-z0-9_\-]*:[^/\s][^\s]*$')
                          and substring-before($value, ':') = $prefixes/@name"/>
  </xsl:function>

  <!-- ===== JSON-LD ===== -->

  <xsl:function name="govuk:md-rdf-jsonld-value" as="xs:string">
    <xsl:param name="v" as="element(govuk:v)"/>
    <xsl:sequence select="if ($v/@p = '@type') then govuk:md-json-string(string($v/@iri))
                          else if ($v/@iri) then concat('{ &quot;@id&quot;: ', govuk:md-json-string(string($v/@iri)), ' }')
                          else if ($v/@dt) then concat('{ &quot;@value&quot;: ', govuk:md-json-string(string($v/@lit)),
                                                       ', &quot;@type&quot;: ', govuk:md-json-string(string($v/@dt)), ' }')
                          else if ($v/@lang) then concat('{ &quot;@value&quot;: ', govuk:md-json-string(string($v/@lit)),
                                                         ', &quot;@language&quot;: ', govuk:md-json-string(string($v/@lang)), ' }')
                          else govuk:md-json-string(string($v/@lit))"/>
  </xsl:function>

  <xsl:function name="govuk:md-rdf-jsonld" as="xs:string">
    <xsl:param name="prefixes" as="element(prefix)*"/>
    <xsl:param name="subjects" as="element(govuk:s)*"/>
    <xsl:variable name="nodes" as="xs:string*">
      <xsl:for-each select="$subjects">
        <xsl:variable name="s" select="."/>
        <xsl:variable name="members" as="xs:string*">
          <xsl:sequence select="concat('&quot;@id&quot;: ', govuk:md-json-string(string($s/@id)))"/>
          <xsl:for-each select="distinct-values($s/govuk:v/@p)">
            <xsl:variable name="p" select="."/>
            <xsl:variable name="values" select="$s/govuk:v[@p = $p] ! govuk:md-rdf-jsonld-value(.)"/>
            <xsl:sequence select="concat(govuk:md-json-string($p), ': ',
                                         if (count($values) = 1) then $values else concat('[', string-join($values, ', '), ']'))"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="concat('    {', '&#10;', string-join(for $m in $members return concat('      ', $m), concat(',', '&#10;')), '&#10;', '    }')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="concat('{', '&#10;',
                                 '  &quot;@context&quot;: {', '&#10;',
                                 string-join(for $p in $prefixes
                                             return concat('    ', govuk:md-json-string(string($p/@name)), ': ', govuk:md-json-string(string($p/@uri))),
                                             concat(',', '&#10;')), '&#10;',
                                 '  },', '&#10;',
                                 '  &quot;@graph&quot;: [', '&#10;',
                                 string-join($nodes, concat(',', '&#10;')), '&#10;',
                                 '  ]', '&#10;', '}')"/>
  </xsl:function>

  <!-- ===== Turtle ===== -->

  <!-- A literal: quotes, backslashes and control characters escaped -->
  <xsl:function name="govuk:md-ttl-string" as="xs:string">
    <xsl:param name="value" as="xs:string"/>
    <xsl:sequence select="concat('&quot;',
      string-join(for $c in string-to-codepoints($value) return
        if ($c = 34) then '\&quot;'
        else if ($c = 92) then '\\'
        else if ($c = 10) then '\n'
        else if ($c = 13) then '\r'
        else if ($c = 9) then '\t'
        else if ($c lt 32 or $c = 127)
          then concat('\u', substring($govuk-md-hex, ($c idiv 4096) mod 16 + 1, 1),
                            substring($govuk-md-hex, ($c idiv 256) mod 16 + 1, 1),
                            substring($govuk-md-hex, ($c idiv 16) mod 16 + 1, 1),
                            substring($govuk-md-hex, $c mod 16 + 1, 1))
        else codepoints-to-string($c), ''),
      '&quot;')"/>
  </xsl:function>

  <!-- An address in angle brackets, with the characters an IRI may not hold percent-encoded -->
  <xsl:function name="govuk:md-ttl-iri" as="xs:string">
    <xsl:param name="iri" as="xs:string"/>
    <xsl:sequence select="concat('&lt;',
      string-join(for $c in string-to-codepoints($iri) return
        if ($c le 32 or $c = (34, 60, 62, 92, 94, 96, 123, 124, 125, 127))
          then concat('%', upper-case(substring($govuk-md-hex, ($c idiv 16) mod 16 + 1, 1)),
                           upper-case(substring($govuk-md-hex, $c mod 16 + 1, 1)))
        else codepoints-to-string($c), ''),
      '&gt;')"/>
  </xsl:function>

  <xsl:function name="govuk:md-rdf-turtle-value" as="xs:string">
    <xsl:param name="prefixes" as="element(prefix)*"/>
    <xsl:param name="v" as="element(govuk:v)"/>
    <xsl:sequence select="if ($v/@iri) then (if (govuk:md-rdf-prefixed($prefixes, string($v/@iri))) then string($v/@iri)
                                             else govuk:md-ttl-iri(string($v/@iri)))
                          else if ($v/@dt) then concat(govuk:md-ttl-string(string($v/@lit)), '^^', $v/@dt)
                          else if ($v/@lang) then concat(govuk:md-ttl-string(string($v/@lit)), '@', $v/@lang)
                          else govuk:md-ttl-string(string($v/@lit))"/>
  </xsl:function>

  <xsl:function name="govuk:md-rdf-turtle" as="xs:string">
    <xsl:param name="prefixes" as="element(prefix)*"/>
    <xsl:param name="subjects" as="element(govuk:s)*"/>
    <xsl:variable name="blocks" as="xs:string*">
      <xsl:for-each select="$subjects">
        <xsl:variable name="s" select="."/>
        <xsl:variable name="lines" as="xs:string*">
          <xsl:for-each select="distinct-values($s/govuk:v/@p)">
            <xsl:variable name="p" select="."/>
            <xsl:variable name="values" select="$s/govuk:v[@p = $p] ! govuk:md-rdf-turtle-value($prefixes, .)"/>
            <xsl:sequence select="concat(if ($p = '@type') then 'a' else $p, ' ', string-join($values, ', '))"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="concat(govuk:md-ttl-iri(string($s/@id)), '&#10;    ',
                                     string-join($lines, concat(' ;', '&#10;    ')), ' .')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="concat(string-join(for $p in $prefixes
                                             return concat('@prefix ', $p/@name, ': ', govuk:md-ttl-iri(string($p/@uri)), ' .'),
                                             '&#10;'),
                                 '&#10;&#10;',
                                 string-join($blocks, concat('&#10;', '&#10;')), '&#10;')"/>
  </xsl:function>

  <!-- ===== The catalogue record (#102): the graph, its files, its place in the cover ===== -->

  <xsl:output name="govuk-rdf" method="text" encoding="UTF-8"/>

  <xsl:variable name="govuk-md-rdf-prefixes" as="element(prefix)*"
                select="govuk:md-rdf-prefixes($govuk-md-rdf-schemes)"/>

  <xsl:variable name="govuk-md-rdf-graph" as="element(govuk:s)*"
                select="if (exists($govuk-md-roots)) then govuk:md-rdf-graph($govuk-md-rdf-schemes, $govuk-md-roots) else ()"/>

  <xsl:variable name="govuk-md-dcat-jsonld" as="xs:string?"
                select="if (exists($govuk-md-rdf-graph)) then govuk:md-rdf-jsonld($govuk-md-rdf-prefixes, $govuk-md-rdf-graph) else ()"/>

  <!-- dcat.jsonld and dcat.ttl at the site root, and the findings; run once, by the map transform -->
  <xsl:template name="govuk-dcat">
    <xsl:if test="$GOVUK-DCAT = 'yes' and $govuk-md-base ne ''">
      <xsl:call-template name="govuk-dcat-check"/>
      <xsl:if test="exists($govuk-md-rdf-graph)">
        <xsl:result-document href="dcat.jsonld" format="govuk-rdf">
          <xsl:value-of select="$govuk-md-dcat-jsonld"/>
        </xsl:result-document>
        <xsl:result-document href="dcat.ttl" format="govuk-rdf">
          <xsl:value-of select="govuk:md-rdf-turtle($govuk-md-rdf-prefixes, $govuk-md-rdf-graph)"/>
        </xsl:result-document>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- In the cover's head: the same record as a block (so a page-reading crawler
       sees it), and the two files as alternates -->
  <xsl:template name="govuk-md-dcat-head">
    <xsl:if test="exists($govuk-md-dcat-jsonld)">
      <link rel="alternate" type="application/ld+json" href="dcat.jsonld"/>
      <link rel="alternate" type="text/turtle" href="dcat.ttl"/>
      <script type="application/ld+json">
        <xsl:value-of select="$govuk-md-dcat-jsonld"/>
      </script>
    </xsl:if>
  </xsl:template>

  <!-- GOVK017W for a declared type the plugin cannot write; GOVK018W when nothing
       is declared; GOVK019W for each required property a record leaves empty -->
  <xsl:template name="govuk-dcat-check">
    <xsl:for-each select="govuk:md-declaring-refs($govuk-md-map)[empty(govuk:md-asset-types(.))]">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK017W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate(string-join(govuk:md-declared-types(.), ', '), ';', ',')"/>;%2=<xsl:value-of select="translate(govuk:md-ref-title(.), ';', ',')"/>;%3=<xsl:value-of select="string-join($govuk-md-vocabularies/@prefix, ', ')"/></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:if test="empty($govuk-md-roots)">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK018W'"/>
      </xsl:call-template>
    </xsl:if>
    <!-- one finding for each required property a record leaves empty; elements,
         not strings, because the message template reads its context node -->
    <xsl:variable name="missing" as="element(govuk:missing)*">
      <xsl:for-each select="$govuk-md-roots, $govuk-md-roots/govuk:rel[@name = 'hasPart']/govuk:record[@kind = 'asset']">
        <xsl:variable name="record" select="."/>
        <xsl:for-each select="$govuk-md-rdf-schemes">
          <xsl:variable name="scheme" select="."/>
          <xsl:for-each select="govuk:md-rdf-missing($scheme, $record)">
            <govuk:missing title="{$record/govuk:p[@term = 'dct:title']/@value}" row="{.}" table="{$scheme/@id}" id="{$record/@id}"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="$missing">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK019W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate(string(@title), ';', ',')"/>;%2=<xsl:value-of select="@row"/>;%3=<xsl:value-of select="@table"/>;%4=<xsl:value-of select="@id"/></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- On the glossary page and a glossary entry's page: the glossary vocabulary, as its two files (#103) -->
  <xsl:template name="govuk-md-skos-head">
    <xsl:param name="prefix" as="xs:string" select="''"/>
    <xsl:if test="$GOVUK-SKOS = 'yes' and $govuk-md-base ne ''">
      <link rel="alternate" type="text/turtle" href="{$prefix}vocab/glossary.ttl"/>
      <link rel="alternate" type="application/ld+json" href="{$prefix}vocab/glossary.jsonld"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

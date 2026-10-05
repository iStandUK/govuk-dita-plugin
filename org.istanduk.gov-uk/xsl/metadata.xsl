<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

One metadata model (design 14, D-26): harvest once, map by table, write by
syntax.

  Harvest  The DITA is read once into neutral records (govuk:record) of a
           kind (publication, page, agent), whose properties are Dublin Core
           terms (govuk:p) and whose relations (govuk:rel) hold the records
           they point to. The rules of design 14 section 5 are applied here
           and nowhere else: sources in order, the dates and persons gates,
           the licence, the site URL and the keyword filter.
  Tables   resource/metadata/*.xml, one per scheme, enabled by govuk.metadata
           through schemes.xml. Data, not code.
  Writers  One per syntax. govuk-md-head writes the meta and link elements of
           a page's head by walking the enabled tables; it names no scheme.

A <data name="prefix:term" value="..."/> in bookmeta, a map's or topicref's
topicmeta, or a topic's prolog becomes a property of the record it describes,
when the term is in a vocabulary resource/metadata/vocabularies.xml declares.

Imported by the topic transform (dita2govuk.xsl, through template.xsl's head)
and the map transform (map2govuk-cover.xsl: the cover, the utility pages and
the once-per-build checks).
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- basic | no (#99); later levels add tables -->
  <xsl:param name="GOVUK-METADATA" select="'basic'"/>
  <xsl:param name="GOVUK-SITE-URL" select="''"/>
  <xsl:param name="GOVUK-ORGANISATION" select="''"/>
  <xsl:param name="GOVUK-ORGANISATION-URL" select="''"/>
  <xsl:param name="GOVUK-OG-IMAGE" select="''"/>
  <xsl:param name="GOVUK-LICENCE-URL" select="''"/>
  <xsl:param name="GOVUK-METADATA-PERSONS" select="'no'"/>
  <xsl:param name="GOVUK-DATES" select="'no'"/>
  <xsl:param name="GOVUK-BRANDING" select="'neutral'"/>
  <xsl:param name="GOVUK-SERVICE-NAME" select="''"/>
  <xsl:param name="GOVUK-FOOTER-LICENCE" select="''"/>

  <!-- The published base URL with its closing slash, or '' when unknown:
       without it no identifier and no URL-valued property is written -->
  <xsl:variable name="govuk-md-base" as="xs:string"
                select="let $u := normalize-space($GOVUK-SITE-URL)
                        return if ($u = '') then '' else if (ends-with($u, '/')) then $u else concat($u, '/')"/>

  <xsl:variable name="govuk-md-dir" as="xs:anyURI"
                select="resolve-uri('../resource/metadata/', static-base-uri())"/>

  <!-- The tables govuk.metadata enables, in schemes.xml's order -->
  <xsl:variable name="govuk-md-schemes" as="element()*"
                select="if ($GOVUK-METADATA = 'no') then ()
                        else for $s in doc(resolve-uri('schemes.xml', $govuk-md-dir))/schemes/scheme
                                       [tokenize(@levels) = $GOVUK-METADATA]
                             return doc(resolve-uri($s/@href, $govuk-md-dir))/scheme"/>

  <xsl:variable name="govuk-md-vocabularies" as="element()*"
                select="doc(resolve-uri('vocabularies.xml', $govuk-md-dir))/vocabularies/vocabulary"/>

  <!-- Terms that describe one thing only, so a page never takes them from
       the publication it is part of -->
  <xsl:variable name="govuk-md-own-terms" as="xs:string*"
                select="('dct:title', 'dct:description', 'dct:alternative', 'dct:identifier',
                         'dct:type', 'rdf:type', 'dct:issued', 'dct:modified', 'dct:created',
                         'dct:subject', 'dcat:keyword', 'dcat:version', 'dcat:landingPage',
                         'adms:status')"/>

  <!-- The Open Government Licence, which official branding states (D-24) -->
  <xsl:variable name="govuk-md-ogl" as="xs:string"
                select="'https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/'"/>

  <!-- ===== Values ===== -->

  <!-- An element's text without the index entries inside it, normalised -->
  <xsl:function name="govuk:md-text" as="xs:string">
    <xsl:param name="element" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join($element//text()
                            [not(ancestor::*[contains(@class, ' topic/indexterm ')
                                             or contains(@class, ' topic/desc ')
                                             or contains(@class, ' topic/draft-comment ')
                                             or contains(@class, ' topic/required-cleanup ')])], ''))"/>
  </xsl:function>

  <!-- An absolute URI, or '' -->
  <xsl:function name="govuk:md-uri" as="xs:string">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:variable name="v" select="normalize-space(string($value))"/>
    <xsl:sequence select="if (matches($v, '^[A-Za-z][A-Za-z0-9+.\-]*:[^\s]+$')) then $v else ''"/>
  </xsl:function>

  <!-- A value in a table's format: date (the ISO date part), locale (en-GB as
       en_GB), uri (absolute only), text -->
  <xsl:function name="govuk:md-format" as="xs:string">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:param name="format" as="xs:string?"/>
    <xsl:variable name="v" select="normalize-space(string($value))"/>
    <xsl:choose>
      <xsl:when test="$format = 'uri'">
        <xsl:sequence select="govuk:md-uri($v)"/>
      </xsl:when>
      <xsl:when test="$format = 'date'">
        <xsl:sequence select="if (substring($v, 1, 10) castable as xs:date) then substring($v, 1, 10) else ''"/>
      </xsl:when>
      <xsl:when test="$format = 'locale'">
        <xsl:variable name="parts" select="tokenize($v, '[-_]')"/>
        <xsl:sequence select="if (not(matches($v, '^[A-Za-z]{2,3}([-_][A-Za-z0-9]{2,8})*$'))) then ''
                              else string-join((lower-case($parts[1]),
                                                for $p in $parts[position() gt 1]
                                                return if (string-length($p) = 2) then upper-case($p) else $p), '_')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$v"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="govuk:md-iso-date" as="xs:string">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:sequence select="govuk:md-format($value, 'date')"/>
  </xsl:function>

  <!-- A property, when it has a value -->
  <xsl:function name="govuk:md-p" as="element(govuk:p)?">
    <xsl:param name="term" as="xs:string"/>
    <xsl:param name="value" as="xs:string?"/>
    <xsl:if test="normalize-space(string($value)) ne ''">
      <govuk:p term="{$term}" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:function>

  <!-- ===== data: any property, as a prefixed term (design 14 section 6) ===== -->

  <!-- Whether a name is a term of a declared vocabulary: an open vocabulary
       takes any term under its prefix, a closed one only those it lists -->
  <xsl:function name="govuk:md-known-term" as="xs:boolean">
    <xsl:param name="name" as="xs:string"/>
    <xsl:variable name="vocabulary" select="$govuk-md-vocabularies[@prefix = substring-before($name, ':')]"/>
    <xsl:variable name="local" select="substring-after($name, ':')"/>
    <xsl:sequence select="exists($vocabulary) and matches($local, '^[A-Za-z_][A-Za-z0-9_.\-]*$')
                          and ($vocabulary/@open = 'yes' or tokenize(normalize-space($vocabulary)) = $local)"/>
  </xsl:function>

  <!-- data elements that are metadata: a prefixed name, at the top level of
       a bookmeta, topicmeta or prolog. Others are the publisher's own. -->
  <xsl:function name="govuk:md-data-elements" as="element()*">
    <xsl:param name="holders" as="element()*"/>
    <xsl:sequence select="for $h in $holders
                          return $h//*[contains(@class, ' topic/data ')]
                                      [not(ancestor::*[contains(@class, ' topic/data ')][. >> $h])]
                                      [matches(normalize-space(@name), '^[A-Za-z][A-Za-z0-9\-]*:')]"/>
  </xsl:function>

  <!-- The properties the data elements of each holder state, in the holders'
       order; a name no vocabulary knows is left out (and reported once per
       build, by govuk-md-check) -->
  <xsl:function name="govuk:md-data" as="element(govuk:p)*">
    <xsl:param name="holders" as="element()*"/>
    <xsl:for-each select="govuk:md-data-elements($holders)[govuk:md-known-term(normalize-space(@name))]">
      <xsl:sequence select="govuk:md-p(normalize-space(@name),
                                       if (normalize-space(@value)) then string(@value) else govuk:md-text(.))"/>
    </xsl:for-each>
  </xsl:function>

  <!-- ===== Structure ===== -->

  <!-- The topicrefs that are pages, in reading order (FR-N5) -->
  <xsl:function name="govuk:md-reading" as="element()*">
    <xsl:param name="map" as="node()?"/>
    <xsl:sequence select="$map//*[contains(@class, ' map/topicref ')]
                          [normalize-space(@href)]
                          [not(@processing-role = 'resource-only')]
                          [not(@scope = 'external')]
                          [not(@format) or @format = 'dita']"/>
  </xsl:function>

  <!-- The page a topicref renders, relative to the site root, or '' -->
  <xsl:function name="govuk:md-ref-path" as="xs:string">
    <xsl:param name="ref" as="element()?"/>
    <xsl:variable name="target" select="string(($ref/@copy-to, $ref/@href)[normalize-space()][1])"/>
    <xsl:sequence select="if (exists($ref) and $target ne '' and not($ref/@scope = 'external')
                              and (not($ref/@format) or $ref/@format = 'dita'))
                          then replace(replace($target, '#.*$', ''), '\.[^./]*$', $OUTEXT)
                          else ''"/>
  </xsl:function>

  <xsl:function name="govuk:md-ref-title" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="normalize-space(string((
                            $ref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')],
                            $ref/@navtitle,
                            $ref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' map/linktext ')])
                            [normalize-space()][1]))"/>
  </xsl:function>

  <xsl:function name="govuk:md-id" as="xs:string">
    <xsl:param name="path" as="xs:string"/>
    <xsl:sequence select="if ($govuk-md-base ne '' and $path ne '') then concat($govuk-md-base, $path) else ''"/>
  </xsl:function>

  <!-- A record that stands for a related page: its address and title -->
  <xsl:function name="govuk:md-ref-record" as="element(govuk:record)">
    <xsl:param name="ref" as="element()"/>
    <govuk:record kind="page">
      <xsl:variable name="id" select="govuk:md-id(govuk:md-ref-path($ref))"/>
      <xsl:if test="$id ne ''">
        <xsl:attribute name="id" select="$id"/>
      </xsl:if>
      <xsl:sequence select="govuk:md-p('dct:title', govuk:md-ref-title($ref))"/>
    </govuk:record>
  </xsl:function>

  <!-- ===== The publication and its organisation ===== -->

  <xsl:variable name="govuk-md-map" as="element()?" select="$govuk-book"/>

  <xsl:variable name="govuk-md-agent" as="element(govuk:record)?">
    <xsl:variable name="name" as="xs:string?"
                  select="(normalize-space($GOVUK-ORGANISATION), $govuk-publishers, $govuk-copyr-owner)[. ne ''][1]"/>
    <xsl:if test="exists($name)">
      <govuk:record kind="agent">
        <xsl:sequence select="govuk:md-p('dct:title', $name),
                              govuk:md-p('foaf:homepage', govuk:md-uri($GOVUK-ORGANISATION-URL))"/>
      </govuk:record>
    </xsl:if>
  </xsl:variable>

  <!-- dct:rights: the statement the footer makes -->
  <xsl:variable name="govuk-md-rights" as="xs:string">
    <xsl:variable name="text">
      <xsl:choose>
        <xsl:when test="$GOVUK-BRANDING = 'official'">
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id" select="'govuk-dita.crown-copyright'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="normalize-space($GOVUK-FOOTER-LICENCE)">
          <xsl:value-of select="$GOVUK-FOOTER-LICENCE"/>
        </xsl:when>
        <xsl:when test="$govuk-copyr-owner ne ''">
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id" select="'govuk-dita.copyright'"/>
          </xsl:call-template>
          <xsl:value-of select="string-join(('', $govuk-copyr-years[. ne ''], $govuk-copyr-owner), ' ')"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="normalize-space($text)"/>
  </xsl:variable>

  <xsl:variable name="govuk-md-publication" as="element(govuk:record)">
    <xsl:variable name="map" select="$govuk-md-map"/>
    <xsl:variable name="bookmeta" select="$map/*[contains(@class, ' bookmap/bookmeta ')]"/>
    <xsl:variable name="topicmeta" select="$map/*[contains(@class, ' map/topicmeta ')][not(contains(@class, ' bookmap/bookmeta '))]"/>
    <xsl:variable name="critdates" select="($bookmeta, $topicmeta)/*[contains(@class, ' topic/critdates ')]"/>
    <govuk:record kind="publication">
      <xsl:if test="$govuk-md-base ne ''">
        <xsl:attribute name="id" select="$govuk-md-base"/>
      </xsl:if>
      <xsl:sequence select="govuk:md-p('dct:title',
                              (normalize-space($GOVUK-SERVICE-NAME),
                               govuk:md-text(($map//*[contains(@class, ' bookmap/mainbooktitle ')])[1]),
                               govuk:md-text($map/*[contains(@class, ' topic/title ')]),
                               normalize-space($map/@title))[. ne ''][1])"/>
      <xsl:sequence select="govuk:md-p('dct:description',
                              (govuk:md-text($topicmeta/*[contains(@class, ' map/shortdesc ')][1]),
                               govuk:md-text(($map//*[contains(@class, ' bookmap/booktitlealt ')])[1]))[. ne ''][1])"/>
      <xsl:sequence select="govuk:md-p('dct:language', string(($map/@xml:lang, $DEFAULTLANG)[1]))"/>
      <xsl:if test="exists($govuk-md-agent)">
        <govuk:p term="dct:publisher" value="{$govuk-md-agent/govuk:p[@term = 'dct:title']/@value}">
          <xsl:sequence select="$govuk-md-agent"/>
        </govuk:p>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$GOVUK-METADATA-PERSONS = 'yes' and exists($bookmeta/*[contains(@class, ' topic/author ')])">
          <xsl:sequence select="for $a in $bookmeta/*[contains(@class, ' topic/author ')] return govuk:md-p('dct:creator', govuk:md-text($a))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="govuk:md-p('dct:creator', string($govuk-md-agent/govuk:p[@term = 'dct:title']/@value))"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:sequence select="govuk:md-p('dct:rights', $govuk-md-rights)"/>
      <xsl:sequence select="govuk:md-p('dct:license',
                              if ($GOVUK-BRANDING = 'official') then $govuk-md-ogl else govuk:md-uri($GOVUK-LICENCE-URL))"/>
      <xsl:if test="$GOVUK-DATES ne 'no'">
        <xsl:sequence select="govuk:md-p('dct:issued', govuk:md-iso-date(($critdates/*[contains(@class, ' topic/created ')]/@date)[1])),
                              govuk:md-p('dct:modified', govuk:md-iso-date(($critdates/*[contains(@class, ' topic/revised ')]/@modified)[last()]))"/>
      </xsl:if>
      <xsl:sequence select="govuk:md-p('dcat:version', govuk:md-text(($bookmeta//*[contains(@class, ' bookmap/edition ')])[1]))"/>
      <xsl:sequence select="govuk:md-p('foaf:depiction', govuk:md-og-image())"/>
      <xsl:sequence select="govuk:md-data(($bookmeta, $topicmeta))"/>
    </govuk:record>
  </xsl:variable>

  <!-- govuk.og.image: an absolute URL, or a path under the site root -->
  <xsl:function name="govuk:md-og-image" as="xs:string">
    <xsl:variable name="v" select="normalize-space($GOVUK-OG-IMAGE)"/>
    <xsl:sequence select="if ($v = '') then ''
                          else if (govuk:md-uri($v) ne '') then $v
                          else govuk:md-id(replace($v, '^/+', ''))"/>
  </xsl:function>

  <!-- ===== A page ===== -->

  <!-- Keywords as tags: a keyword that is only a word of the page's title,
       or has no letter or digit, is not a tag; duplicates go (section 5) -->
  <xsl:function name="govuk:md-tags" as="xs:string*">
    <xsl:param name="keywords" as="xs:string*"/>
    <xsl:param name="title" as="xs:string"/>
    <xsl:variable name="words" select="tokenize(lower-case($title), '[^\p{L}\p{N}]+')[. ne '']"/>
    <xsl:for-each-group select="$keywords[matches(., '[\p{L}\p{N}]')][not(lower-case(.) = $words)]"
                        group-by="lower-case(.)">
      <xsl:sequence select="current-group()[1]"/>
    </xsl:for-each-group>
  </xsl:function>

  <!-- The type of a topic: the last of its class tokens (task, concept,
       reference, glossentry, or a specialisation's own) -->
  <xsl:function name="govuk:md-topic-type" as="xs:string">
    <xsl:param name="topic" as="element()"/>
    <xsl:sequence select="substring-after(tokenize(normalize-space($topic/@class), ' ')[last()], '/')"/>
  </xsl:function>

  <!-- A page record. role: cover | topic | utility. A topic page states its
       own properties (the topicrefs above it, nearest first, then its
       prolog), and takes the rest from the publication; the cover and the
       utility pages are given a title (and the cover a description). -->
  <xsl:template name="govuk-md-page" as="element(govuk:record)">
    <xsl:param name="role" as="xs:string"/>
    <xsl:param name="path" as="xs:string"/>
    <xsl:param name="topic" as="element()?" select="()"/>
    <xsl:param name="ref" as="element()?" select="()"/>
    <xsl:param name="title" as="xs:string" select="''"/>
    <xsl:param name="description" as="xs:string" select="''"/>
    <xsl:param name="previous" as="element()?" select="()"/>
    <xsl:param name="next" as="element()?" select="()"/>
    <xsl:variable name="chain" as="element()*"
                  select="$ref/ancestor-or-self::*[contains(@class, ' map/topicref ')]"/>
    <xsl:variable name="prolog" select="$topic/*[contains(@class, ' topic/prolog ')]"/>
    <xsl:variable name="metadata" select="$prolog/*[contains(@class, ' topic/metadata ')]"/>
    <xsl:variable name="topic-title" as="xs:string"
                  select="if (exists($topic)) then govuk:md-text($topic/*[contains(@class, ' topic/title ')]) else $title"/>
    <xsl:variable name="own" as="element(govuk:p)*">
      <xsl:sequence select="govuk:md-p('dct:title', ($topic-title, $title)[. ne ''][1])"/>
      <xsl:sequence select="govuk:md-p('dct:description',
                              (govuk:md-text(($topic/*[contains(@class, ' topic/shortdesc ')],
                                              $topic/*[contains(@class, ' topic/abstract ')]/*[contains(@class, ' topic/shortdesc ')])[1]),
                               govuk:md-text($ref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' map/shortdesc ')]),
                               $description)[. ne ''][1])"/>
      <xsl:if test="exists($topic)">
        <xsl:sequence select="govuk:md-p('dct:language', string($topic/ancestor-or-self::*[@xml:lang][1]/@xml:lang))"/>
        <xsl:sequence select="govuk:md-p('dct:identifier',
                                string(($prolog/*[contains(@class, ' topic/resourceid ')]/@appid[normalize-space()])[1]))"/>
        <xsl:for-each-group select="$metadata/*[contains(@class, ' topic/category ')]/govuk:md-text(.)[. ne '']" group-by=".">
          <xsl:sequence select="govuk:md-p('dct:subject', current-grouping-key())"/>
        </xsl:for-each-group>
        <xsl:sequence select="for $k in govuk:md-tags($metadata/*[contains(@class, ' topic/keywords ')]
                                                       /*[contains(@class, ' topic/keyword ')]/govuk:md-text(.),
                                                     $topic-title)
                              return govuk:md-p('dct:subject', $k)"/>
        <xsl:for-each-group select="$metadata/*[contains(@class, ' topic/audience ')]
                                      /(if (normalize-space(@type)) then normalize-space(@type) else govuk:md-text(.))[. ne '']"
                            group-by=".">
          <xsl:sequence select="govuk:md-p('dct:audience', current-grouping-key())"/>
        </xsl:for-each-group>
        <xsl:sequence select="govuk:md-p('dct:type', govuk:md-topic-type($topic))"/>
        <xsl:if test="$topic/@importance = 'obsolete'
                      or tokenize(normalize-space(string-join(($topic/@outputclass,
                           $topic/*[contains(@class, ' topic/title ')]/@outputclass), ' '))) = 'retired'">
          <xsl:sequence select="govuk:md-p('adms:status', 'retired')"/>
        </xsl:if>
        <xsl:if test="$GOVUK-METADATA-PERSONS = 'yes'">
          <xsl:sequence select="for $a in $prolog/*[contains(@class, ' topic/author ')] return govuk:md-p('dct:creator', govuk:md-text($a))"/>
        </xsl:if>
        <!-- The topic's own dates only: the toolkit replaces them with the
             map's when bookmeta has critdates, and those date the book -->
        <xsl:if test="$GOVUK-DATES ne 'no'">
          <xsl:variable name="critdates" select="$prolog/*[contains(@class, ' topic/critdates ')]
                                                 [not(@xtrf) or not($topic/@xtrf) or @xtrf = $topic/@xtrf]"/>
          <xsl:sequence select="govuk:md-p('dct:issued', govuk:md-iso-date(($critdates/*[contains(@class, ' topic/created ')]/@date)[1])),
                                govuk:md-p('dct:modified', govuk:md-iso-date(($critdates/*[contains(@class, ' topic/revised ')]/@modified)[last()]))"/>
        </xsl:if>
      </xsl:if>
      <xsl:sequence select="govuk:md-data((reverse($chain)/*[contains(@class, ' map/topicmeta ')], $prolog))"/>
    </xsl:variable>
    <govuk:record kind="page" role="{$role}" path="{$path}">
      <xsl:if test="govuk:md-id($path) ne ''">
        <xsl:attribute name="id" select="govuk:md-id($path)"/>
      </xsl:if>
      <xsl:sequence select="$own"/>
      <xsl:sequence select="$govuk-md-publication/govuk:p[not(@term = ($govuk-md-own-terms, $own/@term))]"/>
      <!-- The publication, then each page above this one, outermost first -->
      <govuk:rel name="isPartOf">
        <govuk:record kind="publication">
          <xsl:sequence select="$govuk-md-publication/@id, $govuk-md-publication/govuk:p[@term = 'dct:title']"/>
        </govuk:record>
        <xsl:sequence select="for $r in $chain[not(. is $ref)][govuk:md-ref-title(.) ne ''] return govuk:md-ref-record($r)"/>
      </govuk:rel>
      <xsl:for-each select="$chain[govuk:md-ref-title(.) ne ''][1]">
        <govuk:rel name="section">
          <xsl:sequence select="govuk:md-ref-record(.)"/>
        </govuk:rel>
      </xsl:for-each>
      <xsl:for-each select="$previous">
        <govuk:rel name="previous"><xsl:sequence select="govuk:md-ref-record(.)"/></govuk:rel>
      </xsl:for-each>
      <xsl:for-each select="$next">
        <govuk:rel name="next"><xsl:sequence select="govuk:md-ref-record(.)"/></govuk:rel>
      </xsl:for-each>
    </govuk:record>
  </xsl:template>

  <!-- ===== Tables ===== -->

  <!-- Whether a kind of a table applies to a record: the record's kind, and
       the one test a table may make, "name = 'value'" or "name != 'value'",
       where the name is a record attribute (@role) or a property term -->
  <xsl:function name="govuk:md-applies" as="xs:boolean">
    <xsl:param name="kind" as="element()"/>
    <xsl:param name="record" as="element(govuk:record)"/>
    <xsl:variable name="when" select="normalize-space($kind/@when)"/>
    <xsl:variable name="test" select="analyze-string($when, '^(@?[A-Za-z][\w:.\-]*)\s*(!?=)\s*''([^'']*)''$')"/>
    <xsl:variable name="name" select="string($test//*:group[@nr = 1])"/>
    <xsl:variable name="values" as="xs:string*"
                  select="if (starts-with($name, '@')) then string($record/@*[name() = substring($name, 2)])
                          else $record/govuk:p[@term = $name]/@value/string()"/>
    <xsl:sequence select="$kind/@record = $record/@kind
                          and (if ($when = '') then true()
                               else if (empty($test/*:match)) then false()
                               else if ($test//*:group[@nr = 2] = '=') then $values = string($test//*:group[@nr = 3])
                               else not($values = string($test//*:group[@nr = 3])))"/>
  </xsl:function>

  <!-- Whether a row's value is a URL: written only when the site URL is known -->
  <xsl:function name="govuk:md-row-is-uri" as="xs:boolean">
    <xsl:param name="row" as="element()"/>
    <xsl:sequence select="$row/@format = 'uri' or $row/@term = '@id'
                          or (local-name($row) = 'relation' and not($row/@term))"/>
  </xsl:function>

  <!-- The values a row of a table takes from a record, formatted, without
       duplicates; one only, unless the row repeats -->
  <xsl:function name="govuk:md-values" as="xs:string*">
    <xsl:param name="row" as="element()"/>
    <xsl:param name="kind" as="element()"/>
    <xsl:param name="record" as="element(govuk:record)"/>
    <xsl:variable name="format" select="if (govuk:md-row-is-uri($row)) then 'uri' else string($row/@format)"/>
    <xsl:variable name="raw" as="xs:string*">
      <xsl:choose>
        <xsl:when test="local-name($row) = 'value'">
          <xsl:sequence select="string($row/@value)"/>
        </xsl:when>
        <xsl:when test="local-name($row) = 'relation'">
          <xsl:sequence select="for $r in $record/govuk:rel[@name = $row/@name]/govuk:record
                                           [not($row/@target) or @kind = $row/@target]
                                return if ($row/@term) then string(($r/govuk:p[@term = $row/@term]/@value)[1])
                                       else string($r/@id)"/>
        </xsl:when>
        <xsl:when test="$row/@term = '@id'">
          <xsl:sequence select="string($record/@id)"/>
        </xsl:when>
        <xsl:when test="$row/@term = '@type'">
          <xsl:sequence select="string($kind/@type)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$record/govuk:p[@term = $row/@term]/@value/string()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="values" select="distinct-values(for $v in $raw return govuk:md-format($v, $format)[. ne ''])"/>
    <xsl:sequence select="if ($row/@repeat = 'yes') then $values else $values[1]"/>
  </xsl:function>

  <!-- ===== Writer: meta and link elements ===== -->

  <xsl:template name="govuk-md-head">
    <xsl:param name="record" as="element(govuk:record)?"/>
    <xsl:for-each select="$govuk-md-schemes[@syntax = ('meta', 'link')]">
      <xsl:variable name="scheme" select="."/>
      <xsl:for-each select="kind[exists($record) and govuk:md-applies(., $record)]">
        <xsl:variable name="kind" select="."/>
        <xsl:for-each select="*">
          <xsl:variable name="row" select="."/>
          <xsl:for-each select="govuk:md-values($row, $kind, $record)">
            <xsl:choose>
              <xsl:when test="$scheme/@syntax = 'link'">
                <link rel="{$row/@as}" href="{.}"/>
              </xsl:when>
              <xsl:otherwise>
                <meta>
                  <xsl:attribute name="{($row/@attribute, $scheme/@attribute, 'name')[1]}" select="$row/@as"/>
                  <xsl:attribute name="content" select="."/>
                </meta>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- ===== Checks, once per build (run by the map transform) ===== -->

  <!-- The required rows of the enabled tables a record leaves empty, as
       "scheme as", skipping URL-valued rows when no site URL is known -->
  <xsl:function name="govuk:md-missing" as="xs:string*">
    <xsl:param name="record" as="element(govuk:record)"/>
    <xsl:sequence select="for $scheme in $govuk-md-schemes,
                              $kind in $scheme/kind[govuk:md-applies(., $record)],
                              $row in $kind/*[@required = 'yes']
                                             [$govuk-md-base ne '' or not(govuk:md-row-is-uri(.))]
                          return if (empty(govuk:md-values($row, $kind, $record)))
                                 then concat($scheme/@id, ' ', $row/@as) else ()"/>
  </xsl:function>

  <!-- Where an element is, relative to the map's folder -->
  <xsl:function name="govuk:md-where" as="xs:string">
    <xsl:param name="element" as="element()"/>
    <xsl:param name="base" as="xs:string"/>
    <xsl:variable name="uri" select="string(base-uri($element))"/>
    <xsl:variable name="dir" select="replace($base, '/[^/]*$', '/')"/>
    <xsl:sequence select="if (starts-with($uri, $dir)) then substring-after($uri, $dir) else $uri"/>
  </xsl:function>

  <!-- GOVK011W for each data name no vocabulary knows; GOVK012W for each
       required row that pages leave empty. Context: the map. -->
  <xsl:template name="govuk-md-check">
    <xsl:param name="cover" as="element(govuk:record)"/>
    <xsl:if test="$GOVUK-METADATA ne 'no'">
      <xsl:variable name="map" select="/*[contains(@class, ' map/map ')]"/>
      <xsl:variable name="base" select="string(base-uri($map))"/>
      <!-- Each topic once: its data names outside the declared vocabularies,
           and, for a page in the navigation, the required rows its record
           leaves empty (relations to neighbours are structural, so not read) -->
      <xsl:variable name="findings" as="element()*">
        <xsl:for-each select="govuk:md-data-elements(($map/*[contains(@class, ' map/topicmeta ')],
                                $map//*[contains(@class, ' map/topicref ')]/*[contains(@class, ' map/topicmeta ')]))
                              [not(govuk:md-known-term(normalize-space(@name)))]">
          <govuk:unknown name="{normalize-space(@name)}" where="{govuk:md-where(., $base)}"/>
        </xsl:for-each>
        <xsl:for-each select="govuk:md-missing($cover)">
          <govuk:missing row="{.}" path="index{$OUTEXT}"/>
        </xsl:for-each>
        <xsl:for-each-group select="$map//*[contains(@class, ' map/topicref ')][normalize-space(@href)]
                                    [not(@scope = 'external')][not(@format) or @format = 'dita']"
                            group-by="replace(@href, '#.*$', '')">
          <xsl:variable name="uri" select="resolve-uri(current-grouping-key(), $base)"/>
          <xsl:variable name="topic" as="element()?"
                        select="if (doc-available($uri)) then (doc($uri)//*[contains(@class, ' topic/topic ')])[1] else ()"/>
          <xsl:for-each select="govuk:md-data-elements($topic/*[contains(@class, ' topic/prolog ')])
                                [not(govuk:md-known-term(normalize-space(@name)))]">
            <govuk:unknown name="{normalize-space(@name)}" where="{govuk:md-where(., $base)}"/>
          </xsl:for-each>
          <xsl:variable name="ref" select="current-group()[not(@processing-role = 'resource-only')][1]"/>
          <xsl:if test="exists($topic) and exists($ref)">
            <xsl:variable name="path" select="govuk:md-ref-path($ref)"/>
            <xsl:variable name="record" as="element(govuk:record)">
              <xsl:call-template name="govuk-md-page">
                <xsl:with-param name="role" select="'topic'"/>
                <xsl:with-param name="path" select="$path"/>
                <xsl:with-param name="topic" select="$topic"/>
                <xsl:with-param name="ref" select="$ref"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="govuk:md-missing($record)">
              <govuk:missing row="{.}" path="{$path}"/>
            </xsl:for-each>
          </xsl:if>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:for-each-group select="$findings[self::govuk:unknown]" group-by="@name">
        <xsl:call-template name="output-message">
          <xsl:with-param name="id" select="'GOVK011W'"/>
          <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate(current-grouping-key(), ';', ',')"/>;%2=<xsl:value-of select="count(current-group())"/>;%3=<xsl:value-of select="current-group()[1]/@where"/>;%4=<xsl:value-of select="string-join($govuk-md-vocabularies/@prefix, ', ')"/></xsl:with-param>
        </xsl:call-template>
      </xsl:for-each-group>
      <xsl:for-each-group select="$findings[self::govuk:missing]" group-by="@row">
        <xsl:call-template name="output-message">
          <xsl:with-param name="id" select="'GOVK012W'"/>
          <xsl:with-param name="msgparams">%1=<xsl:value-of select="count(current-group())"/>;%2=<xsl:value-of select="substring-after(current-grouping-key(), ' ')"/>;%3=<xsl:value-of select="substring-before(current-grouping-key(), ' ')"/>;%4=<xsl:value-of select="current-group()[1]/@path"/></xsl:with-param>
        </xsl:call-template>
      </xsl:for-each-group>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

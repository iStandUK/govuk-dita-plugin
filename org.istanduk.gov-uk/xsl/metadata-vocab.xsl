<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.


The vocabulary harvesters and files (design 14 sections 8, 18 and 19; #103,
#263), included by map2govuk-cover.xsl: the schemes and terms a publication
holds, written by govuk.skos=yes as SKOS, one vocab/<name>.ttl and
vocab/<name>.jsonld for each.

  scheme   The generated glossary (every glossary entry), each glossgroup (its
           entries), each subjectScheme map the build holds (its subjectdefs),
           and each scheme the map declares (the topics beneath the declaration
           that say they are concepts).
  term     A glossary entry, a subjectdef, or a topic that says it is a
           concept: its label, definition and other names, what its data
           elements state, and its place in a hierarchy: a subjectdef's
           nesting, or the broader and narrower concepts a topic states.

A term's address is, in this order: an absolute address the source states
(resourceid appid, or a data element named dct:identifier); the address of its
own page; the glossary page with the entry's anchor; the vocabulary file with
the term's key as the fragment. The page a term is described on is linked from
it. One concept has one address, however it is reached (D-32). Nothing is
invented, and the type of a scheme is its source's.

The names, addresses and rules that a page's own transform needs as well are
in metadata-terms.xsl.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"

                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                version="3.0"
                exclude-result-prefixes="xs govuk map">

  <!-- ===== The generated glossary and its groups ===== -->

  <xsl:variable name="govuk-md-glossary-label" as="xs:string">
    <xsl:variable name="label">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:sequence select="normalize-space(string($label))"/>
  </xsl:variable>


  <!-- The entries of the map that are pages, by the topic each points at. A key, because
       every subjectdef of a scheme asks for its page, and its parent's and its children's:
       a scan of the map for each would grow as the square of a large vocabulary. -->
  <xsl:key name="govuk-md-page-by-topic"
           match="*[contains(@class, ' map/topicref ')][normalize-space(@href)]
                   [not(@processing-role = 'resource-only')][not(@scope = 'external')]
                   [not(@format) or @format = 'dita']"
           use="string(resolve-uri(replace(@href, '#.*$', ''), string(base-uri(.))))"/>

  <!-- The page an entry has of its own, if it does: the entry is the root of a topic the navigation reaches -->
  <xsl:function name="govuk:md-entry-page" as="xs:string">
    <xsl:param name="entry" as="element()"/>
    <xsl:variable name="ref" as="element()?"
                  select="(key('govuk-md-page-by-topic', string(base-uri($entry)), root($govuk-md-map))
                           [$entry is root($entry)/*])[1]"/>
    <xsl:sequence select="if (exists($ref)) then govuk:md-id(govuk:md-ref-path($ref)) else ''"/>
  </xsl:function>

  <!-- The address of every glossary entry, in the order of $govuk-gloss-sources -->
  <xsl:variable name="govuk-md-gloss-ids" as="xs:string*">
    <xsl:for-each select="1 to count($govuk-gloss-sources)">
      <xsl:variable name="entry" select="$govuk-gloss-sources[current()]"/>
      <xsl:variable name="stated" select="govuk:md-stated-iri($entry/*[contains(@class, ' topic/prolog ')])"/>
      <xsl:variable name="page" select="govuk:md-entry-page($entry)"/>
      <xsl:sequence select="($stated[. ne ''], $page[. ne ''],
                             concat($govuk-md-base, 'glossary.html#', $govuk-gloss-anchors[current()]))[1]"/>
    </xsl:for-each>
  </xsl:variable>

  <!-- A glossary entry as a term -->
  <xsl:function name="govuk:md-gloss-term" as="element(govuk:record)?">
    <xsl:param name="i" as="xs:integer"/>
    <xsl:param name="scheme" as="xs:string"/>
    <xsl:variable name="entry" select="$govuk-gloss-sources[$i]"/>
    <xsl:variable name="id" select="$govuk-md-gloss-ids[$i]"/>
    <xsl:variable name="page" select="govuk:md-entry-page($entry)"/>
    <xsl:variable name="term" select="govuk:md-term-record($entry, $id)"/>
    <xsl:if test="exists($term)">
      <govuk:record kind="term" id="{$id}" src="{concat(base-uri($entry), '#', $entry/@id)}"
                    stated="{if (govuk:md-stated-iri($entry/*[contains(@class, ' topic/prolog ')]) ne '') then 'yes' else 'no'}">
        <xsl:sequence select="$term/govuk:p"/>
        <xsl:sequence select="govuk:md-p('dct:language', govuk:md-lang($entry))"/>
        <xsl:if test="$page ne '' and $page ne $id">
          <xsl:sequence select="govuk:md-p('foaf:isPrimaryTopicOf', $page)"/>
        </xsl:if>
        <xsl:if test="govuk:md-term-retired($entry)">
          <xsl:sequence select="govuk:md-p('adms:status', 'retired')"/>
        </xsl:if>
        <!-- any other property the entry's prolog states (design 14 section 6): the tables decide what is written -->
        <xsl:sequence select="govuk:md-data($entry/*[contains(@class, ' topic/prolog ')])"/>
        <govuk:rel name="inScheme">
          <xsl:sequence select="govuk:md-stub('scheme', $scheme)"/>
        </govuk:rel>
        <!-- related terms: the entries its related links point to -->
        <govuk:rel name="related">
          <xsl:for-each select="$entry/*[contains(@class, ' topic/related-links ')]/*[contains(@class, ' topic/link ')][normalize-space(@href)]">
            <xsl:variable name="target" select="string(resolve-uri(replace(@href, '#.*$', ''), string(base-uri($entry))))"/>
            <xsl:variable name="frag" select="substring-after(@href, '#')"/>
            <xsl:variable name="j" select="(for $k in 1 to count($govuk-gloss-sources)
                                            return $k[string(base-uri($govuk-gloss-sources[$k])) = $target
                                                      and ($frag = '' or $govuk-gloss-sources[$k]/@id = $frag)])[1]"/>
            <xsl:if test="exists($j) and $j ne $i">
              <xsl:sequence select="govuk:md-stub('term', $govuk-md-gloss-ids[$j])"/>
            </xsl:if>
          </xsl:for-each>
        </govuk:rel>
      </govuk:record>
    </xsl:if>
  </xsl:function>

  <!-- ===== Subject schemes ===== -->

  <!-- The subject scheme maps the build holds: preprocessing takes a resource-only map out of
       the merged map but leaves its file in the working folder beside it -->
  <xsl:variable name="govuk-md-scheme-maps" as="element()*">
    <xsl:variable name="dir" select="replace(string(base-uri($govuk-md-map)), '/[^/]*$', '/')"/>
    <xsl:for-each select="collection(concat($dir, '?select=*.ditamap;recurse=yes;on-error=ignore'))/*[contains(@class, ' subjectScheme/subjectScheme ')]">
      <xsl:sort select="base-uri(.)"/>
      <xsl:sequence select="."/>
    </xsl:for-each>
  </xsl:variable>

  <!-- The topic a subjectdef points at with its href, when it is a DITA topic of this build -->
  <xsl:function name="govuk:md-subjectdef-topic" as="element()?">
    <xsl:param name="def" as="element()"/>
    <xsl:variable name="href" select="replace(normalize-space($def/@href), '#.*$', '')"/>
    <xsl:variable name="uri" as="xs:string?"
                  select="if ($href ne '' and not($def/@scope = ('external', 'peer')) and (not($def/@format) or $def/@format = 'dita'))
                          then string(resolve-uri($href, string(base-uri($def)))) else ()"/>
    <xsl:sequence select="if (exists($uri) and doc-available($uri)) then doc($uri)/*[contains(@class, ' topic/topic ')] else ()"/>
  </xsl:function>

  <!-- The address a subjectdef's source states: its own (a data element named dct:identifier
       in its topicmeta), else the one the topic it points at states -->
  <xsl:function name="govuk:md-subjectdef-stated" as="xs:string">
    <xsl:param name="def" as="element()"/>
    <xsl:sequence select="(govuk:md-stated-iri($def/*[contains(@class, ' map/topicmeta ')])[. ne ''],
                           govuk:md-stated-iri(govuk:md-subjectdef-topic($def)/*[contains(@class, ' topic/prolog ')]))[1]"/>
  </xsl:function>

  <!-- The page of the topic a subjectdef points at, when the navigation reaches it, or '' -->
  <xsl:function name="govuk:md-subjectdef-page" as="xs:string">
    <xsl:param name="def" as="element()"/>
    <xsl:variable name="topic" select="govuk:md-subjectdef-topic($def)"/>
    <xsl:sequence select="if (exists($topic)) then govuk:md-entry-page($topic) else ''"/>
  </xsl:function>

  <!-- A subjectdef's address (D-32): the one its source states, else its page, else its key
       as a fragment of the vocabulary file. One concept has one address, whether it is
       reached as a subjectdef or as the topic the subjectdef points at. -->
  <xsl:function name="govuk:md-subjectdef-id" as="xs:string">
    <xsl:param name="def" as="element()"/>
    <xsl:variable name="map" select="$def/ancestor::*[contains(@class, ' subjectScheme/subjectScheme ')][1]"/>
    <xsl:sequence select="(govuk:md-subjectdef-stated($def)[. ne ''], govuk:md-subjectdef-page($def)[. ne ''],
                           concat($govuk-md-base, 'vocab/', govuk:md-scheme-stem($map), '.ttl#',
                                  replace(tokenize(normalize-space($def/@keys))[1], '[^A-Za-z0-9_.\-]', '-')))[1]"/>
  </xsl:function>

  <!-- ===== Related concepts, from relationship tables and related links (#295) =====

       Design 14 section 4 has relations come from related links and relationship tables. A
       row of a reltable relates what is in one of its cells to what is in the others, and
       an author's own link from one topic to another relates the two. Each is a pair here,
       whose ends are named as the source names them: by the topic a reference points at,
       and by the key it uses. A scheme then finds, for each of its terms, the other end of
       every pair the term is an end of, and writes skos:related when that end is a term of
       the same scheme too; SKOS has the property symmetric, so both terms say it. A pair
       with an end that is no term of the scheme writes nothing. -->

  <!-- One end of a pair, from a topicref or a link: the topic it points at (as an address
       in the working folder, or '') and the key it uses (or '') -->
  <xsl:function name="govuk:md-pair-end" as="element(govuk:end)?">
    <xsl:param name="from" as="element()"/>
    <xsl:param name="base" as="xs:string"/>
    <xsl:variable name="href" select="replace(normalize-space($from/@href), '#.*$', '')"/>
    <xsl:variable name="local" select="$href ne '' and not($from/@scope = ('external', 'peer'))
                                       and (not($from/@format) or $from/@format = 'dita')"/>
    <xsl:variable name="key" select="replace(tokenize(normalize-space($from/@keyref))[1], '/.*$', '')"/>
    <xsl:if test="$local or $key ne ''">
      <govuk:end uri="{if ($local) then string(resolve-uri($href, $base)) else ''}" key="{$key}"/>
    </xsl:if>
  </xsl:function>

  <!-- A topic's own links to other topics: those its author wrote, not those the build adds
       from the map (which it marks with the class of the map entry they came from) -->
  <xsl:function name="govuk:md-topic-pairs" as="element(govuk:pair)*">
    <xsl:param name="topic" as="element()?"/>
    <xsl:variable name="uri" select="string(base-uri($topic))"/>
    <xsl:for-each select="$topic/*[contains(@class, ' topic/related-links ')]//*[contains(@class, ' topic/link ')]
                          [not(@mapclass)][normalize-space(@href)]">
      <xsl:variable name="other" select="govuk:md-pair-end(., $uri)"/>
      <xsl:if test="exists($other) and $other/@uri ne $uri">
        <govuk:pair>
          <govuk:end uri="{$uri}" key=""/>
          <xsl:sequence select="$other"/>
        </govuk:pair>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:variable name="govuk-md-pairs">
    <xsl:variable name="base" select="string(base-uri($govuk-md-map))"/>
    <!-- a row of a relationship table: each entry of a cell with each entry of every later cell -->
    <xsl:for-each select="$govuk-md-map//*[contains(@class, ' map/reltable ')]/*[contains(@class, ' map/relrow ')]">
      <xsl:variable name="cells" select="*[contains(@class, ' map/relcell ')]"/>
      <xsl:for-each select="1 to count($cells)">
        <xsl:variable name="i" select="."/>
        <xsl:for-each select="$cells[$i]//*[contains(@class, ' map/topicref ')] ! govuk:md-pair-end(., $base)">
          <xsl:variable name="a" select="."/>
          <xsl:for-each select="$cells[position() gt $i]//*[contains(@class, ' map/topicref ')] ! govuk:md-pair-end(., $base)">
            <govuk:pair>
              <xsl:sequence select="$a, ."/>
            </govuk:pair>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>
    <!-- the links of each topic a subjectdef points at, once; those of the topics that say
         they are concepts are read with them, below -->
    <xsl:for-each-group select="$govuk-md-scheme-maps//*[contains(@class, ' subjectScheme/subjectdef ')] ! govuk:md-subjectdef-topic(.)"
                        group-by="string(base-uri(.))">
      <xsl:sequence select="govuk:md-topic-pairs(current-group()[1])"/>
    </xsl:for-each-group>
    <xsl:sequence select="$govuk-md-concepts/govuk:concept/govuk:pair"/>
  </xsl:variable>

  <xsl:key name="govuk-md-end-by-uri" match="govuk:pair/govuk:end[@uri ne '']" use="string(@uri)"/>
  <xsl:key name="govuk-md-end-by-key" match="govuk:pair/govuk:end[@key ne '']" use="string(@key)"/>

  <!-- The terms of a scheme that a term is related to by a pair: the term is named by its
       topic or its keys, and the scheme by its terms' addresses, each under its topic and
       under its keys -->
  <xsl:function name="govuk:md-paired" as="xs:string*">
    <xsl:param name="self" as="xs:string"/>
    <xsl:param name="uri" as="xs:string?"/>
    <xsl:param name="keys" as="xs:string*"/>
    <xsl:param name="by-uri" as="map(xs:string, xs:string)"/>
    <xsl:param name="by-key" as="map(xs:string, xs:string)"/>
    <xsl:variable name="ends" select="(if (normalize-space($uri) ne '') then key('govuk-md-end-by-uri', string($uri), $govuk-md-pairs) else ()),
                                      (for $k in $keys return key('govuk-md-end-by-key', $k, $govuk-md-pairs))"/>
    <xsl:sequence select="distinct-values(for $other in ($ends/../govuk:end except $ends)
                                          return (map:get($by-uri, string($other/@uri)), map:get($by-key, string($other/@key)))[1])
                          [. ne $self]"/>
  </xsl:function>

  <xsl:function name="govuk:md-subject-term" as="element(govuk:record)?">
    <xsl:param name="def" as="element()"/>
    <xsl:param name="by-uri" as="map(xs:string, xs:string)"/>
    <xsl:param name="by-key" as="map(xs:string, xs:string)"/>
    <xsl:variable name="meta" select="$def/*[contains(@class, ' map/topicmeta ')]"/>
    <xsl:variable name="key" select="tokenize(normalize-space($def/@keys))[1]"/>
    <xsl:variable name="map" select="$def/ancestor::*[contains(@class, ' subjectScheme/subjectScheme ')][1]"/>
    <xsl:variable name="parent" select="$def/parent::*[contains(@class, ' subjectScheme/subjectdef ')][normalize-space(@keys)]"/>
    <xsl:variable name="topic" select="govuk:md-subjectdef-topic($def)"/>
    <xsl:variable name="id" select="govuk:md-subjectdef-id($def)"/>
    <xsl:variable name="page" select="govuk:md-subjectdef-page($def)"/>
    <!-- what the entry says of itself, else what the topic it points at says, so that a label
         and a definition need not be written twice (#294) -->
    <xsl:variable name="label" select="(govuk:md-text($meta/*[contains(@class, ' topic/navtitle ')][1]),
                                        govuk:md-text($meta/*[contains(@class, ' map/linktext ')][1]),
                                        govuk:md-text($topic/*[contains(@class, ' topic/title ')][1]), $key)[. ne ''][1]"/>
    <xsl:variable name="keywords" as="element()*"
                  select="($meta/*[contains(@class, ' topic/keywords ')]/*[contains(@class, ' topic/keyword ')],
                           $topic/*[contains(@class, ' topic/prolog ')]/*[contains(@class, ' topic/metadata ')]
                             /*[contains(@class, ' topic/keywords ')]/*[contains(@class, ' topic/keyword ')])"/>
    <xsl:variable name="own-keywords" as="element()*" select="$keywords[ancestor::* intersect $meta]"/>
    <xsl:if test="normalize-space($key) ne ''">
      <govuk:record kind="term" id="{$id}"
                    src="{if (exists($topic)) then concat(base-uri($topic), '#', $topic/@id) else generate-id($def)}"
                    stated="{if (govuk:md-subjectdef-stated($def) ne '') then 'yes' else 'no'}">
        <xsl:sequence select="govuk:md-p('dct:title', $label),
                              govuk:md-p('dct:description',
                                (govuk:md-text($meta/*[contains(@class, ' map/shortdesc ')][1]),
                                 govuk:md-text(($topic/*[contains(@class, ' topic/shortdesc ')],
                                                $topic/*[contains(@class, ' topic/abstract ')]/*[contains(@class, ' topic/shortdesc ')])[1]))[. ne ''][1]),
                              govuk:md-p('skos:notation', $key),
                              govuk:md-p('dct:language', govuk:md-lang($def))"/>
        <!-- its keywords, as the publisher says keywords are written; the entry's own, else its topic's -->
        <xsl:sequence select="govuk:md-keyword-labels(
                                (if (exists($own-keywords)) then $own-keywords else $keywords) ! govuk:md-text(.), $label)"/>
        <!-- the page it is described on, when that is not already its address -->
        <xsl:if test="$page ne '' and $page ne $id">
          <xsl:sequence select="govuk:md-p('foaf:isPrimaryTopicOf', $page)"/>
        </xsl:if>
        <xsl:if test="tokenize(normalize-space($def/@outputclass)) = 'retired' or govuk:md-data($meta)[@term = 'adms:status'] = 'retired'">
          <xsl:sequence select="govuk:md-p('adms:status', 'retired')"/>
        </xsl:if>
        <!-- any other property the entry states in data elements (#293): the tables decide what is written -->
        <xsl:sequence select="govuk:md-data($meta)"/>
        <govuk:rel name="inScheme">
          <xsl:sequence select="govuk:md-stub('scheme', govuk:md-scheme-id($map))"/>
        </govuk:rel>
        <xsl:choose>
          <xsl:when test="exists($parent)">
            <govuk:rel name="broader"><xsl:sequence select="govuk:md-stub('term', govuk:md-subjectdef-id($parent))"/></govuk:rel>
          </xsl:when>
          <xsl:otherwise>
            <govuk:rel name="topConceptOf"><xsl:sequence select="govuk:md-stub('scheme', govuk:md-scheme-id($map))"/></govuk:rel>
          </xsl:otherwise>
        </xsl:choose>
        <govuk:rel name="narrower">
          <xsl:sequence select="$def/*[contains(@class, ' subjectScheme/subjectdef ')][normalize-space(@keys)]
                                ! govuk:md-stub('term', govuk:md-subjectdef-id(.))"/>
        </govuk:rel>
        <!-- the terms of the scheme it is paired with, by a relationship table or a link (#295) -->
        <govuk:rel name="related">
          <xsl:sequence select="govuk:md-paired($id, $topic ! string(base-uri(.)), tokenize(normalize-space($def/@keys)), $by-uri, $by-key)
                                ! govuk:md-stub('term', .)"/>
        </govuk:rel>
      </govuk:record>
    </xsl:if>
  </xsl:function>


  <!-- ===== Schemes the map declares, and the topics that are their concepts (#263) =====

       The rules are in metadata-terms.xsl. Here each concept is read once, with the
       relations its source states (skos:broader, skos:narrower and skos:related, as data
       elements whose value is the other concept's address), and each scheme is then written
       with its relations said from both ends: SKOS has broader and narrower as inverses and
       related as symmetric, and a reader of the file should not have to work that out. -->

  <!-- Every page whose topic says it is a concept, once: its address, the scheme declared
       above it (or ''), what it says of itself, and the relations it states -->
  <xsl:variable name="govuk-md-concepts">
    <xsl:variable name="base" select="string(base-uri($govuk-md-map))"/>
    <xsl:for-each-group select="govuk:md-reading($govuk-md-map)" group-by="replace(normalize-space(@href), '#.*$', '')">
      <xsl:variable name="ref" select="current-group()[1]"/>
      <xsl:variable name="uri" select="string(resolve-uri(current-grouping-key(), $base))"/>
      <xsl:variable name="topic" as="element()?"
                    select="if (doc-available($uri)) then doc($uri)/*[contains(@class, ' topic/topic ')] else ()"/>
      <xsl:if test="govuk:md-is-concept($topic, $ref)">
        <xsl:variable name="decl" select="govuk:md-scheme-decl($ref)"/>
        <xsl:variable name="id" select="govuk:md-concept-id($topic, $ref)"/>
        <xsl:variable name="page" select="govuk:md-id(govuk:md-ref-path($ref))"/>
        <xsl:variable name="properties" select="govuk:md-concept-properties($topic, $ref)"/>
        <govuk:concept id="{$id}" decl="{if (exists($decl)) then generate-id($decl) else ''}"
                       src="{concat(base-uri($topic), '#', $topic/@id)}" uri="{base-uri($topic)}"
                       stated="{if ($id ne $page) then 'yes' else 'no'}"
                       title="{$properties[@term = 'dct:title'][1]/@value}" path="{govuk:md-ref-path($ref)}">
          <xsl:sequence select="$properties"/>
          <xsl:if test="$page ne '' and $page ne $id">
            <xsl:sequence select="govuk:md-p('foaf:isPrimaryTopicOf', $page)"/>
          </xsl:if>
          <xsl:for-each select="$properties[@term = ('skos:broader', 'skos:narrower', 'skos:related')]
                                           [govuk:md-uri(@value) ne ''][@value ne $id]">
            <govuk:edge rel="{substring-after(@term, ':')}" to="{@value}"/>
          </xsl:for-each>
          <xsl:sequence select="govuk:md-topic-pairs($topic)"/>
        </govuk:concept>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:variable>

  <!-- a concept of a scheme by its address, and the relations that point at an address -->
  <xsl:key name="govuk-md-concept-by-id" match="govuk:concept" use="concat(@decl, ' ', @id)"/>
  <xsl:key name="govuk-md-edge-to" match="govuk:edge" use="concat(../@decl, ' ', @rel, ' ', @to)"/>

  <!-- The concepts of a scheme that a concept is related to in one way: those it names that
       are in the scheme, and those that name it in the inverse way -->
  <xsl:function name="govuk:md-concept-related" as="xs:string*">
    <xsl:param name="concept" as="element(govuk:concept)"/>
    <xsl:param name="rel" as="xs:string"/>
    <xsl:param name="inverse" as="xs:string"/>
    <xsl:sequence select="distinct-values((
        $concept/govuk:edge[@rel = $rel]/@to[exists(key('govuk-md-concept-by-id', concat($concept/@decl, ' ', .), $govuk-md-concepts))],
        key('govuk-md-edge-to', concat($concept/@decl, ' ', $inverse, ' ', $concept/@id), $govuk-md-concepts)/../@id)
        ! string(.))[. ne $concept/@id]"/>
  </xsl:function>

  <!-- A concept as a term of its scheme -->
  <xsl:function name="govuk:md-concept-term" as="element(govuk:record)">
    <xsl:param name="concept" as="element(govuk:concept)"/>
    <xsl:param name="scheme" as="xs:string"/>
    <xsl:param name="hierarchy" as="xs:boolean"/>
    <xsl:param name="by-uri" as="map(xs:string, xs:string)"/>
    <xsl:variable name="broader" select="govuk:md-concept-related($concept, 'broader', 'narrower')"/>
    <govuk:record kind="term" id="{$concept/@id}" src="{$concept/@src}" stated="{$concept/@stated}">
      <xsl:sequence select="$concept/govuk:p"/>
      <govuk:rel name="inScheme">
        <xsl:sequence select="govuk:md-stub('scheme', $scheme)"/>
      </govuk:rel>
      <!-- a top concept is one with nothing broader, in a scheme that has a hierarchy at all -->
      <xsl:if test="$hierarchy and empty($broader)">
        <govuk:rel name="topConceptOf"><xsl:sequence select="govuk:md-stub('scheme', $scheme)"/></govuk:rel>
      </xsl:if>
      <govuk:rel name="broader">
        <xsl:sequence select="$broader ! govuk:md-stub('term', .)"/>
      </govuk:rel>
      <govuk:rel name="narrower">
        <xsl:sequence select="govuk:md-concept-related($concept, 'narrower', 'broader') ! govuk:md-stub('term', .)"/>
      </govuk:rel>
      <govuk:rel name="related">
        <xsl:sequence select="distinct-values((govuk:md-concept-related($concept, 'related', 'related'),
                                               govuk:md-paired(string($concept/@id), string($concept/@uri), (), $by-uri, map{})))
                              ! govuk:md-stub('term', .)"/>
      </govuk:rel>
    </govuk:record>
  </xsl:function>

  <!-- A scheme for each declaration that has concepts: its file name, address and what it
       says of itself. A scheme the map itself declares is the publication's, so it has the
       publication's title, description, licence, version and dates; one an entry declares has
       the entry's. The page it is described on is linked from it. -->
  <xsl:variable name="govuk-md-declared-vocab" as="element(govuk:record)*">
    <xsl:if test="$govuk-md-base ne ''">
      <xsl:for-each select="$govuk-md-scheme-decls">
        <xsl:variable name="decl" select="."/>
        <xsl:variable name="concepts" select="$govuk-md-concepts/govuk:concept[@decl = generate-id($decl)]"/>
        <xsl:if test="exists($concepts)">
          <xsl:variable name="id" select="govuk:md-decl-id($decl)"/>
          <xsl:variable name="is-map" select="contains($decl/@class, ' map/map ')"/>
          <xsl:variable name="meta" select="$decl/*[contains(@class, ' map/topicmeta ')]"/>
          <xsl:variable name="page" select="if ($is-map) then $govuk-md-base else govuk:md-id(govuk:md-ref-path($decl))"/>
          <xsl:variable name="hierarchy" as="xs:boolean"
                        select="some $c in $concepts satisfies exists(govuk:md-concept-related($c, 'broader', 'narrower'))"/>
          <govuk:record kind="scheme" id="{$id}" stem="{govuk:md-decl-stem($decl)}">
            <xsl:choose>
              <xsl:when test="$is-map">
                <xsl:sequence select="$govuk-md-publication/govuk:p[not(*)][not(@term = ('rdf:type', 'dct:identifier'))]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="govuk:md-p('dct:title', govuk:md-ref-title($decl)),
                                      govuk:md-p('dct:description', govuk:md-text($meta/*[contains(@class, ' map/shortdesc ')][1])),
                                      govuk:md-p('dct:language', govuk:md-lang($decl)),
                                      govuk:md-data($meta)[not(@term = ('rdf:type', 'dct:identifier'))]"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="$page ne '' and $page ne $id">
              <xsl:sequence select="govuk:md-p('foaf:isPrimaryTopicOf', $page)"/>
            </xsl:if>
            <govuk:rel name="hasPart">
              <xsl:sequence select="let $by-uri := map:merge($concepts ! map:entry(string(@uri), string(@id)), map{'duplicates': 'use-first'})
                                    return $concepts ! govuk:md-concept-term(., $id, $hierarchy, $by-uri)"/>
            </govuk:rel>
            <govuk:rel name="topConcept">
              <xsl:sequence select="if ($hierarchy)
                                    then $concepts[empty(govuk:md-concept-related(., 'broader', 'narrower'))] ! govuk:md-stub('term', string(@id))
                                    else ()"/>
            </govuk:rel>
          </govuk:record>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>

  <!-- ===== All the schemes ===== -->

  <!-- The glossgroups that hold entries, in document order -->
  <xsl:variable name="govuk-md-glossary-groups" as="element()*"
                select="$govuk-gloss-sources/ancestor::*[contains(@class, ' glossgroup/glossgroup ')][1]"/>

  <!-- A scheme for each: its file name (one no other scheme has), address and title -->
  <xsl:variable name="govuk-md-group-schemes" as="element(govuk:group)*">
    <xsl:for-each select="$govuk-md-glossary-groups">
      <xsl:variable name="stem" select="govuk:md-stem(string(@id))"/>
      <xsl:variable name="unique" select="if ($stem = ('', 'glossary')) then concat('group-', position()) else $stem"/>
      <govuk:group n="{position()}" stem="{$unique}"
                   id="{(govuk:md-stated-iri(*[contains(@class, ' topic/prolog ')])[. ne ''],
                         concat($govuk-md-base, 'vocab/', $unique, '.ttl#scheme'))[1]}"
                   title="{govuk:md-text(*[contains(@class, ' topic/title ')][1])}"/>
    </xsl:for-each>
  </xsl:variable>

  <!-- Every vocabulary, each under a file name no other has: the glossary, the glossgroups
       and the subject schemes, then the schemes the map declares. Of two with one name the
       first is written and the second reported (GOVK027W). -->
  <xsl:variable name="govuk-md-vocab" as="element(govuk:record)*">
    <xsl:for-each-group select="($govuk-md-source-vocab, $govuk-md-declared-vocab)" group-by="string(@stem)">
      <xsl:sequence select="current-group()[1]"/>
    </xsl:for-each-group>
  </xsl:variable>

  <xsl:variable name="govuk-md-source-vocab" as="element(govuk:record)*">
    <xsl:if test="$govuk-md-base ne ''">
      <xsl:variable name="glossary-id" select="concat($govuk-md-base, 'glossary.html')"/>
      <!-- the generated glossary: every entry, each in the scheme of its own file -->
      <xsl:if test="exists($govuk-gloss-sources)">
        <govuk:record kind="scheme" id="{$glossary-id}" stem="glossary">
          <xsl:sequence select="govuk:md-p('dct:title', $govuk-md-glossary-label),
                                govuk:md-p('dct:language', govuk:md-lang($govuk-gloss-sources[1]))"/>
          <govuk:rel name="hasPart">
            <xsl:sequence select="(1 to count($govuk-gloss-sources)) ! govuk:md-gloss-term(., $glossary-id)"/>
          </govuk:rel>
        </govuk:record>
      </xsl:if>
      <!-- a scheme for each glossgroup: its entries -->
      <xsl:for-each select="$govuk-md-group-schemes">
        <xsl:variable name="g" select="."/>
        <xsl:variable name="group" select="$govuk-md-glossary-groups[position() = xs:integer($g/@n)]"/>
        <govuk:record kind="scheme" id="{$g/@id}" stem="{$g/@stem}">
          <xsl:sequence select="govuk:md-p('dct:title', string($g/@title)),
                                govuk:md-p('dct:language', govuk:md-lang($group)),
                                govuk:md-data($group/*[contains(@class, ' topic/prolog ')])"/>
          <govuk:rel name="hasPart">
            <xsl:for-each select="1 to count($govuk-gloss-sources)">
              <xsl:if test="$govuk-gloss-sources[current()]/ancestor::*[contains(@class, ' glossgroup/glossgroup ')][1] is $group">
                <xsl:sequence select="govuk:md-gloss-term(., string($g/@id))"/>
              </xsl:if>
            </xsl:for-each>
          </govuk:rel>
        </govuk:record>
      </xsl:for-each>

      <!-- a scheme for each subject scheme map -->
      <xsl:for-each select="$govuk-md-scheme-maps">
        <xsl:variable name="defs" select=".//*[contains(@class, ' subjectScheme/subjectdef ')][normalize-space(@keys)]"/>
        <xsl:if test="exists($defs)">
          <govuk:record kind="scheme" id="{govuk:md-scheme-id(.)}" stem="{govuk:md-scheme-stem(.)}">
            <xsl:sequence select="govuk:md-p('dct:title',
                                    (govuk:md-text(*[contains(@class, ' topic/title ')][1]),
                                     govuk:md-text(*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')][1]),
                                     govuk:md-scheme-stem(.))[. ne ''][1]),
                                  govuk:md-p('dct:language', govuk:md-lang(.)),
                                  govuk:md-data(*[contains(@class, ' map/topicmeta ')])"/>
            <govuk:rel name="hasPart">
              <!-- the scheme's terms by the topic each points at and by each of its keys, to find related terms -->
              <xsl:sequence select="let $by-uri := map:merge(for $d in $defs, $t in govuk:md-subjectdef-topic($d)
                                                             return map:entry(string(base-uri($t)), govuk:md-subjectdef-id($d)),
                                                             map{'duplicates': 'use-first'}),
                                        $by-key := map:merge(for $d in $defs, $k in tokenize(normalize-space($d/@keys))
                                                             return map:entry($k, govuk:md-subjectdef-id($d)),
                                                             map{'duplicates': 'use-first'})
                                    return $defs ! govuk:md-subject-term(., $by-uri, $by-key)"/>
            </govuk:rel>
            <govuk:rel name="topConcept">
              <xsl:sequence select="$defs[not(parent::*[contains(@class, ' subjectScheme/subjectdef ')][normalize-space(@keys)])]
                                    ! govuk:md-stub('term', govuk:md-subjectdef-id(.))"/>
            </govuk:rel>
          </govuk:record>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>

  <!-- ===== The files and the findings ===== -->

  <!-- vocab/<name>.ttl and .jsonld for each scheme; run once, by the map transform -->
  <xsl:template name="govuk-skos">
    <xsl:if test="$GOVUK-SKOS = 'yes' and $govuk-md-base ne ''">
      <xsl:call-template name="govuk-skos-check"/>
      <xsl:variable name="declared" select="govuk:md-rdf-prefixes($govuk-md-skos-schemes)"/>
      <xsl:for-each select="$govuk-md-vocab">
        <xsl:variable name="graph" select="govuk:md-rdf-graph($govuk-md-skos-schemes, .)"/>
        <xsl:variable name="prefixes" select="govuk:md-rdf-prefixes-used($declared, $graph)"/>
        <xsl:result-document href="vocab/{@stem}.ttl" format="govuk-rdf">
          <xsl:value-of select="govuk:md-rdf-turtle($prefixes, $graph)"/>
        </xsl:result-document>
        <xsl:result-document href="vocab/{@stem}.jsonld" format="govuk-rdf">
          <xsl:value-of select="govuk:md-rdf-jsonld($prefixes, $graph)"/>
        </xsl:result-document>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <!-- GOVK021W for an address two terms both state; GOVK022W when there is nothing to publish -->
  <xsl:template name="govuk-skos-check">
    <xsl:if test="empty($govuk-md-vocab)">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK022W'"/>
      </xsl:call-template>
    </xsl:if>
    <!-- a data name no vocabulary knows, in a subject scheme map (#293). The check of the pages'
         metadata (govuk-md-check) reads the merged map: that holds a scheme map's subjectdefs but
         not the scheme map's own topicmeta, and it does not run under govuk.metadata=no. So the
         names it has not reported are reported here, each once. -->
    <xsl:variable name="base" select="string(base-uri($govuk-md-map))"/>
    <xsl:variable name="reported" as="xs:string*"
                  select="if ($GOVUK-METADATA = 'no') then ()
                          else govuk:md-data-elements(($govuk-md-map/*[contains(@class, ' map/topicmeta ')],
                                 $govuk-md-map//*[contains(@class, ' map/topicref ')]/*[contains(@class, ' map/topicmeta ')]))
                               /normalize-space(@name)"/>
    <xsl:for-each-group select="govuk:md-data-elements($govuk-md-scheme-maps//*[contains(@class, ' map/topicmeta ')])
                                [not(govuk:md-known-term(normalize-space(@name)))]
                                [not(normalize-space(@name) = $reported)]"
                        group-by="normalize-space(@name)">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK011W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate(current-grouping-key(), ';', ',')"/>;%2=<xsl:value-of select="count(current-group())"/>;%3=<xsl:value-of select="govuk:md-where(current-group()[1], $base)"/>;%4=<xsl:value-of select="$govuk-md-prefix-list"/></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each-group>
    <!-- GOVK025W: topics that say they are concepts, under no declared scheme -->
    <xsl:variable name="orphans" select="$govuk-md-concepts/govuk:concept[@decl = '']"/>
    <xsl:if test="exists($orphans)">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK025W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="count($orphans)"/>;%2=<xsl:value-of select="translate(string($orphans[1]/@title), ';', ',')"/>;%3=<xsl:value-of select="$orphans[1]/@path"/></xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <!-- GOVK026W: a broader or narrower concept that is no concept of the scheme -->
    <xsl:variable name="outside" select="$govuk-md-concepts/govuk:concept[@decl ne '']/govuk:edge[@rel = ('broader', 'narrower')]
                                           [empty(key('govuk-md-concept-by-id', concat(../@decl, ' ', @to), $govuk-md-concepts))]"/>
    <xsl:if test="exists($outside)">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK026W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="count($outside)"/>;%2=<xsl:value-of select="translate(string($outside[1]/@to), ';', ',')"/>;%3=<xsl:value-of select="translate(string($outside[1]/../@title), ';', ',')"/></xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <!-- GOVK027W: two vocabularies with one file name -->
    <xsl:for-each-group select="($govuk-md-source-vocab, $govuk-md-declared-vocab)" group-by="string(@stem)">
      <xsl:if test="count(current-group()) gt 1">
        <xsl:call-template name="output-message">
          <xsl:with-param name="id" select="'GOVK027W'"/>
          <xsl:with-param name="msgparams">%1=<xsl:value-of select="current-grouping-key()"/>;%2=<xsl:value-of select="translate(string(current-group()[1]/govuk:p[@term = 'dct:title'][1]/@value), ';', ',')"/>;%3=<xsl:value-of select="translate(string(current-group()[2]/govuk:p[@term = 'dct:title'][1]/@value), ';', ',')"/></xsl:with-param>
        </xsl:call-template>
      </xsl:if>
    </xsl:for-each-group>
    <xsl:variable name="dups" as="element(govuk:dup)*">
      <!-- each term once: a glossgroup's entries are in the glossary's file as well -->
      <xsl:for-each-group select="$govuk-md-vocab[not(@stem = $govuk-md-group-schemes/@stem)]
                                  /govuk:rel[@name = 'hasPart']/govuk:record[@kind = 'term'][@stated = 'yes']"
                          group-by="@id">
        <!-- two sources, not one source met twice: a subjectdef and the topic it points at are one concept -->
        <xsl:if test="count(distinct-values(current-group()/@src)) gt 1">
          <govuk:dup id="{current-grouping-key()}" n="{count(distinct-values(current-group()/@src))}"
                     titles="{string-join(for $s in distinct-values(current-group()/@src) return (current-group()[@src = $s])[1]/govuk:p[@term = 'dct:title']/@value, ', ')}"/>
        </xsl:if>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:for-each select="$dups">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK021W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="@id"/>;%2=<xsl:value-of select="@n"/>;%3=<xsl:value-of select="translate(@titles, ';', ',')"/></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>

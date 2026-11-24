<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

The steps and terms harvesters (design 14 section 8, #101), included by
metadata.xsl so both transforms see them.

  step     A step of a task: its command is the name, its further information
           the text. Related to the task's page by a howto record.
  term     A glossary entry: the term, its definition, and the other names it is
           known by (acronyms, abbreviations, short forms, synonyms).
  scheme   The generated glossary: its terms.

They describe what is in the source and invent nothing. A scheme is described on
the page that shows it (the generated glossary page), and a term on the page of
its own, if it has one. #103 reuses the term records for SKOS.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- The most terms a page's structured data will hold: the generated glossary
       already shows every term, and a block as large again would double the page -->
  <xsl:variable name="govuk-md-max-terms" as="xs:integer" select="500"/>

  <!-- ===== Steps ===== -->

  <!-- A task as a how-to: the page's title and description, and a step for each
       step of the task. None when the topic is not a task or has no step. -->
  <xsl:function name="govuk:md-howto-record" as="element(govuk:record)?">
    <xsl:param name="topic" as="element()"/>
    <xsl:param name="title" as="xs:string"/>
    <xsl:param name="description" as="xs:string"/>
    <xsl:variable name="steps" as="element()*"
                  select="$topic/*[contains(@class, ' task/taskbody ')]/*[contains(@class, ' task/steps ')]
                          /*[contains(@class, ' task/step ')]"/>
    <xsl:if test="govuk:md-topic-type($topic) = 'task' and exists($steps)">
      <govuk:record kind="howto">
        <xsl:sequence select="govuk:md-p('dct:title', $title), govuk:md-p('dct:description', $description)"/>
        <govuk:rel name="hasPart">
          <xsl:for-each select="$steps">
            <xsl:variable name="command" select="govuk:md-text(*[contains(@class, ' task/cmd ')][1])"/>
            <xsl:variable name="info" select="govuk:md-text(*[contains(@class, ' task/info ')][1])"/>
            <xsl:if test="$command ne ''">
              <govuk:record kind="step">
                <xsl:sequence select="govuk:md-p('dct:title', $command),
                                      govuk:md-p('dct:description', ($info, $command)[. ne ''][1])"/>
              </govuk:record>
            </xsl:if>
          </xsl:for-each>
        </govuk:rel>
      </govuk:record>
    </xsl:if>
  </xsl:function>

  <!-- ===== Terms ===== -->

  <!-- The names a glossary entry is also known by -->
  <xsl:function name="govuk:md-term-names" as="xs:string*">
    <xsl:param name="entry" as="element()"/>
    <xsl:sequence select="distinct-values(
                            for $n in $entry//*[contains(@class, ' glossentry/glossAcronym ')
                                                or contains(@class, ' glossentry/glossAbbreviation ')
                                                or contains(@class, ' glossentry/glossShortForm ')
                                                or contains(@class, ' glossentry/glossSynonym ')]
                            return govuk:md-text($n)[. ne ''])"/>
  </xsl:function>

  <!-- The keywords of a concept as labels, as govuk.skos.keywords says they are written
       (D-32): alt, alternative labels, for keywords that are other names; hidden, hidden
       labels, for keywords that are search phrases and not names; no, not written. A
       keyword that repeats the label, or another keyword, is left out: SKOS has a
       concept's labels disjoint. -->
  <xsl:function name="govuk:md-keyword-labels" as="element(govuk:p)*">
    <xsl:param name="keywords" as="xs:string*"/>
    <xsl:param name="label" as="xs:string"/>
    <xsl:if test="$GOVUK-SKOS-KEYWORDS = ('alt', 'hidden')">
      <xsl:for-each-group select="$keywords[matches(., '[\p{L}\p{N}]')][lower-case(.) ne lower-case($label)]"
                          group-by="lower-case(.)">
        <xsl:sequence select="govuk:md-p(if ($GOVUK-SKOS-KEYWORDS = 'hidden') then 'skos:hiddenLabel' else 'dct:alternative',
                                         current-group()[1])"/>
      </xsl:for-each-group>
    </xsl:if>
  </xsl:function>

  <!-- A glossary entry as a term; id is the address it is known by, or '' -->
  <xsl:function name="govuk:md-term-record" as="element(govuk:record)?">
    <xsl:param name="entry" as="element()"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:variable name="term" select="govuk:md-text($entry/*[contains(@class, ' glossentry/glossterm ')][1])"/>
    <xsl:if test="$term ne ''">
      <govuk:record kind="term">
        <xsl:if test="$id ne ''">
          <xsl:attribute name="id" select="$id"/>
        </xsl:if>
        <xsl:sequence select="govuk:md-p('dct:title', $term),
                              govuk:md-p('dct:description', govuk:md-text($entry/*[contains(@class, ' glossentry/glossdef ')][1])),
                              for $n in govuk:md-term-names($entry) return govuk:md-p('dct:alternative', $n)"/>
      </govuk:record>
    </xsl:if>
  </xsl:function>

  <!-- Every glossary entry the map reaches, in the map's order: an entry, or the
       entries of a group, however the topic is referred to (resource-only too) -->
  <xsl:function name="govuk:md-glossentries" as="element()*">
    <xsl:param name="map" as="element()?"/>
    <xsl:variable name="base" select="string(base-uri($map))"/>
    <xsl:for-each-group select="$map//*[contains(@class, ' map/topicref ')][normalize-space(@href)]
                                [not(@scope = 'external')][not(@format) or @format = 'dita']"
                        group-by="replace(@href, '#.*$', '')">
      <xsl:variable name="uri" select="resolve-uri(current-grouping-key(), $base)"/>
      <xsl:if test="doc-available($uri)">
        <xsl:variable name="root" select="doc($uri)/*"/>
        <xsl:sequence select="if (contains($root/@class, ' glossentry/glossentry ')) then $root
                              else if (contains($root/@class, ' glossgroup/glossgroup '))
                              then $root//*[contains(@class, ' glossentry/glossentry ')]
                              else ()"/>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:function>

  <xsl:variable name="govuk-md-glossary-entries" as="element()*"
                select="govuk:md-glossentries($govuk-md-map)"/>

  <!-- Whether the generated glossary is described: it has terms, and not more
       than a page's data will hold (a partial set would be wrong, so it is left
       out whole and the build says so, GOVK020W) -->
  <xsl:variable name="govuk-md-glossary-fits" as="xs:boolean"
                select="exists($govuk-md-glossary-entries) and count($govuk-md-glossary-entries) le $govuk-md-max-terms"/>

  <!-- The generated glossary as a scheme of its terms, named as its page is. The
       terms are not given addresses: the page shows them inline, not on pages of
       their own. -->
  <xsl:function name="govuk:md-glossary-record" as="element(govuk:record)?">
    <xsl:param name="title" as="xs:string"/>
    <xsl:if test="$govuk-md-glossary-fits">
      <govuk:record kind="scheme" id="{govuk:md-id('glossary.html')}">
        <xsl:sequence select="govuk:md-p('dct:title', $title)"/>
        <govuk:rel name="hasPart">
          <xsl:sequence select="$govuk-md-glossary-entries ! govuk:md-term-record(., '')"/>
        </govuk:rel>
      </govuk:record>
    </xsl:if>
  </xsl:function>


  <!-- ===== Names and addresses of terms and schemes ===== -->

  <!-- A file name for a scheme: letters, digits, dot, underscore and hyphen -->
  <xsl:function name="govuk:md-stem" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="replace(replace(lower-case(normalize-space($name)), '[^a-z0-9_.\-]+', '-'), '^-+|-+$', '')"/>
  </xsl:function>

  <!-- An address the source states for a topic or a map entry: resourceid appid, or
       a data element named dct:identifier. '' when it states none, or one that is
       not an absolute http(s) or urn address. -->
  <xsl:function name="govuk:md-stated-iri" as="xs:string">
    <xsl:param name="holders" as="element()*"/>
    <xsl:variable name="candidates" as="xs:string*"
                  select="($holders//*[contains(@class, ' topic/resourceid ')]/@appid/string(.),
                           govuk:md-data($holders)[@term = 'dct:identifier']/@value/string(.))"/>
    <xsl:sequence select="string(($candidates ! normalize-space(.)[matches(., '^(https?://|urn:)[^\s]+$')])[1])"/>
  </xsl:function>

  <xsl:function name="govuk:md-lang" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="string(($e/ancestor-or-self::*[@xml:lang][1]/@xml:lang,
                                  $govuk-md-publication/govuk:p[@term = 'dct:language']/@value)[normalize-space()][1])"/>
  </xsl:function>

  <!-- Whether a source says a term is retired: a retired token on its outputclass or its title's, or a status of its own -->
  <xsl:function name="govuk:md-term-retired" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="$e/@importance = 'obsolete'
                          or tokenize(normalize-space(string-join(($e/@outputclass,
                               $e/*[contains(@class, ' topic/title ') or contains(@class, ' glossentry/glossterm ')]/@outputclass), ' '))) = 'retired'"/>
  </xsl:function>

  <!-- A reference to a term or scheme by its address alone -->
  <xsl:function name="govuk:md-stub" as="element(govuk:record)">
    <xsl:param name="kind" as="xs:string"/>
    <xsl:param name="id" as="xs:string"/>
    <govuk:record kind="{$kind}" id="{$id}"/>
  </xsl:function>

  <!-- A subject scheme map's file name and address -->
  <xsl:function name="govuk:md-scheme-stem" as="xs:string">
    <xsl:param name="map" as="element()"/>
    <xsl:sequence select="govuk:md-stem(string(($map/@id[normalize-space()],
                                                replace(replace(string(base-uri($map)), '^.*/', ''), '\.[^.]*$', ''))[1]))"/>
  </xsl:function>

  <xsl:function name="govuk:md-scheme-id" as="xs:string">
    <xsl:param name="map" as="element()"/>
    <xsl:variable name="stated" select="govuk:md-stated-iri($map/*[contains(@class, ' map/topicmeta ')])"/>
    <xsl:sequence select="if ($stated ne '') then $stated
                          else concat($govuk-md-base, 'vocab/', govuk:md-scheme-stem($map), '.ttl#scheme')"/>
  </xsl:function>

  <!-- ===== Concepts that are topics, in a scheme the map declares (#263) =====

       A topic is a concept when it says so: a data element named rdf:type whose value is
       skos:Concept, in its prolog or in the topicmeta of the map entry that makes it a page.
       Its scheme is the one declared above it: the nearest entry over it, itself included,
       whose topicmeta says rdf:type skos:ConceptScheme, else the map when its bookmeta or
       topicmeta says so. Nothing is inferred: a topic that does not say it is a concept is
       not one, and the navigation is not the hierarchy.

       These are read by a page's own transform (the links in its head, and the concept it
       is about) and by the map transform, which writes the vocabulary files
       (metadata-vocab.xsl), so that the two cannot disagree about a name or an address. -->

  <!-- Whether the data elements of some holders state a type of SKOS's, by prefixed name or address -->
  <xsl:function name="govuk:md-states-type" as="xs:boolean">
    <xsl:param name="holders" as="element()*"/>
    <xsl:param name="local" as="xs:string"/>
    <xsl:sequence select="some $d in govuk:md-data-elements($holders)[normalize-space(@name) = 'rdf:type']
                          satisfies normalize-space(if (normalize-space($d/@value)) then string($d/@value) else govuk:md-text($d))
                                    = (concat('skos:', $local), concat('http://www.w3.org/2004/02/skos/core#', $local))"/>
  </xsl:function>

  <xsl:function name="govuk:md-is-concept" as="xs:boolean">
    <xsl:param name="topic" as="element()?"/>
    <xsl:param name="ref" as="element()?"/>
    <xsl:sequence select="exists($topic)
                          and govuk:md-states-type(($ref/*[contains(@class, ' map/topicmeta ')],
                                                    $topic/*[contains(@class, ' topic/prolog ')]), 'Concept')"/>
  </xsl:function>

  <!-- Every declaration of a scheme in the map, in the map's order; the map itself comes last -->
  <xsl:variable name="govuk-md-scheme-decls" as="element()*"
                select="($govuk-md-map//*[contains(@class, ' map/topicref ')]
                           [govuk:md-states-type(*[contains(@class, ' map/topicmeta ')], 'ConceptScheme')],
                         $govuk-md-map[govuk:md-states-type(*[contains(@class, ' map/topicmeta ')], 'ConceptScheme')])"/>


  <!-- The declaration a page is under, or none. Each entry above the page is asked what it
       declares: a page's own transform reads the map as a document of its own, so its
       entries are not the same nodes as those of $govuk-md-scheme-decls. -->
  <xsl:function name="govuk:md-scheme-decl" as="element()?">
    <xsl:param name="ref" as="element()?"/>
    <xsl:sequence select="(($ref/ancestor-or-self::*[contains(@class, ' map/topicref ')]
                              [govuk:md-states-type(*[contains(@class, ' map/topicmeta ')], 'ConceptScheme')])[last()],
                           $ref/ancestor::*[contains(@class, ' map/map ')]
                              [govuk:md-states-type(*[contains(@class, ' map/topicmeta ')], 'ConceptScheme')])[1]"/>
  </xsl:function>

  <!-- A declared scheme's file name: for the map its id, else its file's name; for an entry
       its first key, its id, its topic's file name, or its title. A name another vocabulary
       already has is reported by the map transform (GOVK027W). -->
  <xsl:function name="govuk:md-decl-stem" as="xs:string">
    <xsl:param name="decl" as="element()"/>
    <xsl:variable name="file" select="function($uri as xs:string) as xs:string { replace(replace(replace($uri, '[?#].*$', ''), '^.*/', ''), '\.[^.]*$', '') }"/>
    <xsl:sequence select="govuk:md-stem(string(
                            (if (contains($decl/@class, ' map/map '))
                             then ($decl/@id[normalize-space()], $file(string(base-uri($decl))))
                             else (tokenize(normalize-space($decl/@keys))[1], $decl/@id[normalize-space()],
                                   $file(string($decl/@href))[. ne ''], govuk:md-ref-title($decl)))[1]))"/>
  </xsl:function>

  <!-- A declared scheme's address: the one it states, else the scheme in its vocabulary file -->
  <xsl:function name="govuk:md-decl-id" as="xs:string">
    <xsl:param name="decl" as="element()"/>
    <xsl:variable name="stated" select="govuk:md-stated-iri($decl/*[contains(@class, ' map/topicmeta ')])"/>
    <xsl:sequence select="if ($stated ne '') then $stated
                          else concat($govuk-md-base, 'vocab/', govuk:md-decl-stem($decl), '.ttl#scheme')"/>
  </xsl:function>

  <!-- The subjectdefs of the map that point at a page's topic. The merged map holds every
       subjectdef of every scheme map, with its href made relative to the merged map, as a
       page's is; so the two are equal as written, and a key finds them without a scan. -->
  <xsl:key name="govuk-md-defs-by-href"
           match="*[contains(@class, ' subjectScheme/subjectdef ')][normalize-space(@href)][normalize-space(@keys)]"
           use="replace(normalize-space(@href), '#.*$', '')"/>

  <xsl:function name="govuk:md-page-defs" as="element()*">
    <xsl:param name="ref" as="element()?"/>
    <xsl:sequence select="if (exists($ref) and exists($govuk-md-map) and normalize-space($ref/@href) ne '')
                          then key('govuk-md-defs-by-href', replace(normalize-space($ref/@href), '#.*$', ''), root($govuk-md-map))
                          else ()"/>
  </xsl:function>

  <!-- The address of a concept that is a page (D-32): the one its topic states, else the one
       a subjectdef pointing at it states, else its page. One concept, one address. -->
  <xsl:function name="govuk:md-concept-id" as="xs:string">
    <xsl:param name="topic" as="element()"/>
    <xsl:param name="ref" as="element()?"/>
    <xsl:sequence select="string((govuk:md-stated-iri($topic/*[contains(@class, ' topic/prolog ')])[. ne ''],
                                  (govuk:md-page-defs($ref) ! govuk:md-stated-iri(*[contains(@class, ' map/topicmeta ')]))[. ne ''],
                                  govuk:md-id(govuk:md-ref-path($ref)))[1])"/>
  </xsl:function>

  <!-- The scheme map a subjectdef of the merged map came from. The merged map does not hold
       a scheme map's own element, only its subjectdefs, each with the address of its source
       file (xtrf). The scheme map is in the working folder at the same place relative to
       the merged map as its source is to the root map's, so it is read from there. None
       when the build writes no source addresses. -->
  <xsl:function name="govuk:md-def-scheme-map" as="element()?">
    <xsl:param name="def" as="element()"/>
    <xsl:variable name="from" select="tokenize(replace(string($govuk-md-map/@xtrf), '/[^/]*$', ''), '/')"/>
    <xsl:variable name="to" select="tokenize(string($def/@xtrf), '/')"/>
    <xsl:variable name="same" as="xs:integer"
                  select="count((1 to min((count($from), count($to))))[every $i in 1 to . satisfies $from[$i] = $to[$i]])"/>
    <xsl:variable name="relative" select="string-join(((($same + 1) to count($from)) ! '..', $to[position() gt $same]), '/')"/>
    <xsl:variable name="uri" select="if (normalize-space($def/@xtrf) ne '' and normalize-space($govuk-md-map/@xtrf) ne '' and $relative ne '')
                                     then string(resolve-uri($relative, string(base-uri($govuk-md-map)))) else ''"/>
    <xsl:sequence select="if ($uri ne '' and doc-available($uri))
                          then doc($uri)/*[contains(@class, ' subjectScheme/subjectScheme ')] else ()"/>
  </xsl:function>

  <!-- The vocabularies a page's concept is in, each as its file name and its scheme's
       address: the scheme declared above a topic that says it is a concept, and each subject
       scheme with a subjectdef that points at the topic. None unless govuk.skos=yes. -->
  <xsl:function name="govuk:md-page-schemes" as="element(govuk:in)*">
    <xsl:param name="topic" as="element()?"/>
    <xsl:param name="ref" as="element()?"/>
    <xsl:if test="$GOVUK-SKOS = 'yes' and $govuk-md-base ne '' and exists($topic) and exists($ref)">
      <xsl:variable name="all" as="element(govuk:in)*">
        <xsl:if test="govuk:md-is-concept($topic, $ref)">
          <xsl:for-each select="govuk:md-scheme-decl($ref)">
            <govuk:in stem="{govuk:md-decl-stem(.)}" id="{govuk:md-decl-id(.)}"/>
          </xsl:for-each>
        </xsl:if>
        <xsl:for-each select="govuk:md-page-defs($ref) ! govuk:md-def-scheme-map(.)">
          <govuk:in stem="{govuk:md-scheme-stem(.)}" id="{govuk:md-scheme-id(.)}"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:for-each-group select="$all[@stem ne '']" group-by="@stem">
        <xsl:sequence select="current-group()[1]"/>
      </xsl:for-each-group>
    </xsl:if>
  </xsl:function>

  <!-- A topic's keywords, as text -->
  <xsl:function name="govuk:md-topic-keywords" as="xs:string*">
    <xsl:param name="topic" as="element()?"/>
    <xsl:sequence select="$topic/*[contains(@class, ' topic/prolog ')]/*[contains(@class, ' topic/metadata ')]
                            /*[contains(@class, ' topic/keywords ')]/*[contains(@class, ' topic/keyword ')] ! govuk:md-text(.)"/>
  </xsl:function>

  <!-- What a topic says of the concept it describes: its label, definition, other names
       and language, and whatever its data elements state -->
  <xsl:function name="govuk:md-concept-properties" as="element(govuk:p)*">
    <xsl:param name="topic" as="element()"/>
    <xsl:param name="ref" as="element()?"/>
    <xsl:variable name="label" select="govuk:md-text($topic/*[contains(@class, ' topic/title ')][1])"/>
    <xsl:sequence select="govuk:md-p('dct:title', $label),
                          govuk:md-p('dct:description',
                            govuk:md-text(($topic/*[contains(@class, ' topic/shortdesc ')],
                                           $topic/*[contains(@class, ' topic/abstract ')]/*[contains(@class, ' topic/shortdesc ')])[1])),
                          govuk:md-p('dct:language', govuk:md-lang($topic)),
                          govuk:md-keyword-labels(govuk:md-topic-keywords($topic), $label)"/>
    <xsl:if test="govuk:md-term-retired($topic)">
      <xsl:sequence select="govuk:md-p('adms:status', 'retired')"/>
    </xsl:if>
    <xsl:sequence select="govuk:md-data(($ref/*[contains(@class, ' map/topicmeta ')], $topic/*[contains(@class, ' topic/prolog ')]))"/>
  </xsl:function>

  <!-- The concept a page is about, for the page's own structured data (D-32): its label,
       definition and other names, the page, and the scheme it is in. It has an address of its
       own only when its source states one; otherwise its address is the page's, which the
       page's own record already has, and one node would be both a page and a term. Only
       with govuk.skos=yes, so that a publication that publishes no vocabulary is unchanged. -->
  <xsl:function name="govuk:md-concept-entity" as="element(govuk:record)?">
    <xsl:param name="topic" as="element()?"/>
    <xsl:param name="ref" as="element()?"/>
    <xsl:variable name="schemes" select="govuk:md-page-schemes($topic, $ref)"/>
    <xsl:if test="exists($schemes)">
      <xsl:variable name="id" select="govuk:md-concept-id($topic, $ref)"/>
      <xsl:variable name="page" select="govuk:md-id(govuk:md-ref-path($ref))"/>
      <govuk:record kind="term">
        <xsl:if test="$id ne '' and $id ne $page">
          <xsl:attribute name="id" select="$id"/>
        </xsl:if>
        <xsl:sequence select="govuk:md-concept-properties($topic, $ref)[@term = ('dct:title', 'dct:description', 'dct:alternative')],
                              govuk:md-p('foaf:isPrimaryTopicOf', $page)"/>
        <govuk:rel name="inScheme">
          <xsl:sequence select="govuk:md-stub('scheme', string($schemes[1]/@id))"/>
        </govuk:rel>
      </govuk:record>
    </xsl:if>
  </xsl:function>

</xsl:stylesheet>

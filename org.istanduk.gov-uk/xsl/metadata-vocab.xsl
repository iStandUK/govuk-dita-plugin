<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

The vocabulary harvesters and files (design 14 section 8, #103), included by
map2govuk-cover.xsl: the schemes and terms a publication holds, written by
govuk.skos=yes as SKOS, one vocab/<name>.ttl and vocab/<name>.jsonld for each.

  scheme   The generated glossary (every glossary entry), each glossgroup (its
           entries), and each subjectScheme map the build holds (its subjectdefs).
  term     A glossary entry or a subjectdef: its label, definition, other
           names, and, in a subject scheme, its place in the hierarchy.

A term's address is, in this order: an absolute address the source states
(resourceid appid, or a data element named dct:identifier); the address of its
own page; the glossary page with the entry's anchor; the vocabulary file with
the term's key as the fragment. The page a term is described on is linked from
it. Nothing is invented, and the type of a scheme is its source's.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- ===== Names and addresses ===== -->

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

  <!-- ===== The generated glossary and its groups ===== -->

  <xsl:variable name="govuk-md-glossary-label" as="xs:string">
    <xsl:variable name="label">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:sequence select="normalize-space(string($label))"/>
  </xsl:variable>

  <!-- The page an entry has of its own, if it does: the entry is the root of a topic the navigation reaches -->
  <xsl:function name="govuk:md-entry-page" as="xs:string">
    <xsl:param name="entry" as="element()"/>
    <xsl:variable name="ref" as="element()?"
                  select="($govuk-md-map//*[contains(@class, ' map/topicref ')][normalize-space(@href)]
                           [not(@processing-role = 'resource-only')][not(@scope = 'external')]
                           [not(@format) or @format = 'dita']
                           [string(resolve-uri(replace(@href, '#.*$', ''), string(base-uri($govuk-md-map)))) = string(base-uri($entry))]
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
      <govuk:record kind="term" id="{$id}" stated="{if (govuk:md-stated-iri($entry/*[contains(@class, ' topic/prolog ')]) ne '') then 'yes' else 'no'}">
        <xsl:sequence select="$term/govuk:p"/>
        <xsl:sequence select="govuk:md-p('dct:language', govuk:md-lang($entry))"/>
        <xsl:if test="$page ne '' and $page ne $id">
          <xsl:sequence select="govuk:md-p('foaf:isPrimaryTopicOf', $page)"/>
        </xsl:if>
        <xsl:if test="govuk:md-term-retired($entry)">
          <xsl:sequence select="govuk:md-p('adms:status', 'retired')"/>
        </xsl:if>
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

  <xsl:function name="govuk:md-subjectdef-id" as="xs:string">
    <xsl:param name="def" as="element()"/>
    <xsl:variable name="map" select="$def/ancestor::*[contains(@class, ' subjectScheme/subjectScheme ')][1]"/>
    <xsl:variable name="stated" select="govuk:md-stated-iri($def/*[contains(@class, ' map/topicmeta ')])"/>
    <xsl:sequence select="if ($stated ne '') then $stated
                          else concat($govuk-md-base, 'vocab/', govuk:md-scheme-stem($map), '.ttl#',
                                      replace(tokenize(normalize-space($def/@keys))[1], '[^A-Za-z0-9_.\-]', '-'))"/>
  </xsl:function>

  <xsl:function name="govuk:md-subject-term" as="element(govuk:record)?">
    <xsl:param name="def" as="element()"/>
    <xsl:variable name="meta" select="$def/*[contains(@class, ' map/topicmeta ')]"/>
    <xsl:variable name="key" select="tokenize(normalize-space($def/@keys))[1]"/>
    <xsl:variable name="map" select="$def/ancestor::*[contains(@class, ' subjectScheme/subjectScheme ')][1]"/>
    <xsl:variable name="parent" select="$def/parent::*[contains(@class, ' subjectScheme/subjectdef ')][normalize-space(@keys)]"/>
    <xsl:variable name="label" select="(govuk:md-text($meta/*[contains(@class, ' topic/navtitle ')][1]),
                                        govuk:md-text($meta/*[contains(@class, ' map/linktext ')][1]), $key)[. ne ''][1]"/>
    <xsl:if test="normalize-space($key) ne ''">
      <govuk:record kind="term" id="{govuk:md-subjectdef-id($def)}"
                    stated="{if (govuk:md-stated-iri($meta) ne '') then 'yes' else 'no'}">
        <xsl:sequence select="govuk:md-p('dct:title', $label),
                              govuk:md-p('dct:description', govuk:md-text($meta/*[contains(@class, ' map/shortdesc ')][1])),
                              govuk:md-p('skos:notation', $key),
                              govuk:md-p('dct:language', govuk:md-lang($def))"/>
        <xsl:if test="tokenize(normalize-space($def/@outputclass)) = 'retired' or govuk:md-data($meta)[@term = 'adms:status'] = 'retired'">
          <xsl:sequence select="govuk:md-p('adms:status', 'retired')"/>
        </xsl:if>
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
      </govuk:record>
    </xsl:if>
  </xsl:function>

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

  <xsl:variable name="govuk-md-vocab" as="element(govuk:record)*">
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
                                govuk:md-p('dct:language', govuk:md-lang($group))"/>
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
                                  govuk:md-p('dct:language', govuk:md-lang(.))"/>
            <govuk:rel name="hasPart">
              <xsl:sequence select="$defs ! govuk:md-subject-term(.)"/>
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
      <xsl:variable name="prefixes" select="govuk:md-rdf-prefixes($govuk-md-skos-schemes)"/>
      <xsl:for-each select="$govuk-md-vocab">
        <xsl:variable name="graph" select="govuk:md-rdf-graph($govuk-md-skos-schemes, .)"/>
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
    <xsl:variable name="dups" as="element(govuk:dup)*">
      <!-- each term once: a glossgroup's entries are in the glossary's file as well -->
      <xsl:for-each-group select="$govuk-md-vocab[not(@stem = $govuk-md-group-schemes/@stem)]
                                  /govuk:rel[@name = 'hasPart']/govuk:record[@kind = 'term'][@stated = 'yes']"
                          group-by="@id">
        <xsl:if test="count(current-group()) gt 1">
          <govuk:dup id="{current-grouping-key()}" n="{count(current-group())}"
                     titles="{string-join(current-group()/govuk:p[@term = 'dct:title']/@value, ', ')}"/>
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

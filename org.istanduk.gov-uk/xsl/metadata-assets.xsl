<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

The harvesters for data assets (design 14 sections 6 and 8, #102), included by
metadata.xsl so both transforms see them.

  asset    A branch of the map that declares itself with
           <data name="rdf:type" value="dcat:Dataset"/> (or dct:Standard,
           dcat:DataService, adms:Asset, a full URI) in the topicmeta of the
           topicref, topichead or topicgroup that heads it. A submap is
           declared by wrapping its mapref in a topicgroup: DITA-OT drops a
           mapref's own topicmeta, and the submap file's, when it resolves
           the reference. Its landing page is the branch's first page; its
           title and description are the entry's, else that page's; the rest it
           does not state it takes from the publication.
  file     A resource-only reference inside a branch to a file the site ships
           and whose type is a data type (JSON, CSV, Turtle, YAML, ...). It is
           the asset's distribution, at the address the site publishes it.
  agent, contact
           The publisher with an address of its own, and the organisational
           mailbox of govuk.contact.email.

The declaration is the publisher's statement and is never inferred.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- ===== What a topicref declares ===== -->

  <!-- The types a topicref states, as written -->
  <xsl:function name="govuk:md-declared-types" as="xs:string*">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="for $d in govuk:md-data-elements($ref/*[contains(@class, ' map/topicmeta ')])
                                    [normalize-space(@name) = 'rdf:type']
                          return normalize-space(if (normalize-space($d/@value)) then string($d/@value) else govuk:md-text($d))"/>
  </xsl:function>

  <!-- A type the plugin can write: a term of a vocabulary it knows, or an
       absolute http(s) or urn address -->
  <xsl:function name="govuk:md-type-ok" as="xs:boolean">
    <xsl:param name="type" as="xs:string"/>
    <xsl:sequence select="govuk:md-known-term($type) or matches($type, '^(https?://|urn:)[^\s]+$')"/>
  </xsl:function>

  <xsl:function name="govuk:md-asset-types" as="xs:string*">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="distinct-values(govuk:md-declared-types($ref)[govuk:md-type-ok(.)])"/>
  </xsl:function>

  <!-- The entries that declare a type, valid or not -->
  <xsl:function name="govuk:md-declaring-refs" as="element()*">
    <xsl:param name="map" as="node()?"/>
    <xsl:sequence select="$map//*[contains(@class, ' map/topicref ')][exists(govuk:md-declared-types(.))]"/>
  </xsl:function>

  <!-- The entries that are assets -->
  <xsl:variable name="govuk-md-asset-refs" as="element()*"
                select="govuk:md-declaring-refs($govuk-md-map)[exists(govuk:md-asset-types(.))]"/>

  <!-- ===== Where a branch is, and what it ships ===== -->

  <!-- The first page of a branch: the entry itself, else the first entry beneath it that is a page -->
  <xsl:function name="govuk:md-landing" as="element()?">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="($ref/descendant-or-self::*[contains(@class, ' map/topicref ')]
                           [govuk:md-ref-path(.) ne ''][not(@processing-role = 'resource-only')])[1]"/>
  </xsl:function>

  <!-- A data file's media type, from its extension, else from the format the
       entry names; '' when it is not a data type the plugin knows -->
  <xsl:function name="govuk:md-media-type" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:param name="format" as="xs:string?"/>
    <xsl:variable name="types" as="map(xs:string, xs:string)"
                  select="map{'json': 'application/json', 'geojson': 'application/geo+json',
                              'csv': 'text/csv', 'tsv': 'text/tab-separated-values',
                              'ttl': 'text/turtle', 'turtle': 'text/turtle', 'rdf': 'application/rdf+xml',
                              'jsonld': 'application/ld+json', 'xml': 'application/xml',
                              'yaml': 'application/yaml', 'yml': 'application/yaml',
                              'zip': 'application/zip', 'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                              'xls': 'application/vnd.ms-excel', 'txt': 'text/plain'}"/>
    <xsl:variable name="ext" select="lower-case(replace(replace($href, '[?#].*$', ''), '^.*\.([^./]+)$', '$1'))"/>
    <xsl:sequence select="string(($types($ext), $types(lower-case(normalize-space($format))))[1])"/>
  </xsl:function>

  <!-- The resource-only entries inside a branch that are data files, not
       counting those inside a branch of their own -->
  <xsl:function name="govuk:md-file-refs" as="element()*">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="$ref//*[contains(@class, ' map/topicref ')]
                          [@processing-role = 'resource-only'][normalize-space(@href)]
                          [not(@scope = ('external', 'peer'))]
                          [govuk:md-media-type(string(@href), @format) ne '']
                          [(ancestor::*[. intersect $govuk-md-asset-refs])[last()] is $ref]"/>
  </xsl:function>

  <!-- A file's path under the site: where the output puts it, or '' when it is outside -->
  <xsl:function name="govuk:md-file-path" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:variable name="path" select="replace(string(($ref/@copy-to, $ref/@href)[normalize-space()][1]), '[?#].*$', '')"/>
    <xsl:variable name="clean" select="string-join(tokenize($path, '/')[. ne '.'], '/')"/>
    <xsl:sequence select="if (starts-with($clean, '../') or matches($clean, '^([A-Za-z][A-Za-z0-9+.\-]*:|/)')) then '' else $clean"/>
  </xsl:function>

  <!-- ===== Records ===== -->

  <xsl:function name="govuk:md-file-record" as="element(govuk:record)?">
    <xsl:param name="ref" as="element()"/>
    <xsl:variable name="path" select="govuk:md-file-path($ref)"/>
    <xsl:variable name="type" select="govuk:md-media-type(string($ref/@href), $ref/@format)"/>
    <xsl:if test="$path ne '' and govuk:md-id($path) ne ''">
      <govuk:record kind="file" id="{govuk:md-id($path)}">
        <xsl:sequence select="govuk:md-p('dct:title',
                                (govuk:md-ref-title($ref), replace($path, '^.*/', ''))[. ne ''][1]),
                              govuk:md-p('dcat:downloadURL', govuk:md-id($path)),
                              govuk:md-p('dcat:mediaType', concat('https://www.iana.org/assignments/media-types/', $type)),
                              govuk:md-p('dct:format', upper-case((replace($path, '^.*\.', ''), $ref/@format)[1]))"/>
        <xsl:sequence select="govuk:md-data($ref/*[contains(@class, ' map/topicmeta ')])"/>
      </govuk:record>
    </xsl:if>
  </xsl:function>

  <!-- The publisher with an address of its own: its home page, else a fragment of the site's -->
  <xsl:variable name="govuk-md-publisher" as="element(govuk:record)?">
    <xsl:if test="exists($govuk-md-agent) and $govuk-md-base ne ''">
      <govuk:record kind="agent"
                    id="{(govuk:md-uri($GOVUK-ORGANISATION-URL)[. ne ''], concat($govuk-md-base, '#publisher'))[1]}">
        <xsl:sequence select="$govuk-md-agent/govuk:p"/>
      </govuk:record>
    </xsl:if>
  </xsl:variable>

  <!-- An organisational mailbox, as a contact point: never a person by default -->
  <xsl:variable name="govuk-md-contact" as="element(govuk:record)?">
    <xsl:if test="normalize-space($GOVUK-CONTACT-EMAIL) ne '' and $govuk-md-base ne ''">
      <govuk:record kind="contact" id="{concat($govuk-md-base, '#contact')}">
        <xsl:sequence select="govuk:md-p('dct:title', string($govuk-md-agent/govuk:p[@term = 'dct:title']/@value)),
                              govuk:md-p('vcard:hasEmail', concat('mailto:', normalize-space($GOVUK-CONTACT-EMAIL)))"/>
      </govuk:record>
    </xsl:if>
  </xsl:variable>

  <!-- What the publication states that an asset takes from it unless it says otherwise -->
  <xsl:variable name="govuk-md-shared" as="element(govuk:p)*">
    <xsl:sequence select="$govuk-md-publication/govuk:p[not(@term = ($govuk-md-own-terms, 'dct:publisher'))]"/>
    <xsl:for-each select="$govuk-md-publisher">
      <govuk:p term="dct:publisher" value="{govuk:p[@term = 'dct:title']/@value}">
        <xsl:sequence select="."/>
      </govuk:p>
    </xsl:for-each>
    <xsl:for-each select="$govuk-md-contact">
      <govuk:p term="dcat:contactPoint" value="{@id}">
        <xsl:sequence select="."/>
      </govuk:p>
    </xsl:for-each>
  </xsl:variable>

  <xsl:function name="govuk:md-asset-record" as="element(govuk:record)">
    <xsl:param name="ref" as="element()"/>
    <xsl:variable name="topicmeta" select="$ref/*[contains(@class, ' map/topicmeta ')]"/>
    <xsl:variable name="landing" select="govuk:md-landing($ref)"/>
    <xsl:variable name="landing-id" select="govuk:md-id(govuk:md-ref-path($landing))"/>
    <xsl:variable name="data" select="govuk:md-data($topicmeta)[not(@term = 'rdf:type')]"/>
    <!-- a stated identifier that is an address is the asset's own (D-26); else its landing page -->
    <xsl:variable name="stated" select="($data[@term = 'dct:identifier']/@value[matches(., '^(https?://|urn:)[^\s]+$')])[1]"/>
    <xsl:variable name="own" as="element(govuk:p)*">
      <xsl:sequence select="govuk:md-p('dct:title', (govuk:md-ref-title($ref), govuk:md-ref-title($landing))[. ne ''][1]),
                            govuk:md-p('dct:description',
                              (govuk:md-text($topicmeta/*[contains(@class, ' map/shortdesc ')][1]),
                               govuk:md-text($landing/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' map/shortdesc ')][1]))[. ne ''][1]),
                            for $t in govuk:md-asset-types($ref) return govuk:md-p('rdf:type', $t),
                            govuk:md-p('dcat:landingPage', $landing-id)"/>
      <xsl:sequence select="$data"/>
    </xsl:variable>
    <govuk:record kind="asset" id="{string(($stated, $landing-id)[. ne ''][1])}" path="{govuk:md-ref-path($landing)}">
      <xsl:sequence select="$own"/>
      <xsl:sequence select="$govuk-md-shared[not(@term = $own/@term)]"/>
      <govuk:rel name="hasPart">
        <xsl:sequence select="govuk:md-file-refs($ref) ! govuk:md-file-record(.)"/>
      </govuk:rel>
    </govuk:record>
  </xsl:function>

  <xsl:variable name="govuk-md-assets" as="element(govuk:record)*"
                select="if ($govuk-md-base = '') then ()
                        else $govuk-md-asset-refs ! govuk:md-asset-record(.)[normalize-space(@id) ne '']"/>

  <!-- The publication as a catalogue of its assets: the same properties the
       assets share, the assets as parts, and how many there are -->
  <xsl:variable name="govuk-md-catalogue" as="element(govuk:record)">
    <govuk:record kind="publication" id="{$govuk-md-base}"
                  assets="{if (count($govuk-md-assets) = 0) then 'none' else if (count($govuk-md-assets) = 1) then 'one' else 'many'}">
      <xsl:sequence select="$govuk-md-publication/govuk:p[not(@term = 'dct:publisher')]"/>
      <xsl:sequence select="$govuk-md-shared[@term = ('dct:publisher', 'dcat:contactPoint')]"/>
      <xsl:sequence select="govuk:md-p('dcat:landingPage', $govuk-md-base)"/>
      <govuk:rel name="hasPart"><xsl:sequence select="$govuk-md-assets"/></govuk:rel>
    </govuk:record>
  </xsl:variable>

  <!-- What a catalogue record is rooted at: the one asset, or the catalogue of several -->
  <xsl:variable name="govuk-md-roots" as="element(govuk:record)*"
                select="if (count($govuk-md-assets) = 1) then $govuk-md-assets
                        else if (count($govuk-md-assets) gt 1) then $govuk-md-catalogue
                        else ()"/>

</xsl:stylesheet>

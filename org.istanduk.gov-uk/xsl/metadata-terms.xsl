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

</xsl:stylesheet>

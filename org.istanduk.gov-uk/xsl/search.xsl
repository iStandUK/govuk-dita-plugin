<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Search relevance from DITA semantics (#54). The DITA carries the meaning; this
stylesheet translates it into the attributes Pagefind understands:

  shortdesc / abstract's shortdesc      -> data-pagefind-weight="4"
  outputclass "search-ignore"           -> data-pagefind-ignore (any element)
  demoted topic (outputclass
    "search-demote" on the topic or its
    title, or importance obsolete /
    deprecated on the topic)            -> body 0.3, title 2, shortdesc 1
  prolog keywords                       -> searchable "keywords" metadata
  titlealts/searchtitle                 -> the result title
  prolog category / audience            -> "category" / "audience" filters

Measured on a 10,000-page reference corpus: multipliers barely move Pagefind's
saturated scores, exclusion and demotion do; the title weight decides whether a
demoted page ranks below live pages that share its words (see the manual).
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <xsl:variable name="govuk-search-weight-shortdesc" select="'4'" as="xs:string"/>
  <xsl:variable name="govuk-search-demoted-body" select="'0.3'" as="xs:string"/>
  <xsl:variable name="govuk-search-demoted-title" select="'2'" as="xs:string"/>
  <xsl:variable name="govuk-search-demoted-shortdesc" select="'1'" as="xs:string"/>

  <xsl:function name="govuk:has-token" as="xs:boolean">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:param name="token" as="xs:string"/>
    <xsl:sequence select="tokenize(normalize-space(string($value)), '\s+') = $token"/>
  </xsl:function>

  <!-- A topic is demoted when it, or its title, carries outputclass
       "search-demote", or when its DITA importance is obsolete or deprecated -->
  <xsl:function name="govuk:search-demoted" as="xs:boolean">
    <xsl:param name="topic" as="element()?"/>
    <xsl:sequence select="exists($topic) and (
                            govuk:has-token($topic/@outputclass, 'search-demote')
                            or govuk:has-token($topic/*[contains(@class, ' topic/title ')]/@outputclass, 'search-demote')
                            or $topic/@importance = ('obsolete', 'deprecated'))"/>
  </xsl:function>

  <!-- Every rendered element passes through commonattributes; add the search
       attributes after the toolkit's own (class, id, lang, dir). -->
  <xsl:template match="*" mode="commonattributes" priority="1">
    <xsl:param name="default-output-class" as="xs:string*"/>
    <xsl:next-match>
      <xsl:with-param name="default-output-class" select="$default-output-class"/>
    </xsl:next-match>
    <xsl:apply-templates select="." mode="govuk-search-attributes"/>
  </xsl:template>

  <!-- Excluded from the index (stays on the page) -->
  <xsl:template match="*[govuk:has-token(@outputclass, 'search-ignore')]" mode="govuk-search-attributes" priority="10">
    <xsl:attribute name="data-pagefind-ignore"/>
  </xsl:template>

  <!-- The summary is the most searched-for sentence in a reference publication -->
  <xsl:template match="*[contains(@class, ' topic/shortdesc ')]" mode="govuk-search-attributes">
    <xsl:attribute name="data-pagefind-weight"
                   select="if (govuk:search-demoted(ancestor::*[contains(@class, ' topic/topic ')][1]))
                           then $govuk-search-demoted-shortdesc else $govuk-search-weight-shortdesc"/>
  </xsl:template>

  <!-- Demoted topics: rank below live pages that share their words, stay findable -->
  <xsl:template match="*[contains(@class, ' topic/topic ')]/*[contains(@class, ' topic/title ')]
                        [govuk:search-demoted(parent::*)]" mode="govuk-search-attributes">
    <xsl:attribute name="data-pagefind-weight" select="$govuk-search-demoted-title"/>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/body ')][govuk:search-demoted(parent::*)]" mode="govuk-search-attributes">
    <xsl:attribute name="data-pagefind-weight" select="$govuk-search-demoted-body"/>
  </xsl:template>

  <xsl:template match="@* | node()" mode="govuk-search-attributes"/>

  <!-- ===== Head metadata ===== -->

  <!-- Prolog keywords: the toolkit already emits them as <meta name="keywords">;
       let Pagefind index them as searchable "keywords" metadata (boost via the
       ranking object's metaWeights). Mirrors get-meta.xsl's selection. -->
  <xsl:template match="*[contains(@class, ' topic/topic ')]" mode="gen-keywords-metadata">
    <xsl:variable name="keywords" as="element()*"
                  select="*[contains(@class, ' topic/prolog ')]/*[contains(@class, ' topic/metadata ')]/
                            *[contains(@class, ' topic/keywords ')]/
                            (*[contains(@class, ' topic/keyword ')] | *[contains(@class, ' topic/indexterm ')])"/>
    <xsl:if test="exists($keywords)">
      <meta name="keywords" data-pagefind-meta="keywords[content]"
            content="{string-join(distinct-values($keywords/normalize-space()), ', ')}"/>
    </xsl:if>
  </xsl:template>

  <!-- searchtitle becomes the result title; category and audience become filters -->
  <xsl:template match="/ | *" mode="gen-user-head" priority="1">
    <xsl:next-match/>
    <xsl:variable name="topic" as="element()?"
                  select="(self::*[contains(@class, ' topic/topic ')],
                           /dita/*[contains(@class, ' topic/topic ')][1],
                           /*[contains(@class, ' topic/topic ')])[1]"/>
    <xsl:if test="exists($topic)">
      <xsl:variable name="searchtitle" as="xs:string"
                    select="normalize-space(string(($topic/*[contains(@class, ' topic/titlealts ')]
                                                          /*[contains(@class, ' topic/searchtitle ')])[1]))"/>
      <xsl:if test="$searchtitle != ''">
        <meta name="search-title" data-pagefind-meta="title[content]" content="{$searchtitle}"/>
      </xsl:if>
      <xsl:variable name="metadata" as="element()*"
                    select="$topic/*[contains(@class, ' topic/prolog ')]/*[contains(@class, ' topic/metadata ')]"/>
      <xsl:for-each select="distinct-values($metadata/*[contains(@class, ' topic/category ')]/normalize-space())[. != '']">
        <meta name="search-category" data-pagefind-filter="category[content]" content="{.}"/>
      </xsl:for-each>
      <xsl:for-each select="distinct-values($metadata/*[contains(@class, ' topic/audience ')]
                                              /(if (normalize-space(@type)) then normalize-space(@type) else normalize-space(.)))[. != '']">
        <meta name="search-audience" data-pagefind-filter="audience[content]" content="{.}"/>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

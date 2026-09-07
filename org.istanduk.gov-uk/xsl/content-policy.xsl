<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Content policy (#81, epic #77): DITA content can carry things a static
GOV.UK site should not — script-scheme links, images and objects fetched from
another origin (which breaks the no-external-requests guarantee, NFR-P1, and
reveals readers' addresses to a third party), and embeds of arbitrary types.
The toolkit renders them as authored. This stylesheet reports each one as a
build WARNING (GOVK006W; never an error) and, under govuk.content.policy=strip,
replaces it with a marked placeholder. Every choice is the publisher's, through
parameters; content authors are never blocked. Shared predicates for the SVG
sanitiser live here too.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <!-- yes (default): report findings; no: silent -->
  <xsl:param name="GOVUK-CONTENT-WARNINGS" select="'yes'"/>
  <!-- warn (default): render as authored; strip: replace with a placeholder -->
  <xsl:param name="GOVUK-CONTENT-POLICY" select="'warn'"/>

  <xsl:variable name="govuk-strip" as="xs:boolean" select="$GOVUK-CONTENT-POLICY = 'strip'"/>

  <!-- A reference that would fetch from another origin -->
  <xsl:function name="govuk:remote" as="xs:boolean">
    <xsl:param name="ref" as="xs:string?"/>
    <xsl:sequence select="matches(normalize-space(string($ref)), '^(https?:|//)', 'i')"/>
  </xsl:function>

  <!-- A link whose scheme runs code or smuggles a document -->
  <xsl:function name="govuk:script-scheme" as="xs:boolean">
    <xsl:param name="ref" as="xs:string?"/>
    <xsl:sequence select="matches(normalize-space(string($ref)), '^(javascript|vbscript|data)\s*:', 'i')"/>
  </xsl:function>

  <!-- One finding: GOVK006W names the kind, the value and what was done; when a
       Content-Security-Policy is in force and the content was kept, GOVK007W
       says the policy will block it in the browser -->
  <xsl:template name="govuk-content-finding">
    <xsl:param name="kind" as="xs:string"/>
    <xsl:param name="value" as="xs:string"/>
    <xsl:param name="blocked-by-csp" as="xs:boolean" select="false()"/>
    <xsl:if test="$GOVUK-CONTENT-WARNINGS = 'yes'">
      <xsl:call-template name="output-message">
        <xsl:with-param name="id" select="'GOVK006W'"/>
        <xsl:with-param name="msgparams">%1=<xsl:value-of select="$kind"/>;%2=<xsl:value-of select="translate($value, ';', ',')"/>;%3=<xsl:value-of select="if ($govuk-strip) then 'removed' else 'kept'"/></xsl:with-param>
      </xsl:call-template>
      <xsl:if test="$blocked-by-csp and not($govuk-strip) and $govuk-csp-value ne ''">
        <xsl:call-template name="output-message">
          <xsl:with-param name="id" select="'GOVK007W'"/>
          <xsl:with-param name="msgparams">%1=<xsl:value-of select="$kind"/>;%2=<xsl:value-of select="translate($value, ';', ',')"/></xsl:with-param>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="govuk-content-placeholder">
    <xsl:param name="text" as="xs:string"/>
    <xsl:param name="block" as="xs:boolean" select="false()"/>
    <xsl:variable name="note">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="'govuk-dita.content-removed'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:element name="{if ($block) then 'div' else 'span'}">
      <xsl:attribute name="class" select="'app-content-stripped'"/>
      <xsl:attribute name="title" select="string($note)"/>
      <xsl:value-of select="if ($text ne '') then $text else string($note)"/>
    </xsl:element>
  </xsl:template>

  <!-- ===== Images fetched from another origin ===== -->

  <xsl:template match="*[contains(@class, ' topic/image ')][govuk:remote(@href)]" priority="20">
    <xsl:call-template name="govuk-content-finding">
      <xsl:with-param name="kind" select="'remote image'"/>
      <xsl:with-param name="value" select="string(@href)"/>
      <xsl:with-param name="blocked-by-csp" select="true()"/>
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="$govuk-strip">
        <xsl:call-template name="govuk-content-placeholder">
          <xsl:with-param name="text" select="normalize-space(string(*[contains(@class, ' topic/alt ')][1]))"/>
          <xsl:with-param name="block" select="@placement = 'break'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- svgref to another origin renders as an image (foreign.xsl inlines only
       local files), so it is the same case -->
  <xsl:template match="*[contains(@class, ' svg-d/svgref ')][govuk:remote(@href)]" priority="20">
    <xsl:call-template name="govuk-content-finding">
      <xsl:with-param name="kind" select="'remote SVG reference'"/>
      <xsl:with-param name="value" select="string(@href)"/>
      <xsl:with-param name="blocked-by-csp" select="true()"/>
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="$govuk-strip">
        <xsl:call-template name="govuk-content-placeholder">
          <xsl:with-param name="text" select="normalize-space(string(ancestor::*[contains(@class, ' topic/fig ')][1]/*[contains(@class, ' topic/title ')][1]))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ===== Embedded objects ===== -->

  <xsl:template match="*[contains(@class, ' topic/object ')]" priority="20">
    <xsl:variable name="remote" select="govuk:remote(@data) or govuk:remote(@codebase) or govuk:remote(@classid)"/>
    <xsl:call-template name="govuk-content-finding">
      <xsl:with-param name="kind" select="if ($remote) then 'remote object embed' else 'object embed'"/>
      <xsl:with-param name="value" select="string((@data, @classid, @type, 'object')[1])"/>
      <xsl:with-param name="blocked-by-csp" select="$remote"/>
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="$govuk-strip">
        <xsl:call-template name="govuk-content-placeholder">
          <xsl:with-param name="text" select="normalize-space(string(*[contains(@class, ' topic/desc ')][1]))"/>
          <xsl:with-param name="block" select="true()"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ===== Links whose scheme runs code ===== -->

  <xsl:template match="*[contains(@class, ' topic/xref ')][govuk:script-scheme(@href)]" priority="20">
    <xsl:call-template name="govuk-content-finding">
      <xsl:with-param name="kind" select="'script-scheme link'"/>
      <xsl:with-param name="value" select="string(@href)"/>
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="$govuk-strip">
        <span class="app-content-stripped">
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/link ')][govuk:script-scheme(@href)]" priority="20">
    <xsl:call-template name="govuk-content-finding">
      <xsl:with-param name="kind" select="'script-scheme related link'"/>
      <xsl:with-param name="value" select="string(@href)"/>
    </xsl:call-template>
    <xsl:if test="not($govuk-strip)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

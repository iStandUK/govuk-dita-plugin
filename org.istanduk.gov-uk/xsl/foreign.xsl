<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Foreign-markup passthrough. HTML5 renders MathML and SVG natively, so this
module emits them inline rather than dropping them (mathml, issue #28) or
flattening them to a raster reference (svgref, issue #37). Inlining SVG keeps
links and interactivity inside diagrams working.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:m="http://www.w3.org/1998/Math/MathML"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs m svg xlink govuk">

  <!-- yes (default): inline local SVG references so links inside work; no:
       keep the img rendering -->
  <xsl:param name="GOVUK-SVG-INLINE" select="'yes'"/>

  <!-- ===== MathML (mathml-d, equation-d) — issue #28 ===== -->

  <!-- mathml-d/mathml specialises topic/foreign, which the base drops with an
       empty template. Emit its embedded MathML (or referenced .mml) natively. -->
  <xsl:template match="*[contains(@class, ' mathml-d/mathml ')]" priority="10">
    <xsl:choose>
      <xsl:when test="m:math">
        <xsl:apply-templates select="m:math" mode="govuk-foreign"/>
      </xsl:when>
      <xsl:when test="*[contains(@class, ' mathml-d/mathmlref ')]/@href">
        <xsl:variable name="uri"
                      select="resolve-uri(*[contains(@class, ' mathml-d/mathmlref ')]/@href, base-uri(.))"/>
        <xsl:if test="doc-available($uri)">
          <xsl:apply-templates select="doc($uri)/m:math" mode="govuk-foreign"/>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- ===== SVG (svg-d/svgref) — issue #37 ===== -->

  <!-- Replace the base img rendering with inline SVG when the reference
       resolves to a local file, so links/anchors inside the artwork work.
       External or unresolvable references fall back to img (next-match to the
       base template). -->
  <xsl:template match="*[contains(@class, ' svg-d/svgref ')]" priority="10">
    <!-- svgref targets are copied straight to output, not into temp, so resolve
         the href against the source location recorded in @xtrf rather than the
         topic's temp base-uri -->
    <xsl:variable name="base" as="xs:string"
                  select="string((ancestor-or-self::*[@xtrf][1]/@xtrf, base-uri(.))[1])"/>
    <xsl:variable name="uri" as="xs:string?">
      <xsl:if test="@href and not(@scope = 'external')">
        <xsl:sequence select="string(resolve-uri(@href, $base))"/>
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$GOVUK-SVG-INLINE = 'yes' and exists($uri) and doc-available($uri) and doc($uri)/svg:svg">
        <xsl:variable name="alt"
                      select="normalize-space(string(ancestor::*[contains(@class, ' topic/fig ')][1]
                                                    /*[contains(@class, ' topic/title ')][1]))"/>
        <!-- Per-instance token isolates ids so multiple inlined SVGs on a
             page cannot clash on ids / url(#...) / #fragment references -->
        <xsl:variable name="token" select="concat('svg', generate-id(.))"/>
        <xsl:apply-templates select="doc($uri)/svg:svg" mode="govuk-svg-inline">
          <xsl:with-param name="token" select="$token" tunnel="yes"/>
          <xsl:with-param name="alt" select="$alt" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <!-- fall back to the base img rendering -->
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- The root svg element: add accessibility + a viewBox if missing -->
  <xsl:template match="svg:svg" mode="govuk-svg-inline">
    <xsl:param name="token" tunnel="yes"/>
    <xsl:param name="alt" tunnel="yes" select="''"/>
    <svg xmlns="http://www.w3.org/2000/svg">
      <xsl:apply-templates select="@* except (@id | @width | @height)" mode="govuk-svg-inline"/>
      <xsl:if test="not(@viewBox) and @width and @height">
        <xsl:attribute name="viewBox"
                       select="concat('0 0 ', replace(@width, '[^0-9.]', ''), ' ', replace(@height, '[^0-9.]', ''))"/>
      </xsl:if>
      <xsl:attribute name="role">img</xsl:attribute>
      <xsl:if test="$alt ne '' and not(svg:title)">
        <xsl:attribute name="aria-label" select="$alt"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="govuk-svg-inline"/>
    </svg>
  </xsl:template>

  <!-- SVG elements: preserve the SVG namespace, isolate ids -->
  <xsl:template match="svg:*" mode="govuk-svg-inline">
    <xsl:param name="token" tunnel="yes"/>
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/2000/svg">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <!-- @id and idref attributes get the per-instance prefix -->
  <xsl:template match="@id" mode="govuk-svg-inline">
    <xsl:param name="token" tunnel="yes"/>
    <xsl:attribute name="id" select="concat($token, '-', .)"/>
  </xsl:template>

  <!-- Local fragment links: #foo -> #token-foo (internal), rewrite id-space;
       leave cross-document / external hrefs untouched -->
  <xsl:template match="@xlink:href | @href" mode="govuk-svg-inline">
    <xsl:param name="token" tunnel="yes"/>
    <xsl:variable name="v" select="string(.)"/>
    <xsl:attribute name="{name()}"
                   namespace="{namespace-uri()}"
                   select="if (starts-with($v, '#')) then concat('#', $token, '-', substring($v, 2)) else $v"/>
  </xsl:template>

  <!-- Presentation attributes referencing local ids via url(#id) -->
  <xsl:template match="@*[contains(., 'url(#')]" mode="govuk-svg-inline">
    <xsl:param name="token" tunnel="yes"/>
    <xsl:attribute name="{name()}" namespace="{namespace-uri()}"
                   select="replace(., 'url\(#', concat('url(#', $token, '-'))"/>
  </xsl:template>

  <!-- Style-element text: rewrite url(#id) and #id references to the prefixed
       ids. (Class selectors stay document-global; authors with several
       distinctly-styled SVGs on one page should use unique class names or
       govuk.svg.inline=no.) -->
  <xsl:template match="svg:style/text()" mode="govuk-svg-inline">
    <xsl:param name="token" tunnel="yes"/>
    <xsl:value-of select="replace(., 'url\(#', concat('url(#', $token, '-'))"/>
  </xsl:template>

  <!-- ===== Shared namespace-preserving copy (MathML, and SVG under mathml) ===== -->

  <xsl:template match="*" mode="govuk-foreign">
    <xsl:element name="{local-name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@* | text() | comment()" mode="govuk-foreign govuk-svg-inline">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>

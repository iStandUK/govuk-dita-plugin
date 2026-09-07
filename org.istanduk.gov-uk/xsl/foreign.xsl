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
  <!-- yes (default): strip active content from inlined SVG (#78); no: inline
       as authored. Either way findings are reported (GOVK004W). -->
  <xsl:param name="GOVUK-SVG-SANITIZE" select="'yes'"/>
  <!-- input (default): inline only files under the input directory (or the
       toolkit's temp directory); any: inline wherever the reference points.
       A reference outside the input directory is reported (GOVK005W). -->
  <xsl:param name="GOVUK-INLINE-SCOPE" select="'input'"/>
  <xsl:param name="GOVUK-INPUT-DIR" select="''"/>

  <!-- A file path from a URI or path, without scheme or trailing slash, for
       prefix comparison -->
  <xsl:function name="govuk:path-of" as="xs:string">
    <xsl:param name="uri" as="xs:string?"/>
    <xsl:sequence select="replace(replace(replace(string($uri), '^file:/+', '/'), '%20', ' '), '/+$', '')"/>
  </xsl:function>

  <!-- Whether a resolved reference lies under the input directory, or under
       the toolkit's temp directory (the workdir-uri processing instruction
       every preprocessed topic carries); permissive when the build did not
       say where the input is -->
  <xsl:function name="govuk:within-input" as="xs:boolean">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="context" as="node()"/>
    <xsl:variable name="p" select="govuk:path-of($uri)"/>
    <xsl:variable name="temp" select="govuk:path-of(string(root($context)/processing-instruction('workdir-uri')[1]))"/>
    <xsl:sequence select="normalize-space($GOVUK-INPUT-DIR) = ''
                          or starts-with($p, concat(govuk:path-of($GOVUK-INPUT-DIR), '/'))
                          or ($temp ne '' and starts-with($p, concat($temp, '/')))"/>
  </xsl:function>

  <!-- What an SVG file carries that would run or fetch in the reader's browser -->
  <xsl:function name="govuk:svg-findings" as="xs:string*">
    <xsl:param name="svg" as="element()"/>
    <xsl:sequence select="(
      if (exists($svg/descendant-or-self::svg:script)) then 'script' else (),
      if (exists($svg/descendant-or-self::svg:foreignObject)) then 'foreignObject' else (),
      if (exists($svg/descendant-or-self::*/@*[starts-with(local-name(), 'on')])) then 'event-handler attributes' else (),
      if (exists($svg/descendant-or-self::*/(@href | @xlink:href)[govuk:script-scheme(.)])) then 'script-scheme links' else (),
      if (exists($svg/descendant-or-self::*[self::svg:image or self::svg:use or self::svg:feImage or self::svg:script]
                    /(@href | @xlink:href)[govuk:remote(.)])) then 'remote references' else ())"/>
  </xsl:function>

  <xsl:template name="govuk-inline-scope-warning">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="action" as="xs:string"/>
    <xsl:call-template name="output-message">
      <xsl:with-param name="id" select="'GOVK005W'"/>
      <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate($uri, ';', ',')"/>;%2=<xsl:value-of select="$action"/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- ===== MathML (mathml-d, equation-d) — issue #28 ===== -->

  <!-- mathml-d/mathml specialises topic/foreign, which the base drops with an
       empty template. Emit its embedded MathML (or referenced .mml) natively. -->
  <xsl:template match="*[contains(@class, ' mathml-d/mathml ')]" priority="10">
    <xsl:choose>
      <xsl:when test="m:math">
        <xsl:apply-templates select="m:math" mode="govuk-foreign"/>
      </xsl:when>
      <xsl:when test="*[contains(@class, ' mathml-d/mathmlref ')]/@href">
        <xsl:variable name="uri" as="xs:string"
                      select="string(resolve-uri(*[contains(@class, ' mathml-d/mathmlref ')]/@href, base-uri(.)))"/>
        <xsl:variable name="inside" select="govuk:within-input($uri, .)"/>
        <xsl:choose>
          <xsl:when test="not($inside) and $GOVUK-INLINE-SCOPE ne 'any'">
            <xsl:call-template name="govuk-inline-scope-warning">
              <xsl:with-param name="uri" select="$uri"/>
              <xsl:with-param name="action" select="'not inlined'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="doc-available($uri)">
            <xsl:if test="not($inside)">
              <xsl:call-template name="govuk-inline-scope-warning">
                <xsl:with-param name="uri" select="$uri"/>
                <xsl:with-param name="action" select="'inlined (govuk.inline.scope=any)'"/>
              </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="doc($uri)/m:math" mode="govuk-foreign"/>
          </xsl:when>
        </xsl:choose>
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
    <xsl:variable name="inside" as="xs:boolean" select="exists($uri) and govuk:within-input($uri, .)"/>
    <xsl:choose>
      <!-- Outside the input directory and not allowed there: fall back to the
           image rendering without reading the file (#80) -->
      <xsl:when test="$GOVUK-SVG-INLINE = 'yes' and exists($uri) and not($inside) and $GOVUK-INLINE-SCOPE ne 'any'">
        <xsl:call-template name="govuk-inline-scope-warning">
          <xsl:with-param name="uri" select="$uri"/>
          <xsl:with-param name="action" select="'not inlined'"/>
        </xsl:call-template>
        <xsl:next-match/>
      </xsl:when>
      <xsl:when test="$GOVUK-SVG-INLINE = 'yes' and exists($uri) and doc-available($uri) and doc($uri)/svg:svg">
        <xsl:if test="not($inside)">
          <xsl:call-template name="govuk-inline-scope-warning">
            <xsl:with-param name="uri" select="$uri"/>
            <xsl:with-param name="action" select="'inlined (govuk.inline.scope=any)'"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:variable name="svg" select="doc($uri)/svg:svg"/>
        <xsl:variable name="sanitize" as="xs:boolean" select="$GOVUK-SVG-SANITIZE ne 'no'"/>
        <!-- Active or remote content in the file is reported once per
             reference, whether it is removed or kept (#78) -->
        <xsl:variable name="findings" as="xs:string*" select="govuk:svg-findings($svg)"/>
        <xsl:if test="exists($findings)">
          <xsl:call-template name="output-message">
            <xsl:with-param name="id" select="'GOVK004W'"/>
            <xsl:with-param name="msgparams">%1=<xsl:value-of select="translate(string(@href), ';', ',')"/>;%2=<xsl:value-of select="string-join($findings, ', ')"/>;%3=<xsl:value-of select="if ($sanitize) then 'removed' else 'kept (govuk.svg.sanitize=no)'"/></xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:variable name="alt"
                      select="normalize-space(string(ancestor::*[contains(@class, ' topic/fig ')][1]
                                                    /*[contains(@class, ' topic/title ')][1]))"/>
        <!-- Per-instance token isolates ids so multiple inlined SVGs on a
             page cannot clash on ids / url(#...) / #fragment references -->
        <xsl:variable name="token" select="concat('svg', generate-id(.))"/>
        <xsl:apply-templates select="$svg" mode="govuk-svg-inline">
          <xsl:with-param name="token" select="$token" tunnel="yes"/>
          <xsl:with-param name="alt" select="$alt" tunnel="yes"/>
          <xsl:with-param name="sanitize" select="$sanitize" tunnel="yes"/>
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

  <!-- Attributes that only ever arrive as SVG 1.1 DTD defaults when the file
       carries a doctype; two of them are invalid on <svg> in HTML (#59) -->
  <xsl:template match="svg:svg/@contentScriptType | svg:svg/@contentStyleType | svg:svg/@zoomAndPan
                       | svg:svg/@version | svg:svg/@baseProfile
                       | @xlink:type | @xlink:show | @xlink:actuate"
                mode="govuk-svg-inline"/>

  <!-- Active content (#78): dropped under govuk.svg.sanitize=yes -->
  <xsl:template match="svg:script | svg:foreignObject" mode="govuk-svg-inline">
    <xsl:param name="sanitize" tunnel="yes" as="xs:boolean" select="true()"/>
    <xsl:if test="not($sanitize)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@*[starts-with(local-name(), 'on')]" mode="govuk-svg-inline">
    <xsl:param name="sanitize" tunnel="yes" as="xs:boolean" select="true()"/>
    <xsl:if test="not($sanitize)">
      <xsl:copy/>
    </xsl:if>
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
    <xsl:param name="sanitize" tunnel="yes" as="xs:boolean" select="true()"/>
    <xsl:variable name="v" select="string(.)"/>
    <xsl:choose>
      <xsl:when test="starts-with($v, '#')">
        <xsl:attribute name="{name()}" namespace="{namespace-uri()}"
                       select="concat('#', $token, '-', substring($v, 2))"/>
      </xsl:when>
      <!-- links that run code, and resources fetched from another origin,
           are dropped when sanitising (#78); ordinary external links stay -->
      <xsl:when test="$sanitize and govuk:script-scheme($v)"/>
      <xsl:when test="$sanitize and govuk:remote($v)
                      and parent::*[self::svg:image or self::svg:use or self::svg:feImage or self::svg:script]"/>
      <xsl:otherwise>
        <xsl:attribute name="{name()}" namespace="{namespace-uri()}" select="$v"/>
      </xsl:otherwise>
    </xsl:choose>
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

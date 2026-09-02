<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Element-level typography: appends GOV.UK Design System classes to the classes
the html5 base would emit, by extending the default passed through the
set-output-class mode (the hook commonattributes uses for every element).
An author's @outputclass still replaces the whole default, so publishers keep
full control per element. Structural overrides (notes, table captions and
sections) follow at the end.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:table="http://dita-ot.sourceforge.net/ns/201007/dita-ot/table"
                xmlns:ditamsg="http://dita-ot.sourceforge.net/ns/200704/ditamsg"
                version="3.0"
                exclude-result-prefixes="xs table ditamsg">

  <!-- ===== Headings ===== -->

  <xsl:template match="*[contains(@class, ' topic/topic ')]/*[contains(@class, ' topic/title ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:variable name="level" select="count(ancestor::*[contains(@class, ' topic/topic ')])" as="xs:integer"/>
    <xsl:variable name="heading" select="if ($level le 1) then 'govuk-heading-l'
                                         else if ($level eq 2) then 'govuk-heading-m'
                                         else 'govuk-heading-s'"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' ', $heading))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/section ')]/*[contains(@class, ' topic/title ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-heading-m'))"/>
    </xsl:next-match>
  </xsl:template>

  <!-- ===== Body text and lists ===== -->

  <xsl:template match="*[contains(@class, ' topic/shortdesc ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-body-l'))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/p ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-body'))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/ul ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-list govuk-list--bullet'))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/ol ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-list govuk-list--number'))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/sl ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-list'))"/>
    </xsl:next-match>
  </xsl:template>

  <!-- ===== Links ===== -->

  <!-- topic/link is excluded: the base renders it as a list item, not an
       anchor; child/related links are styled in plugin.css instead.
       svgref is excluded: it specialises xref but renders as an img -->
  <xsl:template match="*[contains(@class, ' topic/xref ')][not(contains(@class, ' svg-d/svgref '))]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-link'))"/>
    </xsl:next-match>
  </xsl:template>

  <!-- ===== Tables (CALS and simpletable) ===== -->

  <xsl:template match="*[contains(@class, ' topic/table ')] | *[contains(@class, ' topic/simpletable ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-table'))"/>
    </xsl:next-match>
  </xsl:template>

  <!-- sthead is included because the base renders its attributes onto the
       generated header tr -->
  <xsl:template match="*[contains(@class, ' topic/row ')] | *[contains(@class, ' topic/strow ')] | *[contains(@class, ' topic/sthead ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' govuk-table__row'))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/entry ')] | *[contains(@class, ' topic/stentry ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:variable name="cell-class" select="if (ancestor::*[contains(@class, ' topic/thead ')] or
                                                parent::*[contains(@class, ' topic/sthead ')])
                                            then 'govuk-table__header'
                                            else 'govuk-table__cell'"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' ', $cell-class))"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/thead ')] | *[contains(@class, ' topic/tbody ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:variable name="section-class" select="if (contains(@class, ' topic/thead '))
                                               then 'govuk-table__head'
                                               else 'govuk-table__body'"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' ', $section-class))"/>
    </xsl:next-match>
  </xsl:template>

  <!-- The simpletable header wrapper carries no commonattributes in the base,
       so class the literal thead; the generated tr gets its row class through
       the sthead set-output-class template above -->
  <xsl:template match="*[contains(@class, ' topic/sthead ')]" name="topic.sthead">
    <thead class="govuk-table__head">
      <tr>
        <xsl:apply-templates select="." mode="table:common"/>
        <xsl:apply-templates/>
      </tr>
    </thead>
  </xsl:template>

  <!-- Captions: the base emits these without commonattributes, so override the
       caption markup itself -->
  <xsl:template match="*[contains(@class, ' topic/table ')]" mode="table:title">
    <xsl:if test="*[contains(@class, ' topic/title ')] | *[contains(@class, ' topic/desc ')]">
      <caption class="govuk-table__caption govuk-table__caption--m">
        <xsl:apply-templates select="*[contains(@class, ' topic/title ')]" mode="label"/>
        <xsl:apply-templates select="
          *[contains(@class, ' topic/title ')] | *[contains(@class, ' topic/desc ')]
        "/>
      </caption>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/simpletable ')]/*[contains(@class, ' topic/title ')]">
    <caption class="govuk-table__caption govuk-table__caption--m">
      <xsl:apply-templates select="." mode="label"/>
      <xsl:apply-templates/>
    </caption>
  </xsl:template>

  <!-- ===== Hazard statements (hazard-d): safety panel ===== -->

  <!-- hazardstatement specialises note but carries block structure, so it
       gets its own panel instead of the inset/warning treatment (which would
       wrap blocks in strong - invalid HTML). Banner label follows the note
       type; the message panel keeps hazard, consequence, and avoidance in
       reading order per the domain's model. -->
  <xsl:template match="*[contains(@class, ' hazard-d/hazardstatement ')]" priority="10">
    <xsl:variable name="hazard-type" as="xs:string"
                  select="lower-case(if (@type and @type ne 'other') then string(@type) else 'warning')"/>
    <div>
      <xsl:call-template name="commonattributes">
        <xsl:with-param name="default-output-class" select="'app-hazard'"/>
      </xsl:call-template>
      <xsl:call-template name="setid"/>
      <p class="app-hazard__banner">
        <span class="govuk-warning-text__icon app-hazard__icon" aria-hidden="true">!</span>
        <strong>
          <xsl:call-template name="getVariable">
            <xsl:with-param name="id"
                            select="concat(upper-case(substring($hazard-type, 1, 1)), substring($hazard-type, 2))"/>
          </xsl:call-template>
        </strong>
      </p>
      <div class="app-hazard__panel">
        <xsl:apply-templates select="*[contains(@class, ' hazard-d/hazardsymbol ')]"/>
        <xsl:for-each select="*[contains(@class, ' hazard-d/messagepanel ')]">
          <p class="app-hazard__hazard">
            <strong><xsl:apply-templates select="*[contains(@class, ' hazard-d/typeofhazard ')]/node()"/></strong>
          </p>
          <xsl:for-each select="*[contains(@class, ' hazard-d/consequence ')]">
            <p class="govuk-body"><xsl:apply-templates/></p>
          </xsl:for-each>
          <xsl:for-each select="*[contains(@class, ' hazard-d/howtoavoid ')]">
            <p class="govuk-body app-hazard__avoid"><xsl:apply-templates/></p>
          </xsl:for-each>
        </xsl:for-each>
      </div>
    </div>
  </xsl:template>

  <!-- ===== Choice tables (task): modern govuk-table markup ===== -->

  <!-- Replaces the inherited legacy renderer, which emits obsolete HTML4
       attributes (border/cellpadding/summary/frame/rules) -->
  <!-- Suppress the base's choicetableborder output-class; the govuk-table class
       comes from the inherited simpletable set-output-class mapping -->
  <xsl:template match="*[contains(@class, ' task/choicetable ')]" mode="get-output-class"/>

  <xsl:template match="*[contains(@class, ' task/choicetable ')]" priority="10">
    <table>
      <xsl:call-template name="commonattributes"/>
      <xsl:call-template name="setid"/>
      <thead class="govuk-table__head">
        <tr class="govuk-table__row">
          <xsl:choose>
            <xsl:when test="*[contains(@class, ' task/chhead ')]">
              <th scope="col" class="govuk-table__header">
                <xsl:apply-templates select="*[contains(@class, ' task/chhead ')]/*[contains(@class, ' task/choptionhd ')]/node()"/>
              </th>
              <th scope="col" class="govuk-table__header">
                <xsl:apply-templates select="*[contains(@class, ' task/chhead ')]/*[contains(@class, ' task/chdeschd ')]/node()"/>
              </th>
            </xsl:when>
            <xsl:otherwise>
              <th scope="col" class="govuk-table__header">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'Option'"/>
                </xsl:call-template>
              </th>
              <th scope="col" class="govuk-table__header">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'Description'"/>
                </xsl:call-template>
              </th>
            </xsl:otherwise>
          </xsl:choose>
        </tr>
      </thead>
      <tbody class="govuk-table__body">
        <xsl:for-each select="*[contains(@class, ' task/chrow ')]">
          <tr class="govuk-table__row">
            <th scope="row" class="govuk-table__header">
              <xsl:apply-templates select="*[contains(@class, ' task/choption ')]/node()"/>
            </th>
            <td class="govuk-table__cell">
              <xsl:apply-templates select="*[contains(@class, ' task/chdesc ')]/node()"/>
            </td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <!-- ===== Properties tables (reference): drop legacy table attributes ===== -->

  <!-- Mirrors the base reference.properties template minus the obsolete
       cellpadding/cellspacing/border attributes; row and cell rendering (and
       generated headers) stay inherited -->
  <xsl:template match="*[contains(@class, ' reference/properties ')]" name="reference.properties">
    <xsl:call-template name="spec-title"/>
    <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]" mode="out-of-line"/>
    <xsl:call-template name="setaname"/>
    <table>
      <xsl:call-template name="setid"/>
      <!-- ancestry supplies simpletable/properties; the simpletable
           set-output-class mapping appends govuk-table -->
      <xsl:call-template name="commonattributes"/>
      <xsl:apply-templates select="." mode="generate-table-summary-attribute"/>
      <xsl:call-template name="setscale"/>
      <xsl:call-template name="dita2html:simpletable-cols"
                         xmlns:dita2html="http://dita-ot.sourceforge.net/ns/200801/dita2html"/>
      <xsl:variable name="header" select="*[contains(@class, ' reference/prophead ')]"/>
      <xsl:variable name="properties" select="*[contains(@class, ' reference/property ')]"/>
      <xsl:variable name="hasType" select="exists($header/*[contains(@class, ' reference/proptypehd ')] | $properties/*[contains(@class, ' reference/proptype ')])"/>
      <xsl:variable name="hasValue" select="exists($header/*[contains(@class, ' reference/propvaluehd ')] | $properties/*[contains(@class, ' reference/propvalue ')])"/>
      <xsl:variable name="hasDesc" select="exists($header/*[contains(@class, ' reference/propdeschd ')] | $properties/*[contains(@class, ' reference/propdesc ')])"/>
      <xsl:variable name="prophead" as="element()">
        <xsl:choose>
          <xsl:when test="*[contains(@class, ' reference/prophead ')]">
            <xsl:sequence select="*[contains(@class, ' reference/prophead ')]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="gen" as="element(gen)?">
              <xsl:call-template name="gen-prophead">
                <xsl:with-param name="hasType" select="$hasType"/>
                <xsl:with-param name="hasValue" select="$hasValue"/>
                <xsl:with-param name="hasDesc" select="$hasDesc"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:sequence select="$gen/*"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:apply-templates select="$prophead">
        <xsl:with-param name="hasType" select="$hasType"/>
        <xsl:with-param name="hasValue" select="$hasValue"/>
        <xsl:with-param name="hasDesc" select="$hasDesc"/>
      </xsl:apply-templates>
      <tbody class="govuk-table__body">
        <xsl:apply-templates select="*[contains(@class, ' reference/property ')] | processing-instruction()">
          <xsl:with-param name="hasType" select="$hasType"/>
          <xsl:with-param name="hasValue" select="$hasValue"/>
          <xsl:with-param name="hasDesc" select="$hasDesc"/>
        </xsl:apply-templates>
      </tbody>
    </table>
    <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-endprop ')]" mode="out-of-line"/>
  </xsl:template>

  <!-- ===== SVG diagrams: img fallback ===== -->

  <!-- foreign.xsl inlines local SVG references (issue #37); this img rendering
       is the fallback it reaches by next-match for external/unresolvable refs.
       @alt is derived from the enclosing figure's title (empty when there is
       none, so the caption-less case reads as decorative) — issue #10, NFR-A1 -->
  <xsl:template match="*[contains(@class, ' svg-d/svgref ')]" name="topic.svg-d.svgref">
    <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]" mode="out-of-line"/>
    <img>
      <xsl:call-template name="commonattributes"/>
      <xsl:call-template name="setid"/>
      <xsl:apply-templates select="@href"/>
      <xsl:attribute name="alt"
                     select="normalize-space(string(ancestor::*[contains(@class, ' topic/fig ')][1]/*[contains(@class, ' topic/title ')][1]))"/>
    </img>
    <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-endprop ')]" mode="out-of-line"/>
    <xsl:if test="$ARTLBL = 'yes'"> [<xsl:value-of select="@href"/>] </xsl:if>
  </xsl:template>

  <!-- ===== Media object: accessible name from desc (#35 / NFR-A1) ===== -->

  <!-- The base emits <object> with no accessible name, which fails axe's
       object-alt (WCAG). Mirror the base template but expose the DITA <desc>
       as the object's aria-label. -->
  <xsl:template match="*[contains(@class, ' topic/object ')]" name="govuk-object">
    <object>
      <xsl:copy-of select="@id | @declare | @codebase | @type | @archive | @height
                            | @usemap | @tabindex | @classid | @data | @codetype
                            | @standby | @width | @name"/>
      <xsl:variable name="desc"
                    select="normalize-space(string(*[contains(@class, ' topic/desc ')][1]))"/>
      <xsl:if test="$desc ne ''">
        <xsl:attribute name="aria-label" select="$desc"/>
      </xsl:if>
      <xsl:apply-templates select="*[contains(@class, ' topic/param ')]"/>
      <xsl:if test="@longdescref or *[contains(@class, ' topic/longdescref ')]">
        <xsl:apply-templates select="." mode="ditamsg:longdescref-on-object"/>
      </xsl:if>
      <xsl:apply-templates select="node() except *[contains(@class, ' topic/param ')]"/>
    </object>
  </xsl:template>

  <!-- ===== Preformatted blocks: keyboard-scrollable (#35 / NFR-A1) ===== -->

  <!-- plugin.css gives pre blocks overflow-x:auto, which makes them a scrollable
       region; axe (scrollable-region-focusable) then requires keyboard access.
       Mirror the base topic.pre but add tabindex="0" so keyboard users can focus
       and scroll a wide code block. Covers codeblock/screen/msgblock (all pre). -->
  <xsl:template match="*[contains(@class, ' topic/pre ')]" name="topic.pre">
    <xsl:if test="contains(@frame, 'top')"><hr/></xsl:if>
    <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]" mode="out-of-line"/>
    <xsl:call-template name="spec-title-nospace"/>
    <pre tabindex="0">
      <xsl:call-template name="commonattributes"/>
      <xsl:call-template name="setscale"/>
      <xsl:call-template name="setidaname"/>
      <xsl:apply-templates/>
    </pre>
    <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-endprop ')]" mode="out-of-line"/>
    <xsl:if test="contains(@frame, 'bot')"><hr/></xsl:if>
  </xsl:template>

  <!-- ===== User-interface domain (ui-d): emphasise controls (#30) ===== -->

  <xsl:template match="*[contains(@class, ' ui-d/uicontrol ')]" mode="set-output-class">
    <xsl:param name="default"/>
    <xsl:next-match>
      <xsl:with-param name="default" select="normalize-space(concat($default, ' app-uicontrol'))"/>
    </xsl:next-match>
  </xsl:template>

  <!-- ===== Troubleshooting topic: label cause and remedy (#31) ===== -->

  <xsl:template match="*[contains(@class, ' troubleshooting/cause ')]">
    <section>
      <xsl:call-template name="commonattributes">
        <xsl:with-param name="default-output-class" select="'cause'"/>
      </xsl:call-template>
      <xsl:call-template name="setid"/>
      <h2 class="govuk-heading-s app-trouble-label">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.cause'"/>
        </xsl:call-template>
      </h2>
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' troubleshooting/remedy ')]">
    <section>
      <xsl:call-template name="commonattributes">
        <xsl:with-param name="default-output-class" select="'remedy'"/>
      </xsl:call-template>
      <xsl:call-template name="setid"/>
      <h2 class="govuk-heading-s app-trouble-label">
        <xsl:call-template name="getVariable">
          <xsl:with-param name="id" select="'govuk-dita.remedy'"/>
        </xsl:call-template>
      </h2>
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- ===== Notes: inset text or warning text (FR-R2) ===== -->

  <xsl:variable name="govuk-warning-note-types"
                select="('warning', 'caution', 'danger', 'important', 'attention', 'notice')"
                as="xs:string+"/>

  <xsl:template match="*[contains(@class, ' topic/note ')][not(contains(@class, ' hazard-d/hazardstatement '))]">
    <xsl:variable name="note-type" as="xs:string"
                  select="lower-case(if (@type and @type ne 'other') then string(@type) else 'note')"/>
    <xsl:choose>
      <xsl:when test="$note-type = $govuk-warning-note-types">
        <div>
          <xsl:call-template name="commonattributes">
            <xsl:with-param name="default-output-class" select="'govuk-warning-text'"/>
          </xsl:call-template>
          <xsl:call-template name="setid"/>
          <span class="govuk-warning-text__icon" aria-hidden="true">!</span>
          <strong class="govuk-warning-text__text">
            <span class="govuk-visually-hidden">
              <xsl:call-template name="getVariable">
                <xsl:with-param name="id"
                                select="concat(upper-case(substring($note-type, 1, 1)), substring($note-type, 2))"/>
              </xsl:call-template>
            </span>
            <xsl:apply-templates/>
          </strong>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <div>
          <xsl:call-template name="commonattributes">
            <xsl:with-param name="default-output-class" select="'govuk-inset-text'"/>
          </xsl:call-template>
          <xsl:call-template name="setid"/>
          <xsl:apply-templates/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

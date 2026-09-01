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
                version="3.0"
                exclude-result-prefixes="xs table">

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
       anchor; child/related links are styled in plugin.css instead -->
  <xsl:template match="*[contains(@class, ' topic/xref ')]" mode="set-output-class">
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

  <!-- ===== Notes: inset text or warning text (FR-R2) ===== -->

  <xsl:variable name="govuk-warning-note-types"
                select="('warning', 'caution', 'danger', 'important', 'attention', 'notice')"
                as="xs:string+"/>

  <xsl:template match="*[contains(@class, ' topic/note ')]">
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

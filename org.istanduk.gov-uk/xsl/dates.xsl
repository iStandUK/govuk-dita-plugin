<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Topic dates (#61): a topic's <critdates> rendered as a GOV.UK-style metadata
line — "Published <date>" from <created>, "Last updated <date>" from the last
<revised> — where the topic's prolog sits (after the short description, before
the body), with the date machine-readable in <time datetime>. Off by default:
many publications carry critdates for editorial tooling, and a date is only as
good as its source. govuk.dates = no | updated | both.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                version="3.0"
                exclude-result-prefixes="xs govuk">

  <xsl:param name="GOVUK-DATES" select="'no'"/>

  <!-- The ISO date part of a date or dateTime value, or '' when it is neither -->
  <xsl:function name="govuk:iso-date" as="xs:string">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:variable name="day" select="substring(normalize-space(string($value)), 1, 10)"/>
    <xsl:sequence select="if ($day castable as xs:date) then $day else ''"/>
  </xsl:function>

  <!-- 7 September 2026 for machine dates; anything else is shown as written -->
  <xsl:function name="govuk:date-text" as="xs:string">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:variable name="iso" select="govuk:iso-date($value)"/>
    <xsl:sequence select="if ($iso ne '') then format-date(xs:date($iso), '[D] [MNn] [Y]', 'en', (), ())
                          else normalize-space(string($value))"/>
  </xsl:function>

  <xsl:template name="govuk-date-item">
    <xsl:param name="label-id" as="xs:string"/>
    <xsl:param name="value" as="xs:string"/>
    <span class="app-page-dates__item">
      <xsl:call-template name="getVariable">
        <xsl:with-param name="id" select="$label-id"/>
      </xsl:call-template>
      <xsl:text> </xsl:text>
      <time>
        <xsl:if test="govuk:iso-date($value) ne ''">
          <xsl:attribute name="datetime" select="govuk:iso-date($value)"/>
        </xsl:if>
        <xsl:value-of select="govuk:date-text($value)"/>
      </time>
    </span>
  </xsl:template>

  <!-- The base drops the prolog; render its dates here when asked -->
  <xsl:template match="*[contains(@class, ' topic/prolog ')]" priority="5">
    <xsl:if test="$GOVUK-DATES = ('updated', 'both')">
      <xsl:variable name="critdates" select="*[contains(@class, ' topic/critdates ')]"/>
      <xsl:variable name="created" as="xs:string"
                    select="normalize-space(string(($critdates/*[contains(@class, ' topic/created ')]/@date)[1]))"/>
      <xsl:variable name="revised" as="xs:string"
                    select="normalize-space(string(($critdates/*[contains(@class, ' topic/revised ')]/@modified)[last()]))"/>
      <xsl:choose>
        <xsl:when test="$GOVUK-DATES = 'both' and ($created ne '' or $revised ne '')">
          <p class="govuk-body-s app-page-dates">
            <xsl:if test="$created ne ''">
              <xsl:call-template name="govuk-date-item">
                <xsl:with-param name="label-id" select="'govuk-dita.published'"/>
                <xsl:with-param name="value" select="$created"/>
              </xsl:call-template>
            </xsl:if>
            <xsl:if test="$revised ne ''">
              <xsl:call-template name="govuk-date-item">
                <xsl:with-param name="label-id" select="'govuk-dita.updated'"/>
                <xsl:with-param name="value" select="$revised"/>
              </xsl:call-template>
            </xsl:if>
          </p>
        </xsl:when>
        <xsl:when test="$GOVUK-DATES = 'updated' and ($revised ne '' or $created ne '')">
          <p class="govuk-body-s app-page-dates">
            <xsl:call-template name="govuk-date-item">
              <xsl:with-param name="label-id" select="if ($revised ne '') then 'govuk-dita.updated' else 'govuk-dita.published'"/>
              <xsl:with-param name="value" select="if ($revised ne '') then $revised else $created"/>
            </xsl:call-template>
          </p>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

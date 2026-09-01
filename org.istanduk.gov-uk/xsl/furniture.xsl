<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Shared page furniture: the masthead (with the header search field, following
GOV.UK's header-search pattern) and the footer (with glossary/index as
support links per the Design System's footer guidance). Used by the topic
template, the cover, and the generated utility pages.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="3.0"
                exclude-result-prefixes="xs">

  <xsl:template name="govuk-masthead">
    <xsl:param name="prefix" as="xs:string" select="''"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="home-href" as="xs:string"/>
    <xsl:param name="search-enabled" as="xs:string" select="'no'"/>
    <xsl:param name="branding" as="xs:string" select="'neutral'"/>
    <header class="app-masthead">
      <div class="govuk-width-container app-masthead__row">
        <a class="app-masthead__title" href="{$home-href}">
          <xsl:if test="$branding = 'istanduk'">
            <img class="app-masthead__logo"
                 src="{concat($prefix, 'govuk/istanduk-logo.svg')}" alt="iStandUK"/>
          </xsl:if>
          <xsl:value-of select="$name"/>
        </a>
        <xsl:if test="$search-enabled = 'yes'">
          <form class="app-masthead__search" role="search" method="get"
                action="{concat($prefix, 'search.html')}">
            <label class="govuk-visually-hidden" for="app-masthead-search">
              <xsl:call-template name="getVariable">
                <xsl:with-param name="id" select="'govuk-dita.search-this-site'"/>
              </xsl:call-template>
            </label>
            <input class="app-masthead__search-input" id="app-masthead-search"
                   name="q" type="search"/>
            <button class="app-masthead__search-button" type="submit">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"
                   viewBox="0 0 20 20" aria-hidden="true" focusable="false">
                <circle cx="8" cy="8" r="6" fill="none" stroke="currentColor" stroke-width="2.5"/>
                <line x1="12.5" y1="12.5" x2="19" y2="19" stroke="currentColor" stroke-width="2.5"/>
              </svg>
              <span class="govuk-visually-hidden">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.search'"/>
                </xsl:call-template>
              </span>
            </button>
          </form>
        </xsl:if>
      </div>
    </header>
  </xsl:template>

  <xsl:template name="govuk-site-footer">
    <xsl:param name="prefix" as="xs:string" select="''"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="glossary" as="xs:string" select="'no'"/>
    <xsl:param name="index" as="xs:string" select="'no'"/>
    <footer class="govuk-footer">
      <div class="govuk-width-container">
        <div class="govuk-footer__meta">
          <div class="govuk-footer__meta-item govuk-footer__meta-item--grow">
            <xsl:if test="$glossary = 'yes' or $index = 'yes'">
              <h2 class="govuk-visually-hidden">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.support-links'"/>
                </xsl:call-template>
              </h2>
              <ul class="govuk-footer__inline-list">
                <xsl:if test="$glossary = 'yes'">
                  <li class="govuk-footer__inline-list-item">
                    <a class="govuk-footer__link" href="{concat($prefix, 'glossary.html')}">
                      <xsl:call-template name="getVariable">
                        <xsl:with-param name="id" select="'govuk-dita.glossary'"/>
                      </xsl:call-template>
                    </a>
                  </li>
                </xsl:if>
                <xsl:if test="$index = 'yes'">
                  <li class="govuk-footer__inline-list-item">
                    <a class="govuk-footer__link" href="{concat($prefix, 'index-page.html')}">
                      <xsl:call-template name="getVariable">
                        <xsl:with-param name="id" select="'govuk-dita.index'"/>
                      </xsl:call-template>
                    </a>
                  </li>
                </xsl:if>
              </ul>
            </xsl:if>
            <span class="govuk-footer__licence-description">
              <xsl:value-of select="$name"/>
            </span>
          </div>
        </div>
      </div>
    </footer>
  </xsl:template>

</xsl:stylesheet>

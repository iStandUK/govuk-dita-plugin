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

  <!-- ===== Footer metadata from bookmap bookmeta (#42) =====
       Read from the input map's own URL so topic pages get the copyright and
       attribution too, not just the cover (which already sees the map as its
       context). A plain map, or a bookmap without bookrights, simply yields no
       copyright/attribution and the footer keeps the service name. -->
  <!-- On a topic page the principal document is the topic, so the map comes from
       its URL; on the generated cover and utility pages the principal document is
       the map itself, where that URL is not set — fall back to the context root. -->
  <xsl:variable name="govuk-book" as="element()?"
                select="((if (exists($input.map.url) and normalize-space($input.map.url))
                          then document($input.map.url)/*[contains(@class, ' map/map ')]
                          else ()),
                         /*[contains(@class, ' map/map ')])[1]"/>
  <xsl:variable name="govuk-bookmeta" as="element()?"
                select="$govuk-book/*[contains(@class, ' bookmap/bookmeta ')]"/>

  <!-- Copyright owner: the organization or person named in bookrights/bookowner -->
  <xsl:variable name="govuk-copyr-owner" as="xs:string"
                select="normalize-space(string((
                          $govuk-bookmeta//*[contains(@class, ' bookmap/bookowner ')]
                            //*[contains(@class, ' bookmap/organization ')
                                or contains(@class, ' topic/author ')])[1]))"/>
  <xsl:variable name="govuk-copyr-first" as="xs:string"
                select="normalize-space(string($govuk-bookmeta//*[contains(@class, ' bookmap/copyrfirst ')][1]))"/>
  <xsl:variable name="govuk-copyr-last" as="xs:string"
                select="normalize-space(string($govuk-bookmeta//*[contains(@class, ' bookmap/copyrlast ')][1]))"/>
  <xsl:variable name="govuk-copyr-years" as="xs:string"
                select="if ($govuk-copyr-first ne '' and $govuk-copyr-last ne '' and $govuk-copyr-first ne $govuk-copyr-last)
                        then concat($govuk-copyr-first, '&#8211;', $govuk-copyr-last)
                        else if ($govuk-copyr-first ne '') then $govuk-copyr-first
                        else $govuk-copyr-last"/>

  <!-- Publisher(s), then any author(s) other than the copyright owner -->
  <xsl:variable name="govuk-publishers" as="xs:string*"
                select="distinct-values($govuk-bookmeta
                          //*[contains(@class, ' bookmap/publisherinformation ')]
                          //*[contains(@class, ' bookmap/organization ')
                              or contains(@class, ' topic/author ')]
                          /normalize-space()[. ne ''])"/>
  <xsl:variable name="govuk-authors" as="xs:string*"
                select="distinct-values($govuk-bookmeta
                          /*[contains(@class, ' topic/author ')]
                          /normalize-space()[. ne ''][. ne $govuk-copyr-owner])"/>

  <xsl:template name="govuk-masthead">
    <xsl:param name="prefix" as="xs:string" select="''"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="home-href" as="xs:string"/>
    <xsl:param name="search-enabled" as="xs:string" select="'no'"/>
    <xsl:param name="branding" as="xs:string" select="'neutral'"/>
    <header class="app-masthead{if ($branding = 'nhs') then ' app-masthead--nhs' else ''}">
      <div class="govuk-width-container app-masthead__row">
        <a class="app-masthead__title" href="{$home-href}">
          <xsl:if test="$branding = 'istanduk'">
            <img class="app-masthead__logo"
                 src="{concat($prefix, 'govuk/istanduk-logo.svg')}" alt="iStandUK"/>
          </xsl:if>
          <xsl:if test="$branding = 'nhs'">
            <!-- NHS logo (nhsuk-frontend, MIT). currentColor lets the overlay
                 render the blue lozenge with the "NHS" letters cut through to the
                 white header. The NHS identity is restricted to NHS organisations
                 (build-log warning; see the manual). -->
            <svg class="app-masthead__nhs-logo" xmlns="http://www.w3.org/2000/svg"
                 viewBox="0 0 200 80" height="32" width="80" focusable="false"
                 role="img" aria-label="NHS">
              <path fill="currentColor" d="M200 0v80H0V0h200Zm-27.5 5.5c-14.5 0-29 5-29 22 0 10.2 7.7 13.5 14.7 16.3l.7.3c5.4 2 10.1 3.9 10.1 8.4 0 6.5-8.5 7.5-14 7.5s-12.5-1.5-16-3.5L135 70c5.5 2 13.5 3.5 20 3.5 15.5 0 32-4.5 32-22.5 0-19.5-25.5-16.5-25.5-25.5 0-5.5 5.5-6.5 12.5-6.5a35 35 0 0 1 14.5 3l4-13.5c-4.5-2-12-3-20-3Zm-131 2h-22l-14 65H22l9-45h.5l13.5 45h21.5l14-65H64l-9 45h-.5l-13-45Zm63 0h-18l-13 65h17l6-28H117l-5.5 28H129l13.5-65H125L119.5 32h-20l5-24.5Z"/>
            </svg>
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
    <xsl:param name="figurelist" as="xs:string" select="'no'"/>
    <xsl:param name="tablelist" as="xs:string" select="'no'"/>
    <footer class="govuk-footer">
      <div class="govuk-width-container">
        <div class="govuk-footer__meta">
          <div class="govuk-footer__meta-item govuk-footer__meta-item--grow">
            <xsl:if test="$glossary = 'yes' or $index = 'yes' or $figurelist = 'yes' or $tablelist = 'yes'">
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
                <xsl:if test="$figurelist = 'yes'">
                  <li class="govuk-footer__inline-list-item">
                    <a class="govuk-footer__link" href="{concat($prefix, 'figurelist.html')}">
                      <xsl:call-template name="getVariable">
                        <xsl:with-param name="id" select="'govuk-dita.figures'"/>
                      </xsl:call-template>
                    </a>
                  </li>
                </xsl:if>
                <xsl:if test="$tablelist = 'yes'">
                  <li class="govuk-footer__inline-list-item">
                    <a class="govuk-footer__link" href="{concat($prefix, 'tablelist.html')}">
                      <xsl:call-template name="getVariable">
                        <xsl:with-param name="id" select="'govuk-dita.tables'"/>
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
              <xsl:choose>
                <xsl:when test="$govuk-copyr-owner ne ''">
                  <xsl:call-template name="getVariable">
                    <xsl:with-param name="id" select="'govuk-dita.copyright'"/>
                  </xsl:call-template>
                  <xsl:text> </xsl:text>
                  <xsl:if test="$govuk-copyr-years ne ''">
                    <xsl:value-of select="$govuk-copyr-years"/><xsl:text> </xsl:text>
                  </xsl:if>
                  <xsl:value-of select="$govuk-copyr-owner"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$name"/>
                </xsl:otherwise>
              </xsl:choose>
            </span>
            <xsl:if test="exists($govuk-publishers) or exists($govuk-authors)">
              <span class="app-footer__attribution">
                <xsl:choose>
                  <xsl:when test="exists($govuk-publishers)">
                    <xsl:call-template name="getVariable">
                      <xsl:with-param name="id" select="'govuk-dita.published-by'"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="string-join($govuk-publishers, ' · ')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="getVariable">
                      <xsl:with-param name="id" select="'govuk-dita.authored-by'"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="string-join($govuk-authors, ' · ')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </span>
            </xsl:if>
          </div>
        </div>
      </div>
    </footer>
  </xsl:template>

</xsl:stylesheet>

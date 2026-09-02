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
          <xsl:if test="$branding = 'official'">
            <!-- GOV.UK logo (crown + wordmark) from govuk-frontend. The crown is
                 Crown copyright, restricted to genuine GOV.UK services; the build
                 warns, and this renders only under branding=official. -->
            <svg class="app-masthead__govuk-logo" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 324 60" height="30" width="162" fill="currentcolor" focusable="false" role="img" aria-label="GOV.UK">
              <title>GOV.UK</title>
              <g>
                  <circle cx="20" cy="17.6" r="3.7"/>
                  <circle cx="10.2" cy="23.5" r="3.7"/>
                  <circle cx="3.7" cy="33.2" r="3.7"/>
                  <circle cx="31.7" cy="30.6" r="3.7"/>
                  <circle cx="43.3" cy="17.6" r="3.7"/>
                  <circle cx="53.2" cy="23.5" r="3.7"/>
                  <circle cx="59.7" cy="33.2" r="3.7"/>
                  <circle cx="31.7" cy="30.6" r="3.7"/>
                  <path d="M33.1,9.8c.2-.1.3-.3.5-.5l4.6,2.4v-6.8l-4.6,1.5c-.1-.2-.3-.3-.5-.5l1.9-5.9h-6.7l1.9,5.9c-.2.1-.3.3-.5.5l-4.6-1.5v6.8l4.6-2.4c.1.2.3.3.5.5l-2.6,8c-.9,2.8,1.2,5.7,4.1,5.7h0c3,0,5.1-2.9,4.1-5.7l-2.6-8ZM37,37.9s-3.4,3.8-4.1,6.1c2.2,0,4.2-.5,6.4-2.8l-.7,8.5c-2-2.8-4.4-4.1-5.7-3.8.1,3.1.5,6.7,5.8,7.2,3.7.3,6.7-1.5,7-3.8.4-2.6-2-4.3-3.7-1.6-1.4-4.5,2.4-6.1,4.9-3.2-1.9-4.5-1.8-7.7,2.4-10.9,3,4,2.6,7.3-1.2,11.1,2.4-1.3,6.2,0,4,4.6-1.2-2.8-3.7-2.2-4.2.2-.3,1.7.7,3.7,3,4.2,1.9.3,4.7-.9,7-5.9-1.3,0-2.4.7-3.9,1.7l2.4-8c.6,2.3,1.4,3.7,2.2,4.5.6-1.6.5-2.8,0-5.3l5,1.8c-2.6,3.6-5.2,8.7-7.3,17.5-7.4-1.1-15.7-1.7-24.5-1.7h0c-8.8,0-17.1.6-24.5,1.7-2.1-8.9-4.7-13.9-7.3-17.5l5-1.8c-.5,2.5-.6,3.7,0,5.3.8-.8,1.6-2.3,2.2-4.5l2.4,8c-1.5-1-2.6-1.7-3.9-1.7,2.3,5,5.2,6.2,7,5.9,2.3-.4,3.3-2.4,3-4.2-.5-2.4-3-3.1-4.2-.2-2.2-4.6,1.6-6,4-4.6-3.7-3.7-4.2-7.1-1.2-11.1,4.2,3.2,4.3,6.4,2.4,10.9,2.5-2.8,6.3-1.3,4.9,3.2-1.8-2.7-4.1-1-3.7,1.6.3,2.3,3.3,4.1,7,3.8,5.4-.5,5.7-4.2,5.8-7.2-1.3-.2-3.7,1-5.7,3.8l-.7-8.5c2.2,2.3,4.2,2.7,6.4,2.8-.7-2.3-4.1-6.1-4.1-6.1h10.6,0Z"/>
                </g>
              <circle class="govuk-logo-dot" cx="226" cy="36" r="7.3"/>
                <path d="M93.94 41.25c.4 1.81 1.2 3.21 2.21 4.62 1 1.4 2.21 2.41 3.61 3.21s3.21 1.2 5.22 1.2 3.61-.4 4.82-1c1.4-.6 2.41-1.4 3.21-2.41.8-1 1.4-2.01 1.61-3.01s.4-2.01.4-3.01v.14h-10.86v-7.02h20.07v24.08h-8.03v-5.56c-.6.8-1.38 1.61-2.19 2.41-.8.8-1.81 1.2-2.81 1.81-1 .4-2.21.8-3.41 1.2s-2.41.4-3.81.4a18.56 18.56 0 0 1-14.65-6.63c-1.6-2.01-3.01-4.41-3.81-7.02s-1.4-5.62-1.4-8.83.4-6.02 1.4-8.83a20.45 20.45 0 0 1 19.46-13.65c3.21 0 4.01.2 5.82.8 1.81.4 3.61 1.2 5.02 2.01 1.61.8 2.81 2.01 4.01 3.21s2.21 2.61 2.81 4.21l-7.63 4.41c-.4-1-1-1.81-1.61-2.61-.6-.8-1.4-1.4-2.21-2.01-.8-.6-1.81-1-2.81-1.4-1-.4-2.21-.4-3.61-.4-2.01 0-3.81.4-5.22 1.2-1.4.8-2.61 1.81-3.61 3.21s-1.61 2.81-2.21 4.62c-.4 1.81-.6 3.71-.6 5.42s.8 5.22.8 5.22Zm57.8-27.9c3.21 0 6.22.6 8.63 1.81 2.41 1.2 4.82 2.81 6.62 4.82S170.2 24.39 171 27s1.4 5.62 1.4 8.83-.4 6.02-1.4 8.83-2.41 5.02-4.01 7.02-4.01 3.61-6.62 4.82-5.42 1.81-8.63 1.81-6.22-.6-8.63-1.81-4.82-2.81-6.42-4.82-3.21-4.41-4.01-7.02-1.4-5.62-1.4-8.83.4-6.02 1.4-8.83 2.41-5.02 4.01-7.02 4.01-3.61 6.42-4.82 5.42-1.81 8.63-1.81Zm0 36.73c1.81 0 3.61-.4 5.02-1s2.61-1.81 3.61-3.01 1.81-2.81 2.21-4.41c.4-1.81.8-3.61.8-5.62 0-2.21-.2-4.21-.8-6.02s-1.2-3.21-2.21-4.62c-1-1.2-2.21-2.21-3.61-3.01s-3.21-1-5.02-1-3.61.4-5.02 1c-1.4.8-2.61 1.81-3.61 3.01s-1.81 2.81-2.21 4.62c-.4 1.81-.8 3.61-.8 5.62 0 2.41.2 4.21.8 6.02.4 1.81 1.2 3.21 2.21 4.41s2.21 2.21 3.61 3.01c1.4.8 3.21 1 5.02 1Zm36.32 7.96-12.24-44.15h9.83l8.43 32.77h.4l8.23-32.77h9.83L200.3 58.04h-12.24Zm74.14-7.96c2.18 0 3.51-.6 3.51-.6 1.2-.6 2.01-1 2.81-1.81s1.4-1.81 1.81-2.81a13 13 0 0 0 .8-4.01V13.9h8.63v28.15c0 2.41-.4 4.62-1.4 6.62-.8 2.01-2.21 3.61-3.61 5.02s-3.41 2.41-5.62 3.21-4.62 1.2-7.02 1.2-5.02-.4-7.02-1.2c-2.21-.8-4.01-1.81-5.62-3.21s-2.81-3.01-3.61-5.02-1.4-4.21-1.4-6.62V13.9h8.63v26.95c0 1.61.2 3.01.8 4.01.4 1.2 1.2 2.21 2.01 2.81.8.8 1.81 1.4 2.81 1.81 0 0 1.34.6 3.51.6Zm34.22-36.18v18.92l15.65-18.92h10.82l-15.03 17.32 16.03 26.83h-10.21l-11.44-20.21-5.62 6.22v13.99h-8.83V13.9"/>
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

  <!-- GOV.UK phase banner (FR-T3, #49). Rendered above the content when
       govuk.phase is set; the tag text is the phase value, with an optional
       feedback link from govuk.feedback.url. Brand-agnostic. -->
  <xsl:template name="govuk-phase-banner">
    <xsl:param name="phase" as="xs:string" select="''"/>
    <xsl:param name="feedback" as="xs:string" select="''"/>
    <xsl:if test="normalize-space($phase)">
      <div class="govuk-phase-banner">
        <p class="govuk-phase-banner__content">
          <strong class="govuk-tag govuk-phase-banner__content__tag">
            <xsl:value-of select="concat(upper-case(substring(normalize-space($phase), 1, 1)),
                                          substring(normalize-space($phase), 2))"/>
          </strong>
          <span class="govuk-phase-banner__text">
            <xsl:choose>
              <xsl:when test="normalize-space($feedback)">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.phase-prefix'"/>
                </xsl:call-template>
                <a class="govuk-link" href="{$feedback}">
                  <xsl:call-template name="getVariable">
                    <xsl:with-param name="id" select="'govuk-dita.phase-feedback'"/>
                  </xsl:call-template>
                </a>
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.phase-suffix'"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.phase-plain'"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </span>
        </p>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="govuk-site-footer">
    <xsl:param name="prefix" as="xs:string" select="''"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="glossary" as="xs:string" select="'no'"/>
    <xsl:param name="index" as="xs:string" select="'no'"/>
    <xsl:param name="figurelist" as="xs:string" select="'no'"/>
    <xsl:param name="tablelist" as="xs:string" select="'no'"/>
    <xsl:param name="branding" as="xs:string" select="'neutral'"/>
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
            <xsl:choose>
              <xsl:when test="$branding = 'official'">
                <!-- Open Government Licence + Crown copyright, per the GOV.UK footer.
                     The OGL logo is inline; the crown crest (a CSS mask to an
                     absolute-path asset upstream) is suppressed in overlay-official.css
                     so no restricted image is shipped. -->
                <svg class="govuk-footer__licence-logo" xmlns="http://www.w3.org/2000/svg"
                     viewBox="0 0 483.2 195.7" height="17" width="41" focusable="false"
                     aria-hidden="true">
                  <path fill="currentColor" d="M421.5 142.8V.1l-50.7 32.3v161.1h112.4v-50.7zm-122.3-9.6A47.12 47.12 0 0 1 221 97.8c0-26 21.1-47.1 47.1-47.1 16.7 0 31.4 8.7 39.7 21.8l42.7-27.2A97.63 97.63 0 0 0 268.1 0c-36.5 0-68.3 20.1-85.1 49.7A98 98 0 0 0 97.8 0C43.9 0 0 43.9 0 97.8s43.9 97.8 97.8 97.8c36.5 0 68.3-20.1 85.1-49.7a97.76 97.76 0 0 0 149.6 25.4l19.4 22.2h3v-87.8h-80l24.3 27.5zM97.8 145c-26 0-47.1-21.1-47.1-47.1s21.1-47.1 47.1-47.1 47.2 21 47.2 47S123.8 145 97.8 145"/>
                </svg>
                <span class="govuk-footer__licence-description">
                  <xsl:call-template name="getVariable">
                    <xsl:with-param name="id" select="'govuk-dita.ogl-prefix'"/>
                  </xsl:call-template>
                  <a class="govuk-footer__link" rel="license"
                     href="https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/">
                    <xsl:call-template name="getVariable">
                      <xsl:with-param name="id" select="'govuk-dita.ogl-name'"/>
                    </xsl:call-template>
                  </a>
                  <xsl:call-template name="getVariable">
                    <xsl:with-param name="id" select="'govuk-dita.ogl-suffix'"/>
                  </xsl:call-template>
                </span>
              </xsl:when>
              <xsl:otherwise>
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
              </xsl:otherwise>
            </xsl:choose>
          </div>
          <xsl:if test="$branding = 'official'">
            <div class="govuk-footer__meta-item">
              <a class="govuk-footer__link govuk-footer__copyright-logo"
                 href="https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/">
                <xsl:call-template name="getVariable">
                  <xsl:with-param name="id" select="'govuk-dita.crown-copyright'"/>
                </xsl:call-template>
              </a>
            </div>
          </xsl:if>
        </div>
      </div>
    </footer>
  </xsl:template>

</xsl:stylesheet>

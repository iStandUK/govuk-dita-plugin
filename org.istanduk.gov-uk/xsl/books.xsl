<?xml version="1.0" encoding="UTF-8"?>
<!--
This file is part of the govuk-dita-plugin project.
Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.

Several books from one map (#178). Applied to the merged map once the pages
are written. DITA-OT merges a referenced bookmap into the map that references
it and drops its booktitle and bookmeta, but every element it brings in keeps
@xtrf, the file it came from; so the books are found again by grouping the
top-level entries on that. The books are:

  - in a map, each referenced bookmap: always;
  - in a bookmap, each part, when GOVUK-PRINT-BOOKS is 'parts'.

For each book this writes, beside the merged map:

  govuk-book-ID.ditamap   a bookmap of the book alone, which the unchanged
                          print transform makes into print-ID.html. A
                          bookmap's book keeps its own title and metadata; a
                          part's takes the part's title and copies the
                          publisher information from the bookmap.
  govuk-book-ID.pages     its pages, one per line, for the footer links.

and, as the main output, govuk-books.xml listing the books for the home
page, and govuk-books-build.xml, an Ant file with one govuk-book step per
book (PDF, size, links), since Ant has no loop. Nothing is written when the
map holds no books.
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:govuk="https://github.com/iStandUK/govuk-dita-plugin"
                exclude-result-prefixes="xs govuk">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:param name="GOVUK-PRINT-BOOKS" select="'whole'"/>
  <xsl:param name="OUTEXT" select="'.html'"/>
  <!-- the whole publication's PDF name, without .pdf; a book's PDF adds -ID -->
  <xsl:param name="GOVUK-PDF-BASE" select="''"/>
  <xsl:param name="GOVUK-PRINT-MAX-TOPICS" select="'500'"/>

  <xsl:variable name="root" select="/*"/>
  <xsl:variable name="base" select="base-uri(/*)"/>
  <xsl:variable name="max" as="xs:integer"
                select="if ($GOVUK-PRINT-MAX-TOPICS castable as xs:integer) then xs:integer($GOVUK-PRINT-MAX-TOPICS) else 500"/>

  <!-- ===== Labels, from the plugin's string registry ===== -->

  <xsl:variable name="lang" select="lower-case(string(($root/@xml:lang, 'en')[1]))"/>
  <xsl:variable name="strings" as="document-node()">
    <xsl:variable name="list" select="doc(resolve-uri('../strings/strings.xml', static-base-uri()))"/>
    <xsl:variable name="file" select="string(($list//lang[@xml:lang = $lang]/@filename,
                                              $list//lang[@xml:lang = substring-before(concat($lang, '-'), '-')]/@filename,
                                              $list//lang[@xml:lang = '']/@filename)[1])"/>
    <xsl:sequence select="doc(resolve-uri(concat('../strings/', $file), static-base-uri()))"/>
  </xsl:variable>
  <xsl:function name="govuk:string" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:sequence select="string(($strings//variable[@id = $id])[1])"/>
  </xsl:function>

  <!-- ===== The books ===== -->

  <xsl:variable name="tops" as="element()*"
                select="$root/*[contains(@class, ' map/topicref ')]"/>

  <!-- book elements: <govuk:book id title kind="bookmap|part"> holding the
       top-level entries that make it, and (for a bookmap) its source root -->
  <xsl:variable name="books" as="element(govuk:book)*">
    <xsl:variable name="found" as="element(govuk:book)*">
      <xsl:choose>
        <!-- a map whose entries come from bookmaps it references -->
        <xsl:when test="not(contains($root/@class, ' bookmap/bookmap '))">
          <xsl:for-each-group select="$tops[@xtrf][@xtrf ne $root/@xtrf]" group-by="string(@xtrf)">
            <xsl:variable name="source" select="if (doc-available(current-grouping-key())) then doc(current-grouping-key())/* else ()"/>
            <xsl:if test="$source[contains(@class, ' bookmap/bookmap ')]">
              <govuk:book kind="bookmap" key="{$source/@id}"
                          title="{normalize-space(string(($source/*[contains(@class, ' bookmap/booktitle ')]
                                                             /*[contains(@class, ' bookmap/mainbooktitle ')],
                                                           $source/*[contains(@class, ' topic/title ')])[1]))}"
                          lang="{($source/@xml:lang, $root/@xml:lang)[1]}">
                <xsl:sequence select="$source/*[contains(@class, ' bookmap/booktitle ')],
                                      $source/*[contains(@class, ' bookmap/bookmeta ')]"/>
                <govuk:refs><xsl:sequence select="current-group()"/></govuk:refs>
              </govuk:book>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:when>
        <!-- a bookmap's parts, when they are to be books -->
        <xsl:when test="$GOVUK-PRINT-BOOKS = 'parts'">
          <xsl:for-each select="$tops[contains(@class, ' bookmap/part ')]">
            <govuk:book kind="part" key="{@id}" title="{govuk:part-title(.)}" lang="{$root/@xml:lang}">
              <xsl:sequence select="$root/*[contains(@class, ' bookmap/bookmeta ')]"/>
              <govuk:refs>
                <!-- the part's own topic, if it has one, comes first; then its chapters -->
                <xsl:if test="normalize-space(@href)">
                  <xsl:copy>
                    <xsl:copy-of select="@* except (@class, @id)"/>
                    <xsl:attribute name="class" select="'- map/topicref '"/>
                    <xsl:copy-of select="*[contains(@class, ' map/topicmeta ')]"/>
                  </xsl:copy>
                </xsl:if>
                <xsl:sequence select="*[contains(@class, ' map/topicref ')]"/>
              </govuk:refs>
            </govuk:book>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <!-- ids: the bookmap's or part's own, made safe for a file name, else its
         position; never repeated -->
    <xsl:for-each select="$found">
      <xsl:variable name="n" select="position()"/>
      <xsl:variable name="own" select="replace(string(@key), '[^A-Za-z0-9_-]', '-')"/>
      <xsl:variable name="id" select="if ($own ne '' and count($found[replace(string(@key), '[^A-Za-z0-9_-]', '-') = $own]) eq 1)
                                      then $own else concat('book-', $n)"/>
      <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:attribute name="id" select="$id"/>
        <xsl:copy-of select="node()"/>
      </xsl:copy>
    </xsl:for-each>
  </xsl:variable>

  <xsl:function name="govuk:part-title" as="xs:string">
    <xsl:param name="part" as="element()"/>
    <xsl:variable name="nav" select="normalize-space(string(($part/*[contains(@class, ' map/topicmeta ')]
                                                             /*[contains(@class, ' topic/navtitle ')],
                                                            $part/@navtitle)[1]))"/>
    <xsl:variable name="uri" select="if (normalize-space($part/@href)) then resolve-uri(replace($part/@href, '#.*$', ''), $base) else ''"/>
    <xsl:sequence select="if ($nav ne '') then $nav
                          else if ($uri ne '' and doc-available($uri))
                          then normalize-space(string((doc($uri)//*[contains(@class, ' topic/topic ')])[1]
                                                      /*[contains(@class, ' topic/title ')]))
                          else ''"/>
  </xsl:function>

  <!-- as furniture.xsl: the file a topicref renders, and its page -->
  <xsl:function name="govuk:file" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="replace(string(if (normalize-space($ref/@copy-to)) then $ref/@copy-to else $ref/@href), '#.*$', '')"/>
  </xsl:function>
  <!-- every navigable local DITA topicref, as govuk:print-topicrefs counts them -->
  <xsl:function name="govuk:printable" as="element()*">
    <xsl:param name="refs" as="element()*"/>
    <xsl:sequence select="$refs/descendant-or-self::*[contains(@class, ' map/topicref ')]
                          [normalize-space(@href)][not(@scope = 'external')]
                          [not(@format) or @format = 'dita']
                          [not(ancestor-or-self::*[contains(@class, ' map/topicref ')]
                                                  [@processing-role = 'resource-only' or @toc = 'no'])]"/>
  </xsl:function>

  <!-- HTML text, then made safe for an Ant replaceregexp replacement -->
  <xsl:function name="govuk:html" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="replace(replace(replace($s, '&amp;', '&amp;amp;'), '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
  </xsl:function>
  <xsl:function name="govuk:regex-safe" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="replace(replace($s, '\\', '\\\\'), '\$', '\\\$')"/>
  </xsl:function>

  <!-- ===== Output ===== -->

  <xsl:template match="/">
    <xsl:if test="exists($books)">
      <xsl:for-each select="$books">
        <xsl:variable name="book" select="."/>
        <!-- the book as a bookmap of its own, beside the merged map so its
             references resolve as before -->
        <xsl:result-document href="{resolve-uri(concat('govuk-book-', @id, '.ditamap'), $base)}" method="xml" indent="no">
          <xsl:element name="{name($root)}" namespace="{namespace-uri($root)}">
            <xsl:copy-of select="$root/@* except ($root/@id, $root/@class, $root/@xml:lang)"/>
            <xsl:attribute name="id" select="@id"/>
            <xsl:attribute name="class" select="'- map/map bookmap/bookmap '"/>
            <xsl:attribute name="xml:lang" select="@lang"/>
            <xsl:attribute name="govuk-book" select="@id"/>
            <xsl:choose>
              <xsl:when test="@kind = 'bookmap'">
                <xsl:copy-of select="*[contains(@class, ' bookmap/booktitle ')]"/>
              </xsl:when>
              <xsl:otherwise>
                <booktitle class="- topic/title bookmap/booktitle ">
                  <mainbooktitle class="- topic/ph bookmap/mainbooktitle "><xsl:value-of select="@title"/></mainbooktitle>
                </booktitle>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="*[contains(@class, ' bookmap/bookmeta ')]"/>
            <xsl:copy-of select="govuk:refs/*"/>
          </xsl:element>
        </xsl:result-document>
        <xsl:result-document href="{resolve-uri(concat('govuk-book-', @id, '.pages'), $base)}" method="text">
          <xsl:value-of select="distinct-values(for $r in govuk:printable(govuk:refs/*)
                                                return concat(replace(govuk:file($r), '\.[^./]*$', ''), $OUTEXT))"
                        separator="&#10;"/>
          <xsl:text>&#10;</xsl:text>
        </xsl:result-document>
      </xsl:for-each>
      <!-- one govuk-book step per book, run by the govuk.books.finish target -->
      <xsl:result-document href="{resolve-uri('govuk-books-build.xml', $base)}" method="xml" indent="yes">
        <project name="govuk-books" default="books">
          <import file="${{dita.plugin.org.istanduk.gov-uk.dir}}/build_govuk_books.xml"/>
          <target name="books">
            <xsl:for-each select="$books">
              <govuk-book id="{@id}"
                          print="print-{@id}.html"
                          pdf="{if ($GOVUK-PDF-BASE ne '') then concat($GOVUK-PDF-BASE, '-', @id, '.pdf') else ''}"
                          pages="govuk-book-{@id}.pages"
                          print-label="{govuk:regex-safe(govuk:html(concat(@title, ' ', govuk:string('govuk-dita.book-print-suffix'))))}"
                          pdf-prefix="{govuk:regex-safe(govuk:html(concat(@title, ' ', govuk:string('govuk-dita.book-pdf-prefix'))))}"
                          pdf-suffix="{govuk:regex-safe(govuk:html(govuk:string('govuk-dita.pdf-version-suffix')))}"/>
            </xsl:for-each>
          </target>
        </project>
      </xsl:result-document>
      <!-- the list of books, for the home page -->
      <govuk:books>
        <xsl:for-each select="$books">
          <xsl:variable name="topics" select="count(distinct-values(govuk:printable(govuk:refs/*)/govuk:file(.)))"/>
          <govuk:book id="{@id}" kind="{@kind}" title="{@title}" topics="{$topics}"
                      print="{if ($topics gt 0 and $topics le $max) then concat('print-', @id, '.html') else ''}"
                      pdf="{if ($GOVUK-PDF-BASE ne '' and $topics gt 0 and $topics le $max)
                            then concat($GOVUK-PDF-BASE, '-', @id, '.pdf') else ''}"/>
        </xsl:for-each>
      </govuk:books>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<!--
  Unknown govuk.* parameters (#174). Applied to the plugin's own plugin.xml,
  whose transtype declares every parameter the plugin reads. GIVEN is a
  properties file of the govuk.* properties the build was given before the
  plugin set any of its own. Writes one GOVK009W line for each given name the
  plugin does not declare, naming a declared parameter with the same last
  word where there is one; writes nothing when every name is known.
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:local="urn:org.istanduk.gov-uk:given-params"
                exclude-result-prefixes="xs local">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="GIVEN" as="xs:string"/>

  <xsl:template match="/">
    <xsl:variable name="declared" as="xs:string*"
                  select="distinct-values(//param/@name[starts-with(., 'govuk.')])"/>
    <!-- key=value lines; # starts a comment; the key ends at the first
         unescaped = or : (the properties-file rules Ant writes by) -->
    <xsl:variable name="given" as="xs:string*"
                  select="distinct-values(
                            for $line in unparsed-text-lines($GIVEN, 'ISO-8859-1')
                            return if (matches($line, '^\s*(#|!|$)')) then ()
                                   else replace(replace($line, '^\s*((\\.|[^=:\s\\])+).*$', '$1'), '\\(.)', '$1'))"/>
    <xsl:for-each select="sort($given[not(. = $declared)])">
      <xsl:variable name="name" select="."/>
      <xsl:variable name="last" select="tokenize(., '\.')[last()]"/>
      <!-- what was probably meant: a declared parameter with the same last
           word (govuk.max-topics), one the name begins (govuk.brand), or one
           a slip or two away (govuk.serach) -->
      <xsl:variable name="like" select="sort($declared[tokenize(., '\.')[last()] = $last
                                                       or starts-with(., $name)
                                                       or local:distance(., $name) le 2])"/>
      <xsl:text>[GOVK009W]: </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text> is not a parameter of this plugin, so it was ignored</xsl:text>
      <xsl:if test="exists($like)">
        <xsl:text>. Did you mean </xsl:text>
        <xsl:value-of select="string-join($like, ' or ')"/>
        <xsl:text>?</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Levenshtein distance between two short names, one row at a time -->
  <xsl:function name="local:distance" as="xs:integer">
    <xsl:param name="a" as="xs:string"/>
    <xsl:param name="b" as="xs:string"/>
    <xsl:variable name="ca" select="string-to-codepoints($a)"/>
    <xsl:variable name="cb" select="string-to-codepoints($b)"/>
    <xsl:sequence select="fold-left(1 to count($ca), 0 to count($cb),
                            function($row as xs:integer*, $i as xs:integer) as xs:integer* {
                              fold-left(1 to count($cb), $i,
                                function($new as xs:integer*, $j as xs:integer) as xs:integer* {
                                  ($new, min((
                                    $row[$j + 1] + 1,
                                    $new[last()] + 1,
                                    $row[$j] + (if ($ca[$i] = $cb[$j]) then 0 else 1))))
                                })
                            })[last()]"/>
  </xsl:function>

</xsl:stylesheet>

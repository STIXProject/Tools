<?xml version="1.0" encoding="UTF-8"?>
<!--
  Copyright (c) 2013 – The MITRE Corporation
  All rights reserved. See LICENSE.txt for complete terms.
 -->

<xsl:stylesheet 
    version="2.0"
    xmlns:stix="http://stix.mitre.org/stix-1"
    xmlns:cybox="http://cybox.mitre.org/cybox-2"
    
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    
    xmlns:stixCommon="http://stix.mitre.org/common-1"
    xmlns:indicator="http://stix.mitre.org/Indicator-2"
    xmlns:TTP="http://stix.mitre.org/TTP-1"
    xmlns:COA="http://stix.mitre.org/CourseOfAction-1"
    xmlns:capec="http://stix.mitre.org/extensions/AP#CAPEC2.5-1"
    xmlns:marking="http://data-marking.mitre.org/Marking-1"
    xmlns:tlpMarking="http://data-marking.mitre.org/extensions/MarkingStructure#TLP-1"
    xmlns:stixVocabs="http://stix.mitre.org/default_vocabularies-1"
    xmlns:cyboxCommon="http://cybox.mitre.org/common-2"
    xmlns:cyboxVocabs="http://cybox.mitre.org/default_vocabularies-2">
    
<xsl:output method="html" omit-xml-declaration="yes" indent="yes" media-type="text/html" version="4.0" />

    <xsl:template name="processHeader">
        <xsl:for-each select="//stix:STIX_Package/stix:STIX_Header">        
            <div id="observablesspandiv" style="font-weight:bold; margin:5px; color:#BD9C8C;">
                <TABLE class="grid tablesorter" cellspacing="0">
                    <COLGROUP>
                        <COL width="30%"/>
                        <COL width="70%"/>
                    </COLGROUP>
                    <THEAD>
                        <TR>
                            <TH class="header">
                                Field
                            </TH>
                            <TH class="header">
                                Value
                            </TH>
                        </TR>
                    </THEAD>
                    <TBODY>
                        <xsl:variable name="evenOrOdd" select="if(position() mod 2 = 0) then 'even' else 'odd'" />
                        <xsl:for-each select="child::*">
                            <xsl:call-template name="processNameValue"><xsl:with-param name="evenOrOdd" select="$evenOrOdd"/></xsl:call-template>
                        </xsl:for-each>
                    </TBODY>
                </TABLE>    
            </div>
        </xsl:for-each>
    </xsl:template>

    <!-- Designed for use in the STIX_HEADER, at least.  Does not yet take into consideration Handling/Marking complexity -->
    <xsl:template name="processNameValue">
        <xsl:param name="evenOrOdd" />
        <TR><xsl:attribute name="class"><xsl:value-of select="$evenOrOdd" /></xsl:attribute>
                <TD>
                    <xsl:value-of select="fn:local-name(.)"/>
                </TD>
                <TD>
                    <!-- does not handle markings gracefully -->
                    <xsl:value-of select="self::node()[text()]"/>
                </TD>
            </TR>
    </xsl:template>    
</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs fn stix cybox"
    version="2.0"
    
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    
    xmlns:stix='http://stix.mitre.org/stix-1'
    xmlns:cybox='http://cybox.mitre.org/cybox-2'
    
    >
    
    <xsl:import href="normalize.xsl" />
    
    <xsl:template match="/">
        <html>
            <head><title>normalization test</title></head>
            <body>
                <xsl:call-template name="main" />
            </body>    
        </html>
    </xsl:template>
    
    <xsl:template name="main">
        <!--
        <normalized>
            <xsl:apply-templates select="/stix:STIX_Package/*" mode="createNormalized">
            </xsl:apply-templates>
        </normalized>
        <reference>
            <xsl:apply-templates select="/stix:STIX_Package//*[@id]" mode="createReference">
                <xsl:with-param name="isTopLevel" select="fn:true()" />
            </xsl:apply-templates>
        </reference>
        -->
        
        <xsl:variable name="normalized">
            <xsl:apply-templates select="/stix:STIX_Package/*" mode="createNormalized" />
        </xsl:variable>
        <xsl:variable name="reference">
            <xsl:apply-templates select="/stix:STIX_Package//*[@id]" mode="createReference">
                <xsl:with-param name="isTopLevel" select="fn:true()" />
            </xsl:apply-templates>
        </xsl:variable>
        
        <div>normalized size: <xsl:value-of select="count($normalized/*)" /></div>
        <div>reference size: <xsl:value-of select="count($reference/*)" /></div>
        
        <h3>normalized indicators</h3>
        
        <xsl:apply-templates select="$normalized/stix:Indicators/stix:Indicator" />


        <h3>reference indicators</h3>
        
        <xsl:apply-templates select="$reference/stix:Indicator" />
        
    </xsl:template>
    
    <xsl:template match="stix:Indicator">
        <div>
            indicator
            <xsl:if test="@id">id = <xsl:value-of select="fn:data(@id)" /></xsl:if>
            <xsl:if test="@idref">idref = <xsl:value-of select="fn:data(@idref)" /></xsl:if>
        </div>
    </xsl:template>
    
</xsl:stylesheet>
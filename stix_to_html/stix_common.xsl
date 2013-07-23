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
    <xsl:include href="cybox_common.xsl"/>

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



    <!--
      This is the template that produces the rows in the indicator table.
      These are the observables just below the root element of the document.
      
      This behavior mimics the behavior in producing the observables table.
      
      Each indicator produces two rows.  The first row is the heading and is
      clickable to expand/collapse the second row with all the details.
      
      The heading row contains the indicator id and the indicator type.
      The type is one of the following categories:
       - "Compostion"
       - "Observable"
       - "Other"
    -->
    <xsl:template name="processIndicator">
        <xsl:param name="evenOrOdd" />
        
        <xsl:variable name="contentVar" select="concat(count(ancestor::node()), '00000000', count(preceding::node()))"/>
        <xsl:variable name="imgVar" select="generate-id()"/>
        
        
        
        <TR><xsl:attribute name="class"><xsl:value-of select="$evenOrOdd" /></xsl:attribute>
            <TD>
                <div class="collapsibleLabel" style="cursor: pointer;" onclick="toggleDiv('{$contentVar}','{$imgVar}')">
                    <span id="{$imgVar}" style="font-weight:bold; margin:5px; color:#BD9C8C;">+</span><xsl:value-of select="@id"/>
                </div>
            </TD>
            <TD>                    
                <xsl:choose>
                    <xsl:when test="indicator:Composite_Indicator_Expression">
                        Composition
                    </xsl:when>
                    <xsl:when test="indicator:Observable">
                        Observable
                    </xsl:when>
                    
                    <!--
                    <xsl:when test="cybox:Event">
                        Event
                    </xsl:when>
                    <xsl:when test="cybox:Object/cybox:Properties/@xsi:type">
                        <xsl:value-of select="fn:local-name-from-QName(fn:resolve-QName(cybox:Object/cybox:Properties/@xsi:type, cybox:Object/cybox:Properties))" />
                    </xsl:when>
                    <xsl:when test="cybox:Object/cybox:Properties/@xsi:type and not(cybox:Object/cybox:Properties/@xsi:type)">
                        Object (no properties set)
                    </xsl:when>
                    -->
                    
                    <xsl:otherwise>
                        Other
                    </xsl:otherwise>
                </xsl:choose>
            </TD>
        </TR>
        <TR><xsl:attribute name="class"><xsl:value-of select="$evenOrOdd" /></xsl:attribute>
            <TD colspan="2">
                <div id="{$contentVar}"  class="collapsibleContent" style="overflow:hidden; display:none; padding:0px 0px;">
                    <!-- create hidden div which will contain a fresh copy of the object at runtime -->
                    <xsl:if test="@id">
                        <div style="overflow:hidden; display:none; padding:0px 0px;" class="copyobj">
                            <xsl:attribute name="id">copy-<xsl:value-of select="@id" />
                            </xsl:attribute>
                        </div>
                    </xsl:if>
                    <div>
                    <div>
                        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
                        
                        <!-- set empty class for non-composition observables -->
                        
                        <!-- <span style="color: red; background-color: yellow;">INDICATOR CONTENTS HERE</span> -->
                        
                        <xsl:attribute name="class">
                        <xsl:if test="not(indicator:Composite_Indicator_Expression)">baseindicator </xsl:if>
                        <xsl:if test="@id">container baseobj</xsl:if>
                        </xsl:attribute>
                        <xsl:if test="indicator:Title">
                            <div id="section">
                                <table class="one-column-emphasis indicator-sub-table">
                                    <colgroup>
                                        <col class="oce-first-obs heading-column" />
                                        <col class="details-column" />
                                    </colgroup>
                                    <tbody>
                                        <tr>
                                            <td>Title</td>
                                            <td>
                                                <xsl:for-each select="indicator:Title">
                                                    <xsl:value-of select="."/>
                                                </xsl:for-each>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table> 
                            </div>
                        </xsl:if>              
                        <xsl:if test="not(indicator:Composite_Indicator_Expression)">
                            <div id="section">
                                <table class="one-column-emphasis indicator-sub-table">
                                    <colgroup>
                                        <col class="oce-first-obs heading-column" />
                                        <col class="details-column" />
                                    </colgroup>
                                    <tbody>
                                        <tr>
                                            <td>
                                                <xsl:apply-templates select="indicator:Observable" />
                                            </td>
                                        </tr>
                                    </tbody>
                                </table> 
                            </div>
                        </xsl:if>
                        <xsl:if test="indicator:Composite_Indicator_Expression">
                            <div id="section">
                                <table class="one-column-emphasis indicator-sub-table">
                                    <colgroup>
                                        <col class="oce-first-obs heading-column" />
                                        <col class="details-column" />
                                    </colgroup>
                                    <tbody>
                                        <tr>
                                            <td>Indicator Composition</td>
                                            <td>
                                                <xsl:apply-templates select="indicator:Composite_Indicator_Expression" />
                                                <!--
                                                <xsl:for-each select="indicator:Composite_Indicator_Expression">
                                                    <xsl:call-template name="processObservableCompositionSimple" />
                                                </xsl:for-each>
                                                -->
                                            </td>
                                        </tr>
                                    </tbody>
                                </table> 
                            </div>
                        </xsl:if>
                        <xsl:if test="indicator:Indicated_TTP">
                            <div id="section">
                                <table class="one-column-emphasis indicator-sub-table">
                                    <colgroup>
                                        <col class="oce-first-obs heading-column" />
                                        <col class="details-column" />
                                    </colgroup>
                                    <tbody>
                                        <tr>
                                            <td>Indicator Indicated TTP</td>
                                            <td>
                                                <xsl:apply-templates select="indicator:Indicated_TTP" />
                                                <!--
                                                <xsl:for-each select="indicator:Composite_Indicator_Expression">
                                                    <xsl:call-template name="processObservableCompositionSimple" />
                                                </xsl:for-each>
                                                -->
                                            </td>
                                        </tr>
                                    </tbody>
                                </table> 
                            </div>
                        </xsl:if>
                        <xsl:if test="indicator:Kill_Chain_Phases">
                            <div id="section">
                                <table class="one-column-emphasis indicator-sub-table">
                                    <colgroup>
                                        <col class="oce-first-obs heading-column" />
                                        <col class="details-column" />
                                    </colgroup>
                                    <tbody>
                                        <tr>
                                            <td>Indicator Kill Chain Phases</td>
                                            <td>
                                                <xsl:apply-templates select="indicator:Kill_Chain_Phases" />
                                                <!--
                                                <xsl:for-each select="indicator:Composite_Indicator_Expression">
                                                    <xsl:call-template name="processObservableCompositionSimple" />
                                                </xsl:for-each>
                                                -->
                                            </td>
                                        </tr>
                                    </tbody>
                                </table> 
                            </div>
                        </xsl:if>
                    </div>
                    </div>
                </div>
            </TD>
        </TR>
    </xsl:template>
    
    
    <!--
    <xsl:template match="indicator:Composite_Indicator_Expression">
        <div>(composite indicator)</div>
    </xsl:template>
    -->
    
    <!--
      This template produces the table displaying composite indicator expressions.
      
      This is similar to how the composite observables are produced.
    -->
    <xsl:template match="indicator:Composite_Indicator_Expression">
        <table class="compositionTableOperator">
            <colgroup>
                <xsl:choose>
                    <xsl:when test="@operator='AND'">
                        <col class="oce-first-obscomp-and"/>
                    </xsl:when>
                    <xsl:when test="@operator='OR'">
                        <col class="oce-first-obscomp-or"/>
                    </xsl:when>
                </xsl:choose>
            </colgroup>
            <tbody>
                <tr>
                    <th>
                        <xsl:attribute name="rowspan"><xsl:value-of select="count(cybox:Observable)"/></xsl:attribute>
                        <span><xsl:value-of select="@operator"/></span>
                    </th>
                    <td>
                        <table class="compositionTableOperand">
                            <xsl:for-each select="indicator:Indicator">
                                <tr>
                                    <td>
                                        <xsl:apply-templates select="." mode="composition" />
                                    </td>
                                </tr>
                                
                            </xsl:for-each>
                            <tr>
                            </tr>
                        </table>
                    </td>
                </tr>
                
            </tbody>
        </table> 
    </xsl:template>
    
    <!--
      This template display the simple indicator within a composit indicator
      expression (one of the operands).
    -->
    <xsl:template match="indicator:Indicator" mode="composition">
        <xsl:if test="@idref">
            <div class="foreignObservablePointer">
                <xsl:variable name="targetId" select="string(@idref)"/>
                <xsl:variable name="relationshipOrAssociationType" select="''" />
                
                <!-- (indicator within composition - - idref: <xsl:value-of select="fn:data(@idref)"/>) -->
                <xsl:call-template name="headerAndExpandableContent">
                    <xsl:with-param name="targetId" select="$targetId"/>
                    <xsl:with-param name="isComposition" select="fn:true()"/>
                    <xsl:with-param name="relationshipOrAssociationType" select="''" />
                </xsl:call-template>
            </div>
        </xsl:if>
        
        <xsl:for-each select="cybox:Observable_Composition">
            <xsl:apply-templates select="." mode="composition" />
        </xsl:for-each>
    </xsl:template>
    
    
    <!--
      This template display an observable contained within an indicator.
    -->
    <xsl:template match="indicator:Observable">
        <!-- <div>(indicator observable)</div> -->
        
        <xsl:variable name="targetId" select="fn:data(@idref)" />
        <xsl:variable name="targetObject" select="//*[@id=$targetId]" />
        
        <div class="expandableContainer expandableSeparate collapsed">
            <xsl:variable name="idVar" select="generate-id(.)"/>
            
            <div class="expandableToggle objectReference">
                <xsl:attribute name="onclick">embedObject(this.parentElement, 'copy-<xsl:value-of select="$targetId"/>','<xsl:value-of select="$idVar"/>');</xsl:attribute>
                <xsl:call-template name="clickableIdref">
                    <xsl:with-param name="targetObject" select="$targetObject" />
                    <xsl:with-param name="relationshipOrAssociationType" select="''"/>
                    <xsl:with-param name="idref" select="$targetId"/>
                </xsl:call-template>
            </div>
            
            <div class="expandableContents">
                <xsl:attribute name="id"><xsl:value-of select="$idVar"/></xsl:attribute>
            </div>
        </div>
        
        
        <!--
        <xsl:for-each select=".">
            <xsl:call-template name="processObservableInObservableCompositionSimple" />
        </xsl:for-each>
        -->
    </xsl:template>
    
    <xsl:template match="indicator:Indicated_TTP">
        <div>
        <!-- <div>(indicator Indicated TTP)</div> -->
        <div>
            <xsl:apply-templates/>
        </div>
        </div>
    </xsl:template>
    
    <xsl:template match="indicator:Kill_Chain_Phases">
        <div>
            <!-- <div>Kill Chain Phases</div> -->
            <div>
                <xsl:apply-templates />
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="stixCommon:TTP">
        <div>
            <div>TTP</div> 
            <xsl:if test="@idref"><div>(reference to "<xsl:value-of select="fn:data(@idref)" />")</div></xsl:if>
            <xsl:if test="@id"><div>(id "<xsl:value-of select="fn:data(@id)" />")</div></xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="stixCommon:Kill_Chain_Phase">
        <div>
            * name = "<xsl:value-of select="fn:data(@name)"/>" | phase id = "<xsl:value-of select="fn:data(@phase_id)"/>"
        </div>
    </xsl:template>
    
    <xsl:template match="stixCommon:TTP">
        <div>
            TTP (references "<xsl:value-of select="fn:data(@idref)" />")
        </div>
    </xsl:template>
    
    
    
    <!--
    <xsl:template match="indicator:Composite_Indicator_Expression/indicator:Indicator">
        <div>(indicator reference inside composition)</div>
        <xsl:if test="@idref">
            <div class="foreignObservablePointer">
                <xsl:variable name="targetId" select="string(@idref)"/>
                <xsl:variable name="relationshipOrAssociationType" select="''" />
                
                <xsl:call-template name="headerAndExpandableContent">
                    <xsl:with-param name="targetId" select="$targetId"/>
                    <xsl:with-param name="isComposition" select="fn:true()"/>
                    <xsl:with-param name="relationshipOrAssociationType" select="''" />
                </xsl:call-template>
            </div>
        </xsl:if>
        
        <xsl:for-each select="cybox:Observable_Composition">
            <xsl:call-template name="processObservableCompositionSimple" />
        </xsl:for-each>
    </xsl:template>
    -->
    
    
</xsl:stylesheet>

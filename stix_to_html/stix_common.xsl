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
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
    xmlns:cyboxVocabs="http://cybox.mitre.org/default_vocabularies-2"
    xmlns:simpleMarking="http://data-marking.mitre.org/extensions/MarkingStructure#Simple-1"
    
    xmlns:ttp='http://stix.mitre.org/TTP-1'
    >
    
<xsl:output method="html" omit-xml-declaration="yes" indent="yes" media-type="text/html" version="4.0" />
    <xsl:include href="cybox_common.xsl"/>

    <xsl:template name="processHeader">
        <xsl:for-each select="//stix:STIX_Package/stix:STIX_Header">        
            <div class="stixHeader">
                <table class="grid tablesorter" cellspacing="0">
                    <colgroup>
                        <col width="30%"/>
                        <col width="70%"/>
                    </colgroup>
                    <thead>
                        <tr>
                            <th class="header">
                                Field
                            </th>
                            <th class="header">
                                Value
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:variable name="evenOrOdd" select="if(position() mod 2 = 0) then 'even' else 'odd'" />
                        <xsl:for-each select="child::*">
                            <xsl:call-template name="processStixHeaderNameValue"><xsl:with-param name="evenOrOdd" select="$evenOrOdd"/></xsl:call-template>
                        </xsl:for-each>
                    </tbody>
                </table>    
            </div>
        </xsl:for-each>
    </xsl:template>

    <!-- Designed for use in the STIX_HEADER, at least.  Does not yet take into consideration Handling/Marking complexity -->
    <xsl:template name="processStixHeaderNameValue">
        <xsl:param name="evenOrOdd" />
        <TR><xsl:attribute name="class"><xsl:value-of select="$evenOrOdd" /></xsl:attribute>
                <TD class="Stix{local-name()}Name">
                  <xsl:value-of select="fn:local-name(.)"/>
                </TD>
                <TD class="Stix{local-name()}Value">
                    <xsl:variable name="class" select="if (self::stix:Description) then ('longText expandableContainer expandableToggle expandableContents expandableSame collapsed') else ('') " />
                    <div>
                        <xsl:if test="$class">
                            <xsl:attribute name="class" select="$class"/>
                            <xsl:attribute name="onclick">toggle(this);</xsl:attribute>
                        </xsl:if>
                        <!--
                          for now, just show the text of simpleMarking:Statement
                          TODO: do something with the entire contents of stix:Handling
                        -->
                        <xsl:choose>
                          <xsl:when test="self::stix:Handling">
                            <xsl:value-of select=".//simpleMarking:Statement/text()"/>
                          </xsl:when>
                          <xsl:when test="self::stix:Information_Source">
                            <xsl:apply-templates mode="cyboxProperties" />
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="self::node()[text()]"/>
                          </xsl:otherwise>
                        </xsl:choose>
                        
                    </div>
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
  
    <xsl:template name="processIndicatorContents">
      
      <div>
      <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      
      <!-- set empty class for non-composition observables -->
      
      <!-- <span style="color: red; background-color: yellow;">INDICATOR CONTENTS HERE</span> -->
      
        <xsl:attribute name="class">
          <xsl:if test="not(indicator:Composite_Indicator_Expression)">baseindicator </xsl:if>
          <xsl:if test="@id">container baseobj</xsl:if>
        </xsl:attribute>
        
        <xsl:if test="indicator:Title">
          <xsl:copy-of select="stix:printNameValueTable('Title', indicator:Title)" />
        </xsl:if>              
        <xsl:if test="indicator:Description">
          <xsl:copy-of select="stix:printNameValueTable('Description', indicator:Description)" />
        </xsl:if>              
        <xsl:if test="indicator:Valid_Time_Position">
          <xsl:copy-of select="stix:printNameValueTable('Valid Time Position', fn:concat('(', indicator:Valid_Time_Position/indicator:Start_Time/text(), ' to ', indicator:Valid_Time_Position/indicator:End_Time/text(), ')'))" />
        </xsl:if>
        <xsl:if test="indicator:Suggested_COAs/indicator:Suggested_COA">
          <xsl:variable name="coaContents">
            <xsl:apply-templates select="indicator:Suggested_COAs/indicator:Suggested_COA" />
          </xsl:variable>
          <xsl:copy-of select="stix:printNameValueTable('Suggested COAs', $coaContents)" />
        </xsl:if>
        <xsl:if test="not(indicator:Composite_Indicator_Expression)">
          <xsl:variable name="observableContents">
            <xsl:apply-templates select="indicator:Observable" />
          </xsl:variable>
          <xsl:copy-of select="stix:printNameValueTable('Observable', $observableContents)" />
        </xsl:if>
        <xsl:if test="indicator:Composite_Indicator_Expression">
          <xsl:variable name="contents">
            <xsl:apply-templates select="indicator:Composite_Indicator_Expression" />
          </xsl:variable>
          <xsl:copy-of select="stix:printNameValueTable('Indicator Composition', $contents)" />
        </xsl:if>
      <xsl:if test="indicator:Indicated_TTP">
        <xsl:variable name="contents">
          <xsl:apply-templates select="indicator:Indicated_TTP" />
        </xsl:variable>
        <xsl:copy-of select="stix:printNameValueTable('Indicated TTP', $contents)" />
      </xsl:if>
      <xsl:if test="indicator:Kill_Chain_Phases">
        <xsl:variable name="contents">
          <xsl:apply-templates select="indicator:Kill_Chain_Phases" />
        </xsl:variable>
        <xsl:copy-of select="stix:printNameValueTable('Kill Chain Phases', $contents)" />
      </xsl:if> 
      <xsl:if test="indicator:Confidence">
        <xsl:variable name="contents">
          <xsl:apply-templates select="indicator:Confidence" mode="cyboxProperties" />
        </xsl:variable>
        <xsl:copy-of select="stix:printNameValueTable('Confidence', $contents)" />
      </xsl:if> 
      </div>
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
        
        <xsl:for-each select="cybox:Observable_Composition|indicator:Composite_Indicator_Expression">
            <xsl:apply-templates select="." mode="#default" />
        </xsl:for-each>
    </xsl:template>
    
    
    <!--
      This template display an observable contained within an indicator.
    -->
    <xsl:template match="indicator:Observable">
        
        <xsl:choose>
            <xsl:when test="@id">
                <xsl:call-template name="processObservableInline" />
            </xsl:when>
            <xsl:when test="@idref">
                <xsl:call-template name="processObservableInObservableCompositionSimple" />
            </xsl:when>
        </xsl:choose>
        
        
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
    
    <xsl:template match="stixCommon:TTP|stix:TTP">
        <div>
            TTP (references "<xsl:value-of select="fn:data(@idref)" />")
        </div>
    </xsl:template>
    
    
    
    <xsl:template name="processTTPContents">
      <div>
        <div>
          <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
          
          <!-- set empty class for non-composition observables -->
          
          <!-- <span style="color: red; background-color: yellow;">INDICATOR CONTENTS HERE</span> -->
          
          <xsl:attribute name="class">
            <!-- <xsl:if test="not(indicator:Composite_Indicator_Expression)">baseindicator </xsl:if> -->
            <xsl:if test="@id">container baseobj</xsl:if>
          </xsl:attribute>
          <xsl:if test="ttp:Description">
            <xsl:copy-of select="stix:printNameValueTable('Description', ttp:Description)" />
          </xsl:if>  

          <xsl:if test="ttp:Intended_Effect">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Intended_Effect" mode="cyboxProperties" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Intended Effect', $contents)" />
          </xsl:if>  
          
          <xsl:if test="ttp:Behavior">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Behavior" mode="cyboxProperties" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Behavior', $contents)" />
          </xsl:if>
          
          <xsl:if test="ttp:Resources">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Resources" mode="cyboxProperties" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Resources', $contents)" />
          </xsl:if>  
          
          <xsl:if test="ttp:Victim_Targeting">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Victim_Targeting" mode="cyboxProperties" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Victim Targeting', $contents)" />
          </xsl:if>  
          
          <xsl:if test="ttp:Exploit_Targets">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Exploit_Targets" mode="cyboxProperties" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Exploit Targets', $contents)" />
          </xsl:if>  
          
          <xsl:if test="ttp:Related_TTPs/ttp:Related_TTP">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Related_TTPs/ttp:Related_TTP" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Related TTPs', $contents)" />
          </xsl:if> 
          <xsl:if test="ttp:Kill_Chain_Phases/stixCommon:Kill_Chain_Phase">
            <xsl:variable name="contents">
              <xsl:apply-templates select="ttp:Kill_Chain_Phases" />
            </xsl:variable>
            <xsl:copy-of select="stix:printNameValueTable('Kill Chain Phases', $contents)" />
          </xsl:if> 
          
        </div>
      </div>
    </xsl:template>
    
  <xsl:template match="stixCommon:Kill_Chain[@id]" priority="30.0">
    <xsl:variable name="localName" select="local-name()"/>
    <xsl:variable name="identifierName" select="'killChain'" />
    <xsl:variable name="friendlyName" select="fn:replace($localName, '_', ' ')" />
    <xsl:variable name="headingName" select="fn:upper-case($friendlyName)" />
    
    <div class="container {$identifierName}Container {$identifierName}">
      <div class="contents {$identifierName}Contents {$identifierName}">
        <!-- Print the description if one is available (often they are not) -->
        
        <xsl:call-template name="printNameValue">
          <xsl:with-param name="identifier" select="$identifierName" />
          <xsl:with-param name="label" select="'Name'" as="xs:string?" />
          <xsl:with-param name="value" select="@name" as="xs:string?" />
        </xsl:call-template>
        
        <xsl:call-template name="printNameValue">
          <xsl:with-param name="identifier" select="$identifierName" />
          <xsl:with-param name="label" select="'Definer'" as="xs:string?" />
          <xsl:with-param name="value" select="@definer" as="xs:string?" />
        </xsl:call-template>
        
        <xsl:call-template name="printNameValue">
          <xsl:with-param name="identifier" select="$identifierName" />
          <xsl:with-param name="label" select="'Reference'" as="xs:string?" />
          <xsl:with-param name="value" select="@reference" as="xs:string?" />
        </xsl:call-template>
        
        <xsl:if test="stixCommon:Kill_Chain_Phase">
          <xsl:apply-templates select="stixCommon:Kill_Chain_Phase" />
        </xsl:if>
        
        
        
      </div>
    </div>
  </xsl:template>
  
  
  <xsl:template match="stixCommon:Kill_Chain_Phase[@id]">
    <div class="debug">DEBUG kill chain phase w/ id</div>
    <div class="container killChainPhase">
      <div class="heading killChainPhase">
        Kill Chain Phase
      </div>
      <div class="contents killChainPhase killChainPhaseContents">
        <div class="contentsCurrent">
          <xsl:call-template name="printNameValue">
            <xsl:with-param name="identifier" select="'name'" />
            <xsl:with-param name="label" select="'Name'" as="xs:string?" />
            <xsl:with-param name="value" select="@name" as="xs:string?" />
          </xsl:call-template>
          
          <xsl:call-template name="printNameValue">
            <xsl:with-param name="identifier" select="'ordinality'" />
            <xsl:with-param name="label" select="'Ordinality'" as="xs:string?" />
            <xsl:with-param name="value" select="@ordinality" as="xs:string?" />
          </xsl:call-template>
          
          
        </div>
        <div class="contentsChildren">
          <xsl:apply-templates />
        </div>
      </div> <!-- end of div contents -->
    </div> <!-- end of div container -->
  </xsl:template>
  
  <xsl:template match="ttp:Related_TTP">
    <div>
      Related TTP Relationship: <xsl:value-of select="stixCommon:Relationship/text()" />
    </div>
    <div>
      <xsl:apply-templates select="stixCommon:TTP" />
    </div>
  </xsl:template>
  
  <xsl:template match="stixCommon:Kill_Chain_Phase[@idref]|stixCommon:TTP[@idref]">
    <div class="debug">DEBUG kill chain phase w/ idref</div>
    <!-- [object link here - - <xsl:value-of select="fn:data(@idref)" />] -->
    
    <xsl:call-template name="headerAndExpandableContent">
      <xsl:with-param name="targetId" select="fn:data(@idref)" />
      <xsl:with-param name="relationshipOrAssociationType" select="()" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="printNameValue" >
    <xsl:param name="identifier" select="''" as="xs:string?" />
    <xsl:param name="label" select="''" as="xs:string?" />
    <xsl:param name="value" select="''" as="xs:string?" />
    
    <xsl:if test="@name">
      <div class="{$identifier}KeyValue keyValue">
        <span class="key"><xsl:value-of select="$label"/>:</span>
        <xsl:text> </xsl:text>
        <span class="key">
          <xsl:choose>
            <xsl:when test="fn:starts-with($value, 'http://') or fn:starts-with($value, 'https://') or fn:starts-with($value, 'ftp://')">
              <a href="{$value}"><xsl:value-of select="$value"/></a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$value"/>
            </xsl:otherwise>
          </xsl:choose>
        </span>
      </div>
    </xsl:if>
  </xsl:template>  
  
  <xsl:template match="indicator:Suggested_COA">
    <xsl:apply-templates />
  </xsl:template>
    
</xsl:stylesheet>

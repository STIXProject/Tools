<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  
  xmlns:stix="http://stix.mitre.org/stix-1" 
  xmlns:stixCommon="http://stix.mitre.org/common-1"
  xmlns:ttp="http://stix.mitre.org/TTP-1"
  
  
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="/">
    <html>
      <head>
        <title>iframe with data uri test</title>
        <script type="text/javascript">
        <![CDATA[
        function initialize()
        {
          var allTargets = document.querySelectorAll(".htmlContainer");
          for (var i = 0; i < allTargets.length; i++)
          {
            var target = allTargets[i];
            var rawHtml = target.getAttribute("data-stix-content");
            
            var targetDivId = target.id + "__div_target";
            var targetDiv = document.getElementById(targetDivId);

            var htmlElement = document.createElement("html");
            htmlElement.innerHTML = rawHtml;
            targetDiv.appendChild(htmlElement.querySelector("body"));

          }
        }
        
        ]]>
        </script>
      </head>
      <body onload="initialize()">
        <h1>copy raw html to temp html element test</h1>
        
        <div>
          <xsl:apply-templates select="(//stix:TTP//stixCommon:Description)[1]" mode="old" />
        </div>
        
        <div>
          <xsl:apply-templates select="(//stix:TTP//stixCommon:Description)[1]" mode="datauri" />
        </div>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="stixCommon:Description" mode="old">
    <fieldset>
      <legend>escaped html description</legend>
      <div>
        <xsl:value-of select="text()" />
      </div>
    </fieldset>
  </xsl:template>
  
  <xsl:template match="stixCommon:Description" mode="datauri">
    <xsl:variable name="id" select="generate-id()" />
    <xsl:variable name="divTargetId" select="concat($id, '__div_target')" />
    <fieldset>
      <legend>description inline</legend>
      <div>
        <div class="htmlContainer" id="{$id}" data-stix-content="{text()}" ></div>
        <div class="divCopyTarget" id="{$divTargetId}" /> 
      </div>
    </fieldset>
  </xsl:template>
  
</xsl:stylesheet>
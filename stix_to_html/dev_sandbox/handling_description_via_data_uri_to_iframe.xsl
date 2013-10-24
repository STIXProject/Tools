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
            var reader = new FileReader();
            var htmlBlob = new Blob([rawHtml], {type: "text/html"});
            
            var targetIframeId = target.getAttribute("data-stix-target-iframe");
            var targetIframe = document.getElementById(targetIframeId);
            
            reader.onloadend = function()
            {
              console.log("inside onloadend -- BEGIN");
              targetIframe.src = reader.result;
              console.log("inside onloadend -- END");
            };
            reader.onerror = function()
            {
              console.log("inside onerror! FAILED!!");
            };
            console.log("before starting read...");
            reader.readAsDataURL(htmlBlob);
            console.log("after starting read...(may still be running)");
          }
        }
        
        ]]>
        </script>
      </head>
      <body onload="initialize()">
        <h1>iframe with data uri test</h1>
        
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
    <xsl:variable name="iframeId" select="concat($id, '__iframe')" />
    <fieldset>
      <legend>description in iframe</legend>
      <div>
        <div class="htmlContainer" data-stix-content="{text()}" data-stix-target-iframe="{$iframeId}"></div>
        <iframe id="{$iframeId}" src="" style="width: 400px; height: 300px;"></iframe>
      </div>
    </fieldset>
  </xsl:template>
  
</xsl:stylesheet>
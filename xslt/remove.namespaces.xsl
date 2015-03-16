<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    version="2.0">
    
    <!-- wir brauchen das script nur noch um:

	- den namespace (marc) aus den marc21 Saetzen zu entfernen
	- XML Declaration zu entfernen
        - es findet keine Umwandlung  des 001 tags zu Docid mehr statt

          

    -->  


    <xsl:output
    omit-xml-declaration="yes"
    />

    <xsl:template match="*">
            <xsl:element name="{local-name()}">
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:template>
    

</xsl:stylesheet>

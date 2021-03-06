<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"    
     version="2.0"
     xmlns:marc="http://www.loc.gov/MARC21/slim">
    
    <xsl:output 
        indent="yes" 
        method="xml"
        />
    
    <!-- here only the default value (correct??)
        you can control parameter values from outside
    -->
    <xsl:param name="hostname" select="'http://www.nb.admin.ch/'" />
    
    <!-- institutioncode is needed by swissbib default CHAR01
         any definitions of NB
    -->
    <xsl:param name="institutioncode" select="'CHARCH01'" />
    
    <xsl:variable name="linkurl949y" select="'http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=80'"/>
    <xsl:variable name="linkurl856vorschaubild" select="'http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=10'"/>
    
    <!--
    <xsl:variable name="linkurl949y" select="'http://externalservices.swissbib.ch/services/ImageTransformer?imagePath=http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=80'" />
    <xsl:variable name="linkurl856vorschaubild" select="'http://externalservices.swissbib.ch/services/ImageTransformer?imagePath=http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=10'"/>
    -->
    
    <!--    <xsl:variable name="levelID" select="/ExportRoot//Record[@Level='Serie']"/> -->
    

    <xsl:template match="/">
        
        <marc:collection >
            <!-- start processing of record nodes -->
            <xsl:apply-templates/>
        </marc:collection>            
    </xsl:template>

    <xsl:template match="Record">
        
        <!-- template engine to process all the record nodes -->
        <xsl:if test="((AdministrativeData/EditForm/text() = 'NB Basisformular Fotografie') or
            (AdministrativeData/EditForm/text() = 'AS Basisformular Fotografie'))
            and DetailData/DataElement[@ElementName='Ansichtsbild']"> 
            <!--and 
            (UsageData/AlwaysVisibleOnline/text() = 'true')"> -->
            <marc:record >
                
                <!-- at first process fix nodes -primarily control nodes- 
                which should be part of every MARC - record
                -->
                
                <xsl:call-template name="createLeader"/>
                <!-- call createCtrlxx when Record is the Context node -->
                <xsl:call-template name="cCtrlF001"/>
                <xsl:call-template name="cCtrlF003"/>
                <xsl:call-template name="cCtrlF007"/>
                <xsl:call-template name="cCtrlF008"/>
                <!-- the next datafields should not be data driven -->
                <xsl:call-template name="cdF035"/>
                <xsl:call-template name="cdF040"/>
                
                <!-- 
                    Die spezielle Behandlung für das das DataElement FotografIn fällt 
                    -vorläufig?? - weg, nachdem Yvonne alle Fotografen aus dem Descriptor holen möchte
                    und ins tag 700 steckt
                <xsl:for-each select="DetailData/DataElement[@ElementName='FotografIn']">
                <xsl:if test="fn:position() = 1"> -->
                        <!-- Aufruf des named templates für erste Position -->
                <!--         <xsl:call-template name="cdFsingFotografin"/>
                    </xsl:if>
                    <xsl:if test="fn:position() &gt; 1">  -->
                        <!-- Aufruf des named templates für folgende Positionen -->
                  <!--       <xsl:call-template name="cdFmultFotografin"/>
                    </xsl:if>
                    </xsl:for-each>  -->
                
                <!-- now the data driven dynamic part begins -->
                <xsl:variable name="datafields">    
                    <xsl:apply-templates select="DetailData/DataElement"/>
                    <xsl:apply-templates select="Descriptors/Descriptor"/>
                    <marc:datafield tag="260" ind2=" " ind1=" " >
                        <xsl:apply-templates select="DetailData/DataElement[@ElementName='Entstehungszeitraum'] | 
                            DetailData/DataElement[@ElementName='Vertrieb/Verlag'] | 
                            DetailData/DataElement[@ElementName='Partnerangaben Verlag/Vertrieb']" mode="feld260"/>
                    </marc:datafield>  
    
                    <marc:datafield tag="300" ind2=" " ind1=" " >
                        <xsl:apply-templates select="DetailData/DataElement[@ElementName='Archivalienart'] | 
                            DetailData/DataElement[@ElementName='Farbe'] | 
                            DetailData/DataElement[@ElementName='Standard Bildformat']" mode="feld300"/>
                    </marc:datafield>  
                    
                    <!--  
                    swissbib specific as format filter
                    necessary for NB?
                    -->
                    
                    <!--
                    <marc:datafield tag="830" ind2=" " ind1="0" >
                        <marc:subfield code="w"><xsl:value-of select="$levelID[fn:count($levelID)]/@Id"/></marc:subfield>
                    </marc:datafield>  
                    -->
                    <marc:datafield tag="898" ind2=" " ind1=" " >
                        <marc:subfield code="a"><xsl:text>VM020453</xsl:text></marc:subfield>
                        <marc:subfield code="b"><xsl:text>VM020453</xsl:text></marc:subfield>
                    </marc:datafield>  
                    
                </xsl:variable>        
    
                <xsl:for-each select="$datafields/marc:datafield">
                    <xsl:sort select="./@tag"/> 
                    <xsl:copy-of select="."/>
                                            
                </xsl:for-each>
            
    
            </marc:record>
        </xsl:if>    
    
        <!-- now look out for the next Record node until the whole XML Input Document is being processed-->
        <xsl:apply-templates select="Record"/>
                
        
    </xsl:template>
    
    <xsl:template match="DetailData">
        <xsl:apply-templates/>
                
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Signatur']">
        <!-- 
            Bitte analog zu Virtua-949 die entsprechenden Indikatoren in Gross-Buchstaben setzen:
            $A VIRTUAITEM
            $D Institution- und Standort
            ...
        -->
        <!--<marc:subfield code="b">Signatur Archivplan</marc:subfield> -->
        <!--<marc:subfield code="b"><xsl:value-of select="/ExportRoot//DataElement[@ElementName='Signatur Archivplan']/ElementValue/TextValue/text()" /></marc:subfield> -->
        <!--
            GH: entfernt 9.11.2010
            Kommentar Tobias:
            Korrektur von 949 $b
            Momentan haben 949 $b und 949 $a denselben Inhalt, was nicht korrekt und unsinnig ist.
            
            949 $b enthält die Signatur fälschlicherweise anstelle des Institutionencodes. Hier bietet es sich also an, pro Sammlung aus Helvetic Archives einen Code zu vergeben:
            
            Der Vorschlag ist "CHARCH" und eine zweistellige Nummer, was 99 unterschiedliche Sammlungen erlaubt.
            
            CHARCH01 = Eidgenössisches Archiv für Denkmalpflege EAD
            CHARCH02 = ...
            
            =949## $b CHARCH01
            
            => Die Benennung ist natürlich frei wählbar
            => Der Wert 949$b steht in Beziehung zu 949$B. In swissbib wird 949$B für den Verbund und 949$b für die Bibliothek verwendet
            
            
            5. Einsetzen von "949 $B CHARCH" als Filtercode für die Gesamtsammlung Helvetic Archives
            =949## $B CHARCH 
            
            <marc:subfield code="b"><xsl:value-of select="parent::node()/child::DataElement[@ElementName='Signatur Archivplan']/ElementValue/TextValue/text()" /></marc:subfield> 
            
            
        -->
        
        <!-- 
            Vorschlag Tobias 18.11.2010
            (Hintergrund: Wir brauchen Informationen um die Exemplaranzeige in der Vollanzeige füllen zu können
            
            <marc:datafield tag="949" ind2=" " ind1=" ">
            <marc:subfield code="B">Datenbank-ID</marc:subfield>
            <marc:subfield code="E">Systemnummer wie im Originalsystem</marc:subfield>
            <marc:subfield code="b">Sammlungs-ID</marc:subfield>
            <marc:subfield code="j">Signatur</marc:subfield>
            <marc:subfield code="y">URL auf Vorschaubild</marc:subfield>
            <marc:subfield code="z"><Permission></marc:subfield>
            <marc:subfield code="1"><Accessability></marc:subfield>
            <marc:subfield code="5"><PhysicalUsability></marc:subfield>
            </marc:datafield>
            
            ==
            2. Beispiel:
            
            <marc:datafield tag="949" ind2=" " ind1=" ">
            <marc:subfield code="B">CHARCH</marc:subfield>
            <marc:subfield code="E">76286</marc:subfield>
            <marc:subfield code="b">CHARCH01</marc:subfield>
            <marc:subfield code="j">EAD-ZING-787</marc:subfield>
            <marc:subfield code="y">http://www.helveticarchives.ch/getimage.aspx?VEID=76286&DEID=10&SQNZNR=1&SIZE=100</marc:subfield>
            <marc:subfield code="z">Reproduktionsbewilligung</marc:subfield>
            <marc:subfield code="1">Archivmitarbeiter / Innen</marc:subfield>
            <marc:subfield code="5">Uneingeschränkt</marc:subfield>
            </marc:datafield>
            
            
            
        -->        
        
        
        
        
        <xsl:variable name="recordid" select="../.././@Id"/>
        <xsl:variable name="replacedurl" select="fn:replace($linkurl949y,'XXX',$recordid)"/>
            
        
        <marc:datafield tag="949" ind2=" " ind1=" " >
            <marc:subfield code="B"><xsl:text>CHARCH</xsl:text></marc:subfield>
            <!-- Bibliothekscode und Standardcode in rero - brauchen wir bei HA nicht -->
            <!--<marc:subfield code="D">0000101001</marc:subfield> -->
            <marc:subfield code="E"><xsl:value-of select="$recordid"/></marc:subfield>
      <!--      <marc:subfield code="1"><xsl:value-of select="../../UsageData/Accessability/text()" /></marc:subfield>  -->
            <!-- Mail Deborah 20101124
                Könntest Du per Default folgende Infos zum Bestand wie folgt anpassen:
                Standort = Archiv  /Ausleihstatus = auf Anfrage
            -->
            <marc:subfield code="1">Archiv</marc:subfield> 
            <marc:subfield code="5"><xsl:value-of select="../../UsageData/PhysicalUsability/text()" /></marc:subfield>
            <marc:subfield code="F"><xsl:value-of select="$institutioncode"/></marc:subfield>
            <marc:subfield code="b"><xsl:value-of select="$institutioncode"/></marc:subfield>
            <!-- code E is swissbib specific -> we need it for the HoldingsDB 
                no combination of cha + number value because a hardcoded implementation would be necessary in the TP swissbib target to remove the prefix cha
                (backlink to Helvetic archive is constructed without the prefix             
            -->
            <marc:subfield code="j"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            
            <!-- Todo: 949y: welche records besitzen ein Bild?? -->
            <!--
            <xsl:if test="not(../../UsageData/Accessability/text() = 'Sonderbewilligung Intranet') and     
                following-sibling::DataElement[@ElementName='Ansichtsbild']">
                <xsl:variable name="recordid" select="../.././@Id"/>
                <xsl:variable name="replacedurl" select="fn:replace($linkurl949y,'XXX',$recordid)"/>
                <marc:subfield code="u"><xsl:value-of select="$replacedurl"/></marc:subfield>
            </xsl:if>
            -->
            <marc:subfield code="z"><xsl:value-of select="../../UsageData/Permission/text()" /></marc:subfield>
        </marc:datafield>
    
    </xsl:template>
    <xsl:template match="DataElement[@ElementName='Signatur Archivplan']">
       
        <!-- Frage Günter:
            eigenes Feld 949 oder in dem vorherigen "unterbringen"
        -->    
        <!--
            Frage Tobias:
            Wofür benötigt man diese Signatur? ->
            Antwort Yvonne Bättig:            
            Diese ist vielfach identisch mit der Signatur, 
            ist z.T. aber viel kürzer            
        -->
        <!-- Marcbeschreibung:
            Im gleichen Virtua-Feld 949 Unterfeld b ergänzen (siehe oben). 
            Unterfeld b = 2. Signatur.
            -> Graphische Sammlung würde dieses Feld weglassen; 
            noch mit SLA abklären, ob sie es benötigen.            
         -->   
    </xsl:template>
        
    <xsl:template match="DataElement[@ElementName='Dateiname Digitalisat']">
        
        <!--
            Kommentar Tobias:
            Eine Variante ist 856 $f Dateiname 
            in Kombination mit 856 $a Hostname        
            -> Diese Angabe kann weggelassen werden, 
            wenn sie nicht technisch für die Bildverlinkung gebraucht wird.        
        -->
        <!-- lasse ich vorerst weg, da ich Vorschaubild und Ansichtsbild habe
            mehr brauchen wir nicht!            
        <marc:datafield tag="856" ind1="0" ind2="2" >
            <marc:subfield code="a"><xsl:value-of select="$hostname"></xsl:value-of></marc:subfield>
            <marc:subfield code="f"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>
        -->
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Titel / Name']">
        
        <marc:datafield tag="245" ind1="0" ind2="0" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="h">[Bild]</marc:subfield>
        </marc:datafield>            
        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Titel (Variante)']">
        <!--
            Guneter:
            Dieses Feld kommt in den Daten nicht vor!!            
        -->        
        <marc:datafield tag="246" ind1="1" ind2="3" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Titel (Variante) Spezifikation – Art und Quelle']">
        <!--
            Guenter:
            Dieses Feld kommt in den Daten nicht vor!!            
        -->        
        <marc:datafield tag="500" ind1=" " ind2=" " >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>
        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Titel der Serie']">
        <!-- Tobias 
            Was ist unter einer Serie im Zusammenhang mit Helv-Arch 
            zu verstehen?
            Falls es sich um einen Hinweis auf eine hierarchisch 
            höherliegende Aufnahme handelt und dazu eine Systemnummer 
            existiert, dann wäre es ausserordentlich toll, 
            wenn diese Nummer mit im Feld abgelegt würde... -> 
        -->
        <!-- Yvonne
            Es handelt sich um eine höhere Stufe.
        -->
        <!-- Tobias
            Würde überhaupt eine „kontrollierte Ansetzung“ existieren?             
        -->
        <!-- Yvonne
            Von kontrolliert würde ich ausgehen, wenn die Angabe 
            immer identisch ist.            
        -->
        <marc:datafield tag="490" ind1="1" ind2=" " >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>    
        <marc:datafield tag="830" ind1=" " ind2="0" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="w">(CHARCH)cha<xsl:value-of select="parent::node()/parent::node()/attribute::ParentId"/></marc:subfield>
        </marc:datafield>
        <!-- Tobias?
            -> Angabe macht nur Sinn, wenn sie verknüpft werden kann  
            -> schauen, was Swissbib anbietet, sonst weglassen
        -->
        <!-- Tobias
            => mit der Systemnummer ist das natürlich möglich
            => deshalb würde ich das immer machen, egal ob die 
            Eintragungen identisch sind…
            => wichtig ist einfach, dass die Systemnummer so 
            erfasst wird, wie sie in 035 zu stehen kommt            
        -->
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Entstehungszeitraum']">
        <!--
            Guenter:
            Dieses Feld hat eine komplexere Struktur in EAD
            <DateRange DateOperator="exact">
            <FromDate>+2002</FromDate>
            <FromApproxIndicator>false</FromApproxIndicator>
            <ToDate/>
            <ToApproxIndicator>false</ToApproxIndicator>
            <TextRepresentation>2002</TextRepresentation>
            </DateRange>
            -> möglicherweise brauche ich den Scope Datentyp?!            
        --> 
        <!--
        Vorerst nehme ich hier ToDate - bis ich genauere Angaben zum datentyp von Scope erhalte            
        <marc:datafield tag="260" ind1=" " ind2=" " >
            <marc:subfield code="c">s. Frage zum Datentyp</marc:subfield>
        </marc:datafield>
        -->
        <!--         
        <marc:datafield tag="260" ind1=" " ind2=" " >
            <marc:subfield code="c"><xsl:value-of select="ElementValue/DateRange/TextRepresentation/text()"/></marc:subfield>
        </marc:datafield>
        -->
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='Archivalienart']">
        
        <!-- 
        <marc:datafield tag="300" ind1=" " ind2=" " >
            <marc:subfield code="a">Fotografie</marc:subfield>
        </marc:datafield>
        -->        
    </xsl:template>
    
    
    <xsl:template match="DataElement[@ElementName='Vorschaubild']">
        
        <!-- Tobias 
            Subfield $3 ist für swissbib dann interessant, 
            wenn man es als Selektionskriterium für die URL verwenden kann.
            
            Yvonne
            -> allenfalls könnte auf die Indikatoren geachtet werden: sie sind unterschiedlich. 
            Ist aber vielleicht einfacher mit $3.            
        -->
        <!--
            so nicht mehr (ab Version 7 Basisformular)            
        <marc:datafield tag="856" ind1="4" ind2="2" >
            <marc:subfield code="31"><xsl:value-of select="ElementValue/BlobValue/@FileName"/></marc:subfield>
            <marc:subfield code="u"><xsl:value-of select="ElementValue/BlobValue/@Url"/></marc:subfield>
        </marc:datafield>
        --> 

        <xsl:if test="not(../../UsageData/Accessability/text() = 'Sonderbewilligung Intranet')">
            
            <xsl:variable name="recordid" select="../.././@Id"/>
            <xsl:variable name="replacedurl" select="fn:replace($linkurl856vorschaubild,'XXX',$recordid)"/>
            
            <marc:datafield tag="950" ind1=" " ind2=" ">
                <marc:subfield code="E">42</marc:subfield>
                <marc:subfield code="B">CHARCH</marc:subfield>
                <marc:subfield code="P">856</marc:subfield>
                <marc:subfield code="3">Vorschaubild</marc:subfield>
                <marc:subfield code="u"><xsl:value-of select="$replacedurl"/></marc:subfield>
            </marc:datafield>
        </xsl:if>

    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Urheberrecht']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>


    <xsl:template match="DataElement[@ElementName='Urheberrechts-Inhaber']">
        
        <!-- Tobias 
            Urheberrechts-Inhaber
            Warum wird nicht das Feld 542 für Urheberangaben verwendet? -> Klar.
            542 $d Urheberrechts-Inhaber
        -->
        
        <marc:datafield tag="542" ind1=" " ind2=" " >
            <marc:subfield code="d"><xsl:value-of select="ElementValue/TextValue/text()"/>
            </marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkungen zum Urheberrechts-Inhaber']">
        
        <!-- Guenter
            Gibt es nicht!            
            Urheberrechts-Inhaber
            Warum wird nicht das Feld 542 für Urheberangaben verwendet? -> Klar.
            542 $d Urheberrechts-Inhaber
        -->
        
        <marc:datafield tag="542" ind1=" " ind2=" " >
            <marc:subfield code="n"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Partnerangaben Urheberrechts-Inhaber']">
        
        <!-- Tobias 
            Was ist hiermit gemeint? = Adresse
        -->
        
        <marc:datafield tag="542" ind1=" " ind2=" " >
            <marc:subfield code="e"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Urheberschaft']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='FotografIn']">
        
        <!-- Tobias 
            Vielleicht wäre hier ein $4-Relator-Code sinnvoll, um die Urheberin klar zu spezifizieren. 
            Yvonne
            -> entspricht nicht der Praxis der NB
            Tobias
            -> Wenn ein Feld 100 vorkommt, wird beim Feld 245 der 1. Indikator zu ind1="1"
            
            -> es wäre besser, wenn der Fotograf aus dem Deskriptoren-Feld generiert wird, 
            anstelle dieses Feldes, hier kann auch "unbekannt" eingegeben werden, was für eine Übernahme ins Feld 100 
            keinen Sinn macht (siehe am Schluss der Tabelle).
            -> Bibliothekarisch bekommt der Fotograf ein 100. Die Frage ist, ob diese Differenzierung mit 
            Haupteintragung bei einem Archivbestand nötig/gewünscht ist.
            
            falls weitere Fotografen vorhanden sind, diese in:
            <marc:datafield tag="700" ind1="1" ind2=" ">
            marc:subfield code="a">Nachname, Vorname</marc:subfield></marc:datafield> -> dieser Fall kommt nicht vor.            
        -->
        
        <!-- the content of this template  is covered in the named templates 
        
        cdFsingFotografin and 
        cdFmultFotografin
        because there is a differentiatiation between first and subsequent persons  
        -->
        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Angaben zum Vertrieb/Verlag']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    
    <xsl:template match="DataElement[@ElementName='Vertrieb/Verlag']">
        
        <!-- Tobias 
            Was ist unter Vertrieb zu verstehen? ->
            Yvonne            
            Wenn es nur eine Bezugsstelle ist       
        -->
        <!-- 
        <marc:datafield tag="260" ind1=" " ind2=" " >
            <marc:subfield code="b"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>    
        -->    
           <!-- -> Ist kein Vertrieb/Verlag vorhanden, wird kein Untefeld b angegeben. -->    
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Partnerangaben Verlag/Vertrieb']">
        
        <!-- -> Sind keine Partnerangaben vorhanden, wird kein Unterfeld a angegeben. 
            
            
            Frage Günter:
            Das heisst, dieser tag wird gar nicht gebildet?
            in den Beispieldaten gibt es hierzu keine Daten
        -->
        <!-- 
        <marc:datafield tag="260" ind1=" " ind2=" " >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>
        -->        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Inhalt und Beschaffenheit']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Visueller Inhalt']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Kurzbeschreibung']">
        <marc:datafield tag="520" ind1="3" ind2=" "   >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Ansichtsbild']">
        
        <!-- Mit Version 7 Basisformular geändert  
        <marc:datafield tag="856" ind1="4" ind2="0" >
            <marc:subfield code="31"><xsl:value-of select="ElementValue/BlobValue/@FileName"/></marc:subfield>
            <marc:subfield code="u"><xsl:value-of select="ElementValue/BlobValue/@Url"/></marc:subfield>
        </marc:datafield>
        -->
        <xsl:if test="not(../../UsageData/Accessability/text() = 'Sonderbewilligung Intranet')">
        
            <xsl:variable name="recordid" select="../.././@Id"/>
            <xsl:variable name="replacedurl" select="fn:replace($linkurl949y,'XXX',$recordid)"/>
            <marc:datafield tag="856" ind1="4" ind2="2">
                <marc:subfield code="3">Ansichtsbild</marc:subfield>
                <marc:subfield code="u"><xsl:value-of select="$replacedurl"/></marc:subfield>
            </marc:datafield>
        
        </xsl:if>        
        
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='VE-Objekt']">
        <!-- 
            Unterscheidet SwissBib zwischen den einzelnen 6XX-Felder (also 600, 650, 651)? 
            Ist es egal, ob wir ein 650 liefern – auch wenn es mal ein 651 sein sollte? 
            
            Die 6XX-Felder sollten auch noch mit der Sacherschliessung besprochen werden:
            Swissbib kann durchaus zwischen den verschiedenen Kategorien unterscheiden. 
            Wichtig wird dies allerdings nur dann, wenn Facetten angelegt werden sollen.
            
            Generell, wenn die Standard-SE-Felder verwendet werden, sollte Indikator 2 „7“ 
            und ein Unterfeld $2 mit der SW-Vokabular-Bezeichnung gesetzt werden, 
            da hierüber selektiert wird.
            -> Leider sind es keine SWD-Schlagworte. Wie ist es, wenn VE-Objekt, 
            Bauperiode, ArchitektIn, BauherrIn in das gleich 650 _4 kommen, 
            mit angezogenem Semikolon: ist es so Facetten tauglich? 
            Wird es bei der Aufnahme angegeben? Wenn nicht, besser in ein 5XX geben? 
            Analog für 651.
            => SWD, spielt eigentlich keine Rolle, die Kombo -7 $2 heisst ja nur, 
            dass das Vokabular wird in Unterfeld $2 spezifiziert wird. 
            Einzig bei einem allfälligen Import nach WorldCat müsste ein LC-Code beantragt werden, 
            ansonsten sind wir relativ frei…
            Wenn die einzelnen Deskriptoren selbst das Semikolon nie enthalten, 
            dann kann man es schon trennen. Insgesamt ist es aber angenehmer, 
            wenn wir pro Deskriptor ein Feld erhalten, dann ist es immer eindeutig.
            650 _4 ist sicher korrekt nur hat es den Nachteil, dass dann eine 
            Facettierung fehlschlägt, weil 6xx _4 ja eine Sammelkategorie für nicht bekannte 
            Schlagwortsysteme darstellt. Sollte man sich entschliessen, 
            diese Felder als Facetten darzustellen, hat man tendenziell "Kraut und 
            Rüben" zusammengemischt, was für die Nutzerinnen und Nutzer nicht 
            hübsch, bzw. unbrauchbar wird.
            
            Mit einem Code in Unterfeld $2 pro 6xx können wir sauber selektieren.
            OK. Separate Felder 6XX mit $2 (Vorschlag: CHARCH)
            
        --> 
        
        <xsl:for-each select="ElementValue/TextValue">
            <marc:datafield tag="650" ind1=" " ind2="7" >
                <marc:subfield code="a"><xsl:value-of select="./text()"/></marc:subfield>
                <marc:subfield code="2">CHARCH</marc:subfield>
            </marc:datafield>  
            
            
        </xsl:for-each>

       <!--             
            -> Angabe der 6XX-Felder in Facetten, wenn technisch möglich, 
            sonst genügt das Feld 245 und 520 für die Stichwortsuche und die Felder, 
            die in der Tabelle für 6XX vorgeschlagen werden, würden nicht angegeben. 
            Was interessanter für die 6XX-Felder (und somit die Facetten) wäre, 
            sind die Deskriptoren (siehe am Schluss der Tabelle).
            
        -->

    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bauperiode']">
        <marc:datafield tag="650" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/DateRange/FromDate"/>
                <xsl:if test="ElementValue/DateRange/ToDate/text()">
                    <xsl:text> / </xsl:text>
                    <xsl:value-of select="ElementValue/DateRange/ToDate"/>
                </xsl:if>
            </marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='ArchitektIn']">
        
        <!-- 
            Wäre es nicht besser, hier auf 700, 710 mit
            einem Relatoren zu setzen?
            700 $a Frisch, Max $4 arch
            
            => Grund:
            1. eine Frage der Indexierung:
            7x0 im Autor/Verfasser plus „alle Felder“
            2. eine Frage der Relation zum Dargestellten:
            Ist eine Interpretation analog zur Nebeneintragung für 
            die gefeierte Person bei einer Festschrift sinnvoll?
            -> Nein, ist nicht ganz der gleiche Fall. 
            Ich würde es eher mit einem Architekturbuch vergleichen, 
            das die Werke eines Architekten bespricht, 
            dort würde der Architekt nur inhaltlich abgedeckt (600), 
            nicht formal.
            => OK, aber dann könnte man ein 600-Feld einsetzen 
            oder wird nicht zwischen Person und Körperschaft 
            unterschieden?

        -->
        
        <marc:datafield tag="600" ind1=" " ind2="7" >
            <marc:subfield code="a">Bisher keine Beispieldaten</marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>            
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='BauherrIn']">
        <marc:datafield tag="600" ind1=" " ind2="7" >
            <marc:subfield code="a">bisher keine Beipieldaten</marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Geopolitische Daten']">
        <!-- 
        
        - 
        -> Angaben für 651-Felder aus Deskriptoren nehmen? 
        Siehe am Schluss der Tabelle.
        Guenter: ????
        
        

        -->   

        <marc:datafield tag="999" ind1=" " ind2="7" >
            <marc:subfield code="a">bisher keine Beipieldaten</marc:subfield>
        </marc:datafield>            
        

    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Land']">
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Kanton']">
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Gemeinde']">
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>            
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Postleitzahl']">
        
        <!--         
            in Ort enthalten
        <marc:datafield tag="651" ind1=" " ind2="7" >was ist das??</marc:datafield>
        <marc:datafield tag="651" ind1=" " ind2="7" >nodename: <xsl:value-of select="name(current())"/></marc:datafield>
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
        -->        
    </xsl:template>


    <xsl:template match="DataElement[@ElementName='Ort']">

        <!-- 
            Die Angaben aus Postleitzahl, Ort, 
            Strasse sollten in ein Feld 651 kommen, 
            da sie einzeln nicht viel aussagen: 
            zuerst Strasse mit Komma Leerschlag, dann Postleitzahl mit Leerschlag, 
            dann Ort
        --> 
        

        <xsl:variable name="ort" select="ElementValue/TextValue/text()"/>
        <xsl:variable name="plz" select="preceding-sibling::DataElement[@ElementName='Postleitzahl']/ElementValue/TextValue/text()"/>
        <xsl:variable name="strasse" select="following-sibling::DataElement[@ElementName='Strasse']/ElementValue/TextValue/text()"/>
        
        
        
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="$strasse"/>, <xsl:value-of select="$plz"/><xsl:text> </xsl:text> <xsl:value-of select="$ort"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>    
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Strasse']">
        <!--
         in Ort enthalten            
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a">keine Beipieldaten</marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
        -->        
            
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Lokalname']">
        <marc:datafield tag="651" ind1=" " ind2="7" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>    
            
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='Koordinaten X']">
        
        <!--
            Tobias:            
            Falls man mit dem Einsatz von 255 und 034 den Bogen 
            nicht überspannt, würde ich diese Variante bevorzugen, 
            da wir diese Felder konsistent auswerten können. 
            Falls nicht dann würde sich ein Feld 59x anbieten, 
            das die Daten analog zur Struktur von 034/255 erfasst – 
            ansonsten ist die Info nur schwer nutzbar. 
            Ich denke v.a. an die Verknüpfung von Bildern mit 
            Geoinformationssystemen... 
            Yvonne
            -> ich habe nachgefragt: es handelt sich um 
            Schweizer Koordinaten (also Feld 595). Gibt es eine 
            automatische Konversion für Swissbib-Daten, 
            die daraus 034 / 255 macht?
            Tobias
            => Nein, das haben wir bislang auch nicht vor – 
            mir war es einfach wichtig, dass die Info möglichst 
            nutzbar erhalten bleibt.


            Mail Yvonne 4.11.2010
            Vielen Dank für deine Anpassungen! Hier bereits mein Kommentar zu den Koordinaten im Feld 595: Bitte X-Koordinate in den Subfields d und e, Y-Koordinate in den Subfields f und g ablegen:
            
            <marc:datafield tag="595" ind1=" " ind2=" ">
            <marc:subfield code="d">691200.1000</marc:subfield><marc:subfield code="e">691200.1000</marc:subfield><marc:subfield code="f">266230.2000</marc:subfield><marc:subfield code="g">266230.2000</marc:subfield>

        -->

        <marc:datafield tag="595" ind1=" " ind2=" " >
            <marc:subfield code="d"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="e"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <xsl:if test="following-sibling::DataElement[@ElementName='Koordinaten Y']/ElementValue/TextValue/text()">
                
                <marc:subfield code="f"><xsl:value-of select="following-sibling::DataElement[@ElementName='Koordinaten Y']/ElementValue/TextValue/text()"/></marc:subfield>
                <marc:subfield code="g"><xsl:value-of select="following-sibling::DataElement[@ElementName='Koordinaten Y']/ElementValue/TextValue/text()"/></marc:subfield>
                
            </xsl:if>
            <!-- 
            <marc:subfield code="f">???</marc:subfield>
            <marc:subfield code="g">???</marc:subfield>
            -->
        </marc:datafield>
        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Koordinaten Y']">
        <!-- 
            s. Koordinaten X            
        -->
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Bewertung']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Beschriftung - Legende']">
        <xsl:for-each select="ElementValue">
            <marc:datafield tag="562" ind1=" " ind2=" " >
                <marc:subfield code="c"><xsl:value-of select="TextValue/text()"/></marc:subfield>
            </marc:datafield>    
            
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung zur Beschriftung - Legende']">
        <!-- 
            Kombination: <marc:datafield tag="562" ind1=" " ind2=" ">
            <marc:subfield code="c">Legende, Bemerkung zur Beschriftung 
            – Legende; Unterschrift, Bemerkung zur Unterschrift</marc:subfield> -> 
            mit angezogenem Semikolon trennen ODER pro Art und 
            Bemerkung ein Feld 562.
        -->
        
        <marc:datafield tag="562" ind1=" " ind2=" " >
            <marc:subfield code="c"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>    
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Unterschrift']">
        <marc:datafield tag="562" ind1=" " ind2=" " >
            <marc:subfield code="c"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>    
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung zur Unterschrift']">
        <marc:datafield tag="562" ind1=" " ind2=" " >
            <marc:subfield code="c"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>            
    </xsl:template>


    <xsl:template match="DataElement[@ElementName='Technische Angaben']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Farbe']">
        <!-- 
        <marc:datafield tag="300" ind1=" " ind2=" " >
            <marc:subfield code="b"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>
        -->        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Orientierung und Form']">

        <!-- 

        Worauf bezieht sich diese Info genau?
        Ich frage deshalb weil der 3##-Bereich hier je nach dem Felder 
        anbietet... 
        -> von mir aus kann man die Angaben wie "Quadrat", "Vertikal", 
        "Horizontal" nicht im Feld 300 angeben. 
        Deshalb habe ich eine Fussnote vorgeschlagen.
        => Ich hätte auch nicht an 300 gedacht sondern 
        342, 343 oder 351 – bin damit nach nochmaligem 
        Lesen der Felddoku aber in jedem Fall auf dem Holzweg
        -->
        
        <marc:datafield tag="500" ind1=" " ind2=" " >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>

        <!-- 
            Hier kann Quadrat, vertikal etc. stehen. 
            Kann das Feld jeweils mit "Orientierung und Form:" 
            eingeleitet werden?
            
            -> Da das Format häufig erst auf der tieferen Stufe 
            vorhanden ist, muss diese Angabe vermerkt werden
        -->


    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Masse']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Standard Bildformat']">
        
        <!-- 
            Angabe nur wenn auf dieser Stufe vorhanden, sonst Unterfeld weglassen
        -->
        <!--
        <marc:datafield tag="300" ind1=" " ind2=" " >
            <marc:subfield code="c"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>
        -->        
    </xsl:template>
                

    <xsl:template match="DataElement[@ElementName='Interne Angaben']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Erschliessungsgrad']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Projekte']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Interne Bemerkung']">
        <!-- 
            bleibt unberücksichtigt!            
        -->
    </xsl:template>
    
    
    <xsl:template match="DataElement[@ElementName='Autor / Sammler']">
        
        
        <!--
            Tobias            
            Hmm, wenn es nur um die genauere Bezeichnung einer Eintragung ginge, 
            wäre dann ein Relator-Code nicht besser? 
            Yvonne
            -> Im Hinblick auf andere Sammlungen, wäre ein 700 mit $4 Sammler 
            wirklich interessant
            => Soweit ich das verstanden habe, müsste $4 immer einen 
            kodierten Wert enthalten. Für Sammler wäre dies „col“        
        -->
        <marc:datafield tag="561" ind1=" " ind2=" " >
            <marc:subfield code="a">bisher keine Daten für Autor sammler</marc:subfield>
        </marc:datafield>

        <!-- 
        oder
        -->
        <marc:datafield tag="700" ind1="1" ind2=" " >
            <marc:subfield code="a">bisher keine Daten  für Auto Sammler</marc:subfield>
            <marc:subfield code="4">col</marc:subfield>
        </marc:datafield>    
        
        <!-- 
            -> Den Sammler nicht aus dem Formular nehmen, sondern aus dem Modul 
            "Ablieferungen": Begriff "Abliefernde Stelle" und 
            "Aktenbildende Stelle" mit Unterscheidung Person oder Körperschaft:
            
        -->
        <!-- Person -->

        <marc:datafield tag="700" ind1="1" ind2=" " >
            <marc:subfield code="a">bisher keine Daten für Autor Sammler</marc:subfield>
            <marc:subfield code="4">col</marc:subfield>
        </marc:datafield>

        <!-- Körperschaft -->

        <marc:datafield tag="710" ind1="2" ind2=" " >
            <marc:subfield code="a">bisher keine Daten für Autor Sammler</marc:subfield>
            <marc:subfield code="4">col</marc:subfield>
        </marc:datafield>



    </xsl:template>
    
    <xsl:template match="AdministrativeData">
        <!-- 
            bleibt unberücksichtigt??
            was machen wir damit??
        -->
    </xsl:template>

    <xsl:template match="UsageData">
        <!-- 
            bleibt unberücksichtigt??
            was machen wir damit??
        -->
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='Effektive Masse Bild']">

        <xsl:comment>Achtung: keine MARCdefinitionen für Effektive Masse Bild</xsl:comment>        
        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Transparenz']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Transparenz</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Montage']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Montage</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Fototechnik allgemein']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Fototechnik allgemein</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Verfahren']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Verfahren</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Trägermaterial']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Trägermaterial</xsl:comment>        
    </xsl:template>
        
    <xsl:template match="DataElement[@ElementName='Fototechnik genau']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Fototechnik genau</xsl:comment>        
    </xsl:template>
        
    <xsl:template match="DataElement[@ElementName='Standort / Behältnis']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Standort Behältnis</xsl:comment>        
    </xsl:template>
            
    <xsl:template match="DataElement[@ElementName='Dokumentart']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Dokumentart</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Alte Dokumentnummern']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Alte Dokumentnummern</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="Descriptors">
        <xsl:comment>Achtung: keine MARCdefinitionen für Descriptors</xsl:comment>        
    </xsl:template>

    <xsl:template match="Files">
        <xsl:comment>Achtung: keine MARCdefinitionen für Files</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Stempel']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Stempel</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Rahmen']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Rahmen</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Rahmenart']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Rahmenart</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung zum Bildformat']">
        <!-- 
            in Word-Dokument nicht gefunden!!            
        -->
    </xsl:template>
        
    <xsl:template match="DataElement[@ElementName='Andere Archivalienarten']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Andere Archivalienarten</xsl:comment>        
    </xsl:template>
      
    <xsl:template match="DataElement[@ElementName='Art der Nachbehandlung']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Art der Nachbehandlung</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Montagemittel']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Montagemittel</xsl:comment>        
    </xsl:template>
    <xsl:template match="DataElement[@ElementName='Montageart andere']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Montageart andere</xsl:comment>        
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Montageart']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Montageart</xsl:comment>        
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='Effektive Masse Montage']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Effektive Masse Montags</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung zum Stempel']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Bemerkungen zum Stempel</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Bemerkung</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Ordnungsnummer']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Ordnungsnummer</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bewertungsmerkmale']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Bewertungsmerkmale</xsl:comment>        
    </xsl:template>
        

    <xsl:template match="DataElement[@ElementName='Darin']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Darin</xsl:comment>        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Partnerangaben Vertrieb/Verlag']">
        <xsl:comment>Achtung: keine MARCdefinitionen für Partnerangaben Vertrieb/Verlag</xsl:comment>        
    </xsl:template>
    
    
    
<!-- templates for Descriptors/Descriptor Elements -->


    <xsl:template match="Descriptors/Descriptor">
        
        <!-- 
        intern Günter:
        warum funktioniert die Konstruktion
        <xsl:template match="Descriptors/Descriptor/Name[text()='Abgebildete Person']">
        <marc:datafield tag="600" ind1="1" ind2="7" >
        <marc:subfield code="a"><xsl:value-of select="normalize-space(parent::node()/child::IdName/text())"/></marc:subfield>
        <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
        <xsl:comment>Warum hier eigentlich das CHARCH??</xsl:comment>        
        <xsl:comment>Wie kommen wir an die Personen aus dem Thesaurus</xsl:comment>        
        
        nicht
        ich erhalte am Ende der Schablone immer noch den Wert des kompletten Nodes.
        Wie kann ich das abfangen
        Behelfslösung:
        choose Abfrage und templateRegel auf den kompletten Node setzen        
        </xsl:template>
        
        <xsl:analyze-string select="$date" 
        regex="([0-9]+)/([0-9]+)/([0-9]{{4}})">
        <xsl:matching-substring>
        <xsl:number value="regex-group(3)"
        format="0001"/>          
        <xsl:text>-</xsl:text> ...
        
        
        Zinggeler, Rudolf (1864 - 1954)
        -->
            
        <xsl:choose>
            <xsl:when test="Name[text()='FotografIn']">
                <xsl:choose>
                    <xsl:when test="Thesaurus[text()='Körperschaften']">
                        <xsl:variable name="fotografInvalue" select="normalize-space(SeeAlso/text())"/>
                        <xsl:analyze-string select="$fotografInvalue" 
                            regex="(.*)(\(.*\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1" select="regex-group(1)"/>
                                <xsl:variable name="part2" select="regex-group(2)"/>
                                <marc:datafield tag="710"  ind1="1" ind2=" "  >
                                    <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                    <marc:subfield code="d"><xsl:value-of select="fn:replace($part2,' ','')"/></marc:subfield>
                                </marc:datafield>
                            </xsl:matching-substring>
                        </xsl:analyze-string>       
                    </xsl:when>
                    <xsl:when test="Thesaurus[text()='Personen']">
                        <xsl:variable name="fotografInvalue" select="normalize-space(SeeAlso/text())"/>
                        <xsl:analyze-string select="$fotografInvalue" 
                            regex="(.*)(\(.*\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1">
                                    <xsl:choose>
                                        <xsl:when test="fn:contains(regex-group(1),'?')">
                                            <xsl:value-of select="fn:substring-before(regex-group(1),',')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    
                                </xsl:variable>
                                
                                <!--<xsl:variable name="part1" select="regex-group(1)"/> -->
                                <xsl:variable name="part2" select="regex-group(2)"/>
                                
                                <!-- Kommafall -->                                
                                <xsl:choose>
                                    <xsl:when test="fn:contains($part1,',')">">
                                        <xsl:variable name="nn" select="fn:substring-before($part1,',')"/> 
                                        <xsl:variable name="vn" select="fn:substring-after($part1,',')"/>                                        
                                        <marc:datafield tag="700"  ind1="1" ind2=" "  >
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($nn)"/></marc:subfield>
                                            <marc:subfield code="D"><xsl:value-of select="normalize-space($vn)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:replace($part2,' ','')"/></marc:subfield>
                                        </marc:datafield>    
                                        
                                    </xsl:when>
                                    
                                    <xsl:otherwise>
                                        <marc:datafield tag="700"  ind1="1" ind2=" "  >
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:replace($part2,' ','')"/></marc:subfield>
                                        </marc:datafield>
                                        
                                    </xsl:otherwise>
                                </xsl:choose>
                                
                                
                            </xsl:matching-substring>
                        </xsl:analyze-string>       
                    </xsl:when>
                </xsl:choose>
                
                
            </xsl:when>


            <xsl:when test="Name[text()='Abgebildete Person']">
                <marc:datafield tag="600" ind1=" " ind2="7" >
                    <marc:subfield code="a"><xsl:value-of select="normalize-space(child::SeeAlso/text())"/></marc:subfield>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
            </xsl:when>
            

        </xsl:choose>
        


        <!--

         Günter: 3.11.2010 (Yvonne v. 28.10.2010)
         Fotografen werden jetzt generell in die 700er Felder genommen
        <xsl:choose>
            <xsl:when test="Name[text()='FotografIn']">
            <marc:datafield tag="100"  ind1=" " ind2="1"  >
                    <marc:subfield code="a"><xsl:value-of select="normalize-space(IdName/text())"/></marc:subfield>
                </marc:datafield>
                <xsl:comment>Achtung: hier ein Problem mit den Daten aus dem DataElement Fotografin
                    Was nehmen wir??
                </xsl:comment>        
                <xsl:comment>Würde es nicht Sinn machen, hier auch die Personen aus dem SeeAlso Tag zu nehmen??</xsl:comment>        
            </xsl:when>
            <xsl:when test="Name[text()='Brustbild']">
                <marc:datafield tag="655" ind1=" " ind2="7" >
                    <marc:subfield code="a"><xsl:value-of select="normalize-space(IdName/text())"/></marc:subfield>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
                <xsl:comment>Was machen wir beim Brustbild mit dem Thesaurus tag</xsl:comment>        
                
            </xsl:when>

            <xsl:when test="Name[text()='Abgebildete Person']">
                <marc:datafield tag="600" ind1=" " ind2="7" >
                    <marc:subfield code="a"><xsl:value-of select="normalize-space(child::IdName/text())"/></marc:subfield>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
                <xsl:comment>Warum hier eigentlich das CHARCH??</xsl:comment>        
                <xsl:comment>Wie kommen wir an die Personen aus dem Thesaurus</xsl:comment>        
            </xsl:when>
            
            <xsl:when test="Name[text()='Kopfbild']">
                <xsl:comment>Achtung: keine MARCdefinitionen für Descriptors/Descriptor/Name[text()='Kopfbild']</xsl:comment>        
            </xsl:when>
            
        </xsl:choose>
        -->
        
    </xsl:template>
        


    <!-- refactor these named templates later (own modules) -> should be imported!  -->
    
    <xsl:template name="createLeader">
        <marc:leader >
            <xsl:text>     nkm a22     4  4500</xsl:text>
        </marc:leader>
    </xsl:template>

    <xsl:template name="cCtrlF001">
        <marc:controlfield  tag="001" >
            <xsl:text>cha</xsl:text><xsl:value-of select="@Id"/>
        </marc:controlfield>
    </xsl:template>

    <xsl:template name="cCtrlF003">
        <!-- 
        <marc:controllfield  tag="003" >
            <xsl:text>Sz</xsl:text><xsl:value-of select="@Id"/>
        </marc:controllfield>
        <marc:controllfield  tag="003" >
            <xsl:text>CHARCH</xsl:text><xsl:value-of select="@Id"/>
        </marc:controllfield>
        geändert auf Hinweis von Yvonne 27.10.2010!
        -->
        <marc:controlfield  tag="003">
            <xsl:text>CHARCH</xsl:text>
        </marc:controlfield>
        
    </xsl:template>

    <xsl:template name="cCtrlF007" >
        <!-- cr plus 21 blanks -->
        <marc:controlfield  tag="007" ><xsl:text>cr                     </xsl:text></marc:controlfield>
    </xsl:template>
    

    <xsl:template name="cCtrlF008" >
       <!-- <xsl:variable name="tempDateEdited" select="fn:year-from-date(AdministrativeData/LastEditedOn)"/> -->
        <xsl:variable name="tempYearEdited2" select="fn:format-date(AdministrativeData/LastEditedOn,'[Y,2-2]')"/>
        <xsl:variable name="tempMonthEdited" select="fn:format-date(AdministrativeData/LastEditedOn,'[M,2]')"/>
        <xsl:variable name="tempDayEdited" select="fn:format-date(AdministrativeData/LastEditedOn,'[D,2]')"/>
        <xsl:variable name="tempYearCreated4" select="fn:substring(DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/FromDate,2)"/>
        
        <!-- Todo: wie bekomme ich heraus, dass ein Wert nicht existiert?? 
            hier bei $tempYearCreated4: vor allem beim ersten record gibt es diesen Satz nicht
        -->
        
        <marc:controlfield  tag="008" >
            <xsl:value-of select="$tempYearEdited2"></xsl:value-of>
            <xsl:value-of select="$tempMonthEdited"></xsl:value-of>
            <xsl:value-of select="$tempDayEdited"></xsl:value-of>
            <xsl:text>s</xsl:text>
            <xsl:choose>
                <xsl:when test="$tempYearCreated4 = ''">
                    <!--<xsl:text>    </xsl:text> 
                    Todo: s. Hinweis Yvonne ob level serie aufgenommen werden soll
                    lassen wir die serie weg, fehlt uns die Referenz auf den Parentid-->                    
                    <xsl:text>uuuu</xsl:text>                    
                </xsl:when>
                <xsl:otherwise>
                    <!-- GH 20110104
                        We got problems with records containing a detailed date 
                        in $tempYearCreated4 like '195409'
                        With the 09 characters the value is too long
                        a more detailed and sophisticated solution 
                        (other character than s
                        isn't handy at this time
                        see also: http://www.loc.gov/marc/bibliographic/bd008a.html
                        
                    -->
                    <xsl:choose>
                        <xsl:when test="fn:string-length($tempYearCreated4) > 4">
                            <xsl:value-of select="fn:substring($tempYearCreated4,1,4)"/>        
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$tempYearCreated4"/>        
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>    sz                inzxx d</xsl:text>
            
        </marc:controlfield>
    </xsl:template>
    
    <xsl:template name="cdF035">
        <marc:datafield  tag="035"  ind1=" " ind2=" "  >
            <marc:subfield code="a">
                <xsl:text>(CHARCH)cha</xsl:text><xsl:value-of select="@Id"/>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template name="cdF040">
        <marc:datafield  tag="040"  ind1=" " ind2=" "  >
            <marc:subfield code="a">
                <xsl:text>Sz</xsl:text>
            </marc:subfield>
            <marc:subfield code="c">
                <xsl:text>Sz</xsl:text>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    

    <xsl:template name="cdFmultFotografin">
        <marc:datafield  tag="700"  ind1="1" ind2=" "  >
            <marc:subfield code="a">
                <xsl:value-of select="ElementValue/TextValue/text()"/>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    

    <xsl:template name="cdFsingFotografin">
        <marc:datafield  tag="100"  ind1="1" ind2=" "  >
            <marc:subfield code="a">
                <xsl:value-of select="ElementValue/TextValue/text()"/>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    

    <xsl:template match="DataElement[@ElementName='Entstehungszeitraum']" mode="feld260">
        <!--
            Guenter:
            Dieses Feld hat eine komplexere Struktur in EAD
            <DateRange DateOperator="exact">
            <FromDate>+2002</FromDate>
            <FromApproxIndicator>false</FromApproxIndicator>
            <ToDate/>
            <ToApproxIndicator>false</ToApproxIndicator>
            <TextRepresentation>2002</TextRepresentation>
            </DateRange>
            -> möglicherweise brauche ich den Scope Datentyp?!            
        --> 
        <!--
            Vorerst nehme ich hier ToDate - bis ich genauere Angaben zum datentyp von Scope erhalte            
            <marc:datafield tag="260" ind1=" " ind2=" " >
            <marc:subfield code="c">s. Frage zum Datentyp</marc:subfield>
            </marc:datafield>
        -->        
            <marc:subfield code="c"><xsl:value-of select="ElementValue/DateRange/TextRepresentation/text()"/></marc:subfield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Vertrieb/Verlag']" mode="feld260">
        
        <marc:subfield code="b"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Partnerangaben Verlag/Vertrieb']" mode="feld260">
        
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Archivalienart']" mode="feld300">
            <marc:subfield code="a">Fotografie</marc:subfield>
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Farbe']" mode="feld300">
        <marc:subfield code="b"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Standard Bildformat']" mode="feld300">
        <marc:subfield code="c"><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
    </xsl:template>
    
</xsl:stylesheet>

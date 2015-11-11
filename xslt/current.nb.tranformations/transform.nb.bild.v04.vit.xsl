<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
     version="2.0"
     xmlns:marc="http://www.loc.gov/MARC21/slim">
    
    <xsl:output 
        indent="yes" 
        method="xml"
        />
    
    <!-- ***************************************
         * Scope-Formular: BILD
         * nicht für Fotos verwenden
         ***************************************
    -->
    
    <!-- =======================================
         Sektion für allgemeine Codes 
         =======================================
    -->
    
    <!-- Base URL (aktuell nicht in Gebrauch) -->
    <xsl:param name="hostname" select="'http://www.nb.admin.ch/'" />
    
    <!-- Sammlungscode für swissbib (muss mit swissbib abgesprochen werden)
     CHARCH01: Graphische Sammlung - EAD
     CHARCH02: Schweizerisches Literatur Archiv (aktuell nur Fotos Annemarie Schwarzenbach)
     CHARCH03: Graphische Sammlung - Sammlung Guggelmann
     CHARCH04: CDN - Dürrenmatt Werke
    -->
    <xsl:param name="institutioncode" select="'CHARCH03'" />
    
    
    <!-- Vorschaulinks auf helveticarchives -->
    <xsl:variable name="linkurl949y" select="'http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=80'"/>
    <xsl:variable name="linkurl856ansichtsbild" select="'http://www.helveticarchives.ch/bild.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=10'" />
    <xsl:variable name="linkurl956vorschaubild" select="'http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=10'" />
   
    <!-- Option zum GLOBALEN Übersteuern des Reproduktionsstatus
        Standard: Reproduktionsbewilligung
        Denkbare Optionen: 
        - CC0
        - keine Reproduktionsbewilligung nötig
    -->
    <xsl:param name="rights949z" select="'Reproduktionsbewilligung'" />

    <!-- =======================================
         Sektion für die Sammlungsstruktur der marc:records 
         =======================================
    -->
    <xsl:template match="/">
        <marc:collection >
            <!-- start processing of record nodes -->
            <xsl:apply-templates/>
        </marc:collection>
    </xsl:template>

    <!-- =======================================
         Sektion zur Erstellung der marc:record-Datenstruktur 
         =======================================
    -->

    <xsl:template match="Record">
        
        <!-- selection criteria for determining if a record-structure should be processed at all
             checks for: 
             - record level information
             - data type (by validating the "edit form")
             - presence of a digital resource
        -->
        <xsl:if test="((@Level='Dokument') and (AdministrativeData/EditForm/text() = 'NB Gemälde/Plan/Zeichnung/Grafik'))
            and DetailData/DataElement[@ElementName='Ansichtsbild']"> 

            <marc:record >
                
                <!-- at first process fix nodes -primarily control nodes- which should be part of every MARC - record
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
                
                <!-- now the data driven dynamic part begins -->
                <xsl:variable name="datafields">
                    <xsl:apply-templates select="DetailData/DataElement"/>
                    <xsl:apply-templates select="Descriptors/Descriptor"/>

                    <!-- named templates -->
                    <xsl:call-template name="cdF260"/>
                    <xsl:call-template name="cdF542"/>
                    <xsl:call-template name="cdF562"/>

                        <!-- VM020353 = Bild (online) und der dazu gehörende allg. Filtercode XM020000 -->
                    <marc:datafield tag="898" ind2=" " ind1=" " >
                        <marc:subfield code="a"><xsl:text>VM020353</xsl:text></marc:subfield>
                        <marc:subfield code="b"><xsl:text>XM020000</xsl:text></marc:subfield>
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
    

    <!-- =======================================
         Sektion zur Erstellung der marc:Datenstruktur 
         =======================================
    -->

    <!-- MARC-Feld 000 -->
    <xsl:template name="createLeader">
         <marc:leader >
             <xsl:text>    nkm a22     4  4500</xsl:text>
         </marc:leader>
     </xsl:template>
     
     <!-- MARC-Feld 001 -->
     <xsl:template name="cCtrlF001">
         <marc:controlfield tag="001" >
             <xsl:text>cha</xsl:text><xsl:value-of select="@Id"/>
         </marc:controlfield>
     </xsl:template>

     <!-- MARC-Feld 003 -->
     <!-- sauber wäre "Sz" , der Code ist aber für die NB und hier zu unspezifisch -->
     <xsl:template name="cCtrlF003">
         <marc:controlfield tag="003">
             <xsl:text>CHARCH</xsl:text>
         </marc:controlfield>
     </xsl:template>

     <!-- MARC-Feld 007 -->
     <xsl:template name="cCtrlF007" >
         <!-- cr plus 21 blanks -->
         <marc:controlfield tag="007" ><xsl:text>cr                     </xsl:text></marc:controlfield>
     </xsl:template>
    
     <!-- MARC-Feld 008 -->
     <!-- Minimales Feld 008 -->
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
             <!-- Erstellungsdatum des Datensatzes: 00-05 -->
             <xsl:value-of select="$tempYearEdited2"></xsl:value-of>
             <xsl:value-of select="$tempMonthEdited"></xsl:value-of>
             <xsl:value-of select="$tempDayEdited"></xsl:value-of>
             <!-- Datumspositionen: 06-11 -->
             <xsl:text>s</xsl:text>
             <xsl:choose>
                 <xsl:when test="$tempYearCreated4 = ''">
                     <!--<xsl:text></xsl:text> 
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
              <!-- Land und Rest: 12-39 (grob) -->
             <xsl:text>    sz                cnzxx d</xsl:text>
         </marc:controlfield>
     </xsl:template>
    
     <!-- MARC-Feld 035 -->
     <xsl:template name="cdF035">
         <marc:datafield tag="035" ind1=" " ind2=" ">
             <marc:subfield code="a">
                 <xsl:text>(CHARCH)cha</xsl:text><xsl:value-of select="@Id"/>
             </marc:subfield>
         </marc:datafield>
     </xsl:template>
    
     <!-- MARC-Feld 040 -->
     <xsl:template name="cdF040">
         <marc:datafield tag="040" ind1=" " ind2=" ">
             <marc:subfield code="a">
                 <xsl:text>Sz</xsl:text>
             </marc:subfield>
             <marc:subfield code="c">
                 <xsl:text>Sz</xsl:text>
             </marc:subfield>
         </marc:datafield>
     </xsl:template>


    <!-- MARC-Feld: 245 -->

    <xsl:template match="DataElement[@ElementName='Titel / Name']">
        <marc:datafield tag="245" ind1="0" ind2="0" >
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="h">[Bild]</marc:subfield>
        </marc:datafield>
    </xsl:template>

    <!-- MARC-Feld: 246 -->

    <xsl:template match="DataElement[@ElementName='Titel (Variante)']/ElementValue/TextValue/text()">
        <xsl:for-each select="tokenize(., '\n\r?')[.]">
            <marc:datafield tag="246" ind1="1" ind2="3" >
                <marc:subfield code="a"><xsl:sequence select="."></xsl:sequence></marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- MARC-Feld 260 -->
    
    <xsl:template name="cdF260">
        <xsl:variable name="ort" select="DetailData/DataElement[@ElementName='Partnerangaben Verlag/Vertrieb']/ElementValue/TextValue/text()"/>
        <xsl:variable name="verlag" select="DetailData/DataElement[@ElementName='Vertrieb/Verlag']/ElementValue/TextValue/text()"/>
        <xsl:variable name="zeit" select="DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/TextRepresentation/text()"/>
        
        <marc:datafield tag="260" ind1=" " ind2=" ">
            <xsl:choose>
                <xsl:when test="$ort | $verlag | $zeit">
                    <xsl:choose>
                        <xsl:when test="$ort">
                            <marc:subfield code="a"><xsl:value-of select="$ort"/></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="a">[s.l.]</marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$verlag">
                            <marc:subfield code="b"><xsl:value-of select="$verlag"/></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="b">[s.n.]</marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$zeit">
                            <marc:subfield code="c"><xsl:value-of select="$zeit"/></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="c">[unbekannt]</marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <marc:subfield code="c">[unbekannt]</marc:subfield>
                </xsl:otherwise>
            </xsl:choose>
        </marc:datafield>
    </xsl:template>
        
    <!-- MARC-Feld: 300 -->

    <xsl:template match="DataElement[@ElementName='Archivalienart']">
        <xsl:variable name="archivalienart" select="ElementValue/TextValue/text()"/>
        <xsl:variable name="technik" select="following-sibling::DataElement[@ElementName='Technik']/ElementValue/TextValue/text()"/>
        <xsl:variable name="bildmasse" select="following-sibling::DataElement[@ElementName='Effektive Masse Bild']/ElementValue/TextValue/text()"/>
        
        <xsl:if test="$archivalienart | $technik | $bildmasse">
         <marc:datafield tag="300" ind1=" " ind2=" " >
            <xsl:choose>
                <xsl:when test="$technik">
                    <xsl:choose>
                        <xsl:when test="fn:contains($technik,', ')">
                            <xsl:variable name="sfa" select="fn:substring-before($technik,', ')"/>
                            <xsl:variable name="sfb" select="fn:substring-after($technik,', ')"/>
                            <marc:subfield code="a"><xsl:value-of select="$sfa" /></marc:subfield>
                            <marc:subfield code="b"><xsl:value-of select="$sfb" /></marc:subfield>
                        </xsl:when>
                        <xsl:when test="fn:contains($technik,'; ')">
                            <xsl:variable name="sfa" select="fn:substring-before($technik,'; ')"/>
                            <xsl:variable name="sfb" select="fn:substring-after($technik,'; ')"/>
                            <marc:subfield code="a"><xsl:value-of select="$sfa" /></marc:subfield>
                            <marc:subfield code="b"><xsl:value-of select="$sfb" /></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="a"><xsl:value-of select="$technik" /></marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$archivalienart">
                    <marc:subfield code="a"><xsl:value-of select="$archivalienart" /></marc:subfield>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="$bildmasse">
                <marc:subfield code="c"><xsl:value-of select="$bildmasse" /></marc:subfield>
            </xsl:if>
         </marc:datafield>
        </xsl:if>
    </xsl:template>

    <!-- MARC-Feld: 490 und 830 -->

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
    
    <!-- MARC-Feld 500 -->
    
    <xsl:template match="DataElement[@ElementName='Titel (Variante) Spezifikation -  Art und Quelle']/ElementValue/TextValue/text()">
        <xsl:for-each select="tokenize(., '\n\r?')[.]">
            <marc:datafield tag="500" ind1=" " ind2=" " >
                <marc:subfield code="a"><xsl:sequence select="."></xsl:sequence></marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Orientierung und Form']">
        <marc:datafield tag="500" ind1=" " ind2=" " >
            <marc:subfield code="a">Orientierung und Form: <xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- MARC-Feld 510 -->
    
    <xsl:template match="DataElement[@ElementName='Kurzbeschreibung/ElementValue/TextValue/text()']">
        <xsl:for-each select="tokenize(., '\n\r?')[.]">
            <marc:datafield tag="510" ind1=" " ind2=" ">
                <marc:subfield code="a"><xsl:sequence select="."></xsl:sequence></marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- MARC-Feld 520 -->
    
    <xsl:template match="DataElement[@ElementName='Kurzbeschreibung']">
        <marc:datafield tag="520" ind1="3" ind2=" ">
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung zur Kurzbeschreibung']">
        <marc:datafield tag="520" ind1="3" ind2=" ">
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- MARC-Feld 542 -->

    <xsl:template name="cdF542">
        <xsl:variable name="UrheberrechtsInhaber" select="DetailData/DataElement[@ElementName='Urheberrechts-Inhaber']/ElementValue/TextValue/text()"/>
        <xsl:variable name="BemUrheberrechtsInhaber" select="DetailData/DataElement[@ElementName='Bemerkungen zum Urheberrechts-Inhaber']/ElementValue/TextValue/text()"/>
        <xsl:variable name="PartUrheberrechtsInhaber" select="DetailData/DataElement[@ElementName='Partnerangaben Urheberrechts-Inhaber']/ElementValue/TextValue/text()"/>

            <xsl:if test="$UrheberrechtsInhaber | $BemUrheberrechtsInhaber | $PartUrheberrechtsInhaber">
                <marc:datafield tag="542" ind1=" " ind2=" ">
                <xsl:if test="$UrheberrechtsInhaber">
                    <marc:subfield code="d"><xsl:value-of select="$UrheberrechtsInhaber"/></marc:subfield>
                </xsl:if>
                <xsl:if test="$PartUrheberrechtsInhaber">
                    <marc:subfield code="e"><xsl:value-of select="$PartUrheberrechtsInhaber"/></marc:subfield>
                </xsl:if>
                <xsl:if test="$BemUrheberrechtsInhaber">
                    <marc:subfield code="n"><xsl:value-of select="$BemUrheberrechtsInhaber"/></marc:subfield>
                </xsl:if>
                </marc:datafield>
            </xsl:if>
    </xsl:template>

    <!-- MARC-Feld 562 -->
    
    <xsl:template name="cdF562">
        <xsl:variable name="BemBeschriftung" select="DetailData/DataElement[@ElementName='Bemerkung zur Beschriftung - Legende']/ElementValue/TextValue/text()"/>
        <xsl:variable name="Unterschrift" select="DetailData/DataElement[@ElementName='Unterschrift']/ElementValue/TextValue/text()"/>
        <xsl:variable name="BemUnterschrift" select="DetailData/DataElement[@ElementName='Bemerkung zur Unterschrift - Legende']/ElementValue/TextValue/text()"/>

            <xsl:if test="DetailData/DataElement[@ElementName='Beschriftung - Legende'] | $BemBeschriftung | $Unterschrift | $BemUnterschrift">
                <marc:datafield tag="562" ind1=" " ind2=" ">
                <xsl:if test="DetailData/DataElement[@ElementName='Beschriftung - Legende']">
                    <xsl:for-each select="DetailData/DataElement[@ElementName='Beschriftung - Legende']/ElementValue">
                        <marc:subfield code="c"><xsl:value-of select="TextValue/text()"/></marc:subfield>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="$BemBeschriftung">
                    <marc:subfield code="c"><xsl:value-of select="$BemBeschriftung"/></marc:subfield>
                </xsl:if>
                <xsl:if test="$Unterschrift">
                    <marc:subfield code="c"><xsl:value-of select="$Unterschrift"/></marc:subfield>
                </xsl:if>
                <xsl:if test="$BemUnterschrift">
                    <marc:subfield code="c"><xsl:value-of select="$BemUnterschrift"/></marc:subfield>
                </xsl:if>
                </marc:datafield>
            </xsl:if>
    </xsl:template>
    
    <!-- MARC-Feld 581 -->
    
    <xsl:template match="DataElement[@ElementName='Literaturangabe']/ElementValue/TextValue/text()">
        <xsl:for-each select="tokenize(., '\n\r?')[.]">
            <marc:datafield tag="581" ind1="8" ind2=" ">
                <marc:subfield code="a">Literaturangabe: <xsl:sequence select="."></xsl:sequence></marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Publikationen']/ElementValue/TextValue/text()">
        <xsl:for-each select="tokenize(., '\n\r?')[.]">
            <marc:datafield tag="581" ind1="8" ind2=" ">
                <marc:subfield code="a">Veröffentlichung: <xsl:sequence select="."></xsl:sequence></marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- MARC-Feld 585 -->
    
    <xsl:template match="DataElement[@ElementName='Präsentation in Ausstellungen']/ElementValue/TextValue/text()">
        <xsl:for-each select="tokenize(., '\n\r?')[.]">
            <marc:datafield tag="585" ind1=" " ind2=" ">
                <marc:subfield code="a">Präsentation in Ausstellung: <xsl:sequence select="."></xsl:sequence></marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- MARC-Feld 595 -->
    
    <xsl:template match="DataElement[@ElementName='Koordinaten X']">
        <!-- Tobias:
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

    <!-- MARC-Feld 7x0 und begrenzt 690 -->
    
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
            <xsl:if test="Name[text()='ArchitektIn']">
                <xsl:choose>
                    <xsl:when test="Thesaurus[text()='Körperschaften']">
                        <xsl:variable name="koerperschaftvalue" select="normalize-space(IdName/text())"/>
                        <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(.*)(\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1" select="regex-group(2)"/>
                                <marc:datafield tag="690" ind1=" " ind2="7">
                                    <marc:subfield code="B">b</marc:subfield>
                                    <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                    <marc:subfield code="4">arc</marc:subfield>
                                    <marc:subfield code="2">CHARCH</marc:subfield>
                                </marc:datafield>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                    <xsl:when test="Thesaurus[text()='Personen']">
                        <xsl:variable name="personvalue" select="normalize-space(IdName/text())"/>
                        <xsl:analyze-string select="$personvalue" regex="(Personen\\[A-Z]\\)(.*)(\(.*\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1" select="regex-group(2)"/>
                                <xsl:variable name="part2" select="regex-group(3)"/>
                                    <marc:datafield tag="690" ind1=" " ind2="7">
                                        <marc:subfield code="B">p</marc:subfield>
                                        <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                        <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                        <marc:subfield code="4">arc</marc:subfield>
                                        <marc:subfield code="2">CHARCH</marc:subfield>
                                    </marc:datafield>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="Name[text()='Abgebildete Person']">
                <xsl:variable name="personvalue" select="normalize-space(IdName/text())"/>
                <xsl:analyze-string select="$personvalue" regex="(Personen\\[A-Z]\\)(.*)(\(.*\))">
                    <xsl:matching-substring>
                        <xsl:variable name="part1" select="regex-group(2)"/>
                        <xsl:variable name="part2" select="regex-group(3)"/>
                            <marc:datafield tag="690" ind1=" " ind2="7">
                                <marc:subfield code="B">p</marc:subfield>
                                <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                <marc:subfield code="2">CHARCH</marc:subfield>
                            </marc:datafield>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:if>
            <xsl:if test="Name[text()='BildendeR KünstlerIn']">
                <xsl:choose>
                    <xsl:when test="Thesaurus[text()='Körperschaften']">
                        <xsl:variable name="koerperschaftvalue" select="normalize-space(IdName/text())"/>
                        <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(.*)(\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1" select="regex-group(2)"/>
                                <marc:datafield tag="710" ind1="2" ind2=" ">
                                    <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                </marc:datafield>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                    <xsl:when test="Thesaurus[text()='Personen']">
                        <xsl:variable name="personvalue" select="normalize-space(IdName/text())"/>
                        <xsl:analyze-string select="$personvalue" regex="(Personen\\[A-Z]\\)(.*)(\(.*\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1">
                                    <xsl:choose>
                                        <xsl:when test="fn:contains(regex-group(2),'?')">
                                            <xsl:value-of select="fn:substring-before(regex-group(2),',')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="regex-group(2)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <!--<xsl:variable name="part1" select="regex-group(1)"/> -->
                                <xsl:variable name="part2" select="regex-group(3)"/>
                                
                                <!-- Kommafall -->
                                <xsl:choose>
                                    <xsl:when test="fn:contains($part1,',')">">
                                        <xsl:variable name="nn" select="fn:substring-before($part1,',')"/>
                                        <xsl:variable name="vn" select="fn:substring-after($part1,',')"/>
                                        <marc:datafield tag="700" ind1="1" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($nn)"/></marc:subfield>
                                            <marc:subfield code="D"><xsl:value-of select="normalize-space($vn)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                        </marc:datafield>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <marc:datafield tag="700" ind1="1" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                        </marc:datafield>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="Name[text()='FotografIn']">
                <xsl:choose>
                    <xsl:when test="Thesaurus[text()='Körperschaften']">
                        <xsl:variable name="koerperschaftvalue" select="normalize-space(IdName/text())"/>
                        <!--marc:datafield tag="710"  ind1="1" ind2=" "  >
                            <marc:subfield code="a"><xsl:value-of select="$koerperschaftvalue"/></marc:subfield>
                        </marc:datafield-->
                        <xsl:choose>
                            <xsl:when test="contains($koerperschaftvalue, 'Schweiz.')">
                                <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(Schweiz\. )(.*)(\))">
                                    <xsl:matching-substring>
                                        <xsl:variable name="part1" select="regex-group(2)"/>
                                        <xsl:variable name="part2" select="regex-group(3)"/>
                                        <marc:datafield tag="710"  ind1="1" ind2=" "  >
                                            <marc:subfield code="a"><xsl:value-of select="fn:translate($part1,' .()','')"/></marc:subfield>
                                            <marc:subfield code="b"><xsl:value-of select="normalize-space($part2)"/></marc:subfield>
                                            <marc:subfield code="4">pht</marc:subfield>
                                        </marc:datafield>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(.*)(\(.*\))">
                                    <xsl:matching-substring>
                                        <xsl:variable name="part1" select="regex-group(2)"/>
                                        <xsl:variable name="part2" select="regex-group(3)"/>
                                        <marc:datafield tag="710" ind1="2" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                            <marc:subfield code="4">pht</marc:subfield>
                                        </marc:datafield>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                                <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(.*)(\))">
                                    <xsl:matching-substring>
                                        <xsl:variable name="part1" select="regex-group(2)"/>
                                        <marc:datafield tag="710" ind1="2" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                        </marc:datafield>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="Thesaurus[text()='Personen']">
                        <xsl:variable name="personvalue" select="normalize-space(IdName/text())"/>
                        <xsl:analyze-string select="$personvalue" regex="(Personen\\[A-Z]\\)(.*)(\(.*\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1">
                                    <xsl:choose>
                                        <xsl:when test="fn:contains(regex-group(2),'?')">
                                            <xsl:value-of select="fn:substring-before(regex-group(2),',')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="regex-group(2)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <!--<xsl:variable name="part1" select="regex-group(1)"/> -->
                                <xsl:variable name="part2" select="regex-group(3)"/>
                                
                                <!-- Kommafall -->
                                <xsl:choose>
                                    <xsl:when test="fn:contains($part1,',')">">
                                        <xsl:variable name="nn" select="fn:substring-before($part1,',')"/>
                                        <xsl:variable name="vn" select="fn:substring-after($part1,',')"/>
                                        <marc:datafield tag="700" ind1="1" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($nn)"/></marc:subfield>
                                            <marc:subfield code="D"><xsl:value-of select="normalize-space($vn)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                            <marc:subfield code="4">pht</marc:subfield>
                                        </marc:datafield>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <marc:datafield tag="700" ind1="1" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                            <marc:subfield code="4">pht</marc:subfield>
                                        </marc:datafield>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
        
    </xsl:template>

    <!-- MARC-Feld 690 -->
    <xsl:template match="DataElement[@ElementName='VE-Objekt']">
        <xsl:for-each select="ElementValue/TextValue">
            <marc:datafield tag="690" ind1=" " ind2="7" >
                <marc:subfield code="B">s</marc:subfield>
                <marc:subfield code="a"><xsl:value-of select="./text()"/></marc:subfield>
                <marc:subfield code="2">CHARCH</marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bauperiode']/ElementValue/DateRange">
        <xsl:variable name="year1" select="./FromDate"/>
        <xsl:variable name="year2" select="./ToDate"/>
        <xsl:choose>
            <xsl:when test="TextRepresentation/text() = 'keine Angabe'"></xsl:when>
            <xsl:otherwise>
                <marc:datafield tag="690" ind1=" " ind2="7" >
                    <marc:subfield code="B">z</marc:subfield>
                    <xsl:choose>
                        <xsl:when test="fn:string-length(fn:translate($year1, ' +-', '')) = 4">
                            <marc:subfield code="a"><xsl:value-of select="fn:translate($year1, ' +-', '')"/>
                                <xsl:if test="./ToDate/text()">
                                    <xsl:text>-</xsl:text>
                                    <xsl:value-of select="fn:translate($year2, ' +-', '')"/>
                                </xsl:if>
                            </marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="a"><xsl:value-of select="./TextRepresentation"/></marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='BauherrIn']">
        <xsl:choose>
            <xsl:when test="ElementValue/TextValue/text() = 'keine Angabe'"></xsl:when>
            <xsl:when test="ElementValue/TextValue/text() = 'unbekannt'"></xsl:when>
            <xsl:when test="ElementValue/TextValue/text() = 'Unbekannt'"></xsl:when>
            <xsl:otherwise>
                <marc:datafield tag="690" ind1=" " ind2="7" >
                    <marc:subfield code="B">p</marc:subfield>
                    <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
                    <marc:subfield code="4">own</marc:subfield>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Land']">
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Kanton']">
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Gemeinde']">
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/><xsl:text> (Gemeinde)</xsl:text></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Ort']">
        <xsl:variable name="ort" select="ElementValue/TextValue/text()"/>
        <xsl:variable name="plz" select="preceding-sibling::DataElement[@ElementName='Postleitzahl']/ElementValue/TextValue/text()"/>
        <xsl:variable name="strasse" select="following-sibling::DataElement[@ElementName='Strasse']/ElementValue/TextValue/text()"/>
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a">
                <xsl:choose>
                    <xsl:when test="$strasse = '.'"></xsl:when>
                    <xsl:otherwise><xsl:value-of select="$strasse"/></xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$strasse = '.'"></xsl:when>
                    <xsl:when test="$strasse">, </xsl:when>
                    <xsl:otherwise></xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="$plz"/><xsl:if test="$plz"><xsl:text> </xsl:text></xsl:if><xsl:value-of select="$ort"/>
            </marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Lokalname']">
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- MARC-Feld 856 -->
    
    <xsl:template match="DataElement[@ElementName='Ansichtsbild']">
        <xsl:if test="not(../../UsageData/Accessability/text() = 'Sonderbewilligung Intranet')">
        
            <xsl:variable name="recordid" select="../.././@Id"/>
            <xsl:variable name="replacedurl" select="fn:replace($linkurl856ansichtsbild,'XXX',$recordid)"/>
            <marc:datafield tag="856" ind1="4" ind2="2">
                <marc:subfield code="3">Ansichtsbild</marc:subfield>
                <marc:subfield code="u"><xsl:value-of select="$replacedurl"/></marc:subfield>
                <marc:subfield code="z">Ansichtsbild</marc:subfield>
            </marc:datafield>
            <marc:datafield tag="950" ind1=" " ind2=" ">
                <marc:subfield code="B">CHARCH</marc:subfield>
                <marc:subfield code="E">42</marc:subfield>
                <marc:subfield code="P">856</marc:subfield>
                <marc:subfield code="3">Ansichtsbild</marc:subfield>
                <marc:subfield code="u"><xsl:value-of select="$replacedurl"/></marc:subfield>
                <marc:subfield code="z">Ansichtsbild</marc:subfield>
            </marc:datafield>
        
        </xsl:if>
    </xsl:template>
    
    <!-- MARC-Feld 949 -->
    
    <xsl:template match="DataElement[@ElementName='Signatur']">
        <xsl:variable name="recordid" select="../.././@Id"/>
        <xsl:variable name="replacedurl" select="fn:replace($linkurl949y,'XXX',$recordid)"/>

        <marc:datafield tag="949" ind2=" " ind1=" " >
            <marc:subfield code="B"><xsl:text>CHARCH</xsl:text></marc:subfield>
            <marc:subfield code="F"><xsl:value-of select="$institutioncode"/></marc:subfield>
            <marc:subfield code="b"><xsl:value-of select="$institutioncode"/></marc:subfield>
            <marc:subfield code="E"><xsl:value-of select="$recordid"/></marc:subfield>
            <marc:subfield code="1">Archiv</marc:subfield> 
            <marc:subfield code="5"><xsl:value-of select="../../UsageData/PhysicalUsability/text()" /></marc:subfield>
            <marc:subfield code="j"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="z"><xsl:value-of select="$rights949z" /></marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- MARC-Feld 956 -->
    
    <xsl:template match="DataElement[@ElementName='Vorschaubild']">
        <xsl:if test="not(../../UsageData/Accessability/text() = 'Sonderbewilligung Intranet')">
            
            <xsl:variable name="recordid" select="../.././@Id"/>
            <xsl:variable name="replacedurl" select="fn:replace($linkurl956vorschaubild,'XXX',$recordid)"/>
            <marc:datafield tag="956" ind1="4" ind2=" ">
                <marc:subfield code="B">CHARCH</marc:subfield>
                <marc:subfield code="a"><xsl:value-of select="$institutioncode"/></marc:subfield>
                <marc:subfield code="u"><xsl:value-of select="$replacedurl"/></marc:subfield>
                <marc:subfield code="q">bild</marc:subfield>
                <marc:subfield code="x">THUMBNAIL</marc:subfield>
                <marc:subfield code="y">Vorschaubild</marc:subfield>
            </marc:datafield>
            
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>

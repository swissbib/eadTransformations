<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="#all"
     version="2.0"
     xmlns:marc="http://www.loc.gov/MARC21/slim">
    
    <xsl:output 
        indent="yes" 
        method="xml"
        />
    
    <!-- ***************************************
         * Scope-Formular: BILD, FOTO, TEXT
         * Erfasst die gesamte Struktur (Bestand, Sammlungseinheit/Serie/Dossier, Dokument)
         ***************************************
    -->
    
    <!-- =======================================
         Sektion für allgemeine Codes 
         =======================================
    -->
    
    <!-- Base URL (aktuell nicht in Gebrauch) -->
    <xsl:param name="hostname" select="'http://www.nb.admin.ch/'" />
    
    <!-- Sammlungscode für swissbib (muss mit swissbib abgesprochen werden)
     CHARCH01: Graphische Sammlung
     CHARCH02: Schweizerisches Literatur Archiv (aktuell nur Fotos Annemarie Schwarzenbach)
     CHARCH03: Spezialarchive
     CHARCH04: CDN - Dürrenmatt Werke
    -->
    <xsl:param name="institutioncode" select="'CHARCH01'" /> <!-- Standard, da die meisten Sammlungen aktuell von dieser Institution stammen -->
    <xsl:param name="bild" select="'N'" /> <!-- Ermöglicht das Ein- und Ausblenden von URLs. Standard ist 'N', da die meisten Sammlungen nicht mit Vorschau und Ansichtsbildern geliefert werden. Ansonsten ist 'Y' zu setzen -->
    
    <!-- Selektionscode zur Einschränkung auf Datensätze (muss mit swissbib abgesprochen werden)
     ALL = liefert sämtliche Ebenen
     BESTAND = liefert nur Ebene Bestand
     DOK = liefert nur Dokumente
    -->
    <xsl:param name="level" select="'BESTAND'" /> <!-- Ermöglicht die Einschränkung auf Datensätze. Standard ist 'BESTAND'. -->
    
    
    <!-- Vorschaulinks auf helveticarchives -->
    <xsl:variable name="linkurl949y" select="'http://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=80'"/> <!-- ACHTUNG: nicht auf https -->
    <xsl:variable name="linkurl856ansichtsbild" select="'http://www.helveticarchives.ch/bild.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1'" /> <!-- ACHTUNG: nicht auf https -->
    <xsl:variable name="linkurl956vorschaubild" select="'https://www.helveticarchives.ch/getimage.aspx?VEID=XXX&amp;DEID=10&amp;SQNZNR=1&amp;SIZE=30'" />
   
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
        
        <xsl:choose>
            <xsl:when test="$level = 'BESTAND'">
                <!-- Additionally you can define arbitrary record ids that must not be transformed. 
                     Used to exclude records that define the structure of the collection. -->
                <xsl:variable name="exclude">
                    <xsl:variable name="excl" select="163520,575402,222373,578185,96770,575401,537228,163522,576303,163524,222299,222310,222328" />
                    <xsl:variable name="rms">
                        <xsl:value-of select="$excl"/><xsl:text>,</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="recid" select="@Id" />
                    <xsl:for-each select="tokenize($rms, ',')">
                        <xsl:choose>
                            <xsl:when test="contains(., $recid)">
                                <xsl:text>NI</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>YESS</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:if test="@Level='Bestand'">
                    <xsl:choose>
                        <xsl:when test="contains($exclude, 'NI')">
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="marcFields">
                                <xsl:with-param name="type" select="'collection'" />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$level = 'ALL' or $level = 'DOK'">
                <xsl:choose>
                    <xsl:when test="(@Level='Dokument' and AdministrativeData/EditForm/text() = 'NB Gemälde/Plan/Zeichnung/Grafik' and DetailData/DataElement[@ElementName='Ansichtsbild'])"> <!-- Dokument: Bilder und Gemälde {and UsageData/AlwaysVisibleOnline/text() = 'true'} -->
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(AdministrativeData/ViewingForm/text()), 'offline')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="marcFields">
                                    <xsl:with-param name="type" select="'bild'" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="contains(DetailData/DataElement[@ElementName='FotografIn']/ElementValue[1]/TextValue/text(), 'Schwarzenbach') and (@Level='Dokument' and AdministrativeData/EditForm/text() = 'NB Fotografie' and DetailData/DataElement[@ElementName='Ansichtsbild'])"> <!-- Dokument: Fotografie Schwarzenbach {and UsageData/AlwaysVisibleOnline/text() = 'true'} -->
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(AdministrativeData/ViewingForm/text()), 'offline')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="marcFields">
                                    <xsl:with-param name="type" select="'foto'" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="(@Level='Dokument' and AdministrativeData/EditForm/text() = 'NB Fotografie' and DetailData/DataElement[@ElementName='Ansichtsbild']) and lower-case($institutioncode) != 'charch02'"> <!-- ACHTUNG nur solange funktional wie nur eine Fotosammlung des SLA digitalisiert ist. Dokument: Fotografie allgemein { and UsageData/AlwaysVisibleOnline/text() = 'true'} -->
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(AdministrativeData/ViewingForm/text()), 'offline')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="marcFields">
                                    <xsl:with-param name="type" select="'foto'" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="(@Level='Dokument' and AdministrativeData/EditForm/text() = 'NB Publikation')"> <!-- Dokument: Dokumente allgemein -->
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(AdministrativeData/ViewingForm/text()), 'offline')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="marcFields">
                                    <xsl:with-param name="type" select="'monographie'" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="(@Level='Sammlungseinheit' or @Level='Serie' or @Level='Dossier') and AdministrativeData/EditForm/text() = 'NB Publikation'">
                        <xsl:if test="$level = 'ALL'">
                            <xsl:call-template name="marcFields">
                                <xsl:with-param name="type" select="'monographie'" />
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="@Level='Sammlungseinheit'or @Level='Serie' or @Level='Dossier'">
                        <xsl:if test="$level = 'ALL'">
                            <xsl:call-template name="marcFields">
                                <xsl:with-param name="type" select="'dossier'" />
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="@Level='Bestand'">
                        <xsl:if test="$level = 'ALL'">
                            <xsl:call-template name="marcFields">
                                <xsl:with-param name="type" select="'collection'" />
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    
        <!-- now look out for the next Record node until the whole XML Input Document is being processed-->
       <xsl:apply-templates select="Record"/>
    </xsl:template>
   
    

    <!-- =======================================
         Sektion zur Erstellung der marc:Datenstruktur 
         =======================================
    -->

    <xsl:template name="marcFields">
    
        <!-- Dient der Definition von Dokumenttypen für Leader, 007, 008, 245$h und 898 -->
        <xsl:param name="type"/>
        <marc:record >
            
            <!-- at first process fix nodes -primarily control nodes- which should be part of every MARC - record
            -->
            
            <xsl:call-template name="createLeader">
                <xsl:with-param name="type" select="$type" />
            </xsl:call-template>
            <xsl:call-template name="cCtrlF001"/>
            <xsl:call-template name="cCtrlF003"/>
            <xsl:call-template name="cCtrlF007">
                <xsl:with-param name="type" select="$type" />
            </xsl:call-template>
            <xsl:call-template name="cCtrlF008">
                <xsl:with-param name="type" select="$type" />
            </xsl:call-template>
            
            <!-- now the data driven dynamic part begins -->
            <xsl:variable name="datafields">

                <!-- named templates -->
                <xsl:call-template name="cdF035"/>
                <xsl:call-template name="cdF040"/>
                <xsl:call-template name="cdF043"/>
                <xsl:call-template name="cdF245">
                    <xsl:with-param name="type" select="$type" />
                </xsl:call-template>
                <xsl:call-template name="cdF260"/>
                <xsl:call-template name="cdF300"/>
                <xsl:call-template name="cdF351"/>
                <xsl:call-template name="cdF542"/>
                <xsl:call-template name="cdF562"/>
                <xsl:call-template name="Linking"/>
                <xsl:call-template name="chbMediacode">
                    <xsl:with-param name="type" select="$type" />
                </xsl:call-template>
                
                <!-- data driven templates -->
                <xsl:apply-templates select="DetailData/DataElement">
                    <xsl:with-param name="type" select="$type" />
                </xsl:apply-templates>
                <xsl:apply-templates select="Descriptors/Descriptor"/>

            </xsl:variable>

            <xsl:for-each select="$datafields/marc:datafield">
                <xsl:sort select="./@tag"/> 
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </marc:record>
    </xsl:template>
    
    <!-- =======================================
         Sektion zur Erstellung der marc:Datenfelder
         =======================================
    -->
    
    <!-- MARC-Feld 000 -->
    <xsl:template name="createLeader">
        <xsl:param name="type" />
         <marc:leader >
             <xsl:choose>
                 <xsl:when test="$type = 'foto' or $type = 'bild'"> 
                     <xsl:text>    nkm a22     4  4500</xsl:text>
                 </xsl:when>
                 <xsl:when test="$type = 'monographie'">
                     <xsl:text>    nam a22     4  4500</xsl:text>
                 </xsl:when>
                 <xsl:when test="$type = 'collection'">
                     <xsl:text>    npc a22     4  4500</xsl:text>
                 </xsl:when>
                 <xsl:when test="$type = 'dossier'"> <!-- "@Level='Sammlungseinheit' or @Level='Serie' or @Level='Dossier'" -->
                     <xsl:text>    npd a22     4  4500</xsl:text>
                 </xsl:when>
                 <xsl:otherwise> <!-- Fallback sollte nie eintreffen -->
                     <xsl:text>    npd a22     4  4500</xsl:text>
                 </xsl:otherwise>
             </xsl:choose>
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
         <xsl:param name="type" />
         <xsl:if test="$type = 'foto' or $type = 'bild'"> 
             <!-- cr plus 21 blanks -->
             <marc:controlfield tag="007" ><xsl:text>cr                     </xsl:text></marc:controlfield>
         </xsl:if>
         <xsl:if test="$type = 'collection' or $type = 'dossier'">
         </xsl:if>
     </xsl:template>
    
     <!-- MARC-Feld 008 -->
     <!-- Minimales Feld 008 -->
     <xsl:template name="cCtrlF008" >
         <xsl:param name="type" />
        <!-- <xsl:variable name="tempDateEdited" select="fn:year-from-date(AdministrativeData/LastEditedOn)"/> -->
         <xsl:variable name="tempYearEdited2" select="fn:format-date(AdministrativeData/LastEditedOn,'[Y,2-2]')"/>
         <xsl:variable name="tempMonthEdited" select="fn:format-date(AdministrativeData/LastEditedOn,'[M,2]')"/>
         <xsl:variable name="tempDayEdited" select="fn:format-date(AdministrativeData/LastEditedOn,'[D,2]')"/>
         
         <xsl:variable name="date">
             <xsl:variable name="pos06"> <!-- datetype -->
                 <xsl:variable name="tempPattern" select="DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/@DateOperator"/>
                 <xsl:choose>
                     <xsl:when test="$type = 'collection' or $type = 'dossier'">
                         <xsl:choose>
                             <xsl:when test="$tempPattern='after' or $tempPattern='before' or $tempPattern='fromTo' or $tempPattern='startingWith' or $tempPattern='between'">
                                 <xsl:text>i</xsl:text>
                             </xsl:when>
                             <xsl:when test="$tempPattern='exact'">
                                 <xsl:text>s</xsl:text>
                             </xsl:when>
                             <xsl:otherwise> <!-- catches "N/A" -->
                                 <xsl:text>n</xsl:text>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:when>
                     <xsl:when test="$type = 'foto' or $type = 'bild' or $type = 'monographie' or $type = 'film' or $type = 'ton'">
                         <xsl:choose>
                             <xsl:when test="$tempPattern='after' or $tempPattern='before'">
                                 <xsl:text>q</xsl:text>
                             </xsl:when>
                             <xsl:when test="$tempPattern='fromTo' or $tempPattern='startingWith' or $tempPattern='between'">
                                 <xsl:text>m</xsl:text>
                             </xsl:when>
                             <xsl:when test="$tempPattern='exact'">
                                 <xsl:text>s</xsl:text>
                             </xsl:when>
                             <xsl:otherwise> <!-- catches "N/A" -->
                                 <xsl:text>n</xsl:text>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:when>
                 </xsl:choose>
             </xsl:variable>
             <xsl:variable name="pos07to10"> <!-- date 1 -->
                 <xsl:variable name="tempPattern" select="DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/@DateOperator"/>
                 <xsl:variable name="temp1stYearCreated4" select="fn:substring(DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/FromDate,2,4)"/>
                 <xsl:choose>
                     <xsl:when test="$type = 'collection' or $type = 'dossier'">
                         <xsl:choose>
                             <xsl:when test="$tempPattern='before' or $tempPattern='N/A' or $temp1stYearCreated4=''">
                                 <xsl:text>uuuu</xsl:text>
                             </xsl:when>
                             <xsl:otherwise> <!-- catches "exact" and "startingWith" -->
                                 <xsl:choose>
                                     <xsl:when test="fn:string-length($temp1stYearCreated4) = 3">
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>u</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp1stYearCreated4) = 2">
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uu</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp1stYearCreated4) = 1">
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uuu</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:when>
                     <xsl:when test="$type = 'foto' or $type = 'bild' or $type = 'monographie' or $type = 'film' or $type = 'ton'">
                         <xsl:choose>
                             <xsl:when test="$tempPattern='before' or $tempPattern='N/A' or $temp1stYearCreated4=''">
                                 <xsl:text>uuuu</xsl:text>
                             </xsl:when>
                             <xsl:otherwise> <!-- catches all cases with a first date -->
                                 <xsl:choose>
                                     <xsl:when test="fn:string-length($temp1stYearCreated4) = 3">
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>u</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp1stYearCreated4) = 2">
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uu</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp1stYearCreated4) = 1">
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uuu</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:when>
                 </xsl:choose>
             </xsl:variable>
             <xsl:variable name="pos11to14"> <!-- date 2 -->
                 <xsl:variable name="tempPattern" select="DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/@DateOperator"/>
                 <xsl:variable name="temp2ndYearCreated4" select="fn:substring(DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/ToDate,2,4)"/>
                 <xsl:choose>
                     <xsl:when test="$type = 'collection' or $type = 'dossier'"> <!-- @Level='Bestand' or @Level='Sammlungseinheit' or @Level='Serie' -->
                         <xsl:choose>
                             <xsl:when test="$tempPattern='exact'">
                                 <xsl:text>    </xsl:text>
                             </xsl:when>
                             <xsl:when test="$tempPattern='before'">
                                 <xsl:variable name="temp1stYearCreated4" select="fn:substring(DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/FromDate,2,4)"/>
                                 <xsl:choose>
                                     <xsl:when test="$temp1stYearCreated4=''">
                                         <xsl:text>uuuu</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:choose>
                                             <xsl:when test="fn:string-length($temp1stYearCreated4) = 3">
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>u</xsl:text>
                                             </xsl:when>
                                             <xsl:when test="fn:string-length($temp1stYearCreated4) = 2">
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uu</xsl:text>
                                             </xsl:when>
                                             <xsl:when test="fn:string-length($temp1stYearCreated4) = 1">
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uuu</xsl:text>
                                             </xsl:when>
                                             <xsl:otherwise>
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of>
                                             </xsl:otherwise>
                                         </xsl:choose>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:when>
                             <xsl:when test="$tempPattern='after' or $tempPattern='N/A' or $temp2ndYearCreated4=''">
                                 <xsl:text>uuuu</xsl:text>
                             </xsl:when>
                             <xsl:otherwise> <!-- catches "all others" -->
                                 <xsl:choose>
                                     <xsl:when test="fn:string-length($temp2ndYearCreated4) = 3">
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of><xsl:text>u</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp2ndYearCreated4) = 2">
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of><xsl:text>uu</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp2ndYearCreated4) = 1">
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of><xsl:text>uuu</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:when>
                     <xsl:when test="$type = 'foto' or $type = 'bild' or $type = 'monographie' or $type = 'film' or $type = 'ton'">
                         <xsl:choose>
                             <xsl:when test="$tempPattern='exact'">
                                 <xsl:text>    </xsl:text>
                             </xsl:when>
                             <xsl:when test="$tempPattern='before'">
                                 <xsl:variable name="temp1stYearCreated4" select="fn:substring(DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/FromDate,2,4)"/>
                                 <xsl:choose>
                                     <xsl:when test="$temp1stYearCreated4=''">
                                         <xsl:text>uuuu</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:choose>
                                             <xsl:when test="fn:string-length($temp1stYearCreated4) = 3">
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>u</xsl:text>
                                             </xsl:when>
                                             <xsl:when test="fn:string-length($temp1stYearCreated4) = 2">
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uu</xsl:text>
                                             </xsl:when>
                                             <xsl:when test="fn:string-length($temp1stYearCreated4) = 1">
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of><xsl:text>uuu</xsl:text>
                                             </xsl:when>
                                             <xsl:otherwise>
                                                 <xsl:value-of select="$temp1stYearCreated4"></xsl:value-of>
                                             </xsl:otherwise>
                                         </xsl:choose>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:when>
                             <xsl:when test="$tempPattern='after' or $tempPattern='N/A' or $temp2ndYearCreated4=''">
                                 <xsl:text>uuuu</xsl:text>
                             </xsl:when>
                             <xsl:otherwise> <!-- catches "all others" -->
                                 <xsl:choose>
                                     <xsl:when test="fn:string-length($temp2ndYearCreated4) = 3">
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of><xsl:text>u</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp2ndYearCreated4) = 2">
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of><xsl:text>uu</xsl:text>
                                     </xsl:when>
                                     <xsl:when test="fn:string-length($temp2ndYearCreated4) = 1">
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of><xsl:text>uuu</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:value-of select="$temp2ndYearCreated4"></xsl:value-of>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:when>
                 </xsl:choose>
             </xsl:variable>
             
             <xsl:value-of select="$pos06"></xsl:value-of>
             <xsl:value-of select="$pos07to10"></xsl:value-of>
             <xsl:value-of select="$pos11to14"></xsl:value-of>
             
         </xsl:variable>
         
         <xsl:variable name="lng">
            <xsl:variable name="lang" select="DetailData/DataElement[@ElementName='Sprache']/ElementValue[@Sequence='1']/TextValue/text()" />
            <xsl:choose>
                <xsl:when test="$lang='Deutsch'">
                    <xsl:text>ger</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Deutsch, althochdeutsch (ca. 750 - 1050)'">
                    <xsl:text>goh</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Deutsch, Schweizerdeutsch'">
                    <xsl:text>gsw</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Französisch'">
                    <xsl:text>fre</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Französisch, Mittelfranzösisch (1300 - 1600)'">
                    <xsl:text>frm</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Französisch, Altfranzösisch (ca. 842 - 1300)'">
                    <xsl:text>fro</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Englisch'">
                    <xsl:text>eng</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Italienisch'">
                    <xsl:text>ita</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Polnisch'">
                    <xsl:text>pol</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Baskisch'">
                    <xsl:text>baq</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Schwedisch'">
                    <xsl:text>swe</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Niederländisch' or $lang='Flämisch'">
                    <xsl:text>dut</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Türkisch'">
                    <xsl:text>tur</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Griechisch, Altgriechisch (bis 1453)'">
                    <xsl:text>grc</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Griechisch, Neugriechisch (1453 - )'">
                    <xsl:text>gre</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Slowakisch'">
                    <xsl:text>slo</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Spanisch'">
                    <xsl:text>spa</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Portugiesisch'">
                    <xsl:text>por</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Georgisch'">
                    <xsl:text>geo</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Rätoromanisch'">
                    <xsl:text>roh</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Rumänisch'">
                    <xsl:text>rum</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Tschechisch'">
                    <xsl:text>cze</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Ungarisch'">
                    <xsl:text>hun</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Lateinisch'">
                    <xsl:text>lat</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Jiddisch'">
                    <xsl:text>yid</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Dänisch'">
                    <xsl:text>dan</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Finnisch'">
                    <xsl:text>fin</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Russisch'">
                    <xsl:text>rus</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Schwedisch'">
                    <xsl:text>swe</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Norwegisch'">
                    <xsl:text>nor</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Arabisch'">
                    <xsl:text>ara</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Hebräisch'">
                    <xsl:text>heb</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Chinesisch'">
                    <xsl:text>chi</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Japanisch'">
                    <xsl:text>jpn</xsl:text>
                </xsl:when>
                <xsl:when test="$lang='Armenisch'">
                    <xsl:text>arm</xsl:text>
                </xsl:when>
                <xsl:when test="$type = 'bild' or $type = 'foto' or $type = 'ton' or $type = 'video'">
                    <xsl:text>zxx</xsl:text>
                </xsl:when>
                <xsl:when test="$type = 'collection'">
                    <xsl:text>zxx</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>und</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         
         <xsl:variable name="remains">
             <xsl:choose>
                 <xsl:when test="$type = 'foto'"> <!-- Foto -->
                     <xsl:text>sz                in</xsl:text>
                 </xsl:when>
                 <xsl:when test="$type = 'bild'"> <!-- Bild -->
                     <xsl:text>sz                cn</xsl:text>
                 </xsl:when>
                 <xsl:when test="$type = 'collection' or $type='dossier'"> <!-- @Level='Sammlungseinheit' or @Level='Serie' or @Level='Bestand' -->
                     <xsl:text>sz            000   </xsl:text>
                 </xsl:when>
                 <xsl:when test="$type = 'monographie'"> <!-- Druckwerke -->
                     <xsl:text>xx            000   </xsl:text>
                 </xsl:when>
             </xsl:choose>
         </xsl:variable>
         
         <marc:controlfield  tag="008" >
             <!-- Erstellungsdatum des Datensatzes: 00-05 -->
             <xsl:value-of select="$tempYearEdited2"></xsl:value-of>
             <xsl:value-of select="$tempMonthEdited"></xsl:value-of>
             <xsl:value-of select="$tempDayEdited"></xsl:value-of>
              <!-- Datumswerte: 06-11 -->
             <xsl:value-of select="$date"></xsl:value-of>
              <!-- Land und Rest: 12-39 (grob) -->
             <xsl:value-of select="$remains"></xsl:value-of>
             <xsl:value-of select="$lng"></xsl:value-of>
             <xsl:text> d</xsl:text>
         </marc:controlfield>
     </xsl:template>
    
    <!-- MARC-Feld 020 -->
    <!-- TODO: Verbesserung: Das Feld enthält auch ISSN, über eine weitere Prüfung kann ein Feld 022 erstellt werden -->
    <xsl:template match="DataElement[@ElementName='ISBN']">
        <xsl:for-each select="ElementValue">
            <xsl:variable name="isbn">
                <xsl:variable name="string" select="TextValue/text()" />
                <xsl:choose>
                    <xsl:when test="fn:contains($string, '(')">
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(fn:substring($string, 1,4)), 'sz')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="tmpISBN" select="fn:substring-before($string, ' (')" />
                                <xsl:choose>
                                    <xsl:when test="fn:contains($tmpISBN, ' ') or fn:contains($tmpISBN, '-') or fn:contains($tmpISBN, '.')">
                                        <xsl:value-of select="fn:translate($tmpISBN,' ()-.','')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$tmpISBN"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(fn:substring($string, 1,4)), 'sz')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="tmpISBN" select="$string" />
                                <xsl:choose>
                                    <xsl:when test="fn:contains($tmpISBN, ' ') or fn:contains($tmpISBN, '-') or fn:contains($tmpISBN, '.')">
                                        <xsl:value-of select="fn:translate($tmpISBN,' ()-.','')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$tmpISBN"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="remainder">
                 <xsl:variable name="string" select="TextValue/text()" />
                <xsl:choose>
                    <xsl:when test="fn:contains($string, '(')">
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case(fn:substring($string, 1,4)), 'sz')">
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="tmpRemainder" select="fn:substring-after($string, ' (')" />
                                <xsl:value-of select="fn:translate($tmpRemainder,'()','')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="fn:string-length($isbn) = 10 or (fn:string-length($isbn) = 13 and (fn:substring($isbn, 1,3) = '978' or fn:substring($isbn, 1,3) = '979'))">
                <marc:datafield tag="020" ind1=" " ind2=" ">
                    <marc:subfield code="a"><xsl:value-of select="$isbn"/></marc:subfield>
                    <xsl:if test="fn:string-length($remainder) &gt; 0">
                        <xsl:choose>
                            <xsl:when test="fn:contains(lower-case($remainder), 'br') or fn:contains(lower-case($remainder), 'geb')">
                                <marc:subfield code="c"><xsl:value-of select="$remainder"/></marc:subfield>
                            </xsl:when>
                            <xsl:otherwise>
                                <marc:subfield code="q"><xsl:value-of select="$remainder"/></marc:subfield>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </marc:datafield>
            </xsl:if>
        </xsl:for-each>
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
            <marc:subfield code="b">
                <xsl:text>ger</xsl:text>
            </marc:subfield>
            <marc:subfield code="c">
                <xsl:text>Sz</xsl:text>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>

    <!-- MARC-Feld 041 -->
    <!-- TODO: Es werden nur jene Sprachen aufgeführt, die während der Evaluation gefunden wurden. Dies ist periodisch zu prüfen -->
    <xsl:template match="DataElement[@ElementName='Sprache']/ElementValue[@Sequence='2']">
        <marc:datafield tag="041" ind1=" " ind2=" " >
            <xsl:for-each select="../ElementValue/TextValue/text()">
                <xsl:variable name="lng">
                   <xsl:variable name="lang" select="." />
                   <xsl:choose>
                       <xsl:when test="$lang='Deutsch'">
                           <xsl:text>ger</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Deutsch, althochdeutsch (ca. 750 - 1050)'">
                           <xsl:text>goh</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Deutsch, Schweizerdeutsch'">
                           <xsl:text>gsw</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Französisch'">
                           <xsl:text>fre</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Französisch, Mittelfranzösisch (1300 - 1600)'">
                           <xsl:text>frm</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Französisch, Altfranzösisch (ca. 842 - 1300)'">
                           <xsl:text>fro</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Englisch'">
                           <xsl:text>eng</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Italienisch'">
                           <xsl:text>ita</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Polnisch'">
                           <xsl:text>pol</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Baskisch'">
                           <xsl:text>baq</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Schwedisch'">
                           <xsl:text>swe</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Niederländisch' or $lang='Flämisch'">
                           <xsl:text>dut</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Türkisch'">
                           <xsl:text>tur</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Griechisch, Altgriechisch (bis 1453)'">
                           <xsl:text>grc</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Griechisch, Neugriechisch (1453 - )'">
                           <xsl:text>gre</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Slowakisch'">
                           <xsl:text>slo</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Spanisch'">
                           <xsl:text>spa</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Portugiesisch'">
                           <xsl:text>por</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Georgisch'">
                           <xsl:text>geo</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Rätoromanisch'">
                           <xsl:text>roh</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Rumänisch'">
                           <xsl:text>rum</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Tschechisch'">
                           <xsl:text>cze</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Ungarisch'">
                           <xsl:text>hun</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Lateinisch'">
                           <xsl:text>lat</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Jiddisch'">
                           <xsl:text>yid</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Dänisch'">
                           <xsl:text>dan</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Finnisch'">
                           <xsl:text>fin</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Russisch'">
                           <xsl:text>rus</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Schwedisch'">
                           <xsl:text>swe</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Norwegisch'">
                           <xsl:text>nor</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Arabisch'">
                           <xsl:text>ara</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Hebräisch'">
                           <xsl:text>heb</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Chinesisch'">
                           <xsl:text>chi</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Japanisch'">
                           <xsl:text>jpn</xsl:text>
                       </xsl:when>
                       <xsl:when test="$lang='Armenisch'">
                           <xsl:text>arm</xsl:text>
                       </xsl:when>
                       <xsl:otherwise>
                           <xsl:text>und</xsl:text>
                       </xsl:otherwise>
                   </xsl:choose>
                </xsl:variable>
                <marc:subfield code="a"><xsl:value-of select="$lng" /></marc:subfield>
            </xsl:for-each>
        </marc:datafield>
    </xsl:template>

    <!-- MARC-Feld 043 / 690 -->
    <xsl:template name="cdF043">
        <xsl:variable name="land" select="DetailData/DataElement[@ElementName='Land']/ElementValue/TextValue/text()"/>
        <xsl:variable name="kanton" select="DetailData/DataElement[@ElementName='Kanton']/ElementValue/TextValue/text()"/>
        <!-- <marc:datafield tag="043" ind1=" " ind2=" " >
            <marc:subfield code="a">sz</marc:subfield>
            <marc:subfield code="c"><xsl:value-of select="$land"/><xsl:text>/</xsl:text><xsl:value-of select="$kanton"/></marc:subfield>
        </marc:datafield> -->
        <xsl:choose>
            <xsl:when test="($land !='' and $kanton !='') and (string-length($land) = 2 and string-length($kanton) = 2)">
                <marc:datafield tag="043" ind1=" " ind2=" " >
                    <marc:subfield code="a">sz</marc:subfield>
                    <marc:subfield code="c"><xsl:value-of select="lower-case($land)"/><xsl:text>-</xsl:text><xsl:value-of select="lower-case($kanton)"/></marc:subfield>
                </marc:datafield>
            </xsl:when>
            <xsl:when test="($land !='' and $kanton !='') and (string-length($land) &gt; 2 and string-length($kanton) &gt; 2)">
                <marc:datafield tag="690" ind1=" " ind2="7" >
                    <marc:subfield code="B">g</marc:subfield>
                    <marc:subfield code="a"><xsl:value-of select="$land"/></marc:subfield>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
                <marc:datafield tag="690" ind1=" " ind2="7" >
                    <marc:subfield code="B">g</marc:subfield>
                    <marc:subfield code="a"><xsl:value-of select="$kanton"/></marc:subfield>
                    <marc:subfield code="2">CHARCH</marc:subfield>
                </marc:datafield>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- MARC-Feld: 245 -->
    <xsl:template name="cdF245">
        <xsl:param name="type" />
        <xsl:variable name="titel" select="DetailData/DataElement[@ElementName='Titel / Name']/ElementValue/TextValue/text()" />
        <xsl:variable name="fallback" select="@IdName" />
        <xsl:variable name="GMD">
            <xsl:choose>
                <xsl:when test="$type = 'foto' or type = 'bild'">
                    <xsl:text>[Bild]</xsl:text>
                </xsl:when>
                <xsl:when test="$type = 'ton'">
                    <xsl:text>[Ton]</xsl:text>
                </xsl:when>
                <xsl:when test="$type = 'film'">
                    <xsl:text>[Filmmaterial]</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <marc:datafield tag="245" ind1="0" ind2="0" >
            <xsl:choose>
                <xsl:when test="$titel">
                    <marc:subfield code="a"><xsl:value-of select="$titel"/></marc:subfield>
                    <xsl:choose>
                        <xsl:when test="$GMD !=''">
                            <marc:subfield code="h"><xsl:value-of select="$GMD" /></marc:subfield>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <marc:subfield code="a"><xsl:value-of select="$fallback"/></marc:subfield>
                </xsl:otherwise>
            </xsl:choose>
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
        <!-- <xsl:variable name="komplett" select="DetailData/DataElement[@ElementName='Verlag']/ElementValue/TextValue/text()"/> 
        <TextValue>[S.l.] : [s.n.], [1750]</TextValue> -->
        <xsl:variable name="kOrt" select="fn:substring-before(DetailData/DataElement[@ElementName='Verlag']/ElementValue/TextValue/text(), ' : ')" />
        <xsl:variable name="kVerlag" select="fn:substring-before(fn:substring-after(DetailData/DataElement[@ElementName='Verlag']/ElementValue/TextValue/text(), ' : '), ', ')" />
        <xsl:variable name="kJahr" select="fn:substring-after(DetailData/DataElement[@ElementName='Verlag']/ElementValue/TextValue/text(), ', ')" />
        <xsl:variable name="ort" select="DetailData/DataElement[@ElementName='Partnerangaben Verlag/Vertrieb']/ElementValue/TextValue/text()"/>
        <xsl:variable name="verlag" select="DetailData/DataElement[@ElementName='Vertrieb/Verlag']/ElementValue/TextValue/text()"/>
        <xsl:variable name="zeit" select="DetailData/DataElement[@ElementName='Entstehungszeitraum']/ElementValue/DateRange/TextRepresentation/text()"/>
        
        <marc:datafield tag="260" ind1=" " ind2=" ">
            <xsl:choose>
                <xsl:when test="DetailData/DataElement[@ElementName='Verlag']">
                    <xsl:choose>
                        <xsl:when test="$kOrt">
                            <marc:subfield code="a"><xsl:value-of select="$kOrt"/></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="a">[s.l.]</marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$kVerlag">
                            <marc:subfield code="b"><xsl:value-of select="$kVerlag"/></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="b">[s.n.]</marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$kJahr">
                            <marc:subfield code="c"><xsl:value-of select="$kJahr"/></marc:subfield>
                        </xsl:when>
                        <xsl:otherwise>
                            <marc:subfield code="c">[unbekannt]</marc:subfield>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
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
    <xsl:template name="cdF300">
        <!-- Bestand -->
    <xsl:if test="DetailData/DataElement[@ElementName='Umfang (Text)'] | DetailData/DataElement[@ElementName='Umfang (Laufmeter)']">
        <xsl:variable name="txt" select="DetailData/DataElement[@ElementName='Umfang (Text)']/ElementValue[@Sequence='1']/TextValue/text()" />
        <xsl:variable name="lfm" select="DetailData/DataElement[@ElementName='Umfang (Laufmeter)']/ElementValue/FloatValue/text()" />
        <marc:datafield tag="300" ind1=" " ind2=" " >
            <xsl:choose>
                <xsl:when test="fn:string-length($txt) &gt; 0 and fn:string-length($lfm) &gt; 0">
                    <marc:subfield code="a"><xsl:value-of select="$txt" /></marc:subfield>
                    <marc:subfield code="a"><xsl:value-of select="$lfm" /></marc:subfield>
                    <marc:subfield code="f"><xsl:text>Laufmeter</xsl:text></marc:subfield>
                </xsl:when>
                <xsl:when test="fn:string-length($lfm) &gt; 0">
                    <marc:subfield code="a"><xsl:value-of select="$lfm" /></marc:subfield>
                    <marc:subfield code="f"><xsl:text>Laufmeter</xsl:text></marc:subfield>
                </xsl:when>
                <xsl:when test="fn:string-length($txt) &gt; 0">
                    <marc:subfield code="a"><xsl:value-of select="$txt" /></marc:subfield>
                </xsl:when>
            </xsl:choose>
        </marc:datafield>
    </xsl:if>
        <!-- Dossier -->
    <xsl:if test="DetailData/DataElement[@ElementName='Anzahl beschriebene Seiten'] | DetailData/DataElement[@ElementName='Diverse'] | DetailData/DataElement[@ElementName='Anzahl Fotografien (Positive)']">
        <xsl:variable name="abs" select="DetailData/DataElement[@ElementName='Anzahl beschriebene Seiten']/ElementValue/TextValue/text()" />
        <xsl:variable name="div" select="DetailData/DataElement[@ElementName='Diverse']/ElementValue/FloatValue/text()" />
        <xsl:variable name="pht" select="DetailData/DataElement[@ElementName='Anzahl Fotografien (Positive)']/ElementValue/FloatValue/text()" />
        <marc:datafield tag="300" ind1=" " ind2=" " >
            <xsl:choose>
                <xsl:when test="$abs and $div">
                    <marc:subfield code="a"><xsl:value-of select="$abs" /></marc:subfield>
                    <marc:subfield code="a"><xsl:value-of select="$div" /></marc:subfield>
                </xsl:when>
                <xsl:when test="$pht">
                    <marc:subfield code="a"><xsl:value-of select="$abs" /></marc:subfield>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$abs">
                            <marc:subfield code="a"><xsl:value-of select="$abs" /></marc:subfield>
                        </xsl:when>
                        <xsl:when test="div">
                            <marc:subfield code="a"><xsl:value-of select="$div" /></marc:subfield>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </marc:datafield>
    </xsl:if>
        <!-- Dokument Foto -->
    <xsl:if test="DetailData/DataElement[@ElementName='Effektive Masse Bild'] or (DetailData/DataElement[@ElementName='Archivalienart'] and DetailData/DataElement[@ElementName='Farbe'])">
        <xsl:variable name="archivalienart" select="DetailData/DataElement[@ElementName='Archivalienart']/ElementValue/TextValue/text()"/>
        <xsl:variable name="farbe" select="DetailData/DataElement[@ElementName='Farbe']/ElementValue/TextValue/text()"/>
        <xsl:variable name="bildmasse" select="DetailData/DataElement[@ElementName='Standard Bildformat']/ElementValue/TextValue/text()"/>
        
        <xsl:if test="$archivalienart | $farbe | $bildmasse">
         <marc:datafield tag="300" ind1=" " ind2=" " >
            <xsl:if test="$archivalienart">
                <marc:subfield code="a"><xsl:value-of select="$archivalienart" /></marc:subfield>
            </xsl:if>
            <xsl:if test="$farbe">
                <marc:subfield code="b"><xsl:value-of select="$farbe" /></marc:subfield>
            </xsl:if>
            <xsl:if test="$bildmasse">
                <marc:subfield code="c"><xsl:value-of select="$bildmasse" /></marc:subfield>
            </xsl:if>
         </marc:datafield>
        </xsl:if>
    </xsl:if>
        <!-- Dokument Bild -->
    <xsl:if test="(DetailData/DataElement[@ElementName='Archivalienart'] | DetailData/DataElement[@ElementName='Technik'] | DetailData/DataElement[@ElementName='Effektive Masse Bild']) and AdministrativeData/EditForm/text() = 'NB Gemälde/Plan/Zeichnung/Grafik'">
        <xsl:variable name="archivalienart" select="DetailData/DataElement[@ElementName='Archivalienart']/ElementValue/TextValue/text()"/>
        <xsl:variable name="technik" select="DetailData/DataElement[@ElementName='Technik']/ElementValue/TextValue/text()"/>
        <xsl:variable name="bildmasse" select="DetailData/DataElement[@ElementName='Effektive Masse Bild']/ElementValue/TextValue/text()"/>
        
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
    </xsl:if>
        <!-- Dokument Text-->
    <xsl:if test="DetailData/DataElement[@ElementName='Kollation']">
        <xsl:variable name="kseite" select="fn:substring-before(DetailData/DataElement[@ElementName='Kollation']/ElementValue[@Sequence='1']/TextValue/text(), ' : ')" />
        <xsl:variable name="kill" select="fn:substring-before(fn:substring-after(DetailData/DataElement[@ElementName='Kollation']/ElementValue[@Sequence='1']/TextValue/text(), ' : '), ' ; ')" />
        <xsl:variable name="kmasse" select="fn:substring-after(DetailData/DataElement[@ElementName='Kollation']/ElementValue[@Sequence='1']/TextValue/text(), ' ; ')" />
        
        <xsl:if test="fn:string-length($kseite) &gt; 0 or fn:string-length($kill) &gt; 0 or fn:string-length($kmasse) &gt; 0">
         <marc:datafield tag="300" ind1=" " ind2=" " >
            <xsl:if test="fn:string-length($kseite) &gt; 0">
                <marc:subfield code="a"><xsl:value-of select="$kseite" /></marc:subfield>
            </xsl:if>
            <xsl:if test="fn:string-length($kill) &gt; 0">
                <marc:subfield code="b"><xsl:value-of select="$kill" /></marc:subfield>
            </xsl:if>
            <xsl:if test="fn:string-length($kmasse) &gt; 0">
                <marc:subfield code="c"><xsl:value-of select="$kmasse" /></marc:subfield>
            </xsl:if>
         </marc:datafield>
        </xsl:if>
    </xsl:if>
    </xsl:template>
    
    <!-- MARC-Feld 351 -->
    <xsl:template name="cdF351">
        <marc:datafield tag="351" ind1=" " ind2=" ">
            <marc:subfield code="c">
                <xsl:value-of select="@Level"/>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- Linking Marc-Feld: 490 / 777 / 830 - UMSTELLUNG FÜR SWISSBIB VON 490 auf 779 -->
    <!-- ACHTUNG: Das Linking ist komplett an swissbib angepasst und entspricht nicht den Gepflogenheiten von MARC21 -->
    <xsl:template name="Linking">
        <xsl:variable name="parentLevel">
            <xsl:choose>
                <xsl:when test="parent::node()/attribute::Level">
                    <xsl:value-of select="parent::node()/attribute::Level" />
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$level='BESTAND'">
                <xsl:variable name="cdF490a">
                    <xsl:choose>
                        <xsl:when test="fn:contains(parent::node()/attribute::IdName, '   ')">
                            <xsl:value-of select="fn:substring-after(parent::node()/attribute::IdName, '   ')" />
                        </xsl:when>
                        <xsl:when test="fn:contains(parent::node()/attribute::IdName, 'EAD-')">
                            <xsl:value-of select="parent::node()/attribute::IdName" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="fn:substring-after(parent::node()/attribute::IdName, '   ')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$cdF490a != ''">
                    <marc:datafield tag="490" ind1="1" ind2=" " >
                        <marc:subfield code="a"><xsl:value-of select="$cdF490a"/></marc:subfield>
                    </marc:datafield>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$level='DOK'">
                <xsl:variable name="cdF490v" select="fn:substring-before(./@IdName, '   ')" />
                <xsl:variable name="cdF830w" select="root(.)/ExportRoot/Record/attribute::Id" />
                <xsl:variable name="cdF490a">
                    <xsl:choose>
                        <xsl:when test="fn:contains(root(.)/ExportRoot/Record/attribute::IdName, '   ')">
                            <xsl:value-of select="fn:substring-after(root(.)/ExportRoot/Record/attribute::IdName, '   ')" />
                        </xsl:when>
                        <xsl:when test="fn:contains(root(.)/ExportRoot/Record/attribute::IdName, 'EAD-')">
                            <xsl:value-of select="root(.)/ExportRoot/Record/attribute::IdName" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="fn:substring-after(root(.)/ExportRoot/Record/attribute::IdName, '   ')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <marc:datafield tag="779" ind1="1" ind2=" " >
                    <marc:subfield code="a"><xsl:value-of select="$cdF490a"/></marc:subfield>
                    <xsl:if test="$cdF490v !=''">
                        <marc:subfield code="v"><xsl:value-of select="$cdF490v"/></marc:subfield>
                    </xsl:if>
                    <xsl:if test="$cdF830w !=''">
                        <marc:subfield code="w"><xsl:text>(CHARCH)cha</xsl:text><xsl:value-of select="$cdF830w"/></marc:subfield>
                        <marc:subfield code="9"><xsl:text>cha</xsl:text><xsl:value-of select="$cdF830w"/></marc:subfield>
                    </xsl:if>
                </marc:datafield>
                <!-- Related Document-->
                <xsl:variable name="recid" select="../@Id"/>
                <xsl:variable name="parentid" select="@ParentId"/>
                <xsl:variable name="levl" select="../@Level"/>
                <xsl:if test="($recid = $parentid) and $levl = 'Dokument'">
                    <xsl:variable name="rectitle" select="fn:substring-after(../attribute::IdName, '   ')" />
                    <marc:datafield tag="777" ind1="0" ind2=" " >
                        <marc:subfield code="a"><xsl:value-of select="$rectitle"/></marc:subfield>
                        <xsl:choose>
                            <xsl:when test="$parentid !=''">
                                <marc:subfield code="w"><xsl:text>(CHARCH)cha</xsl:text><xsl:value-of select="$parentid"/></marc:subfield>
                                <marc:subfield code="9"><xsl:text>cha</xsl:text><xsl:value-of select="$parentid"/></marc:subfield>
                            </xsl:when>
                        </xsl:choose>
                    </marc:datafield>
                </xsl:if>
                
            </xsl:when>
            <xsl:when test="ALL">
                <xsl:variable name="cdF830w">
                    <xsl:variable name="parentid" select="@ParentId" />
                    <xsl:variable name="recordid" select="parent::node()/attribute::Id" />
                    <xsl:choose>
                        <xsl:when test="$parentid = $recordid">
                            <xsl:value-of select="$recordid" />
                        </xsl:when>
                        <xsl:otherwise>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="cdF490a">
                    <xsl:choose>
                        <xsl:when test="DetailData/DataElement[@ElementName='Titel der Serie']">
                            <xsl:value-of select="DetailData/DataElement/ElementValue/TextValue/text()" />
                        </xsl:when>
                        <xsl:when test="fn:contains(parent::node()/attribute::IdName, '   ')">
                            <xsl:value-of select="fn:substring-after(parent::node()/attribute::IdName, '   ')" />
                        </xsl:when>
                        <xsl:when test="fn:contains(parent::node()/attribute::IdName, 'EAD-')">
                            <xsl:value-of select="parent::node()/attribute::IdName" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="fn:substring-after(parent::node()/attribute::IdName, '   ')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
        
                <!-- xsl:if test="((DetailData/DataElement[@ElementName='Titel der Serie'] or parent::node()/attribute::IdName) and ($parentLevel='Sammlungseinheit' or $parentLevel='Serie' or $parentLevel='Bestand' or $parentLevel='Dossier'))" -->
                <xsl:if test="$cdF490a != ''">
                    <marc:datafield tag="779" ind1="1" ind2=" " >
                        <marc:subfield code="a"><xsl:value-of select="$cdF490a"/></marc:subfield>
                        <xsl:choose>
                            <xsl:when test="$cdF830w != ''">
                                <marc:subfield code="w"><xsl:text>(CHARCH)cha</xsl:text><xsl:value-of select="$cdF830w"/></marc:subfield>
                                <marc:subfield code="9"><xsl:text>cha</xsl:text><xsl:value-of select="$cdF830w"/></marc:subfield>
                            </xsl:when>
                        </xsl:choose>
                    </marc:datafield>
                   <!-- <marc:datafield tag="830" ind1=" " ind2="0" >
                        <marc:subfield code="a"><xsl:value-of select="$cdF490a"/></marc:subfield>
                        <xsl:choose>
                            <xsl:when test="$cdF830w !=''">
                                <marc:subfield code="w"><xsl:text>(CHARCH)cha</xsl:text><xsl:value-of select="$cdF830w"/></marc:subfield>
                            </xsl:when>
                        </xsl:choose>
                    </marc:datafield> -->
                </xsl:if>
            </xsl:when>
        </xsl:choose>
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
            <marc:subfield code="a"><xsl:text>Orientierung und Form: </xsl:text><xsl:value-of select="ElementValue/TextValue/text()" /></marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Verwandtes Material']">
        <marc:datafield tag="500" ind1=" " ind2=" " >
            <marc:subfield code="a"><xsl:text>Verwandtes Material: </xsl:text>
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template> 
    
    <!-- MARC-Feld 506 --> 
    <xsl:template match="DataElement[@ElementName='Zugangsbedingungen']">
        <marc:datafield tag="506" ind1=" " ind2=" ">
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
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
    
    <!-- MARC-Feld 516 -->
    <xsl:template match="DataElement[@ElementName='Digitales Fileformat']">
        <marc:datafield tag="516" ind1=" " ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- MARC-Feld 520 --> 
    <xsl:template match="DataElement[@ElementName='Kurzbeschreibung']">
        <marc:datafield tag="520" ind1="3" ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bemerkung zur Kurzbeschreibung']">
        <marc:datafield tag="520" ind1="3" ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Inhalt']">
        <marc:datafield tag="520" ind1="3" ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bestandsbeschreibung']">
        <marc:datafield tag="520" ind1="2" ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Stichwort']">
        <marc:datafield tag="520" ind1=" " ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Darin']">
        <marc:datafield tag="520" ind1=" " ind2=" ">
            <marc:subfield code="a">
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- MARC-Feld 542 -->
    <xsl:template name="cdF542">
        <xsl:variable name="UrheberrechtsInhaber" select="DetailData/DataElement[@ElementName='Urheberrechts-Inhaber']/ElementValue/TextValue/text()"/>
        <xsl:variable name="BemUrheberrechtsInhaber" select="DetailData/DataElement[@ElementName='Bemerkungen zum Urheberrechts-Inhaber']/ElementValue/TextValue/text()"/>
        <xsl:variable name="PartUrheberrechtsInhaber" select="DetailData/DataElement[@ElementName='Partnerangaben Urheberrechts-Inhaber']/ElementValue/TextValue/text()"/>

            <xsl:if test="fn:string-length($UrheberrechtsInhaber) &gt; 0 or fn:string-length($BemUrheberrechtsInhaber) &gt; 0 or fn:string-length($PartUrheberrechtsInhaber) &gt; 0">
                <marc:datafield tag="542" ind1=" " ind2=" ">
                <xsl:if test="fn:string-length($UrheberrechtsInhaber) &gt; 0">
                    <marc:subfield code="d"><xsl:value-of select="$UrheberrechtsInhaber"/></marc:subfield>
                </xsl:if>
                <xsl:if test="fn:string-length($PartUrheberrechtsInhaber) &gt; 0">
                    <marc:subfield code="e"><xsl:value-of select="$PartUrheberrechtsInhaber"/></marc:subfield>
                </xsl:if>
                <xsl:if test="fn:string-length($BemUrheberrechtsInhaber) &gt; 0">
                    <marc:subfield code="n"><xsl:value-of select="$BemUrheberrechtsInhaber"/></marc:subfield>
                </xsl:if>
                </marc:datafield>
            </xsl:if>
    </xsl:template>

    <!-- MARC-Feld 561 --> 
    <xsl:template match="DataElement[@ElementName='Art des Bestands']">
        <marc:datafield tag="561" ind1=" " ind2=" ">
            <marc:subfield code="a"><xsl:text>Art des Bestands: </xsl:text>
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Art des Erwerbs']">
        <marc:datafield tag="561" ind1=" " ind2=" ">
            <marc:subfield code="a"><xsl:text>Art des Erwerbs: </xsl:text>
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Bestandsgeschichte']">
        <marc:datafield tag="561" ind1=" " ind2=" ">
            <marc:subfield code="a"><xsl:text>Art des Erwerbs: </xsl:text>
                <xsl:for-each select="ElementValue/TextValue/text()">
                    <xsl:value-of select="." /><xsl:if test="not(position() = last())"><xsl:text>. </xsl:text></xsl:if>
                </xsl:for-each>
            </marc:subfield>
        </marc:datafield>
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
        <xsl:choose>
            <xsl:when test="Name[text()='ArchitektIn'] or Name[text()='Abgebildete Person'] or Name[text()='Behandelte Person']">
                <xsl:variable name="relator">
                    <xsl:if test="Name[text()='ArchitektIn']">
                        <xsl:text>arc</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="Thesaurus[text()='Körperschaften']">
                        <xsl:variable name="koerperschaftvalue" select="normalize-space(IdName/text())"/>
                        <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(.*)(\))">
                            <xsl:matching-substring>
                                <xsl:variable name="part1" select="regex-group(2)"/>
                                <marc:datafield tag="690" ind1=" " ind2="7">
                                    <marc:subfield code="B">b</marc:subfield>
                                    <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                    <xsl:if test="fn:string-length($relator) != 0">
                                        <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                    </xsl:if>
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
                                        <xsl:if test="fn:string-length($relator) != 0">
                                            <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                        </xsl:if>
                                        <marc:subfield code="2">CHARCH</marc:subfield>
                                    </marc:datafield>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="relator">
                    <xsl:choose>
                        <xsl:when test="Name[text()='FotografIn']">
                            <xsl:text>pht</xsl:text>
                        </xsl:when>
                        <xsl:when test="fn:contains(Name, 'AutorIn')">
                            <xsl:text>aut</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='InterviewpartnerIn']">
                            <xsl:text>ivr</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='AbsenderIn'] or Name[text()='AdressatIn']">
                            <xsl:text>crp</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='ÜbersetzerIn']">
                            <xsl:text>trl</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='BildendeR KünstlerIn']">
                            <xsl:text>art</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='HerausgeberIn']">
                            <xsl:text>edt</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='KomponistIn']">
                            <xsl:text>cmp</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='WidmungsverfasserIn']">
                            <xsl:text>dto</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='WidmungsempfängerIn']">
                            <xsl:text>dte</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='BestandsbildnerIn']">
                            <xsl:text>col</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='DonatorIn']">
                            <xsl:text>dnr</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='ProduzentIn']">
                            <xsl:text>pro</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='Urheberrechts-Inhaber']">
                            <xsl:text>cph</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='ModeratorIn']">
                            <xsl:text>mod</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='RedaktorIn']">
                            <xsl:text>red</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='RegisseurIn']">
                            <xsl:text>drt</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='TechnikerIn']">
                            <xsl:text>prd</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='KostümbildnerIn']">
                            <xsl:text>cst</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='SprecherIn']">
                            <xsl:text>spk</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='Kamera']">
                            <xsl:text>vdg</xsl:text>
                        </xsl:when>
                        <xsl:when test="Name[text()='Vertrieb/Verlag']">
                            <xsl:text>dst</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="Thesaurus[text()='Körperschaften']">
                        <xsl:variable name="koerperschaftvalue" select="normalize-space(IdName/text())"/>
                        <xsl:choose>
                            <xsl:when test="contains($koerperschaftvalue, 'Schweiz.')">
                                <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(Schweiz\. )(.*)(\))">
                                    <xsl:matching-substring>
                                        <xsl:variable name="part1" select="regex-group(2)"/>
                                        <xsl:variable name="part2" select="regex-group(3)"/>
                                        <marc:datafield tag="710"  ind1="1" ind2=" "  >
                                            <marc:subfield code="a"><xsl:value-of select="fn:translate($part1,' .()','')"/></marc:subfield>
                                            <marc:subfield code="b"><xsl:value-of select="normalize-space($part2)"/></marc:subfield>
                                            <xsl:if test="fn:string-length($relator) != 0">
                                                <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                            </xsl:if>
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
                                            <xsl:if test="fn:string-length($relator) != 0">
                                                <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                            </xsl:if>
                                        </marc:datafield>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                                <xsl:analyze-string select="$koerperschaftvalue" regex="(Körperschaften\\[A-Z]\\)(.*)(\))">
                                    <xsl:matching-substring>
                                        <xsl:variable name="part1" select="regex-group(2)"/>
                                        <marc:datafield tag="710" ind1="2" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                            <xsl:if test="fn:string-length($relator) != 0">
                                                <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                            </xsl:if>
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
                                            <xsl:if test="fn:string-length($relator) != 0">
                                                <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                            </xsl:if>
                                        </marc:datafield>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <marc:datafield tag="700" ind1="1" ind2=" ">
                                            <marc:subfield code="a"><xsl:value-of select="normalize-space($part1)"/></marc:subfield>
                                            <marc:subfield code="d"><xsl:value-of select="fn:translate($part2,' ()','')"/></marc:subfield>
                                            <xsl:if test="fn:string-length($relator) != 0">
                                                <marc:subfield code="4"><xsl:value-of select="$relator"/></marc:subfield>
                                            </xsl:if>
                                        </marc:datafield>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="Thesaurus[text()='Dewey Dezimal Klassifikation']">
            <xsl:variable name="ddc" select="normalize-space(lower-case(IdName/text()))"/>
            <!--xsl:analyze-string select="$ddc" regex="(^(\d\d\d\.?\d?\d?)( .*))"-->
            <xsl:analyze-string select="$ddc" regex="(^([1-9][0-9][0-9]\.?[0-9]?[0-9]?[ ])([a-z]*))">
                <xsl:matching-substring>
                    <marc:datafield tag="083" ind1="0" ind2=" " >
                        <marc:subfield code="a"><xsl:value-of select="normalize-space(regex-group(2))"/></marc:subfield>
                        <marc:subfield code="2">23</marc:subfield>
                    </marc:datafield>
                </xsl:matching-substring>
            </xsl:analyze-string>
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
    
    <xsl:template match="DataElement[@ElementName='Gemeinde']">
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/><xsl:text> (Gemeinde)</xsl:text></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>

    <xsl:template match="DataElement[@ElementName='Ort']">
        <xsl:param name="type" />
        <xsl:choose>
            <xsl:when test="$type = 'bild' or $type = 'foto'">
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
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="ElementValue[@Sequence='2']">
                        <xsl:for-each select="ElementValue/TextValue">
                            <marc:datafield tag="690" ind1=" " ind2="7" >
                                <marc:subfield code="B">g</marc:subfield>
                                <marc:subfield code="a"><xsl:value-of select="./text()"/></marc:subfield>
                                <marc:subfield code="2">CHARCH</marc:subfield>
                            </marc:datafield>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="ElementValue/TextValue/text() = 's.l.'">
                            <marc:datafield tag="690" ind1=" " ind2="7" >
                                <marc:subfield code="B">g</marc:subfield>
                                <marc:subfield code="a">
                                   <xsl:value-of select="ElementValue/TextValue/text()"/>
                                </marc:subfield>
                                <marc:subfield code="2">CHARCH</marc:subfield>
                            </marc:datafield>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="DataElement[@ElementName='Lokalname']">
        <marc:datafield tag="690" ind1=" " ind2="7" >
            <marc:subfield code="B">g</marc:subfield>
            <marc:subfield code="a"><xsl:value-of select="ElementValue/TextValue/text()"/></marc:subfield>
            <marc:subfield code="2">CHARCH</marc:subfield>
        </marc:datafield>
    </xsl:template>
    
    <!-- CHB-Mediencodes: Marc-Feld 898 -->
    <!-- TODO: Der CHB-Mediencode ist aktuell sehr limitiert und sollte noch verbessert werden -->
    <xsl:template name="chbMediacode">
        <xsl:param name="type" />
        <xsl:choose>
            <xsl:when test="$type = 'foto'">
                <!-- VM020453 = Fotografie (online) und der dazu gehörende allg. Filtercode XM020400 -->
                <marc:datafield tag="898" ind2=" " ind1=" " >
                    <marc:subfield code="a"><xsl:text>VM020453</xsl:text></marc:subfield>
                    <marc:subfield code="b"><xsl:text>XM020400</xsl:text></marc:subfield>
                    <marc:subfield code="c"><xsl:text>XM020000</xsl:text></marc:subfield>
                </marc:datafield>
            </xsl:when>
            <xsl:when test="$type = 'bild'">
                <!-- VM020353 = Bild (online) und der dazu gehörende allg. Filtercode XM020000 -->
                <marc:datafield tag="898" ind2=" " ind1=" " >
                    <marc:subfield code="a"><xsl:text>VM020353</xsl:text></marc:subfield>
                    <marc:subfield code="b"><xsl:text>XM020000</xsl:text></marc:subfield>
                    <marc:subfield code="c"><xsl:text>XM020000</xsl:text></marc:subfield>
                </marc:datafield>
            </xsl:when>
            <xsl:when test="$type = 'monographie'">
                <!-- BK020000 = Buch und der dazu gehörende allg. Filtercode XK020000 -->
                <marc:datafield tag="898" ind2=" " ind1=" " >
                    <marc:subfield code="a"><xsl:text>BK020000</xsl:text></marc:subfield>
                    <marc:subfield code="b"><xsl:text>XK020000</xsl:text></marc:subfield>
                    <marc:subfield code="c"><xsl:text>XK020000</xsl:text></marc:subfield>
                </marc:datafield>
            </xsl:when>
            <xsl:otherwise>
                <!-- CL010000 = Bestand/Dossier und der dazu gehörende allg. Filtercode XL010000 -->
                <marc:datafield tag="898" ind2=" " ind1=" " >
                    <marc:subfield code="a"><xsl:text>CL010000</xsl:text></marc:subfield>
                    <marc:subfield code="b"><xsl:text>XL010000</xsl:text></marc:subfield>
                    <marc:subfield code="c"><xsl:text>XL010000</xsl:text></marc:subfield>
                </marc:datafield>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- MARC-Feld 856 -->
    <xsl:template match="DataElement[@ElementName='Ansichtsbild']">
        <xsl:if test="$bild = 'Y'">
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
        <xsl:if test="$bild = 'Y'"> 
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
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>

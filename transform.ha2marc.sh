#Script purpose: process the exported NB EAD files with an xslt - transformation to get MARC21 records

basedir=$1


inputdir=$1/nb.raw.export
outputdir=$1/nb.marc21
xslt=$basedir/xslt/transform.nb.vers09.vf.xsl
output=nb.marc21.nr
cp=$1/libs/saxon9.jar
institutioncode=$2

nr=1

echo "start (NB) EAD -> Marc21 transformation" 

for datei in $inputdir/*.xml
do

	echo "file: "$datei
	java -Xms2024m -Xmx2024m  -cp $cp  net.sf.saxon.Transform -s:$datei -xsl:$xslt -o:$outputdir/$output$nr.xml institutioncode=$institutioncode
	nr=$(($nr+1))

done




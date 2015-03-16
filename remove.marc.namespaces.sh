#Script purpose: remove marc namespaces


basedir=$1


inputdir=$basedir/marc.with.namespaces
outputdir=$basedir/marc.no.namespaces
xslt=$basedir/xslt/remove.namespaces.xsl
cp=$basedir/libs/saxon9.jar


echo "start transformation archive to marc"

for datei in $inputdir/*.xml
do

	echo "file: "$datei
	filename=`basename ${datei}`
	java -Xms1024m -Xmx1024m  -cp $cp  net.sf.saxon.Transform -s:$datei -xsl:$xslt -o:$outputdir/$filename

done




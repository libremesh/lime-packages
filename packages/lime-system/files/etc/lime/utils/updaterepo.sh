#!/bin/sh


DIR="/www/wbm"
METAFILE="/www/wbm/META"
TIMESTAMP="$(date +%Y%m%d%H%M)"

[ ! -d $DIR ] && make -p $DIR

rm -f $METAFILE 2>/dev/null

cd $DIR 

for f in *.bin *.img.gz *.img; do
	[ -f "$f" ] &&	echo "$(md5sum $f) $TIMESTAMP" >> $METAFILE
done

cat $METAFILE


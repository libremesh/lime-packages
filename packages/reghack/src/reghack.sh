#!/bin/sh

hackMe="ath cfg80211"

cd /tmp

for module in ${hackMe}
do
	cp /lib/modules/*/${module}.ko /tmp
	/usr/bin/reghack ${module}.ko
	mv ${module}.ko /lib/modules/*/
done

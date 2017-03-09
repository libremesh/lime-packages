#!/bin/bash
make -C po2lmo/ po2lmo
mkdir -p luasrc/i18n 2>/dev/null
for l in $(cd po; ls); do
  for f in $(cd po/$l; ls *.po); do
    b=$(basename -s po po/$l/$f)
    ./po2lmo/po2lmo po/$l/$f luasrc/i18n/${b}${l}.lmo
  done
done

#!/bin/sh

set -e

local="$1"
if [ "$local" != "" ] && { [ -f "$local" ] || [ -d "$local" ]; }; then
    luacheck "$local"
    return
fi

luacheck packages tests tools

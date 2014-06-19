#!/bin/sh

burstStopFile="/tmp/lime-hotplug-usbradio-burst-check"

[ -e "${burstStopFile}" ] ||
{
	lua_hotplug_args="hotplug_hook_args = { action='${ACTION}', devicename='${DEVICENAME}', devname='${DEVNAME}', devpath='${DEVPATH}', product='${PRODUCT}', type='${TYPE}', interface='${INTERFACE}' }"
	date > "${burstStopFile}"
	((sleep 2s ; lua -e"${lua_hotplug_args}" /usr/bin/lime-config ; rm -rf "${burstStopFile}")&)
}

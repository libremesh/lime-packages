#!/bin/sh


burstStopFile="/tmp/lime-hotplug-usbradio-burst-check"

#[Doc] Check if burstStopFile exists to avoid multiple execution due to hotplug call burst
#[Doc] In the case burstStopFile exists the following code will be not executed
[ -e "${burstStopFile}" ] ||
{
	#[Doc] Prepare Lua table with the hotplug parameters
	lua_hotplug_args="hotplug_hook_args = { action='${ACTION}', devicename='${DEVICENAME}', devname='${DEVNAME}', devpath='${DEVPATH}', product='${PRODUCT}', type='${TYPE}', interface='${INTERFACE}' }"

	#[Doc] Create burstStopFile; Write the date just for debugging
	date > "${burstStopFile}"

	#[Doc] Wait for the radio to be ready
	#[Doc] Configure the device calling lime-config but first execute lua_hotplug_args to pass hotplug parameters
	#[Doc] Finally remove burstStopFile 
	((sleep 2s ; lua -e"${lua_hotplug_args}" /usr/bin/lime-config ; rm -rf "${burstStopFile}")&)
}

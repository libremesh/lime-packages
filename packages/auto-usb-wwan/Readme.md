# auto-usb-wann
After installing  **auto-usb-wann**, a hotplug.d script will detect when any USB WiFi device is connected, automatically configure it to connect as client to a predefined SSID/password and ask for DHCP.
The idea is to provide internet access to a router, without needing to mess with LuCI or CLI.
Just insert a supported USB device on the router, and open an AP with 3g/4g tethering on a phone.

By default, it will try connect to SSID "android" with password "internet", you can edit this configuration in  */etc/hotplug.d/ieee80211/11_auto-usb-wwan*
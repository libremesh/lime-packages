LIME_TITLE:=soporteremoto allows AlterMundi to provide remote support through SSH root access
LIME_MAINTAINER:=Gui Iribarren <gui@altermundi.net>
LIME_DEPENDS:= +zerotier +auto-usb-wwan +kmod-ath9k-htc +ath9k-htc-firmware
LIME_SECTION:=utils
LIME_CATEGORY:=Utilities

define LIME_DESCRIPTION
  Installs auto-usb-wwan to provide a zero-configuration WWAN via USB dongle
  zerotier to provide VPN transport and installs a predefined set of ssh
  authorized_keys of AlterMundi members that will be granted root access.
endef

include ../../libremesh.mk

# call BuildPackage - OpenWrt buildroot signature

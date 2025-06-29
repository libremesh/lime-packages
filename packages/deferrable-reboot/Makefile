#
# Copyright (C) 2019 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides a deferrable reboot.
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+lua +lime-system
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	This $(PKG_NAME) provides a deferrable reboot mechanism. The system
	will be rebooted when the uptime of the system reach a specified amount
	of seconds and if /tmp/deferrable-reboot.defer file does not contain a
	number that is greater than the current uptime.
	This way if anyone wants to postpone the reboot, the way is to store the
	next checkpoint in seconds. For example if the system must not reboot from
	now and up to 120 seconds in the future then something like this can be donde
	awk '{print $1 + 120}' /proc/uptime > /tmp/deferrable-reboot.defer
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=safe-reboot
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) falls back to a last-known-good config after an ill-fated reboot.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  When you run $(PKG_NAME) specifying a grace time, it makes a backup of /etc at that point,
  and after the grace time reboots the system. At the next boot, it waits again for a timeout;
  if you can't login and delete the backup, it will restore it and reboot.
  This mechanism makes it possible to run $(PKG_NAME), try risky operations (like restarting
  the network), and if something goes wrong, just wait for the fallback timeout.
  Even more, you can make actual changes to /etc config and reboot. If it comes back up right,
  you can login and delete the backup. If something went wrong with the new /etc, just wait
  for the revert timeout.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/safe-reboot $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

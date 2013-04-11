#
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=safe-reboot
PKG_VERSION:=$(shell hg log --template "{date|shortdate}-{rev}\n" -l 1 .)
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/safe-reboot
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=safe-reboot falls back to a last-known-good config after an ill-fated reboot.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
endef

define Package/safe-reboot/description
  When you run $PKG_NAME specifying a grace time, it makes a backup of /etc at that point,
  and after the grace time reboots the system. At the next boot, it waits again for a timeout;
  if you can't login and delete the backup, it will restore it and reboot.
  This mechanism makes it possible to run $PKG_NAME, try risky operations (like restarting
  the network), and if something goes wrong, just wait for the fallback timeout.
  Even more, you can make actual changes to /etc config and reboot. If it comes back up right,
  you can login and delete the backup. If something went wrong with the new /etc, just wait
  for the revert timeout.
endef

define Build/Compile
endef

define Package/safe-reboot/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/safe-reboot $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,safe-reboot))

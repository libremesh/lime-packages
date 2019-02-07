#
# Copyright (C) 2019 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=safe-upgrade
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides safe firmware upgrades using two partitions.
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:=+lua-argparse
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	$(PKG_NAME) provides safe firmware upgrades using two partitions and a
	confirmation step. When the new firmware boots it must be confirmed with
	'$(PKG_NAME) confirm' before a defined period of time. If confirmation is not
	done, because you don't like the new firmware or the firmware does not work
	(you can't reach the device, etc), the device is automatically reverted to the
	previous state. This automatic revert is performed by the hardware watchdog  if
	the firmware crash before linux boots or by a linux userspace timer if the
	firmware boots  but you don't confirm it. The state of which firmware partition
	has to be booted and the logic that  allows booting a partition with rollback
	is implemented by a u-boot script that is installed  by '$(PKG_NAME) install'.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/safe-upgrade $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

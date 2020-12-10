#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-hwd-usbradio
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=LiMe hardware detection usb radio support
  CATEGORY:=LibreMesh
  URL:=http://libremesh.org
  DEPENDS:=+lime-system +lua +libuci-lua
  PKGARCH:=all
endef

define Build/Compile
	@rm -rf ./build || true
	@cp -r ./src ./build
	@sed -i '/^\s*--!.*/d' build/*.lua
	@sed -i '/^\s*#\[Doc\]/d' build/*.sh
endef

define Package/$(PKG_NAME)/install
	@mkdir -p $(1)/usr/lib/lua/lime/hwd || true
	@mkdir -p $(1)/etc/hotplug.d/usb || true
	$(CP) ./build/usbradio.lua $(1)/usr/lib/lua/lime/hwd/usbradio.lua
	$(CP) ./build/hotplug-hook.sh $(1)/etc/hotplug.d/usb/60-lime-hwd-usbradio
	@chmod +x $(1)/usr/lib/lua/lime/hwd/usbradio.lua
	@chmod +x $(1)/etc/hotplug.d/usb/60-lime-hwd-usbradio
endef

$(eval $(call BuildPackage,$(PKG_NAME)))


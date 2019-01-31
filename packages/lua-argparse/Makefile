#
# Copyright (C) 2019 Santiago Piccinini
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lua-argparse
PKG_VERSION:=0.6.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
PKG_LICENSE:=MIT

PKG_SOURCE:=argparse-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/mpeterv/argparse/archive/$(PKG_VERSION)/
PKG_HASH:=0eddda29d591536bc7310b99ce7acc3e5e00557f18d6e63ab10d56683e8952f1
PKG_BUILD_DIR:=$(BUILD_DIR)/argparse-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/lua-argparse
	SUBMENU:=Lua
	SECTION:=lang
	CATEGORY:=Languages
	TITLE:=Lua argparse
	URL:=https://github.com/mpeterv/argparse
	DEPENDS:=+lua
	MAINTAINER:=Peter Melnichenko <mpeterval@gmail.com>
endef

define Package/lua-argparse/description
	Argparse is a feature-rich command line parser for Lua inspired by argparse for Python.
	Argparse supports positional arguments, options, flags, optional arguments,
	subcommands and more. Argparse automatically generates usage, help and error messages.
endef


define Build/Configure
endef

define Build/Compile
endef

define Package/lua-argparse/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/argparse.lua $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,lua-argparse))

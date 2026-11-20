# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2023-2024  Gioacchino Mazzurco <gio@eigenlab.org>
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023-2024  Asociación Civil Altermundi <info@altermundi.net>

include $(TOPDIR)/rules.mk

PKG_NAME:=shared-state-async

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/libremesh/shared-state-async.git
PKG_SOURCE_DATE:=2026-11-19
PKG_SOURCE_VERSION:=1a20921704184fa83af6f661dded2cb4a40b34d9
PKG_MIRROR_HASH:=06d2ce1a21d9b1af801fd36d6a6db3a6292d94fdeea57e1f4627a16f983780f0
PKG_MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
PKG_LICENSE:=AGPL-3.0-only



GIT_COMMIT_DATE:=$(shell psd="$(PKG_SOURCE_DATE)" && echo $${psd} | sed 's|-|.|g' )
GIT_COMMIT_SHORTHASH:=$(shell psv="$(PKG_SOURCE_VERSION)" && echo $${psv:0:7} )
PKG_VERSION:=$(GIT_COMMIT_DATE)~$(GIT_COMMIT_SHORTHASH)
PKG_RELEASE:=1

PKG_CONFIG_DEPENDS:=CONFIG_SHARED_STATE_ASYNC_STATIC

HOST_BUILD_PREFIX:=$(STAGING_DIR_HOST)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/host-build.mk

define Package/shared-state-async
  TITLE:=shared-state C++ async
  CATEGORY:=LibreMesh
  URL:=https://github.com/libremesh/shared-state-async
  DEPENDS:=+!SHARED_STATE_ASYNC_STATIC:libstdcpp +shared-state
endef

define Package/shared-state-async/config
	config SHARED_STATE_ASYNC_STATIC
		bool "Link libstdc++ statically"
		depends on PACKAGE_shared-state-async
		default y
		help
		  Build shared-state-async with -static-libstdc++ so the
		  libstdcpp package is not required on the device.
endef

define Package/shared-state-async/description
	shared-state re-written in C++20 and coroutines to handle information exchange between network nodes more efficiently.
endef

# Otherwise OpenWrt's CPPFLAGS are ignored
TARGET_CFLAGS += $(TARGET_CPPFLAGS)

CMAKE_OPTIONS += -DCMAKE_VERBOSE_MAKEFILE=ON

# Disable Cpptrace as it depends on zlib and doesn't seems to work anyway on
# OpenWrt even with CONFIG_DEBUG=y it prints out
# Stack trace (most recent call first):
# #0 0x00000000
# #1 0x00000000
# #2 0x00000000
CMAKE_OPTIONS += -DSS_CPPTRACE_STACKTRACE=OFF

# Link libstdc++ statically or dynamically depending on the config option
ifeq ($(CONFIG_SHARED_STATE_ASYNC_STATIC),y)
  CMAKE_OPTIONS += -DSS_STATIC_LIBSTDCPP=ON
else
  CMAKE_OPTIONS += -DSS_STATIC_LIBSTDCPP=OFF
endif

# Let OpenWrt strip the binary according to CONFIG_USE_STRIP/SSTRIP
CMAKE_OPTIONS += -DSS_STRIP_SYMBOLS=OFF

define Package/shared-state-async/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/shared-state-async $(1)/usr/bin/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,shared-state-async))

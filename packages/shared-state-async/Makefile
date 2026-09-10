# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2023-2024  Gioacchino Mazzurco <gio@eigenlab.org>
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023-2024  Asociación Civil Altermundi <info@altermundi.net>

include $(TOPDIR)/rules.mk

PKG_NAME:=shared-state-async

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/javierbrk/shared-state-async.git
PKG_SOURCE_VERSION:=use-statically-linked-stdlib
PKG_MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
PKG_LICENSE:=AGPL-3.0-only



GIT_COMMIT_DATE:=$(shell psd="$(PKG_SOURCE_DATE)" && echo $${psd} | sed 's|-|.|g' )
GIT_COMMIT_SHORTHASH:=$(shell psv="$(PKG_SOURCE_VERSION)" && echo $${psv:0:7} )
PKG_VERSION:=$(GIT_COMMIT_DATE)~$(GIT_COMMIT_SHORTHASH)
PKG_RELEASE:=1

HOST_BUILD_PREFIX:=$(STAGING_DIR_HOST)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/host-build.mk

define Package/shared-state-async/Default
  TITLE:=shared-state C++ async 
  CATEGORY:=LibreMesh
  URL:=https://github.com/libremesh/shared-state-async
endef

define Package/shared-state-async
  $(call Package/shared-state-async/Default)
  TITLE+= (dynamic linking)
  DEPENDS:=+libstdcpp
  VARIANT:=dynamic
  CONFLICTS:=shared-state-async-static
endef

define Package/shared-state-async-static
  $(call Package/shared-state-async/Default)
  TITLE+= (static linking)
  VARIANT:=static
  PROVIDES:=shared-state-async
  CONFLICTS:=shared-state-async
endef

define Package/shared-state-async/description
	shared-state re-written in C++20 and coroutines to handle information exchange between network nodes more efficiently.
endef

define Package/shared-state-async-static/description
	shared-state re-written in C++20 and coroutines to handle information exchange between network nodes more efficiently.
	This variant is statically linked against the C++ standard library.
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

# Build configuration según variante
ifeq ($(BUILD_VARIANT),static)
  CMAKE_OPTIONS += -DSS_STATIC_LIBSTDCPP=ON
  CMAKE_OPTIONS += -DSS_STRIP_SYMBOLS=ON
else
  CMAKE_OPTIONS += -DSS_STATIC_LIBSTDCPP=OFF
  CMAKE_OPTIONS += -DSS_STRIP_SYMBOLS=OFF
endif

define Package/shared-state-async/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/shared-state-async $(1)/usr/bin/
	$(CP) ./files/* $(1)/

	# TODO: Remove this line once discovery is reimplemented in C++
	$(CP) ../shared-state/files/usr/bin/shared-state-get_candidates_neigh $(1)/usr/bin/shared-state-async-discover
endef

Package/shared-state-async-static/install = $(Package/shared-state-async/install)

$(eval $(call BuildPackage,shared-state-async))
$(eval $(call BuildPackage,shared-state-async-static))

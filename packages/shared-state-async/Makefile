# Shared State
#
# Copyright (C) 2023-2024  Gioacchino Mazzurco <gio@eigenlab.org>
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023-2024  Asociación Civil Altermundi <info@altermundi.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>
#
# SPDX-License-Identifier: AGPL-3.0-only

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . | sed 's|-|.|g' )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=shared-state-async
PKG_VERSION=$(GIT_COMMIT_DATE)~$(GIT_COMMIT_TSTAMP)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/libremesh/shared-state-async.git
PKG_SOURCE_VERSION:=db58e3d16e8658417956f9bb42e7e87f6aadcd4d
PKG_MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
PKG_LICENSE:=AGPL-3.0

HOST_BUILD_PREFIX:=$(STAGING_DIR_HOST)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/host-build.mk

define Package/$(PKG_NAME)
	TITLE:=shared-state C++ async re-implementation
	CATEGORY:=LibreMesh
	# TODO: Statically linking libstdcpp instead of depending on it and then
	# stripping unused symbols might reduce space usage, until this is the
	# only package to use it
	DEPENDS:=+libstdcpp
endef

define Package/$(PKG_NAME)/description
	shared-state re-written in C++20 and corotuines to handle information exchange between network nodes more efficiently.
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


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/shared-state-async $(1)/usr/bin/
	$(CP) ./files/* $(1)/

	# TODO: Remove this line once discovery is reimplemented in C++
	$(CP) ../shared-state/files/usr/bin/shared-state-get_candidates_neigh $(1)/usr/bin/shared-state-async-discover
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

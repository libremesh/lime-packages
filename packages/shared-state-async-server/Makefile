# Shared State
#
# Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
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

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=shared-state-async-server
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
#PKG_SOURCE_VERSION:=dc438f9ee005f9ad75d509bdb4dc2f22af99a579


PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/javierajorge/epollcoroutinedoctest.git
PKG_MAINTAINER:=Javier Jorge <javierbrk@gmail.com>
PKG_LICENSE:=AGPL-3.0

#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
#PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
HOST_BUILD_PREFIX:=$(STAGING_DIR_HOST)

# Source settings (i.e. where to find the source codes)
# This is a custom variable, used below 
# disable git package source and enable Build/Prepare line xx
#SOURCE_DIR:=/home/jjorge/Desktop/epollcoroutinedoctest


include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/host-build.mk

# Package definition; instructs on how and where our package will appear in the overall configuration menu ('make menuconfig')
define Package/$(PKG_NAME)
	TITLE:=Very small server written in c++ (20)
	CATEGORY:=LibreMesh
	SECTION:=experimental
	DEPENDS:=+libstdcpp
endef

define Package/$(PKG_NAME)/description
	Very small server written in c++ (20) implementing corotuines to handle incomming requests and request requirements.
endef

# Otherwise OpenWrt's CPPFLAGS are ignored
TARGET_CFLAGS += $(TARGET_CPPFLAGS)

CMAKE_OPTIONS += \
	-DCMAKE_VERBOSE_MAKEFILE=TRUE \
	-DENABLE_SHARED=YES \
	-DENABLE_STATIC=NO \
	-DENABLE_TESTS=NO

# Package preparation instructions; create the build directory and copy the source code. 
# The last command is necessary to ensure our preparation instructions remain compatible with the patching system.
# only used in conjuntion with SOURCE_DIR line 43
#define Build/Prepare
#	mkdir -p $(PKG_BUILD_DIR)
#	cp $(SOURCE_DIR)/* $(PKG_BUILD_DIR) -R
#	$(Build/Patch)
#endef

define Package/sharedstate/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/main $(1)/usr/bin/sharedstate
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

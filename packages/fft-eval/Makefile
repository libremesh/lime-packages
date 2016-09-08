#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fft-eval
PKG_VERSION:=2013-06-26
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://github.com/libremesh/FFT_eval.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=236940c6b92f89a4cc8f77412b18a521ab9d9f8b
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Evaluates FFT samples from ath9k driver
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +libc
endef

TARGET_CFLAGS  += -ffunction-sections -fdata-sections -flto 

define Build/Compile
	$(TARGET_CC) $(PKG_BUILD_DIR)/fft_eval.c -o $(PKG_BUILD_DIR)/fft_eval -lm
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fft_eval $(1)/usr/bin/fft_eval
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

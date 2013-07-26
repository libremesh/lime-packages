#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=FFT_eval
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_REV:=236940c6b92f89a4cc8f77412b18a521ab9d9f8b

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git://github.com/libre-mesh/FFT_eval.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_PROTO:=git

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/fft-eval
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Evaluates FFT samples from ath9k driver
  DEPENDS:= +libc
endef

#define Build/Prepare
#	mkdir -p $(PKG_BUILD_DIR)
#	$(CP) ./src/* $(PKG_BUILD_DIR)/
#endef

TARGET_CFLAGS  += -ffunction-sections -fdata-sections -flto 

define Build/Compile
	$(TARGET_CC) $(PKG_BUILD_DIR)/fft_eval.c -o $(PKG_BUILD_DIR)/fft_eval -lm
endef

define Package/fft-eval/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fft_eval $(1)/usr/bin/fft_eval
endef

$(eval $(call BuildPackage,fft-eval))

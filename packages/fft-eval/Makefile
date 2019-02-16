#
## Copyright (C) 2006-2013 OpenWrt.org
#
## This is free software, licensed under the GNU General Public License v2.
#
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fft-eval
PKG_VERSION:=2017-06-28
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://github.com/simonwunderlich/FFT_eval.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=3cc175570379da172b0b2bcdbb8d2a42f83dad88
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	MAINTAINER:=Nicolas Pace <nicopace@altermundi.net>
	URL:=https://github.com/simonwunderlich/FFT_eval
	TITLE:=Evaluates FFT samples from ath9k driver
	DEPENDS:= +libc
endef

define Package/$(PKG_NAME)/description
	Evaluates FFT samples from diferent wifi boards drivers
endef

TARGET_CFLAGS  += -ffunction-sections -fdata-sections -flto

define Build/Compile
	$(TARGET_CC) -D__NOSDL__ $(PKG_BUILD_DIR)/fft_eval.c -o $(PKG_BUILD_DIR)/fft_eval -lm
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fft_eval $(1)/usr/bin/fft_eval
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
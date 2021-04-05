# Provide ping6 compatibility between Openwrt master and future releases based
# on it with OpenWrt 19.07.X and 18.06.X
# Other attempts using LINUX_X_Y variable proven to not work reliably and where
# even uglier.
# Include this file in your makefile and the use the PING6_PACKAGE
# and PING6_SYMLINK as you need.
# See shared-state and lime-debug for usage examples.

PING6_PACKAGE=iputils-ping
PING6_SYMLINK=PING_LEGACY_SYMLINKS
ifeq ($(wildcard $(TOPDIR)/feeds/packages/net/iputils/.),)
PING6_PACKAGE=iputils-ping6
PING6_SYMLINK=PACKAGE_iputils-ping6
endif

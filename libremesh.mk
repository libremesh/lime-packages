include $(TOPDIR)/rules.mk

PKG_NAME?=$(notdir ${CURDIR})

# from https://github.com/openwrt/luci/blob/master/luci.mk
# default package version follow this scheme:
# [year].[day_of_year].[seconds_of_day]~[commit_short_hash] eg. 24.322.80622~a403707
PKG_VERSION?=$(if $(DUMP),x,$(strip $(shell \
    if git log -1 >/dev/null 2>/dev/null; then \
      set -- $$(git log -1 --format="%ct %h" --abbrev=7); \
        secs="$$(($$1 % 86400))"; \
        yday="$$(date --utc --date="@$$1" "+%y.%j")"; \
        printf '%s.%05d~%s' "$$yday" "$$secs" "$$2"; \
    else \
      echo "0"; \
    fi; \
)))

PKG_BUILD_DIR?=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Build/Compile
	@rm -rf ./build || true
	@mkdir ./build
	$(CP) ./files ./build
	$(FIND) ./build -name '*.sh' -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -name '*.lua' -exec sed -i '/^\s*--!.*/d' {} +
	$(FIND) ./build -type f -executable -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -type f -executable -exec sed -i '/^\s*--!.*/d' {} +
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./build/files/* $(1)/
endef

define Build/Configure
endef


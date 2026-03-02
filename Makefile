ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Blued
THEOS_PACKAGE_SCHEME=rootless


ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
THEOS_PACKAGE_DIR = rootless
else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
THEOS_PACKAGE_DIR = roothide
else
THEOS_PACKAGE_DIR = rootful
endif

THEOS_DEVICE_IP = 192.168.1.110
THEOS_DEVICE_PORT = 22


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BluedHook

BluedHook_FILES = Tweak.xm
BluedHook_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos $(THEOS_PACKAGE_DIR)

after-package::
	@echo -e "\033[32m==>\033[0m Packaging complete."
	@if [ "$(INSTALL)" = "1" ]; then \
        DEB_FILE=$$(ls -t $(THEOS_PACKAGE_DIR)/*.deb | head -1); \
        PACKAGE_NAME=$$(basename "$$DEB_FILE" | cut -d'_' -f1); \
        echo -e "\033[34m==>\033[0m Installing $$PACKAGE_NAME to device…"; \
        ssh root@$(THEOS_DEVICE_IP) "rm -rf /tmp/$${PACKAGE_NAME}.deb"; \
        scp "$$DEB_FILE" root@$(THEOS_DEVICE_IP):/tmp/$${PACKAGE_NAME}.deb; \
        ssh root@$(THEOS_DEVICE_IP) "dpkg -i --force-overwrite /tmp/$${PACKAGE_NAME}.deb && rm -f /tmp/$${PACKAGE_NAME}.deb"; \
	else \
        echo -e "\033[33m==>\033[0m Skipping installation (INSTALL!=1)"; \
	fi
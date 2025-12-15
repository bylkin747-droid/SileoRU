ARCHS = arm64
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = Sileo
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SileoRU
SileoRU_FILES = Tweak.xm TranslateManager.m NetworkUtil.m
SileoRU_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 Sileo || true"

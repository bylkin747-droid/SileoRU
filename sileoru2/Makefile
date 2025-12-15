ARCHS = arm64
# Use latest available SDK on runner, keep deployment target 15.0
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SileoRU2
SileoRU2_FILES = Tweak.xm
SileoRU2_FRAMEWORKS = UIKit
SileoRU2_BUNDLE_PATH = /Library/MobileSubstrate/DynamicLibraries
SileoRU2_RESOURCE_DIRS = .
include $(THEOS_MAKE_PATH)/tweak.mk

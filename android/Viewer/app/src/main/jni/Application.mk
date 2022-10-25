LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

APP_ABI := armeabi-v7a
APP_STL := gnustl_static
NDK_TOOLCHAIN_VERSION := 4.9
APP_CPPFLAGS += -std=c++11
APP_CPPFLAGS += -fexceptions
APP_CPPFLAGS += -frtti
#NDK_TOOLCHAIN_VERSION := clang3.4-obfuscator


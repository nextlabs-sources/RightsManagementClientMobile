LOCAL_PATH := $(call my-dir)
LOCAL_SRC_PATH := $(LOCAL_PATH)/../../../../../../common/nxl

#
# Build nxlFormatNxl
#

include $(CLEAR_VARS)

# ---- core cpp files are putted at common
LOCAL_CPP_FEATURES  += exceptions
VIEWER_NXL_COMMON   := $(LOCAL_PATH)/../../../../../../common/
LOCAL_C_INCLUDES    += $(LOCAL_PATH)/include \
                       $(VIEWER_NXL_COMMON) \
                       $(VIEWER_NXL_COMMON)/boost_1_61_0 \
                       $(VIEWER_NXL_COMMON)/crypto/ \
                       $(VIEWER_NXL_COMMON)/crypto/aes \
                       $(VIEWER_NXL_COMMON)/crypto/cryptlite \
                       $(VIEWER_NXL_COMMON)/nxl/ \
                       $(VIEWER_NXL_COMMON)/nxl/include
LOCAL_MODULE        := nxl-format
LOCAL_SRC_FILES     := nxl_fileFormat_Utils.cpp \
                       nxl_bridge_NxlUtils.cpp \
                       $(VIEWER_NXL_COMMON)/crypto/aes/rijndael-alg-fst.c \
                       $(VIEWER_NXL_COMMON)/nxl/src/utils.cpp \
                       $(VIEWER_NXL_COMMON)/nxl/src/nxlobj.cpp


LOCAL_LDLIBS        := -llog

$(info |====================================================================)
$(info oye test for build nxlFormatNxl)
$(info Dump defined settings:)
$(info TARGET_ARCH:         $(TARGET_ARCH))
$(info TARGET_PLATFORM:     $(TARGET_PLATFORM))
$(info TARGET_ARCH_ABI:     $(TARGET_ARCH_ABI))
$(info TARGET_AB:           $(TARGET_AB))
$(info LOCAL_CPP_FEATURES   $(LOCAL_CPP_FEATURES))
$(info LOCAL_PATH:          $(LOCAL_PATH))
$(info VIEWER_NXL_COMMON:   $(VIEWER_NXL_COMMON))
$(info LOCAL_C_INCLUDES:    $(LOCAL_C_INCLUDES))
$(info LOCAL_MODULE:        $(LOCAL_MODULE))
$(info LOCAL_SRC_FILES:     $(LOCAL_SRC_FILES))
$(info LOCAL_LDLIBS:        $(LOCAL_LDLIBS))
$(info ====================================================================|)


include $(BUILD_SHARED_LIBRARY)

#
# end oye test
#

include $(CLEAR_VARS)

LOCAL_SRC_PATH := $(LOCAL_PATH)/../../../../../../common/policyengine

common_SRC_FILES := $(LOCAL_SRC_PATH)/xmlparser/SAX.c $(LOCAL_SRC_PATH)/xmlparser/entities.c $(LOCAL_SRC_PATH)/xmlparser/encoding.c $(LOCAL_SRC_PATH)/xmlparser/error.c \
        $(LOCAL_SRC_PATH)/xmlparser/parserInternals.c $(LOCAL_SRC_PATH)/xmlparser/parser.c $(LOCAL_SRC_PATH)/xmlparser/tree.c $(LOCAL_SRC_PATH)/xmlparser/hash.c $(LOCAL_SRC_PATH)/xmlparser/list.c $(LOCAL_SRC_PATH)/xmlparser/xmlIO.c \
        $(LOCAL_SRC_PATH)/xmlparser/xmlmemory.c $(LOCAL_SRC_PATH)/xmlparser/uri.c $(LOCAL_SRC_PATH)/xmlparser/valid.c $(LOCAL_SRC_PATH)/xmlparser/xlink.c $(LOCAL_SRC_PATH)/xmlparser/HTMLparser.c $(LOCAL_SRC_PATH)/xmlparser/HTMLtree.c \
        $(LOCAL_SRC_PATH)/xmlparser/debugXML.c $(LOCAL_SRC_PATH)/xmlparser/xpath.c $(LOCAL_SRC_PATH)/xmlparser/xpointer.c $(LOCAL_SRC_PATH)/xmlparser/xinclude.c \
        $(LOCAL_SRC_PATH)/xmlparser/DOCBparser.c $(LOCAL_SRC_PATH)/xmlparser/catalog.c $(LOCAL_SRC_PATH)/xmlparser/globals.c $(LOCAL_SRC_PATH)/xmlparser/threads.c $(LOCAL_SRC_PATH)/xmlparser/c14n.c $(LOCAL_SRC_PATH)/xmlparser/xmlstring.c \
        $(LOCAL_SRC_PATH)/xmlparser/buf.c $(LOCAL_SRC_PATH)/xmlparser/xmlregexp.c $(LOCAL_SRC_PATH)/xmlparser/xmlschemas.c $(LOCAL_SRC_PATH)/xmlparser/xmlschemastypes.c $(LOCAL_SRC_PATH)/xmlparser/xmlunicode.c \
        $(LOCAL_SRC_PATH)/xmlparser/xmlreader.c $(LOCAL_SRC_PATH)/xmlparser/relaxng.c $(LOCAL_SRC_PATH)/xmlparser/dict.c $(LOCAL_SRC_PATH)/xmlparser/SAX2.c \
        $(LOCAL_SRC_PATH)/xmlparser/xmlwriter.c $(LOCAL_SRC_PATH)/xmlparser/legacy.c $(LOCAL_SRC_PATH)/xmlparser/chvalid.c $(LOCAL_SRC_PATH)/xmlparser/pattern.c $(LOCAL_SRC_PATH)/xmlparser/xmlsave.c $(LOCAL_SRC_PATH)/xmlparser/xmlmodule.c \
        $(LOCAL_SRC_PATH)/xmlparser/schematron.c

common_C_INCLUDES += $(LOCAL_SRC_PATH)/xmlparser//include

common_CFLAGS += -DLIBXML_THREAD_ENABLED=1

common_CFLAGS += \
     -Wno-missing-field-initializers \
     -Wno-self-assign \
     -Wno-sign-compare \
     -Wno-tautological-pointer-compare \

LOCAL_MODULE    := PolicyEngine

LOCAL_SRC_FILES := $(common_SRC_FILES) \
                NXPolicyEngineMain.cpp \
			    $(LOCAL_SRC_PATH)/NXPolicyEngine.cpp

LOCAL_C_INCLUDES := $(common_C_INCLUDES)

LOCAL_CFLAGS += $(common_CFLAGS)
LOCAL_CLANG := true

LOCAL_LDLIBS := \
	-llog \
	-lm \
	-lz \

include $(BUILD_SHARED_LIBRARY)
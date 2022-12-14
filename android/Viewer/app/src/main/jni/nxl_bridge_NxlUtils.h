/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class nxl_bridge_NxlUtils */

#ifndef _Included_nxl_bridge_NxlUtils
#define _Included_nxl_bridge_NxlUtils
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    isMatchNxlFmt
 * Signature: (Ljava/lang/String;Z)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_isMatchNxlFmt
  (JNIEnv *, jclass, jstring, jboolean);

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    convertToNxlFile
 * Signature: (Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;[BZ)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_convertToNxlFile
  (JNIEnv *, jclass, jstring, jstring, jstring, jbyteArray, jboolean);

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    decryptToNormalFile
 * Signature: (Ljava/lang/String;Ljava/lang/String;[BZ)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_decryptToNormalFile
  (JNIEnv *, jclass, jstring, jstring, jbyteArray, jboolean);

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    extractInfoFromNxlFile
 * Signature: (Ljava/lang/String;[B[B)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_extractInfoFromNxlFile
  (JNIEnv *, jclass, jstring, jbyteArray, jbyteArray);

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    extractFingerPrint
 * Signature: (Ljava/lang/String;[BI)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_extractFingerPrint
  (JNIEnv *, jclass, jstring, jbyteArray, jint);

#ifdef __cplusplus
}
#endif
#endif

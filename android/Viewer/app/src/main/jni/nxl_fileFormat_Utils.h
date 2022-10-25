/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class nxl_fileFormat_Utils */

#ifndef _Included_nxl_fileFormat_Utils
#define _Included_nxl_fileFormat_Utils
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     nxl_fileFormat_Utils
 * Method:    isMatchNxlFmt
 * Signature: (Ljava/lang/String;)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_isMatchNxlFmt
  (JNIEnv *, jclass, jstring);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    isMatchNxlHeader
 * Signature: (Ljava/lang/String;)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_isMatchNxlHeader
  (JNIEnv *, jclass, jstring);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    convertToNxlFile
 * Signature: (Ljava/lang/String;Ljava/lang/String;[BZ)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_convertToNxlFile
  (JNIEnv *, jclass, jstring, jstring, jbyteArray, jboolean);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    decryptToNormalFile
 * Signature: (Ljava/lang/String;Ljava/lang/String;[BZ)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_decryptToNormalFile
  (JNIEnv *, jclass, jstring, jstring, jbyteArray, jboolean);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    getTags
 * Signature: (Ljava/lang/String;Z[B[B)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_getTags
  (JNIEnv *, jclass, jstring, jboolean, jbyteArray, jbyteArray);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    setTags
 * Signature: (Ljava/lang/String;[B[B)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_setTags
  (JNIEnv *, jclass, jstring, jbyteArray, jbyteArray);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    getKeyId
 * Signature: (Ljava/lang/String;[B)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_getKeyId
  (JNIEnv *, jclass, jstring, jbyteArray);

/*
 * Class:     nxl_fileFormat_Utils
 * Method:    gettype
 * Signature: (Ljava/lang/String;)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_nxl_fileFormat_Utils_getType
  (JNIEnv *, jclass, jstring);

#ifdef __cplusplus
}
#endif
#endif

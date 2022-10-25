#include "nxl_fileFormat_Utils.h"
#include <stdio.h>
#include <android/log.h>
#include <utils.h>
#include "nxlexception.hpp"
#ifndef LOG_TAG
#define LOG_TAG "NX_NxlFmtUtil"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#endif
#ifdef __cplusplus
extern "C" {
#endif


JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_isMatchNxlFmt
        (JNIEnv* env, jclass obj , jstring pathObj)
{
	bool rt = false;
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathObj)
		return (jboolean)false;
    // prepare params
	const char* path = env->GetStringUTFChars(pathObj,NULL);
    if( NULL == path)
        return (jboolean)false;
	// do task
	try	{
		rt = nxl::util::check(path);
	}catch(nxl::exception& ex){
		LOGE("Exception: %s",ex.details().c_str());
		rt = false;
	}catch(std::exception& ex){
		LOGE("Exception: %s",ex.what());
		rt = false;
	}
	// clean up
	env->ReleaseStringUTFChars(pathObj,path);

    return (jboolean)rt;
}



JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_isMatchNxlHeader
        (JNIEnv* env, jclass obj, jstring pathObj)
{
	bool rt = false;
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathObj)
		return (jboolean)false;
    // prepare params
	const char* path = env->GetStringUTFChars(pathObj, NULL);
    if( NULL == path)
        return (jboolean)false;
	// do task
	try {
		rt = nxl::util::simplecheck(path);
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}
	// clean up
	env->ReleaseStringUTFChars(pathObj, path);

    return (jboolean)rt;
}


JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_convertToNxlFile
(JNIEnv* env, jclass obj, jstring srcobj, jstring targetobj, jbyteArray keyobj, jboolean overwrite)
{
	bool rt = false;
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == srcobj)
		return (jboolean)false;
	if (NULL == targetobj)
		return (jboolean)false;
    if (NULL == keyobj)
        return (jboolean)false;

    // prepare params
	const char* src = env->GetStringUTFChars(srcobj, NULL);
    if(NULL == src)
        return (jboolean)false;
	const char* dst = env->GetStringUTFChars(targetobj, NULL);
    if(NULL == dst)
        return (jboolean)false;
	jbyte* pKey = env->GetByteArrayElements(keyobj, NULL);
	if (NULL == pKey)
        return (jboolean)false;

	// do task
	try	{
	    // osm:wait for verion2
		//nxl::util::convert(src, dst, (NXL_KEKEY_BLOB*)pKey, NULL, overwrite);
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}
	// clean up
	env->ReleaseStringUTFChars(srcobj, src);
	env->ReleaseStringUTFChars(targetobj, dst);
    env->ReleaseByteArrayElements(keyobj, pKey, 0);

	return (jboolean)rt;
}


JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_decryptToNormalFile
(JNIEnv* env, jclass obj, jstring srcobj, jstring targetobj, jbyteArray keyobj, jboolean overwrite)
{
	bool rt = false;

	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == srcobj)
		return (jboolean)false;
	if (NULL == targetobj)
		return (jboolean)false;
    if (NULL == keyobj)
        return (jboolean)false;
    // prepare params
	const char* src = env->GetStringUTFChars(srcobj, NULL);
    if(NULL == src)
        return (jboolean)false;
	const char* dst = env->GetStringUTFChars(targetobj, NULL);
    if(NULL == dst)
        return (jboolean)false;
	jbyte* pKey = env->GetByteArrayElements(keyobj, NULL);
	if (NULL == pKey)
        return (jboolean)false;

	// do task
	try	{
	    // osm:wait for verion2
		//nxl::util::decrypt(src, dst, (NXL_KEKEY_BLOB*)pKey, overwrite);
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}

	// clean up
	env->ReleaseStringUTFChars(srcobj, src);
	env->ReleaseStringUTFChars(targetobj, dst);
    env->ReleaseByteArrayElements(keyobj, pKey, 0);

	return (jboolean)rt;
}


JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_getTags
(JNIEnv* env, jclass obj, jstring pathobj, jboolean safeway, jbyteArray keyobj, jbyteArray bufobj)
{
	bool rt = false;
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathobj)
		return (jboolean)false;
	if (NULL == bufobj)
		return (jboolean)false;

    if (safeway) {  // for safeway keyobj must be provided
        if( NULL == keyobj)
            return (jboolean)false;
    }

	const char* src = env->GetStringUTFChars(pathobj, NULL);
    if (NULL == src)
        return (jboolean)false;
	jbyte* pKey = NULL;
	if (safeway){
        pKey = env->GetByteArrayElements(keyobj, NULL);
        if( NULL == pKey)
            return (jboolean)false;
	}
	jbyte* pbuf = env->GetByteArrayElements(bufobj, NULL);
    if ( NULL == pbuf)
        return (jboolean)false;
	// do task
	try	{
	    // osm:wait for verion2
		//nxl::util::gettags(src, safeway, (NXL_KEKEY_BLOB*)pKey, (char*)pbuf, env->GetArrayLength(bufobj));
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}

	// clean up
	env->ReleaseStringUTFChars(pathobj, src);
	if (safeway){
		env->ReleaseByteArrayElements(keyobj, pKey, 0);
	}
	env->ReleaseByteArrayElements(bufobj, pbuf, 0);
	return (jboolean)rt;
}



JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_setTags
(JNIEnv* env, jclass obj, jstring pathobj, jbyteArray keyobj, jbyteArray bufobj)
{
	bool rt = false;
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathobj)
		return (jboolean)false;
    if (NULL == keyobj)
        return (jboolean)false;
    if (NULL == bufobj)
		return (jboolean)false;
    // prepare params
	const char* src = env->GetStringUTFChars(pathobj, NULL);
    if(NULL == src)
        return (jboolean)false;
	jbyte* pKey = pKey= env->GetByteArrayElements(keyobj, NULL);
	if (NULL == pKey)
        return (jboolean)false;
	jbyte* pbuf = env->GetByteArrayElements(bufobj, NULL);
    if(NULL == pbuf)
        return (jboolean)false;
	// do task
	try	{
	    // osm:wait for verion2
		//nxl::util::settags(src, (NXL_KEKEY_BLOB*)pKey, (char*)pbuf, env->GetArrayLength(bufobj));
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}
	// clean up
	env->ReleaseStringUTFChars(pathobj, src);
    env->ReleaseByteArrayElements(keyobj, pKey, 0);
	env->ReleaseByteArrayElements(bufobj, pbuf, 0);

	return (jboolean)rt;
}

JNIEXPORT jboolean JNICALL Java_nxl_fileFormat_Utils_getKeyId
		(JNIEnv* env, jclass obj, jstring pathobj, jbyteArray keyidobj)
{
	bool rt = false;
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathobj)
		return (jboolean)false;
	if (NULL == keyidobj)
		return (jboolean)false;
    // prepare params
	const char* nxlpath = env->GetStringUTFChars(pathobj, NULL);
    if(NULL ==nxlpath)
        return (jboolean)false;
	jbyte* idbuf = env->GetByteArrayElements(keyidobj, NULL);
    if(NULL == idbuf)
        return (jboolean)false;
    // do task
	try{
	    // osm:wait for verion2
		//nxl::util::getkeyid(nxlpath, (NEXTLABS_KEY_ID*)idbuf);
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}
	// clean up
	env->ReleaseStringUTFChars(pathobj, nxlpath);
	env->ReleaseByteArrayElements(keyidobj, idbuf, 0);

	return (jboolean)rt;
}

JNIEXPORT jstring JNICALL Java_nxl_fileFormat_Utils_getType
		(JNIEnv * env, jclass obj, jstring pathobj)
{
	if (NULL == pathobj)
		return env->NewStringUTF("");

	const char* nxlpath = env->GetStringUTFChars(pathobj, NULL);
	if(NULL == nxlpath)
		return env->NewStringUTF("");

	try{
	    // osm:wait for verion2
		//std::u16string FileType = nxl::util::getfiletype(nxlpath);
		std::u16string FileType = u"nxl";
		env->ReleaseStringUTFChars(pathobj, nxlpath);
		return env->NewString((const jchar*)FileType.c_str(), FileType.size());
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
	}

	env->ReleaseStringUTFChars(pathobj, nxlpath);
	return env->NewStringUTF("");
}

#ifdef __cplusplus
}
#endif
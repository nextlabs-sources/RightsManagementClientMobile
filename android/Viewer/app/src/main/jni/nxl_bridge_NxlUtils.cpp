#include "nxl_bridge_NxlUtils.h"
#include <stdio.h>
#include <string.h>
#include <android/log.h>
#include <utils.h>
#include "nxlexception.hpp"
#ifndef LOG_TAG
#define LOG_TAG "NXL_BRIDGE_NXLUTILS"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#endif
#ifdef __cplusplus
extern "C" {
#endif


/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    isMatchNxlFmt
 * Signature: (Ljava/lang/String;Z)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_isMatchNxlFmt
  (JNIEnv *env, jclass obj, jstring pathObj, jboolean isFastObj)
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
		
		if(JNI_TRUE == isFastObj){
			rt = nxl::util::simplecheck(path);
			}
		else{
			rt = nxl::util::check(path);
			}
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


/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    convertToNxlFile
 * Signature: (Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;[BZ)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_convertToNxlFile
  (JNIEnv *env, jclass obj, jstring ownerIdOjb, jstring srcOjb, jstring dstObj, jbyteArray keyObj, jboolean overwrite)
{
	bool rt =false;

	//sanity check
	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == ownerIdOjb)
		return (jboolean)false;
	if (NULL == srcOjb)
		return (jboolean)false;
	if (NULL == dstObj)
		return (jboolean)false;
    if (NULL == keyObj)
        return (jboolean)false;

	//prepare params
	const char* ownerId = env->GetStringUTFChars(ownerIdOjb,NULL);
	if(NULL == ownerId)
        return (jboolean)false;
	const char* src = env->GetStringUTFChars(srcOjb, NULL);
    if(NULL == src)
        return (jboolean)false;
	const char* dst = env->GetStringUTFChars(dstObj, NULL);
    if(NULL == dst)
        return (jboolean)false;
	jbyte* pKey = env->GetByteArrayElements(keyObj, NULL);
	if (NULL == pKey)
        return (jboolean)false;
	// do task
	try	{
		nxl::util::convert(ownerId,src, dst, (NXL_CRYPTO_TOKEN*)pKey, NULL, overwrite);
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}
	// clear up
	env->ReleaseStringUTFChars(ownerIdOjb, ownerId); 
	env->ReleaseStringUTFChars(srcOjb, src);
	env->ReleaseStringUTFChars(dstObj, dst);
    env->ReleaseByteArrayElements(keyObj, pKey, 0);
	
	return (jboolean) rt;
}

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    decryptToNormalFile
 * Signature: (Ljava/lang/String;Ljava/lang/String;[BZ)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_decryptToNormalFile
  (JNIEnv *env, jclass obj, jstring srcOjb, jstring dstObj, jbyteArray keyObj, jboolean overwrite)
{
	bool rt = false;

	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == srcOjb)
		return (jboolean)false;
	if (NULL == dstObj)
		return (jboolean)false;
    if (NULL == keyObj)
        return (jboolean)false;
    // prepare params
	const char* src = env->GetStringUTFChars(srcOjb, NULL);
    if(NULL == src)
        return (jboolean)false;
	const char* dst = env->GetStringUTFChars(dstObj, NULL);
    if(NULL == dst)
        return (jboolean)false;
	jbyte* pKey = env->GetByteArrayElements(keyObj, NULL);
	if (NULL == pKey)
        return (jboolean)false;
	// do task
	try	{
	    // osm:wait for verion2
		nxl::util::decrypt(src, dst, (NXL_CRYPTO_TOKEN*)pKey, overwrite);
		rt = true;
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}

	// clean up
	env->ReleaseStringUTFChars(srcOjb, src);
	env->ReleaseStringUTFChars(dstObj, dst);
    env->ReleaseByteArrayElements(keyObj, pKey, 0);

	return (jboolean)rt;
	
}

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    extractInfoFromNxlFile
 * Signature: (Ljava/lang/String;[B[B)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_extractInfoFromNxlFile
  (JNIEnv *env, jclass obj, jstring pathObj, jbyteArray ownerIdObj, jbyteArray DUIDObj)
{
	bool rt = false;

	// sanity check
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathObj)
		return (jboolean)false;
	if (NULL == ownerIdObj)
		return (jboolean)false;
    if (NULL == DUIDObj)
        return (jboolean)false;
	
	// prepare params
	const char* path = env->GetStringUTFChars(pathObj, NULL);
    if(NULL == path)
        return (jboolean)false;

	jbyte* pOwnerId = env -> GetByteArrayElements(ownerIdObj,NULL);
	if(NULL == pOwnerId)
		return (jboolean)false;

	jbyte* pDUID = env -> GetByteArrayElements(DUIDObj,NULL);
	if(NULL == pDUID)
		return (jboolean)false;
	

	// do task
	try	{
		// for DUID
	   NXL_CRYPTO_TOKEN token ={0};
	   nxl::util::read_token_info_from_nxl(path,&token);
	   memcpy(pDUID,token.UDID,32);
		
	   // for owner id
	   int len_buf=256;
	   char buf[256] ={0};
	   nxl::util::read_ownerid_from_nxl(path,buf,&len_buf);
	   memcpy(pOwnerId,buf,len_buf);
	   
	   rt =true;
		
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}

	// clean up
	env->ReleaseStringUTFChars(pathObj, path);
	env->ReleaseByteArrayElements(ownerIdObj,pOwnerId,0);
	env->ReleaseByteArrayElements(DUIDObj,pDUID,0);
	
	
	return (jboolean)rt;
	
}

/*
 * Class:     nxl_bridge_NxlUtils
 * Method:    extractFingerPrint
 * Signature: (Ljava/lang/String;[BI)Z
 */
JNIEXPORT jboolean JNICALL Java_nxl_bridge_NxlUtils_extractFingerPrint
  (JNIEnv *env, jclass obj, jstring pathObj, jbyteArray fingerprintObj, jint version)
{
	bool rt = false;
	// sanity check	
	if (NULL == env)
		return (jboolean)false;
	if (NULL == pathObj)
		return (jboolean)false;
	if (NULL == fingerprintObj)
		return (jboolean)false;
    // prepare params
	const char* path = env->GetStringUTFChars(pathObj, NULL);
    if(NULL == path)
        return (jboolean)false;

	jbyte* pfingerprint = env -> GetByteArrayElements(fingerprintObj,NULL);
	if(NULL == pfingerprint)
		return (jboolean)false;
	
	// do task
	try	{
		if(version ==1){
		/*
for version 1; total bytes is 804
    rootAgreementKey    [256]
    icaAgreementKey     [256]
    ownerid             [256];
    duid                [32]
    ml                  4;
 */
 
	   NXL_CRYPTO_TOKEN token ={0};
	   nxl::util::read_token_info_from_nxl(path,&token);
	   // rootAgreementKey
	   memcpy(pfingerprint,token.PublicKey,256);
	   // rootICAAgreementKey
	   memcpy(pfingerprint+256,token.PublicKeyWithiCA,256);
	   // ownerid
	   int len_buf=256;
	   nxl::util::read_ownerid_from_nxl(path,(char*)(pfingerprint+(256+256)),&len_buf);
	   // duid
	   memcpy(pfingerprint+(256+256+256),token.UDID,32);
	   // ml
	   memcpy(pfingerprint+(256+256+256+32),&token.ml,4);  
	   rt =true;
		}
		else{
			rt =false;
		}				
	}catch (nxl::exception& ex){
		LOGE("Exception: %s", ex.details().c_str());
		rt = false;
	}catch (std::exception& ex){
		LOGE("Exception: %s", ex.what());
		rt = false;
	}
	
	// clean up
	env->ReleaseStringUTFChars(pathObj, path);
	env->ReleaseByteArrayElements(fingerprintObj,pfingerprint,0);
	
	return (jboolean)rt;
	
}

#ifdef __cplusplus
}
#endif
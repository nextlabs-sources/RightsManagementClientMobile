#include "PolicyEngineWrapper_NXPolicyEngineWrapper.h"
#include "../../../../../../common/policyengine/NXPolicyEngine.h"

#include <map>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif
JNIEXPORT jint JNICALL Java_PolicyEngineWrapper_NXPolicyEngineWrapper_GetRightsViaJni
        (JNIEnv * env, jclass, jstring username, jstring sid, jobject tags, jbyteArray xmlcontent, jobject vecOb, jobject vecHitPolicy)
  {
    const char* pusername = env->GetStringUTFChars(username, 0);
    std::string strusername = pusername;
    env->ReleaseStringUTFChars(username, pusername);

    const char* psid = env->GetStringUTFChars(sid, 0);
    std::string strsid = psid;
    env->ReleaseStringUTFChars(sid, psid);

    jclass jhashmapclass = env->GetObjectClass(tags);
    jmethodID jkeysetmethod = env->GetMethodID(jhashmapclass, "keySet", "()Ljava/util/Set;");
    jmethodID jgetmethod = env->GetMethodID(jhashmapclass, "get", "(Ljava/lang/Object;)Ljava/lang/Object;");

    jobject jsetkey = env->CallObjectMethod(tags, jkeysetmethod);

    jclass jsetclass = env->FindClass("java/util/Set");
    jmethodID jtoArraymethod = env->GetMethodID(jsetclass, "toArray", "()[Ljava/lang/Object;");

    jobjectArray jobjArray = (jobjectArray)env->CallObjectMethod(jsetkey, jtoArraymethod);

    jclass jvectorclass = env->FindClass("java/util/Vector");
    jmethodID jsizeMethod = env->GetMethodID(jvectorclass, "size", "()I");
    jmethodID jelementAtMethod = env->GetMethodID(jvectorclass, "elementAt", "(I)Ljava/lang/Object;");
    jmethodID jaddelementMethod = env->GetMethodID(jvectorclass, "addElement", "(Ljava/lang/Object;)V");
    jmethodID jvectorinitMethod = env->GetMethodID(jvectorclass, "<init>", "()V");

    jsize arraysize = env->GetArrayLength(jobjArray);

    std::map<std::string, std::vector<std::string>> tagsofcpp;

    for(int i = 0; i < arraysize; i++)
    {
      jstring jkey = (jstring)env->GetObjectArrayElement(jobjArray, i);

      const char* key = env->GetStringUTFChars(jkey, 0);
      std::string tag = key;
      std::transform(tag.begin(), tag.end(),tag.begin(), toupper);
      env->ReleaseStringUTFChars(jkey, key);

      std::vector<std::string> values;

      jobject jvalues = env->CallObjectMethod(tags, jgetmethod, jkey);
      int jSize = env->CallIntMethod(jvalues, jsizeMethod);
      for(int j = 0; j < jSize; j++)
      {
        jstring jvalue = (jstring)env->CallObjectMethod(jvalues, jelementAtMethod, j);

        const char* pvalue = env->GetStringUTFChars(jvalue, 0);

        std::string strvalue = pvalue;
        std::transform(strvalue.begin(), strvalue.end(),strvalue.begin(), toupper);

        values.push_back(strvalue);

        env->ReleaseStringUTFChars(jvalue, pvalue);

        env->DeleteLocalRef(jvalue);
      }

      tagsofcpp[tag] = values;

      env->DeleteLocalRef(jvalues);
      env->DeleteLocalRef(jkey);
    }

    env->DeleteLocalRef(jobjArray);
    env->DeleteLocalRef(jsetclass);
    env->DeleteLocalRef(jsetkey);
    env->DeleteLocalRef(jhashmapclass);

    nxl::NXPolicyEngine PolicyEngine("");

    std::multimap<std::string, std::vector<std::pair<std::string, std::string>>> Obligations;

    jbyte* jcontent = env->GetByteArrayElements(xmlcontent, 0);
    jsize  contentsize = env->GetArrayLength(xmlcontent);

    std::vector<std::pair<std::string, std::string>> hitPolicy;

    jint Rights = PolicyEngine.getRights(strusername, strsid, tagsofcpp, (const char*)jcontent, contentsize, Obligations, hitPolicy);

    jclass jsimpleentryclass = env->FindClass("java/util/AbstractMap$SimpleEntry");
    jmethodID jsimpleentryinitMethod = env->GetMethodID(jsimpleentryclass, "<init>", "(Ljava/lang/Object;Ljava/lang/Object;)V");

    for(std::vector<std::pair<std::string, std::string>>::const_iterator ci = hitPolicy.begin(); ci != hitPolicy.end(); ++ci)
    {
      jstring id = env->NewStringUTF(ci->first.c_str());
      jstring name = env->NewStringUTF(ci->second.c_str());

      jobject hitEachPolicy = env->NewObject(jsimpleentryclass, jsimpleentryinitMethod, id, name);

      env->CallVoidMethod(vecHitPolicy, jaddelementMethod, hitEachPolicy);

      env->DeleteLocalRef(hitEachPolicy);
      env->DeleteLocalRef(name);
      env->DeleteLocalRef(id);
    }

    for(std::multimap<std::string, std::vector<std::pair<std::string, std::string>>>::const_iterator ci = Obligations.begin(); ci != Obligations.end(); ++ci)
    {
      jobject opts = env->NewObject(jvectorclass, jvectorinitMethod);

      for(std::vector<std::pair<std::string, std::string>>::const_iterator vecci = ci->second.begin(); vecci != ci->second.end(); ++vecci)
      {
        jstring optname = env->NewStringUTF(vecci->first.c_str());
        jstring optvalue = env->NewStringUTF(vecci->second.c_str());

        jobject opt = env->NewObject(jsimpleentryclass, jsimpleentryinitMethod, optname, optvalue);

        env->CallVoidMethod(opts, jaddelementMethod, opt);

        env->DeleteLocalRef(opt);
        env->DeleteLocalRef(optvalue);
        env->DeleteLocalRef(optname);
      }

      jstring optsname = env->NewStringUTF(ci->first.c_str());

      jobject ob = env->NewObject(jsimpleentryclass, jsimpleentryinitMethod, optsname, opts);

      env->CallVoidMethod(vecOb, jaddelementMethod, ob);

      env->DeleteLocalRef(ob);
      env->DeleteLocalRef(optsname);
      env->DeleteLocalRef(opts);
    }

    env->DeleteLocalRef(jsimpleentryclass);
    env->DeleteLocalRef(jvectorclass);

    return Rights;
  }

#ifdef __cplusplus
}
#endif

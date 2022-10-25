//
//  NXRMCCommon.cpp
//  nxrmc
//
//  Created by Kevin on 15/4/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#include "NXRMCCommon.h"

#include <sys/time.h>

#include "ldap.h"

#include "nxcommon.hpp"

namespace nxrmc {
    std::string loginWithLDAP(const std::string& server, const std::string& domain, const std::string& uname, const std::string pwd, int vldap, char** errstr)
    {
        LDAP*       ld = nullptr;
        int         err = LDAP_SUCCESS;
        
        err = ldap_initialize(&ld, server.c_str());  // init ldap session
        
        if (err != LDAP_SUCCESS)
        {
            printf("ldap_initialize() failed, server: %s, err: %s\n", server.c_str(), ldap_err2string(err));
            if (errstr) {
                *errstr = ldap_err2string(err);
            }
            return "";
        }
        
        int version = vldap? vldap : LDAP_VERSION3 ;
        err = ldap_set_option(ld, LDAP_OPT_PROTOCOL_VERSION, &version);
        
        if (err != LDAP_SUCCESS) {
            printf("ldap_set_option() failed, %s\n", ldap_err2string(err));
            if (errstr) {
                *errstr = ldap_err2string(err);
            }
            ldap_unbind_ext_s(ld, NULL, NULL);
            return "";
        }
        
        // try to bind
        BerValue         cred;
        cred.bv_val = const_cast<char*>(pwd.c_str());
        cred.bv_len = pwd.length();
        
        printf("try to bind ldap, %s\n", getCurTimeStr().c_str());
        BerValue       * servercredp = nullptr;
        std::string loginname;
        loginname.append(domain);
        loginname.append("\\");
        loginname.append(uname);
        err = ldap_sasl_bind_s(ld, loginname.c_str(), LDAP_SASL_SIMPLE, &cred, NULL, NULL, &servercredp);
        
        printf("bind finished, %s\n", getCurTimeStr().c_str());
        
        if (err != LDAP_SUCCESS) {
            printf("ldap_sasl_bind_s() failed, uname: %s, err: %s\n", loginname.c_str(), ldap_err2string(err));
            if (errstr) {
                *errstr = ldap_err2string(err);
            }
            ldap_unbind_ext_s(ld, NULL, NULL);
            return "";
        }
        
        // bind successfully, then try to search current user.
        const std::string kSAMAccountName = "sAMAccountName=";
        char temp[1024] = {0};
        sprintf(temp, "(%s%s)", kSAMAccountName.c_str(), uname.c_str());
        
        LDAPMessage*    res = nullptr;
        const char* attrs[] = {"objectsid", nullptr};
        err = ldap_search_ext_s(ld, NULL, LDAP_SCOPE_SUBTREE, temp, (char**)attrs, 0, NULL, NULL, NULL, -1, &res);
        
        if (err != LDAP_SUCCESS || res == nullptr) {
            printf("ldap_search_ext_s() failed, filter: %s, err: %s\n", temp, ldap_err2string(err));
            if (errstr) {
                *errstr = ldap_err2string(err);
            }
            ldap_unbind_ext_s(ld, NULL, NULL);
            return "";
        }
        
        std::string sid;
        const std::string kDc = "dc=";
        // got the logged in account info, now try to get sid from attributes.
        // don't need to free entry, since it will be freed when res was freed.
        for (LDAPMessage* entry = ldap_first_entry(ld, res); entry != nullptr; entry = ldap_next_entry(ld, entry))
        {
            char* dn = ldap_get_dn(ld, entry);
            if (dn == nullptr) {
                continue;
            }
            
            // figure out domain
            std::string sDn(dn);
            ldap_memfree(dn);
            std::transform(sDn.begin(), sDn.end(), sDn.begin(), tolower);
            auto index1 = sDn.find(kDc);
            if (index1 == std::string::npos) {
                continue;
            }
            auto index2 = sDn.find(",", index1);
            if (index2 == std::string::npos) {
                continue;
            }
            
            std::string dm = sDn.substr(index1 + kDc.length(), index2 - index1 - kDc.length());
            std::string smalldm = domain;
            std::transform(smalldm.begin(), smalldm.end(), smalldm.begin(), tolower);
            if (dm != smalldm) {  //different domain, maybe entry is under sub-domain
                continue;
            }
            
            // get the entry for current logged in user.
            BerElement* ber = nullptr;
            char* attribute = ldap_first_attribute(ld, entry, &ber);
            if (attribute) {
                berval** attrList = nullptr;
                if ((attrList = ldap_get_values_len(ld, entry, attribute)) && attrList[0]) {
                    auto len = attrList[0]->bv_len;
                    auto v = attrList[0]->bv_val;
                    
                    sid = nxcommon::convertToStringSid(reinterpret_cast<const unsigned char*>(v), static_cast<int>(len));
                    
                    printf("get sid, %s, for user: %s\n", sid.c_str(), loginname.c_str());
                    
                    
                    ldap_value_free_len(attrList);
                    attrList = nullptr;
                }
                
                ldap_memfree(attribute);
                attribute = nullptr;
            }
            if (ber) {
                ber_free(ber, 0);
                ber = nullptr;
            }
        }
        
        ldap_msgfree(res);
        res = nullptr;
        ldap_unbind_ext_s(ld, NULL, NULL);
        
        if (errstr) {
            *errstr = nullptr;
        }
        
        return sid;
    }

    time_t getCurTime()
    {
        time_t timep;

        struct timeval nowTimeval = {0, 0};
        gettimeofday(&nowTimeval, NULL);
        
        timep = nowTimeval.tv_sec;

        
        return timep;
    }
    
    void getCurTime(int& y, int& m, int& d, int& h, int& M, int& s)
    {
        
        time_t timep = getCurTime();
        struct tm* tm = localtime(&timep);
        y = tm->tm_year + 1900;
        m = tm->tm_mon + 1;
        d = tm->tm_mday;
        h = tm->tm_hour;
        M = tm->tm_min;
        s = tm->tm_sec;
        
    }
    
    std::string getCurTimeStr()
    {
        int y, m, d, h, M, s;
        getCurTime(y, m, d, h, M, s);
        
        char buf[500] = {0};
        sprintf(buf, "%d-%d-%d %d:%d:%d", y, m, d, h, M, s);
        
        return buf;
    }
    
    
}  // namespace nxrmc


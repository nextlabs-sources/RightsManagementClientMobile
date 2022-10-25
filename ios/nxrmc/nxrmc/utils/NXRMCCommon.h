//
//  NXRMCCommon.h
//  nxrmc
//
//  Created by Kevin on 15/4/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

/*****************************C/C++******************************************/
#ifndef __nxrmc__NXRMCCommon__
#define __nxrmc__NXRMCCommon__

#include <stdio.h>

#include <string>

namespace nxrmc {
    /** Login with LDAP (Microsoft AD server was supported) account.
     *  User can call this function to login with LDAP account and get the SID.
     *  \code
     *      std::string sid = loginWithLDAP("ldap://qapf1.qalab01.nextlabs.com:3268", "qapf1", "john.tyler", "john.tyler", 0);
     *      if (sid.empty())
     *          return;  // failed
     *      printf("sid: %s\n", sid.c_str());
     *  \endcode
     *  @param server specifies ldap server address
     *  @param domain specifies domain name
     *  @param uname  specifies the user name which will be logged in
     *  @param pwd    password of user
     *  @param vldap  specifies version of ldap protocol, 0 means v3.
     *  @param errstr if fails, err point to an error string, otherwise it point to null. caller doesn't need to free.
     *  @return returns sid of logged in user if log in successfully. otherwise return emptry string.
     */
    std::string loginWithLDAP(const std::string& server, const std::string& domain, const std::string& uname, const std::string pwd, int vldap, char** errstr);
    
    void getCurTime(int& y, int& m, int& d, int& h, int& M, int&s);
    time_t getCurTime();
    std::string getCurTimeStr();
}  // nxrmc

#endif /* defined(__nxrmc__NXRMCCommon__) */




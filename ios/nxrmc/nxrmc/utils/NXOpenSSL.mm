//
//  NXOpenSSL.m
//  nxrmc
//
//  Created by EShi on 6/25/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXOpenSSL.h"
#include <openssl/md5.h>
#include <openssl/sha.h>
#import <openssl/evp.h>
#import <openssl/pem.h>
#import <openssl/dh.h>
#import <string>

#import "GTMBase64.h"

static NSLock *prePrivKeyLock = nullptr;
static BIGNUM *prePrivKey = nullptr;
static NSString *agreementStr = @"";

const  char* P = "D310125B294DBD856814DFD4BAB4DC767DF6A999C9EDFA8F8D7B12551F8D71EF6032357405C7F11EE147DB0332716FC8FD85ED027585268360D16BD761563D7D1659D4D73DAED617F3E4223F48BCEFA421860C3FC4393D27545677B22459E852F5254D3AC58C0D63DD79DE2D8D868CD940DECF5A274605DB0EEE762020C39D0F6486606580EAACCE16FB70FB7C759EA9AABAB4DCBF941891B0CE94EC4D3D5954217C6E84A9274F1AB86073BDF9DC851E563B90455B8397DAE3A1B998607BB7699CEA0805A7FF013EF44FDE7AF830F1FD051FFAEC539CE4452D8229098AE3EE2008AB9DB7B2C948312CBC0137C082D6672618E1BFE5D5006E810DC7AA7F1E6EE3";

const  char* G = "64ACEBA5F7BC803EF29731C9C6AE009B86FC5201F81BC2B8F84890FCF71CAD51C1429FD261A2A715C8946154E0E4E28EF6B2D493CC1739F5659E9F14DD14037F5FE72B3BA4D9BCB3B95B8417BDA48F118E61C8214CF8D558DA6774F08B58D97B2CCE20F5AA2F8E9539C014E7761E4E6336CFFC35127DDD527206766AE72045C11B0FF4DA76172523713B31C9F18ABABA92612BDE105141F04DB5DA3C39CDE5C6877B7F8CD96949FCC876E2C1224FB9188D714FDD6CB80682F8967833AD4B51354A8D58598E6B2DEF4571A597AD39BD3177D54B24CA518EDA996EEDBA8A31D5876EFED8AA44023CC9F13D86DCB4DDFCF389C7A1435082EF69703603638325954E";

namespace
{
    std::string bin2hex(const std::string& input)
    {
        std::string res;
        const char hex[] = "0123456789ABCDEF";
        for(auto sc : input)
        {
            unsigned char c = static_cast<unsigned char>(sc);
            res += hex[c >> 4];
            res += hex[c & 0xf];
        }
        
        return res;
    }
}


@implementation NXOpenSSL

+ (DH*) generateDH
{
    DH* dh = DH_new();
    
    BIGNUM *DH_P = NULL;
    
    BIGNUM *DH_G = NULL;
    
    int success = BN_hex2bn(&DH_P, P);
    
    if (success) {
        dh->p = DH_P;
    }
    
    success = BN_hex2bn(&DH_G, G);
    
    if (success) {
        dh->g = DH_G;
    }
    
    return dh;
}

+(NSDictionary *) generateDHKeyPair
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        prePrivKeyLock = [[NSLock alloc] init];
    });
  
    EVP_PKEY* evp = EVP_PKEY_new();
    EVP_PKEY_set1_DH(evp, [self generateDH]);
 
    EVP_PKEY_CTX* kctx = EVP_PKEY_CTX_new(evp, NULL);
    
    EVP_PKEY_keygen_init(kctx);
    EVP_PKEY* khkey = NULL;
    EVP_PKEY_keygen(kctx, &khkey);
    
    // store private lock to generate agreement pubkey
    [prePrivKeyLock lock];
    if (prePrivKey) {
        BN_free(prePrivKey);
    }
    
    prePrivKey = BN_dup(khkey->pkey.dh->priv_key);
    [prePrivKeyLock unlock];
    
    BIO* pubMem=BIO_new(BIO_s_mem());
    
    PEM_write_bio_PUBKEY(pubMem, khkey);
    

    char *publicKeyPointer = NULL;
    NSUInteger publicKeyLength = (NSUInteger) BIO_get_mem_data(pubMem, &publicKeyPointer);
  
    
    NSData *publicKeyData = [NSData dataWithBytesNoCopy:publicKeyPointer length:publicKeyLength freeWhenDone:NO];
    NSString *publicKey = [[NSString alloc] initWithData:publicKeyData encoding:NSUTF8StringEncoding];
   
    publicKey = [self DHPublicKeyToString:publicKey];
    
    BIO* priMem=BIO_new(BIO_s_mem());
    PEM_write_bio_PrivateKey(priMem, khkey, NULL, NULL, 0, NULL, NULL);
    char *privateKeyPointer = NULL;
    NSUInteger privateKeyLength = (NSUInteger) BIO_get_mem_data(priMem, &privateKeyPointer);
    NSData *privateKeyData = [NSData dataWithBytesNoCopy:privateKeyPointer length:privateKeyLength freeWhenDone:NO];
    NSString *privateKey = [[NSString alloc] initWithData:privateKeyData encoding:NSUTF8StringEncoding];
   
    privateKey = [self DHPrivateKeyToString:privateKey];
    
    // clear up
    EVP_PKEY_free(evp);
    EVP_PKEY_CTX_free(kctx);
    EVP_PKEY_free(khkey);
    BIO_free_all(pubMem); BIO_free_all(priMem);
    
    NSDictionary *dic = @{DH_PUBLIC_KEY:publicKey, DH_PRIVATE_KEY:privateKey};
    return dic;
}

+(void) DHAgreementPublicKey:(NSString *) certification binPublicKey: (NSData**)publicKey agreement: (NSString**) agreement
{
    // step1. get public key from certification
    EVP_PKEY* pubKey = NULL;
    BIO* certificationBuffer = BIO_new_mem_buf(certification.UTF8String, (int)certification.length);
    X509* x509 = NULL;
    PEM_read_bio_X509(certificationBuffer, &x509, NULL, NULL);
    pubKey = X509_get_pubkey(x509);
    
    // step2. generate new Diffie Hellman public key according to cert-public key's p, g
    DH *tempDH = DH_new();
    tempDH->g = BN_dup(pubKey->pkey.dh->pub_key);
    tempDH->p = BN_dup(pubKey->pkey.dh->p);
    [prePrivKeyLock lock];
    tempDH->priv_key = BN_dup(prePrivKey);
    [prePrivKeyLock unlock];
    DH_generate_key(tempDH);
 
    
    // extract public key from tempDH
    unsigned char* binpubkey = (unsigned char*)OPENSSL_malloc(1024);
    int len = BN_bn2bin(tempDH->pub_key, binpubkey);
    NSData* pKey = [NSData dataWithBytes:binpubkey length:len];
    *publicKey = pKey;
    
    std::string sBinPubKey((char*)binpubkey, len);
    std::string hexPubKey = bin2hex(sBinPubKey);
    NSString* retAgreementPubKey = [NSString stringWithFormat:@"%s", hexPubKey.c_str()];
    
    OPENSSL_free(binpubkey);
/*
    // convert public key to PEM format
    BIO* pubMem=BIO_new(BIO_s_mem());
    PEM_write_bio_PUBKEY(pubMem, khkey);
    
    // get bytes stream from BIO.
    char *publicKeyPointer = NULL;
    NSUInteger publicKeyLength = (NSUInteger) BIO_get_mem_data(pubMem, &publicKeyPointer);
    
    // store bytes stream public key into OC object
    NSData *publicKeyData = [NSData dataWithBytesNoCopy:publicKeyPointer length:publicKeyLength freeWhenDone:NO];
    NSString *retAgreementPubKey = [[NSString alloc] initWithData:publicKeyData encoding:NSUTF8StringEncoding];
    retAgreementPubKey = [self DHPublicKeyToString:retAgreementPubKey];*/
    
/*    NSData* encoded = [GTMBase64 encodeData:pKey];
    NSString* retAgreementPubKey = [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];*/
    
    
    
    // step3. clean up
    BIO_free_all(certificationBuffer);
   // BIO_free_all(pubMem);
    X509_free(x509);
    EVP_PKEY_free(pubKey);
    DH_free(tempDH);
    
    *agreement = retAgreementPubKey;

}

+(NSString *) DHPublicKeyToString:(NSString *) publicKey
{
    publicKey = [publicKey stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""];
    publicKey = [publicKey stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""];
    publicKey = [publicKey stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    publicKey = [publicKey stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return publicKey;
}

+(NSString *) DHPrivateKeyToString:(NSString *) privateKey
{
    privateKey = [privateKey stringByReplacingOccurrencesOfString:@"-----BEGIN PRIVATE KEY-----" withString:@""];
    privateKey = [privateKey stringByReplacingOccurrencesOfString:@"-----END PRIVATE KEY-----" withString:@""];
    privateKey = [privateKey stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    privateKey = [privateKey stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return privateKey;
    
}

+ (NSString*) DHAgreementFromBinary:(NSData *)data
{
/*    DH* dh = [self generateDH];
    
    BIGNUM* pubkey = BN_bin2bn([data bytes], (int)data.length, NULL);
    EVP_PKEY* evpPublicKey = EVP_PKEY_new();
    EVP_PKEY_set1_DH(evpPublicKey, dh);
    evpPublicKey->pkey.dh->pub_key = pubkey;
    
    BIO* mem = BIO_new(BIO_s_mem());
    PEM_write_bio_PUBKEY(mem, evpPublicKey);
    
    char *publicKeyPointer = NULL;
    NSUInteger publicKeyLength = (NSUInteger) BIO_get_mem_data(mem, &publicKeyPointer);
    NSData *publicKeyData = [NSData dataWithBytesNoCopy:publicKeyPointer length:publicKeyLength freeWhenDone:NO];
    NSString *retAgreementPubKey = [[NSString alloc] initWithData:publicKeyData encoding:NSUTF8StringEncoding];
    retAgreementPubKey = [self DHPublicKeyToString:retAgreementPubKey];
    
    
    BN_free(pubkey);
    BIO_free(mem);
    EVP_PKEY_free(evpPublicKey);
 //   DH_free(dh);
  //  OPENSSL_free(publicKeyPointer);
    
    */
    
/*    NSData* encoded = [GTMBase64 encodeData:data];
    NSString *retAgreementPubKey = [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];*/
    
    
    std::string sBinPubKey((char*)[data bytes], data.length );
    
    std::string hexPubKey = bin2hex(sBinPubKey);
    NSString* retAgreementPubKey = [NSString stringWithFormat:@"%s", hexPubKey.c_str()];

    
    return retAgreementPubKey;
}

@end

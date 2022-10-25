#ifndef __NXL_NXLUTIL_H__
#define __NXL_NXLUTIL_H__

#include "nxlfmt.h"
#include "nxlobj.h"

#define BUILDINSECTIONINFO          ".FileInfo"
#define BUILDINSECTIONPOLICY        ".FilePolicy"
#define BUILDINSECTIONTAG           ".FileTag"


#define FILETYPEKEY                 "fileExtension"

namespace nxl {
namespace util {


/*
 *
 *		check if the given file is NXL file
 *
 */
bool check( const char* path) throw();

/*
 *
 *		check if the given file's first bytes match the signature header of NXL
 *
 */
bool simplecheck(const char* path) throw();

/*
 *
 *		convert an existing normal file to NXL file
 *
 */
void convert( const char* owner_id, const char* source,  const char* target, const NXL_CRYPTO_TOKEN* crypto_token, const void* recovery_token,  bool overwrite);

/*
 *
 *		decrypt an existing NXL file
 *
 */
void decrypt( const char* source,  const char* target, const NXL_CRYPTO_TOKEN* crypto_token,  bool overwrite);

void write_section_in_nxl(const char* path, const char* section_name, const char* data, const int datalen, const uint32_t flag, const NXL_CRYPTO_TOKEN* crypto_token);
    
void read_section_in_nxl(const char* path, const char* section_name, char* data, int* datalen, int* flag, const NXL_CRYPTO_TOKEN* crypto_token);


/*
 *
 *      Get DUID in nxl file
 *
 */
void read_token_info_from_nxl(const char* path, NXL_CRYPTO_TOKEN* token);
    

void read_ownerid_from_nxl(const char* path, char* data, int* datalen);
    

/*
 *      Calculate HMAC
 *
 */

void hmac_sha256(const char* src, int len, const char* hex_token, char* hash, int* hashlen);

}   // namespace util
}   // namespace nxl


#endif  // #ifndef __NXL_NXLUTIL_H__

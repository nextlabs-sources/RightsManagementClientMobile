#include "utils.h"
#include "nxlbasic.hpp"
#include "nxlobj.h"

namespace {
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


using namespace nxl;

bool nxl::util::check(const char* path) throw () {
    try {
        // sanity check
        if (NULL == path) {
            throw NXEXCEPTION("path string is null");
        }

        if (!nxl::exist(path)) {
            throw NXEXCEPTION("path file is not exist");
        }

        nxl::FmtHeader::valid_format(path);

        return true;
    } catch (nxl::exception& e) {
        //tbd
    } catch (std::exception& e) {
        //tbd
    } catch (...) {
        //tbd
    }

    return false;
}

bool nxl::util::simplecheck(const char* path) throw () {
    try {
        // sanity check
        if (NULL == path) {
            throw NXEXCEPTION("path string is null");
        }

        if (!nxl::exist(path)) {
            throw NXEXCEPTION("path file is not exist");
        }

        nxl::FmtHeader::valid_signature(path);

        return true;
    } catch (nxl::exception& e) {
        //tbd
    } catch (std::exception& e) {
        //tbd
    } catch (...) {
        //tbd
    }

    return false;
}

/*
 owner_id: UTF-8, end with '\0', up to 255 bytes
 */
void nxl::util::convert(const char* owner_id, const char* source, const char* target, const NXL_CRYPTO_TOKEN* crypto_token, const void* recovery_token, bool overwrite) {
    // sanity check
    if (NULL == source) {
        throw NXEXCEPTION("source string is null");
    }

    if (!nxl::exist(source)) {
        throw NXEXCEPTION("source file is not exist");
    }

    if (0 == nxl::getfilesize(source)) {
        throw NXEXCEPTION("source file content is empty");
    }

    if (check(source)) {
        throw NXEXCEPTION("source file is already a nxl file");
    }


    if (NULL == target) {
        throw NXEXCEPTION("target path is null");
    }

    if (nxl::exist(target)) {
        if (!overwrite) {
            throw NXEXCEPTION("target file has already exist,but the @overwrite is set by false");
        }
    } else {
        if (!nxl::makesure_exist(target)) {
            throw NXEXCEPTION("target file can not be create");
        }
    }

    // create target file
    nxl::FileStream ofs;
    ofs.open(target, nxl::FileStream::kEncrypt);
    ofs.prepare_for_encrypt((unsigned char*)owner_id, crypto_token, recovery_token);
    ofs.encrypt(source);

    ofs.close();
    
    // try to write file extension in .FileInfo section
    try {
        std::string ext;
        // get suffix of the source file
        const char* psfxv = strrchr(source, '.');
        // add suffix attr into new created nxl file
        if (NULL != psfxv) {
            ext.assign(psfxv);
        }

        char fileExtension[256] = {0};
        sprintf(fileExtension, "{\"%s\":\"%s\"}", FILETYPEKEY, ext.c_str());
        
        write_section_in_nxl(target, BUILDINSECTIONINFO, fileExtension, (uint32_t)strlen(fileExtension), 0, crypto_token);
        
    } catch (...) {
        // fail to set attr section is not error 
    }
    

}

void nxl::util::decrypt(const char* source, const char* target, const NXL_CRYPTO_TOKEN* crypto_token, bool overwrite) {
    // sanity check
    if (NULL == source) {
        throw NXEXCEPTION("source path string is null");
    }
    
    if (NULL == target) {
        throw NXEXCEPTION("target path string is null");
    }
    
    if (!nxl::exist(source)) {
        throw NXEXCEPTION("source file is not exist");
    }
    
    if (!check(source)) {
        throw NXEXCEPTION("source file is not a nxl file");
    }
    
    if (nxl::exist(target) && !overwrite) {
        throw NXEXCEPTION("target file has already exist,but the @overwrite is set by false");
    }
    
    // tbd :: if target had existed and @overwrite is set by true , what if decyrpt operation failed?  recovery the target?
    
    if (NULL == crypto_token) {
        throw NXEXCEPTION("key is null");
    }
    
    // create nxlfile based on source path
    nxl::FileStream dfs;
    dfs.open(source, nxl::FileStream::kDecrypt);
    dfs.prepare_for_decrypt(crypto_token);
    dfs.decrypt(target);
    dfs.close();
}

void nxl::util::write_section_in_nxl(const char* path, const char* section_name, const char *data, const int datalen, const uint32_t flag, const NXL_CRYPTO_TOKEN *crypto_token)
{
    if (!check(path))
        throw NXEXCEPTION("file is not a nxl file");
    
    nxl::FileStream dfs;
    dfs.open(path, nxl::FileStream::kSectionOperations);
    
    dfs.write_section(section_name, data, datalen, flag, crypto_token);
    
    dfs.close();
}

void nxl::util::read_section_in_nxl(const char* path, const char *section_name, char *data, int *datalen, int* flag, const NXL_CRYPTO_TOKEN *crypto_token)
{
    if (!check(path))
        throw NXEXCEPTION("file is not a nxl file");
    
    
    nxl::FileStream fs;
    fs.open(path, nxl::FileStream::kGetInfo);
    
    
    fs.read_section(section_name, data, (uint32_t*)datalen, (uint32_t*)flag, true, crypto_token);
    
    
    fs.close();
}

void nxl::util::read_token_info_from_nxl(const char *path, NXL_CRYPTO_TOKEN* token)
{
    if (!check(path))
        throw NXEXCEPTION("file is not a nxl file");
    
    nxl::FileStream fs;
    
    fs.open(path, nxl::FileStream::kGetInfo);
    
    
    fs.read_token(path, token);

    std::string hex = bin2hex(std::string((char*)token->UDID, 16));
    
    memcpy(token->UDID, hex.c_str(), hex.length());
        
    
    fs.close();
}

void nxl::util::read_ownerid_from_nxl(const char *path, char *data, int *datalen)
{
    if (!path || !data || !datalen) {
        throw NXEXCEPTION("invalid parameters");
    }
    
    if (!check(path))
        throw NXEXCEPTION("file is not a nxl file");
    
    nxl::FileStream fs;
    
    fs.open(path, nxl::FileStream::kGetInfo);
    
    fs.read_ownerid(path, data, (uint32_t*)datalen, false, NULL);
    
    fs.close();
}

void nxl::util::hmac_sha256(const char *src, int len, const char *hex_token, char *hash, int *hashlen)
{
    if (!src || !hex_token || !hash || !hashlen) {
        throw NXEXCEPTION("invalid parameters");
    }
    
    if (*hashlen < 64) {
        throw NXEXCEPTION("hash buffer is too small");
    }
    
    char tmp[32] = {0};
    nxl::hmac_sha256_token(hex_token, 64, src, len, tmp);
    std::string str(tmp, 32);
    std::string hex = bin2hex(str);
    memcpy(hash, hex.c_str(), 64);
    
    *hashlen = 64;
}

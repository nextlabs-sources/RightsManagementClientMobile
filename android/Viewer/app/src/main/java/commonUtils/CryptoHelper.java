package commonUtils;

import java.security.MessageDigest;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/**
 * Designed to implement some common crypto functionality, including:
 * -ase encrypt & decrypt
 * -md5
 */
public class CryptoHelper {
    /**
     * AES encrypt function
     *
     * @param original the plain text
     * @param key      16, 24, 32 bytes available
     * @param iv       initial vector (16 bytes) - if null: ECB mode, otherwise: CBC mode
     * @return the cypher text
     */
    public static byte[] aesEncrypt(byte[] original, byte[] key, byte[] iv) throws Exception {
        // sanity check
        if (original == null) {
            throw new RuntimeException("invalid original buffer");
        }
        if (key == null || (key.length != 16 && key.length != 24 && key.length != 32)) {
            throw new RuntimeException("invalid key, key must be as 16 ,24, or 32 bytes");
        }
        if (iv != null && iv.length != 16) {
            throw new RuntimeException("invalid iv, iv must be either null or 16 bytes ");
        }

        SecretKeySpec keySpec;
        Cipher cipher;
        if (iv != null) {
            keySpec = new SecretKeySpec(key, "AES/CBC/PKCS7Padding");
            cipher = Cipher.getInstance("AES/CBC/PKCS7Padding");
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, new IvParameterSpec(iv));
        } else {
            keySpec = new SecretKeySpec(key, "AES/ECB/PKCS7Padding");
            cipher = Cipher.getInstance("AES/ECB/PKCS7Padding");
            cipher.init(Cipher.ENCRYPT_MODE, keySpec);
        }

        return cipher.doFinal(original);

    }

    /**
     * AES decrypt function
     *
     * @param encrypted the encrypted buffer
     * @param key       16, 24, 32 bytes available
     * @param iv        initial vector (16 bytes)
     *                  if null: ECB mode, otherwise: CBC mode
     * @return decrypted
     */
    public static byte[] aesDecrypt(byte[] encrypted, byte[] key, byte[] iv) throws Exception {
        // sanity check
        if (key == null || (key.length != 16 && key.length != 24 && key.length != 32)) {
            throw new RuntimeException("invalid key, key must be as 16 ,24, or 32 bytes");
        }
        if (iv != null && iv.length != 16) {
            throw new RuntimeException("invalid iv, iv must be either null or 16 bytes ");
        }

        SecretKeySpec keySpec;
        Cipher cipher;
        if (iv != null) {
            keySpec = new SecretKeySpec(key, "AES/CBC/PKCS7Padding");
            cipher = Cipher.getInstance("AES/CBC/PKCS7Padding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec, new IvParameterSpec(iv));
        } else {
            keySpec = new SecretKeySpec(key, "AES/ECB/PKCS7Padding");
            cipher = Cipher.getInstance("AES/ECB/PKCS7Padding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec);
        }

        return cipher.doFinal(encrypted);
    }

    /**
     * calculate the checksum of the input data array
     *
     * @param data must less than 2^64
     * @return thumbprint of 2^128 bit , array of 16 bytes
     * @throws Exception
     */
    public static byte[] md5(byte[] data) throws Exception {
        // sanity check
        if (data == null) {
            throw new RuntimeException("invalid data");
        }
        MessageDigest md = MessageDigest.getInstance("MD5");
        return md.digest(data);
    }

    /**
     * calculate the checksum of the input data array
     *
     * @param data      must less than 2^64
     * @param uppercase true for uppercase result,  false for lowercase
     * @return 32 chars hexify of 2^128 bit
     * @throws Exception
     */
    public static String md5WithHexifyResult(byte[] data, boolean uppercase) throws Exception {

        byte[] checksum = md5(data);

        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < checksum.length; i++) {
            int val = ((int) checksum[i]) & 0xff;
            if (val < 16) {
                sb.append("0");
            }
            sb.append(Integer.toHexString(val));
        }

        return uppercase ? sb.toString().toUpperCase() : sb.toString().toLowerCase();
    }

}

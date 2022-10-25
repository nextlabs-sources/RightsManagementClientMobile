package nxl.bridge;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.concurrent.Executor;

/*
try to encapsulate c++ struct into to Java byte[]
----------------------------------
struct _NXL_CRYPTO_TOKEN{
    unsigned char PublicKey[256];   //The public key between member and Root CA
    unsigned char PublicKeyWithiCA[256];  //The public key between member and iCA
    uint32_t      ml;            token's maintenance level
    unsigned char UDID[32];      UDID, unique document id HEX string
    unsigned char Token[64];     token, used to encrypt cek or decrypt cek HEX string
        };

 sizeof(_NXL_CRYPTO_TOKEN) = 0n612,0x264
----------------------------------
 */
public final class NxlCryptoTokenBlob {

    private String mPublicKeyRootCA;    // -> unsigned char PublicKey[256]
    private String mPublicKeyWithiCA;   // -> unsigned char PublicKeyWithiCA[256];
    private int mMaintenanceLevel;      // -> uint32_t
    private String mDUID;               // -> unsigned char DUID[32]
    private String mToken;              // -> unsigned char Token[64]

    public NxlCryptoTokenBlob(int mMaintenanceLevel, String mDUID, String mToken) {
        this.mMaintenanceLevel = mMaintenanceLevel;
        this.mDUID = mDUID;
        this.mToken = mToken;
    }

    public NxlCryptoTokenBlob(String aggrementKey, String publicKeyInCA, int mMaintenanceLevel, String mDUID, String mToken) {
        this.mPublicKeyRootCA = aggrementKey;
        this.mPublicKeyWithiCA = publicKeyInCA;
        this.mMaintenanceLevel = mMaintenanceLevel;
        this.mDUID = mDUID;
        this.mToken = mToken;
    }

    public byte[] toByteBuffer() {
        // sanity check
        // prepare
        /*
         unsigned char PublicKey[256];          |  0
         unsigned char PublicKeyWithiCA[256];   |
         uint32_t      ml;                      |
         unsigned char UDID[32];                |
         unsigned char Token[64];               |
         */
        // encapsulate
        ByteBuffer blob = ByteBuffer.allocate(612); // 612 for 32bit is ok, but 616 for 64bit is ok
        try {
            blob.order(ByteOrder.LITTLE_ENDIAN);
            if (null == mPublicKeyRootCA) {
                blob.position(256);
            } else {

                blob.put(hexStringToByteArray(mPublicKeyRootCA), 0, 256);
            }
            if (null == mPublicKeyWithiCA) {
                blob.position(512);
            } else {
                blob.put(hexStringToByteArray(mPublicKeyWithiCA), 0, 256);
            }
            blob.putInt(mMaintenanceLevel);
            blob.put(mDUID.getBytes("UTF-8"), 0, 32);
            blob.put(mToken.getBytes("UTF-8"), 0, 64);
        } catch (Exception e) {
            // ignored
        }
        byte[] rt = blob.array();
        return rt;
    }


    public static byte[] hexStringToByteArray(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                    + Character.digit(s.charAt(i + 1), 16));
        }
        return data;
    }

}

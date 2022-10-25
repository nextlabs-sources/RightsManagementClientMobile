package nxl.bridge;

import java.util.Arrays;

/*
for version 1; total bytes is 804
    rootAgreementKey    [256]
    icaAgreementKey     [256]
    ownerid             [256];
    duid                [32]
    ml                  4;
 */
public class NxlFingerPrint {
    public String ownerId;
    public String duid;
    public int ml;
    public String rootAgreementKey;
    public String icaAgreementKey;

    byte[] toByteBuffer(int version) {
        int size = 0;
        if (version == 1) {
            size = 804;
        }
        return new byte[size];
    }

    public boolean fromByteBuffer(byte[] bytes, int version) {
        if (version != 1) {
            return false;
        }
        // fill all member data from bytes
        rootAgreementKey = bytesToHexString(Arrays.copyOfRange(bytes, 0, 256));
        icaAgreementKey = bytesToHexString(Arrays.copyOfRange(bytes, 256, 256 + 256));
        int endpos = 0;
        while (bytes[256 + 256 + endpos++] != 0) ;
        // filter out owerId's extra \u0000;
        ownerId = new String(bytes, 256 + 256, endpos - 1);
        duid = new String(bytes, 256 + 256 + 256, 32);
        int posml = 256 + 256 + 256 + 32;
        ml = (bytes[posml] & 0xff) | ((bytes[posml + 1] << 8) & 0xff00)
                | ((bytes[posml + 2] << 24) >>> 8) | (bytes[posml + 3] << 24);
        return true;
    }

    public static String bytesToHexString(byte[] src) {
        StringBuilder stringBuilder = new StringBuilder("");
        if (src == null || src.length <= 0) {
            return null;
        }
        for (int i = 0; i < src.length; i++) {
            int v = src[i] & 0xFF;
            String hv = Integer.toHexString(v);
            if (hv.length() < 2) {
                stringBuilder.append(0);
            }
            stringBuilder.append(hv);
        }
        return stringBuilder.toString();
    }

}

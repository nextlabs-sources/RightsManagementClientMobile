package nxl.bridge;


public class NxlUtils {
    private static final String TAG = NxlUtils.class.getSimpleName();

    private NxlUtils() {
        { /* cannot be instantiated */ }
    }

    /**
     * this utils represents as a BRIDGE to c++ version of NXL2 through JNI
     */
    static {
        System.loadLibrary("nxl-format");
    }

    static public boolean isNxlFile(String path, boolean fast) {
        return isMatchNxlFmt(path, fast);
    }

    static public boolean convert(String ownerId, String normalFile,
                                  String nxlFile, NxlCryptoTokenBlob tokenBlob,
                                  boolean overwrite) {
        return convertToNxlFile(ownerId, normalFile, nxlFile, tokenBlob.toByteBuffer(), overwrite);
    }

    static public boolean decrypt(String nxlFile, String normalFile,
                                  NxlCryptoTokenBlob tokenBlob,
                                  boolean overwrite) {
        return decryptToNormalFile(nxlFile, normalFile, tokenBlob.toByteBuffer(), overwrite);
    }

    static public boolean getNxlFingerPrint(String nxFile, NxlFingerPrint fingerPrint) {
        byte[] ownerID_256 = new byte[256];
        byte[] duid_32 = new byte[32];
        if (extractInfoFromNxlFile(nxFile, ownerID_256, duid_32)) {
            //
            int endpos = 0;
            while (ownerID_256[endpos++] != 0) ;
            fingerPrint.ownerId = new String(ownerID_256, 0, endpos - 1);
            fingerPrint.duid = new String(duid_32);
            return true;

        } else {
            return false;
        }
    }

    static public boolean getNxlFingerPrint(String nxlFile, NxlFingerPrint fingerPrint, int version) {
        byte[] buf = fingerPrint.toByteBuffer(version);
        return extractFingerPrint(nxlFile, buf, version) && fingerPrint.fromByteBuffer(buf, version);
    }

    private static native boolean isMatchNxlFmt(String path, boolean fast);

    private static native boolean convertToNxlFile(String ownerId, String normalFile, String nxlFile,
                                                   byte[] tokenBlob, boolean overwrite);

    private static native boolean decryptToNormalFile(String nxlFile, String normalFile,
                                                      byte[] keyBlob, boolean overwrite);

    private static native boolean extractInfoFromNxlFile(String path, byte[] ownerId, byte[] DUID);

    private static native boolean extractFingerPrint(String nxl, byte[] FingerPrint, int version);
}

package nxl.fileFormat;


import android.util.Base64;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.LinkedList;
import java.util.List;
import java.util.TimeZone;

import restAPIWithRMS.dataTypes.NXKey;
import restAPIWithRMS.dataTypes.NXKeyRing;

public class Utils {
    static private final String TAG = "NX_NXL";

    /**
     * this utils represents corresponding ndk version through JNI
     */
    static {
        System.loadLibrary("nxl-format");
    }


    /**
     * this function check if the document assigned by path matches the nxl format
     * if set fast , it only check the NXL signature header
     */
    static public boolean check(String path, boolean fast) {
        return fast ? isMatchNxlHeader(path) : isMatchNxlFmt(path);
    }

    /**
     * This function convert an existing normal file to NXL file
     */
    static public boolean convert(String normalFile, String nxlFile, byte[] keyBlob, boolean overwrite) {
        return convertToNxlFile(normalFile, nxlFile, keyBlob, overwrite);
    }

    /**
     * This function decrypt an existing NXL file
     */
    static public boolean decrypt(String nxlFile, String normalFile, byte[] keyBlob, boolean overwrite) {
        return decryptToNormalFile(nxlFile, normalFile, keyBlob, overwrite);
    }

    /**
     * This fuction get tags from an existing NXL file
     *
     * @param nxlFile path of a nxl file
     * @param safeway make sure retrieved tags had pass through crc check by provide kekey
     * @param keyBlob if set safeway, it must provide keyBlob
     * @param tags    tags container
     * @return
     */
    static public boolean getTags(String nxlFile, boolean safeway, byte[] keyBlob, Tags tags) {
        byte[] tagValues = new byte[4096];
        getTags(nxlFile, safeway, keyBlob, tagValues);
        tags.fromUnicodeBuffer(tagValues);
        return true;
    }

    static public boolean setTags(String nxlFile, byte[] keyBlob, Tags tags) {
        byte[] tagsValues = tags.toUnicodeByteArray();
        return setTags(nxlFile, keyBlob, tagsValues);
    }

    static public byte[] getKeyBlobLatest(final List<NXKeyRing> rings) {
        if (rings == null) {
            Log.e(TAG, "key rings is null");
            return null;
        }

        class KeyFindPolicy {
            List<NXKeyRing> eligibleRings = new LinkedList<>();
            int ringIndex = 0;
            int keyIndex = 0;

            public KeyFindPolicy(final List<NXKeyRing> rings, int maxSizeofRingName) {
                for (NXKeyRing r : rings) {
                    if (r.keyRingName == null ||
                            r.keys == null ||
                            r.keys.isEmpty() ||
                            r.lastModifiedDate == null ||
                            r.keyRingName.length() > maxSizeofRingName) {
                        continue;
                    }
                    eligibleRings.add(r);
                }
            }

            public boolean find() {
                // sort eligibleRings with descending order by lastModifiedDate
                Collections.sort(eligibleRings, new Comparator<NXKeyRing>() {
                    @Override
                    public int compare(NXKeyRing lhs, NXKeyRing rhs) {
                        //descending order
                        return getTimeSeconds(rhs.lastModifiedDate) - getTimeSeconds(lhs.lastModifiedDate);
                    }
                });

                while (ringIndex < eligibleRings.size()) {
                    // sort keyRing with descending order by timeStamp
                    NXKeyRing ring = eligibleRings.get(ringIndex);
                    Collections.sort(ring.keys, new Comparator<NXKey>() {
                        @Override
                        public int compare(NXKey lhs, NXKey rhs) {
                            return getTimeSeconds(rhs.timeStamp) - getTimeSeconds(lhs.timeStamp);
                        }
                    });
                    // find qualified key
                    while (keyIndex < ring.keys.size()) {
                        NXKey k = ring.keys.get(keyIndex);
                        if (k.keyId != null && k.keyData != null) {
                            return true;
                        }
                        keyIndex++;
                    }
                    ringIndex++;
                }
                return false;
            }

            public NXKeyRing getRing() {
                return eligibleRings.get(ringIndex);
            }

            public NXKey getKey() {
                return eligibleRings.get(ringIndex).keys.get(keyIndex);
            }
        }

        KeyFindPolicy policy = new KeyFindPolicy(rings, 8);
        if (!policy.find()) {
            throw new RuntimeException("can not find proper key");
        }

        NXKeyRing ring = policy.getRing();
        NXKey key = policy.getKey();

        // pack the found key into keyBlob format
        byte[] id = Base64.decode(key.keyId.getBytes(), Base64.DEFAULT);
        byte[] pw = Base64.decode(key.keyData.getBytes(), Base64.DEFAULT);
        int Timestamp = getTimeSeconds(key.timeStamp);


        ByteBuffer keyBlob = ByteBuffer.allocate(580);
        keyBlob.order(ByteOrder.LITTLE_ENDIAN);
        /*
        short   Algorithm ;          // must 2              0
        short   IdSize ;             // must 44             2
        char            Name[8];     // NL_SHARE            4
        unsigned char   Hash[32];    // the byte id         12
        int32_t       Timestamp;                            44
        char            pading[16]    // any                60
        uint32_t   keySize;          // must32              64
        unsigned char   Key[512];    // put byte pw         68
        };
        */
        keyBlob.putShort((short) 2);  // Algorithm
        keyBlob.putShort((short) 44);
        keyBlob.put(ring.keyRingName.getBytes());
        keyBlob.position(12);
        keyBlob.put(id);
        keyBlob.position(44);
        keyBlob.putInt(Timestamp);
        keyBlob.position(64);
        keyBlob.putInt(32);
        keyBlob.put(pw);

        return keyBlob.array();
    }


    static public byte[] getKeyBlobByNextlabsKeyId(List<NXKeyRing> rings, NextlabsKeyId keyId) {
        if (rings == null) {
            return null;
        }
        if (keyId == null) {
            return null;
        }
        // prepare keyblob
         /*
        short   Algorithm ;          // must 2              0
        short   IdSize ;             // must 44             2
        char            Name[8];     // NL_SHARE            4
        unsigned char   Hash[32];    // the byte id         12
        int32_t       Timestamp;                            44
        char            pading[16]    // any                60
        uint32_t   keySize;          // must32              64
        unsigned char   Key[512];    // put byte pw         68
        };
        */
        ByteBuffer keyBlob = ByteBuffer.allocate(580);
        keyBlob.order(ByteOrder.LITTLE_ENDIAN);

        keyBlob.putShort((short) 2);
        keyBlob.putShort((short) 44);

        // find other components
        for (int i = 0; i < rings.size(); ++i) {
            NXKeyRing nkr = rings.get(i);
            // compare keyRngName
            if (!nkr.keyRingName.equals(keyId.getName())) {
                continue;
            }
            // set keyringName;
            keyBlob.position(4);
            keyBlob.put(nkr.keyRingName.getBytes());
            keyBlob.position(12);

            // find key
            List<NXKey> lk = nkr.keys;
            for (int j = 0; j < lk.size(); ++j) {
                NXKey nx = lk.get(j);
                byte[] nxHash = Base64.decode(nx.keyId, Base64.DEFAULT);
                byte[] keyidHash = keyId.getHash();
                // compare key's hash
                int len = nxHash.length > keyidHash.length ? nxHash.length : keyidHash.length;
                boolean isEqual = true;
                for (int k = 0; k < len; k++) {
                    if (nxHash[k] != keyidHash[k])
                        isEqual = false;
                    break;
                }
                if (!isEqual) {
                    continue;
                }
                // compare key's timestamp
                int timeSec = getTimeSeconds(nx.timeStamp);
                if (keyId.getTimestamp() != timeSec) {
                    continue;
                }
                // found the key
                byte[] keyValue = Base64.decode(nx.keyData, Base64.DEFAULT);

                keyBlob.put(nxHash);
                keyBlob.position(44);
                keyBlob.putInt(timeSec);
                keyBlob.position(64);
                keyBlob.putInt(keyValue.length);
                keyBlob.put(keyValue);
                return keyBlob.array();
            }
        }
        return null;
    }

    static public boolean getNextlabsKeyId(String nxlFile, NextlabsKeyId keyId) {
        byte[] keyIdBlob = new byte[NextlabsKeyId.KID_SIZE];
        if (!getKeyId(nxlFile, keyIdBlob)) {
            return false;
        }
        if (!keyId.getFromKeyIdBlob(keyIdBlob)) {
            return false;
        }
        return true;
    }


    static private int getTimeSeconds(String timeValue) {

        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ");
            TimeZone to_tz = TimeZone.getTimeZone("UTC");
            sdf.setTimeZone(to_tz);
            Date d = sdf.parse(timeValue);
            return (int) (d.getTime() / 1000);   // millisecond to second
        } catch (Exception e) {
            Log.e(TAG, e.toString());

        }
        // for first dateformat parse error, thr another
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
            TimeZone to_tz = TimeZone.getTimeZone("UTC");
            sdf.setTimeZone(to_tz);
            Date d = sdf.parse(timeValue);
            return (int) (d.getTime() / 1000);   // millisecond to second
        } catch (Exception e) {
            Log.e(TAG, e.toString());

        }
        return 0;
    }

    static public String getFileType(String nxlFile) {
        return getType(nxlFile);
    }

    private static native boolean isMatchNxlFmt(String path);

    private static native boolean isMatchNxlHeader(String path);

    private static native boolean convertToNxlFile(String source, String dest, byte[] keyBlob, boolean overwrite);

    private static native boolean decryptToNormalFile(String nxlFile, String normalFile, byte[] keyBlob, boolean overwrite);

    private static native boolean getTags(String nxlFile, boolean safeway, byte[] keyBlob, byte[] buffer);

    private static native boolean setTags(String nxlFile, byte[] keyBlob, byte[] buffer);

    private static native boolean getKeyId(String nxlFile, byte[] KeyIdBlob);

    private static native String getType(String nxlFile);
}

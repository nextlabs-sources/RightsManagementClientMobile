package nxl.fileFormat;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * 44 chars in binary format
 * - as well-defined document says NextlabsKeyID is defined as C-style struct with 44 bytes sizeof()
 * and three field , like
 * struct NextlabsKeyID
 * {
 * char      name[8];   // key ring name
 * char      hash[32];  // hash value of this key
 * int32     timestamp; // creation time of this key
 * }
 */
public class NextlabsKeyId {

    static final public int KID_SIZE = 44;

    private byte[] mName = new byte[8];     /*Key ring name*/
    private byte[] mHash = new byte[32];   /*Hash of this key*/
    private int mTimestamp = 0;          /*Key's creation time*/


    public String getName() {
        return new String(mName);
    }

    public byte[] getHash() {
        return mHash;
    }

    public int getTimestamp() {
        return mTimestamp;
    }

    public boolean getFromKeyIdBlob(byte[] keyIdBlob) {
        if (keyIdBlob == null) {
            return false;
        }
        if (keyIdBlob.length < NextlabsKeyId.KID_SIZE) {
            return false;
        }
        // set timestamp
        ByteBuffer bb = ByteBuffer.wrap(keyIdBlob);
        try {
            bb.order(ByteOrder.LITTLE_ENDIAN);
            bb.get(mName, 0, 8);
            bb.get(mHash, 0, 32);
            mTimestamp = bb.getInt(40);
            return true;
        } catch (Exception e) {

        }
        return false;
    }

}


package com.sap.ve;

import com.sap.ve.DVLTypes.DVLRESULT;

public class DVLLibrary {
    private long m_handle = 0;

    public DVLLibrary(long handle) {
        m_handle = handle;
    }

    static private native int nativeRetrieveThumbnail(long hLibrary, String filename, Object image);

    // native stuff

    public DVLRESULT RetrieveThumbnail(String filename, SDVLImage image) {
        return DVLRESULT.fromInt(nativeRetrieveThumbnail(m_handle, filename, image));
    }
}

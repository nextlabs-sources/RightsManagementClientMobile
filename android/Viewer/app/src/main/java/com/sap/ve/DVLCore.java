package com.sap.ve;

import android.content.Context;

import com.sap.ve.DVLTypes.DVLRESULT;

public class DVLCore {
    static {
        System.loadLibrary("DVL");
    }

    private long m_handle = 0;
    private Context m_context;
    private DVLRenderer m_renderer;
    private DVLLibrary m_library;

    public DVLCore(Context context) {
        m_context = context;
        m_handle = nativeInit();
        if (m_handle == 0)
            throw new java.lang.UnsupportedOperationException("can't instantiate core");

        m_library = new DVLLibrary(nativeGetLibrary(m_handle));
    }

    static private native long nativeInit();

    static private native void nativeDone(long handle);

    static private native long nativeGetLibrary(long handle);

    static private native int nativeInitRenderer(long handle);

    static private native int nativeDoneRenderer(long handle);

    static private native long nativeGetRenderer(long handle);

    static private native int nativeGetMajorVersion(long handle);

    static private native int nativeGetMinorVersion(long handle);

    // system stuff

    static private native int nativeGetBuildNumber(long handle);

    static private native int nativeLoadScene(long handle, String filename, String password, Object scene);

    // native stuff

    public DVLLibrary GetLibrary() {
        return m_library;
    }

    public DVLRESULT InitRenderer() {
        DVLRESULT res = DVLRESULT.fromInt(nativeInitRenderer(m_handle));
        if (res.Failed()) {
            android.util.Log.w("DVLCore", "InitRenderer failed: " + res.toString());
            return res;
        }

        long hRenderer = nativeGetRenderer(m_handle);
        if (hRenderer == 0)
            return DVLRESULT.FAIL;

        m_renderer = new DVLRenderer(hRenderer, m_context);
        return res;
    }

    public DVLRESULT DoneRenderer() {
        return DVLRESULT.fromInt(nativeDoneRenderer(m_handle));
    }

    public DVLRenderer GetRenderer() {
        return m_renderer;
    }

    public int GetMajorVersion() {
        return nativeGetMajorVersion(m_handle);
    }

    public int GetMinorVersion() {
        return nativeGetMinorVersion(m_handle);
    }

    public int GetBuildNumber() {
        return nativeGetBuildNumber(m_handle);
    }

    public DVLRESULT LoadScene(String filename, String password, DVLScene scene) {
        DVLClient.startLoading();
        return DVLRESULT.fromInt(nativeLoadScene(m_handle, filename, password, scene));
    }

    public void dispose() {
        if (m_renderer != null) {
            m_renderer.dispose();
            m_renderer = null;
        }

        m_library = null;

        if (m_handle != 0) {
            nativeDone(m_handle);
            m_handle = 0;
        }
    }

    @Override
    protected void finalize() throws Throwable {
        try {
            dispose();
        } finally {
            super.finalize();
        }
    }
}

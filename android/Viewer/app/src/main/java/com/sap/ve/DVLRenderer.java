package com.sap.ve;

import android.content.Context;

import com.sap.ve.DVLTypes.DVLRESULT;
import com.sap.ve.DVLTypes.DVLZOOMTO;

public class DVLRenderer {
    private long m_handle = 0;
    private Context m_context;
    private DVLScene m_scene;

    public DVLRenderer(long handle, Context context) {
        m_handle = handle;
        m_context = context;
    }

    static private native int nativeSetDimensions(long hRenderer, int width, int height);

    static private native void nativeSetBackgroundColor(long hRenderer, float fTopRed, float fTopGreen, float fTopBlue, float fBottomRed, float fBottomGreen, float fBottomBlue);

    static private native int nativeAttachScene(long hRenderer, long hScene);

    static private native int nativeGetAuxiliaryScenesCount(long hRenderer);

    static private native int nativeAttachAuxiliaryScene(long hRenderer, long hScene);

    static private native int nativeDetachAuxiliaryScene(long hRenderer, int index);

    static private native long nativeGetAuxiliaryScene(long hRenderer, int index);

    static private native long nativeGetAuxiliarySceneAnchorNode(long hRenderer, int index);

    static private native int nativeGetAuxiliarySceneWorldMatrix(long hRenderer, int index, Object matWorld);

    static private native int nativeSetAuxiliarySceneAnchor(long hRenderer, int index, long idAnchorNode);

    static private native int nativeSetAuxiliarySceneAnchorMatrix(long hRenderer, int index, Object matAnchor);

    static private native int nativeSetAuxiliarySceneMatrix(long hRenderer, int index, Object matWorld);

    static private native boolean nativeShouldRenderFrame(long hRenderer);

    static private native int nativeRenderFrame(long hRenderer);

    static private native int nativeRenderFrameEx(long hRenderer, Object matView, Object matProjection);

    static private native int nativeGetCameraMatrices(long hRenderer, Object matView, Object matProjection);

    static private native int nativeSetOption(long hRenderer, int type, boolean bEnable);

    static private native boolean nativeGetOption(long hRenderer, int type);

    static private native int nativeSetOptionF(long hRenderer, int type, float fValue);

    static private native float nativeGetOptionF(long hRenderer, int type);

    static private native int nativeResetView(long hRenderer);

    static private native int nativeBeginGesture(long hRenderer, float x, float y);

    static private native int nativeEndGesture(long hRenderer);

    static private native int nativePan(long hRenderer, float dx, float dy);

    static private native int nativeRotate(long hRenderer, float dx, float dy);

    static private native int nativeZoom(long hRenderer, float f);

    static private native boolean nativeCanIsolateNode(long hRenderer, long id);

    static private native int nativeSetIsolatedNode(long hRenderer, long id);

    static private native long nativeGetIsolatedNode(long hRenderer);

    static private native int nativeZoomTo(long hRenderer, int what, long idNode, float fCrossFadeSeconds);

    static private native int nativeTap(long hRenderer, float x, float y, boolean bDouble);

    static private native int nativeHitTest(long hRenderer, float x, float y, Object hitTest);

    public DVLRESULT SetDimensions(int w, int h) {
        return DVLRESULT.fromInt(nativeSetDimensions(m_handle, w, h));
    }

    // system stuff

    public void SetBackgroundColor(float fTopRed, float fTopGreen, float fTopBlue, float fBottomRed, float fBottomGreen, float fBottomBlue) {
        nativeSetBackgroundColor(m_handle, fTopRed, fTopGreen, fTopBlue, fBottomRed, fBottomGreen, fBottomBlue);
    }

    // native stuff

    public DVLRESULT AttachScene(DVLScene scene) {
        m_scene = scene;
        return DVLRESULT.fromInt(nativeAttachScene(m_handle, scene.getHandle()));
    }

    public DVLScene GetAttachedScene() {
        return m_scene;
    }

    public int GetAuxiliaryScenesCount() {
        return nativeGetAuxiliaryScenesCount(m_handle);
    }

    public DVLRESULT AttachAuxiliaryScene(DVLScene scene) {
        return DVLRESULT.fromInt(nativeAttachAuxiliaryScene(m_handle, scene.getHandle()));
    }

    public DVLRESULT DetachAuxiliaryScene(int index) {
        return DVLRESULT.fromInt(nativeDetachAuxiliaryScene(m_handle, index));
    }

    public DVLScene GetAuxiliaryScene(int index) {
        long sceneHandle = nativeGetAuxiliaryScene(m_handle, index);
        return sceneHandle != 0 ? new DVLScene(sceneHandle, m_context) : null;
    }

    public long GetAuxiliarySceneAnchorNode(int index) {
        return nativeGetAuxiliarySceneAnchorNode(m_handle, index);
    }

    public DVLRESULT GetAuxiliarySceneWorldMatrix(int index, SDVLMatrix matWorld) {
        return DVLRESULT.fromInt(nativeGetAuxiliarySceneWorldMatrix(m_handle, index, matWorld));
    }

    public DVLRESULT GetAuxiliarySceneAnchor(int index, long idAnchorNode) {
        return DVLRESULT.fromInt(nativeSetAuxiliarySceneAnchor(m_handle, index, idAnchorNode));
    }

    public DVLRESULT SetAuxiliarySceneAnchorMatrix(int index, SDVLMatrix matAnchor) {
        return DVLRESULT.fromInt(nativeSetAuxiliarySceneAnchorMatrix(m_handle, index, matAnchor));
    }

    public DVLRESULT GetAuxiliarySceneMatrix(int index, SDVLMatrix matWorld) {
        return DVLRESULT.fromInt(nativeSetAuxiliarySceneMatrix(m_handle, index, matWorld));
    }

    public boolean ShouldRenderFrame() {
        return nativeShouldRenderFrame(m_handle);
    }

    public DVLRESULT RenderFrame() {
        return DVLRESULT.fromInt(nativeRenderFrame(m_handle));
    }

    public DVLRESULT RenderFrameEx(SDVLMatrix matView, SDVLMatrix matProjection) {
        return DVLRESULT.fromInt(nativeRenderFrameEx(m_handle, matView, matProjection));
    }

    public DVLRESULT GetCameraMatrices(SDVLMatrix matView, SDVLMatrix matProjection) {
        return DVLRESULT.fromInt(nativeGetCameraMatrices(m_handle, matView, matProjection));
    }

    public DVLRESULT SetOption(DVLTypes.DVLRENDEROPTION type, boolean bEnable) {
        return DVLRESULT.fromInt(nativeSetOption(m_handle, type.ordinal(), bEnable));
    }

    public boolean GetOption(DVLTypes.DVLRENDEROPTION type) {
        return nativeGetOption(m_handle, type.ordinal());
    }

    public DVLRESULT SetOptionF(DVLTypes.DVLRENDEROPTIONF type, float fValue) {
        return DVLRESULT.fromInt(nativeSetOptionF(m_handle, type.ordinal(), fValue));
    }

    public float GetOptionF(DVLTypes.DVLRENDEROPTIONF type) {
        return nativeGetOptionF(m_handle, type.ordinal());
    }

    public DVLRESULT ResetView() {
        return DVLRESULT.fromInt(nativeResetView(m_handle));
    }

    public DVLRESULT BeginGesture(float x, float y) {
        return DVLRESULT.fromInt(nativeBeginGesture(m_handle, x, y));
    }

    public DVLRESULT EndGesture() {
        return DVLRESULT.fromInt(nativeEndGesture(m_handle));
    }

    public DVLRESULT Pan(float dx, float dy) {
        return DVLRESULT.fromInt(nativePan(m_handle, dx, dy));
    }

    public DVLRESULT Rotate(float dx, float dy) {
        return DVLRESULT.fromInt(nativeRotate(m_handle, dx, dy));
    }

    public DVLRESULT Zoom(float f) {
        return DVLRESULT.fromInt(nativeZoom(m_handle, f));
    }

    public boolean CanIsolateNode(long idNode) {
        return nativeCanIsolateNode(m_handle, idNode);
    }

    public DVLRESULT SetIsolatedNode(long idNode) {
        return DVLRESULT.fromInt(nativeSetIsolatedNode(m_handle, idNode));
    }

    public long GetIsolatedNode() {
        return nativeGetIsolatedNode(m_handle);
    }

    public DVLRESULT ZoomTo(DVLZOOMTO what, long idNode, float fCrossFadeSeconds) {
        return DVLRESULT.fromInt(nativeZoomTo(m_handle, what.ordinal(), idNode, fCrossFadeSeconds));
    }

    public DVLRESULT Tap(float x, float y, boolean bDouble) {
        return DVLRESULT.fromInt(nativeTap(m_handle, x, y, bDouble));
    }

    public DVLRESULT HitTest(float x, float y, SDVLHitTest hitTest) {
        hitTest.screenCoordinate[0] = x;
        hitTest.screenCoordinate[1] = y;
        return DVLRESULT.fromInt(nativeHitTest(m_handle, x, y, hitTest));
    }

    public void dispose() {
        m_scene = null;
        m_handle = 0;
    }
}

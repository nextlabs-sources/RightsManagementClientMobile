package com.nextlabs.viewer.hps;

// Auto-generated file

import android.content.Context;

public class AndroidUserMobileSurfaceView extends AndroidMobileSurfaceView {
    public AndroidUserMobileSurfaceView(Context context) {
        super(context);
    }

    public AndroidUserMobileSurfaceView(Context context, AndroidMobileSurfaceView.Callback svcb, int guiSurfaceId, int savedSurfacePointer) {
        super(context, svcb, guiSurfaceId, savedSurfacePointer);
    }

    private static native boolean loadFileS(int ptr, String fileName);

    private static native void setOperatorOrbitV(int ptr);

    private static native void setOperatorZoomAreaV(int ptr);

    private static native void setOperatorFlyV(int ptr);

    private static native void setOperatorSelectPointV(int ptr);

    private static native void setOperatorSelectAreaV(int ptr);

    private static native void onModeSimpleShadowZ(int ptr, boolean enable);

    private static native void onModeSmoothV(int ptr);

    private static native void onModeHiddenLineV(int ptr);

    private static native void onModeFrameRateV(int ptr);

    private static native void onUserCode1V(int ptr);

    private static native void onUserCode2V(int ptr);

    private static native void onUserCode3V(int ptr);

    private static native void onUserCode4V(int ptr);

    public boolean loadFile(String fileName) {
        return loadFileS(mSurfacePointer, fileName);
    }


    public void setOperatorOrbit() {
        setOperatorOrbitV(mSurfacePointer);
    }


    public void setOperatorZoomArea() {
        setOperatorZoomAreaV(mSurfacePointer);
    }


    public void setOperatorFly() {
        setOperatorFlyV(mSurfacePointer);
    }


    public void setOperatorSelectPoint() {
        setOperatorSelectPointV(mSurfacePointer);
    }


    public void setOperatorSelectArea() {
        setOperatorSelectAreaV(mSurfacePointer);
    }


    public void onModeSimpleShadow(boolean enable) {
        onModeSimpleShadowZ(mSurfacePointer, enable);
    }


    public void onModeSmooth() {
        onModeSmoothV(mSurfacePointer);
    }


    public void onModeHiddenLine() {
        onModeHiddenLineV(mSurfacePointer);
    }


    public void onModeFrameRate() {
        onModeFrameRateV(mSurfacePointer);
    }


    public void onUserCode1() {
        onUserCode1V(mSurfacePointer);
    }


    public void onUserCode2() {
        onUserCode2V(mSurfacePointer);
    }


    public void onUserCode3() {
        onUserCode3V(mSurfacePointer);
    }


    public void onUserCode4() {
        onUserCode4V(mSurfacePointer);
    }


}


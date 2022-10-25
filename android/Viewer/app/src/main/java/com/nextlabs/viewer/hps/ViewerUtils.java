package com.nextlabs.viewer.hps;

public class ViewerUtils {
    public final static String FONT_DIRECTORY_PATH = "file:///android_asset/fonts";
    public final static String MATERIAL_DIRECTORY_PATH = "file:///android_asset/materials";

    private static boolean mNativeLibsLoaded = false;

    public static void LoadNativeLibs() {
        if (!mNativeLibsLoaded) {
            System.loadLibrary("gnustl_shared");
            System.loadLibrary("hps_core");
            System.loadLibrary("hps_sprk");
            System.loadLibrary("hps_sprk_ops");
            System.loadLibrary("hpsviewer");
            mNativeLibsLoaded = true;
        }
    }
}

package com.nextlabs.viewer.hps;

// Auto-generated file

public class MobileApp {
    private static native void setFontDirectoryS(String fontDir);

    private static native void setMaterialsDirectoryS(String materialsDir);

    public static void setFontDirectory(String fontDir) {
        setFontDirectoryS(fontDir);
    }


    public static void setMaterialsDirectory(String materialsDir) {
        setMaterialsDirectoryS(materialsDir);
    }


}


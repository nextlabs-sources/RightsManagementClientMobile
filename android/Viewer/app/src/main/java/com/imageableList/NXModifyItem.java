package com.imageableList;

/**
 * Created by snowman on 7/29/2015.
 */
public class NXModifyItem {
    private String mModifyName;
    private String mModifyValue;
    private int mImag;

    public NXModifyItem(String name, String value, int imge) {
        mModifyName = name;
        mModifyValue = value;
        mImag = imge;
    }

    public String getModifyName() {
        return mModifyName;
    }

    public String getmModifyValue() {
        return mModifyValue;
    }

    public int getmImag() {
        return mImag;
    }
}

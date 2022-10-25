package com.imageableList;

/**
 * Created by snowman on 7/23/2015.
 */
public class NXProfileRightsItem {
    private String mRightName;
    private boolean mIfChecked;

    public NXProfileRightsItem(String name, boolean checked) {
        mRightName = name;
        mIfChecked = checked;
    }

    public String getmRightName() {
        return mRightName;
    }

    public boolean getmIFChecked() {
        return mIfChecked;
    }
}

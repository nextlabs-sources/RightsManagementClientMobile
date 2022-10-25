package com.imageableList;

/**
 * Created by snowman on 7/23/2015.
 */
public class NXProfileCommonattributeItem {
    private String mAttributeName;
    private String mAttributeValue;

    public NXProfileCommonattributeItem(String name, String value) {
        mAttributeName = name;
        mAttributeValue = value;
    }

    public String getmAttributeName() {
        return mAttributeName;
    }

    public String getmAttributeValue() {
        return mAttributeValue;
    }
}

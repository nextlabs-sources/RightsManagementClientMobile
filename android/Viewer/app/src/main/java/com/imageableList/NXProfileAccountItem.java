package com.imageableList;

public class NXProfileAccountItem {
    private String mName;
    private String mValue;

    public NXProfileAccountItem(String name, String value) {
        mName = name;
        mValue = value;
    }

    public String getName() {
        return mName;
    }

    public String getValue() {
        return mValue;
    }
}

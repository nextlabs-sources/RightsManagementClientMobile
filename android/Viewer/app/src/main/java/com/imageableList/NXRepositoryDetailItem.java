package com.imageableList;

public class NXRepositoryDetailItem {
    private String mItemName;
    private String mItemValue;

    public NXRepositoryDetailItem(String name, String value) {
        mItemName = name;
        mItemValue = value;
    }

    public String getItmeName() {
        return mItemName;
    }

    public String getItemValue() {
        return mItemValue;
    }
}

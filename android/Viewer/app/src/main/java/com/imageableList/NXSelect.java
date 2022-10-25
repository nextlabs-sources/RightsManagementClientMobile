package com.imageableList;

public class NXSelect {
    private int imageId;
    private String itemName;

    public NXSelect(int imageId, String itemName) {
        this.imageId = imageId;
        this.itemName = itemName;
    }

    public int getImageId() {
        return this.imageId;
    }

    public String getItemName() {
        return this.itemName;
    }
}

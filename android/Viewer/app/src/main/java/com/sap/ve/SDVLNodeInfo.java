package com.sap.ve;

import com.sap.ve.DVLTypes.DVLNODEFLAG;

import java.util.ArrayList;

public class SDVLNodeInfo extends ListSelectionItem {
    public long nodeID;
    public String nodeName;
    public String assetID;
    public String uniqueID;
    public ArrayList<Long> parentNodes = new ArrayList<Long>();
    public ArrayList<Long> childNodes = new ArrayList<Long>();
    public int flags;
    public float opacity;
    public int highlightColor;
    public ArrayList<SDVLURI> uriList = new ArrayList<SDVLURI>();

    public boolean isVisible() {
        return (flags & DVLNODEFLAG.VISIBLE) != 0;
    }

    public boolean isSelected() {
        return (flags & DVLNODEFLAG.SELECTED) != 0;
    }

    @Override
    public String toString() {
        return nodeName;
    }

    @Override
    public boolean equals(Object o) {
        return (o instanceof SDVLNodeInfo) && (this.nodeID == ((SDVLNodeInfo) o).nodeID);
    }
}

package com.TagList;

import java.util.ArrayList;
import java.util.List;

public class Node {
    private int id;

    // root node pid
    private int pId = -1;
    private int subValueId;
    private String tagName;
    private String displayName;
    private String defaultValue;
    private String value;
    private boolean multipleSelect;
    private boolean mandatory;
    private int priority;
    private boolean flagRed;
    // current level
    private int level;
    private boolean isExpand = true;
    private int icon;
    private List<Node> children = new ArrayList<Node>();
    private Node parent;
    private boolean isChecked = false;

    public Node() {

    }

    public Node(int id, int pId, int subValueId, String tagName, String displayName, String defaultValue, boolean multipleSelect, boolean mandatory, int priority) {
        super();
        this.id = id;
        this.pId = pId;
        this.subValueId = subValueId;
        this.tagName = tagName;
        this.displayName = displayName;
        this.value = defaultValue;
        this.defaultValue = defaultValue;
        this.multipleSelect = multipleSelect;
        this.mandatory = mandatory;
        this.priority = priority;

    }

    public boolean getChecked() {
        return this.isChecked;
    }

    public void setChecked(boolean isChecked) {
        this.isChecked = isChecked;
    }

    public boolean getFlagRed() {
        return flagRed;
    }

    public void setFlagRed(boolean bFlag) {
        this.flagRed = bFlag;
    }

    public int getPriority() {
        return priority;
    }

    public int getIcon() {
        return icon;
    }

    public void setIcon(int icon) {
        this.icon = icon;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getpId() {
        return pId;
    }

    public void setpId(int pId) {
        this.pId = pId;
    }

    public int getSubValueId() {
        return subValueId;
    }

    public void setSubValueId(int subValueId) {
        this.subValueId = subValueId;
    }

    public String getTagName() {
        return tagName;
    }

    public void setTagName(String tagName) {
        this.tagName = tagName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getDefaultValue() {
        return defaultValue;
    }

    public void setDefaultValue(String defaultValue) {
        this.defaultValue = defaultValue;
    }

    public String getValue() {
        return value;
    }

    public boolean getMultipleSelect() {
        return multipleSelect;
    }

    public void setMultipleSelect(boolean multipleSelect) {
        this.multipleSelect = multipleSelect;
    }

    public boolean getMandatory() {
        return mandatory;
    }

    public boolean isExpand() {
        return isExpand;
    }

    public void setExpand(boolean isExpand) {
        this.isExpand = isExpand;
    }

    // contains its tag nodes and value nodes.
    public List<Node> getChildren() {
        return children;
    }

    public void setChildren(List<Node> children) {
        this.children = children;
    }

    public Node getParent() {
        return parent;
    }

    public void setParent(Node parent) {
        this.parent = parent;
    }

    public boolean isRoot() {
        return parent == null;
    }

    public boolean isParentExpand() {
        if (parent == null)
            return false;
        return parent.isExpand();
    }

    public boolean isLeaf() {
        return children.size() == 0;
    }

    public int getLevel() {
        return parent == null ? 0 : parent.getLevel() + 1;
    }

    public void setLevel(int level) {
        this.level = level;
    }

}


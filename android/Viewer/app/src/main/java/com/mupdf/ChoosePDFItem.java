package com.artifex.mupdfdemo;

public class ChoosePDFItem {
    final public Type type;
    final public String name;

    public ChoosePDFItem(Type t, String n) {
        type = t;
        name = n;
    }

    enum Type {
        PARENT, DIR, DOC
    }
}

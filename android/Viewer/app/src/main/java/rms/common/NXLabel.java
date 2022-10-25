package rms.common;

public class NXLabel {
    public int defaultValue;
    public boolean bMultiSelect;
    public boolean bMandatory;
    public String displayName;
    public String name;
    public int id;
    public NXValue value;

    public NXLabel() {
        defaultValue = -1;
        bMultiSelect = false;
        bMandatory = false;
        displayName = null;
        name = null;
        id = -1;
        value = new NXValue();
    }
}

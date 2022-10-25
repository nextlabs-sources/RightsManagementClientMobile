package rms.common;

import nxl.types.INxFile;

public class NXWatermarkInfo {
    public String serialNumber;
    // content
    public String text;
    public int transparentRatio;
    public String fontName;
    public int fontSize;
    public String fontColor;
    public String rotation;
    public boolean bRepeat;
    public String density;

    public NXWatermarkInfo() {
        text = null;
        transparentRatio = -1;
        fontName = null;
        fontSize = -1;
        fontColor = null;
        rotation = null;
        bRepeat = false;
        density = null;
    }
}

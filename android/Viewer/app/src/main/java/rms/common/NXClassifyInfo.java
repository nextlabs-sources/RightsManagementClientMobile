package rms.common;

import java.util.ArrayList;
import java.util.List;

public class NXClassifyInfo {
    public String serialNumber;
    public int profile_default;
    public List<NXLabel> labels;

    public NXClassifyInfo() {
        serialNumber = null;
        profile_default = -1;
        labels = new ArrayList<>();
    }

}

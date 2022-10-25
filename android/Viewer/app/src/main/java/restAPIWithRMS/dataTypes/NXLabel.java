package restAPIWithRMS.dataTypes;

import java.util.ArrayList;
import java.util.List;


public class NXLabel {
    public String name;
    public String displayName;
    public boolean mandatory;
    public boolean multipleSelection;
    public int defaultValueId;
    public int id;
    public List<NXValue> values;

    public NXLabel() {
        name = null;
        displayName = null;
        mandatory = false;
        multipleSelection = false;
        defaultValueId = -1;
        id = -1;
        values = new ArrayList<>();
    }
}

package restAPIWithRMS.dataTypes;

import java.util.ArrayList;
import java.util.List;


public class NXKeyRing {
    public String keyRingName;
    public String lastModifiedDate;
    public List<NXKey> keys;

    public NXKeyRing() {
        keyRingName = null;
        lastModifiedDate = null;
        keys = new ArrayList<>();
    }
}

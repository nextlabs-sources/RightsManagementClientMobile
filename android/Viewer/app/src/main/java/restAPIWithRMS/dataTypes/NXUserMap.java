package restAPIWithRMS.dataTypes;

import java.util.HashSet;
import java.util.Set;

/**
 * Created by oye on 12/10/2015.
 */
public class NXUserMap {
    public String idName;
    public long context;
    public Set<Integer> group;

    public NXUserMap() {
        idName = null;
        context = -1;
        group = new HashSet<>();
    }
}

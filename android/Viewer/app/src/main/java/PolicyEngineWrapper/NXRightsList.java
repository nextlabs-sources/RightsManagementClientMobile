package PolicyEngineWrapper;

import java.util.ArrayList;
import java.util.List;

/**
 * This class is change the rights' bool value to string
 * The String is defined by eric, just for test.
 */
public class NXRightsList {
    public static List<String> getRightsList(NXRights mRights) {
        List<String> list = new ArrayList<>();
        if (mRights.hasView()) {
            list.add("RIGHTS_VIEW");
        } else if (mRights.hasClassify()) {
            list.add("RIGHTS_CLASSIFY");
        } else if (mRights.hasCopy()) {
            list.add("RIGHTS_COPY");
        } else if (mRights.hasSend()) {
            list.add("RIGHTS_SEND");
        } else if (mRights.hasShare()) {
            list.add("RIGHTS_SHARE");
        }
        return list;
    }
}

package PolicyEngineWrapper;

import java.util.Map;
import java.util.Vector;

/**
 * Created by wwu on 7/23/2015.
 */
public class NXRights {
    private boolean bView = false;
    private boolean bClassify = false;
    private boolean bCopy = false;
    private boolean bSend = false;
    private boolean bShare = false;
    private Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> Obligations;

    public NXRights() {

    }

    public NXRights(int Rights, Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> Obligations) {
        if ((Rights & 1) != 0) {
            bView = true;
        }

        if ((Rights & 2) != 0) {
            bClassify = true;
        }

        if ((Rights & 4) != 0) {
            bCopy = true;
        }

        if ((Rights & 8) != 0) {
            bSend = true;
        }

        if ((Rights & 16) != 0) {
            bShare = true;
        }

        this.Obligations = Obligations;
    }

    public boolean hasView() {
        return bView;
    }

    public boolean hasClassify() {
        return bClassify;
    }

    public boolean hasCopy() {
        return bCopy;
    }

    public boolean hasSend() {
        return bSend;
    }

    public boolean hasShare() {
        return bShare;
    }

    public Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> getObligations() {
        return Obligations;
    }
}

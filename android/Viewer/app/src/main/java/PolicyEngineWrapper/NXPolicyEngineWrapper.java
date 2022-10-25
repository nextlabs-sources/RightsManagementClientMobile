package PolicyEngineWrapper;

import android.util.Log;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Vector;

/**
 * Created by wwu on 7/23/2015.
 */
public class NXPolicyEngineWrapper {
    final private static String TAG = "GETRIGHTS";
    private static Vector<Map.Entry<String, String>> mHitPolicy;

    static {
        System.loadLibrary("PolicyEngine");
    }

    public static NXRights GetRights(String uid, HashMap<String, Vector<String>> tags, String xmlfile) {
        //@todo delete, now that only print parama

        Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> Obligations = new Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>>();
        Vector<Map.Entry<String, String>> hitPolicy = new Vector<>();

        //if the xmlfile value is null, it is not necessary to parse rights.
        if (xmlfile == null) {
            return new NXRights(0, Obligations);
        }
        int Rights = GetRightsViaJni("", uid, tags, xmlfile.getBytes(), Obligations, hitPolicy);

        mHitPolicy = hitPolicy;

        StringBuffer msg = new StringBuffer();
        msg.append("UID:" + uid + "\n");
        Map map = new HashMap();
        Iterator iter = map.entrySet().iterator();
        while (iter.hasNext()) {
            Map.Entry entry = (Map.Entry) iter.next();
            Object key = entry.getKey();
            Object val = entry.getValue();
            msg.append(key + " = " + val + "\n");
        }
        Log.e(TAG, msg.toString());

        return new NXRights(Rights, Obligations);
    }

    public static Vector<Map.Entry<String, String>> getHitPolicy() {
        return mHitPolicy;
    }

    native static int GetRightsViaJni(String username, String uid, HashMap<String, Vector<String>> tags, byte[] xmlcontent, Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> Obligations, Vector<Map.Entry<String, String>> hitPolicy);
}

package nxl.fileFormat;

import android.util.Log;
import android.util.Pair;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Vector;


public class Tags {
    private ArrayList<Pair<String, String>> tags = new ArrayList<>();

    public byte[] toUnicodeByteArray() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < tags.size(); ++i) {
            Pair<String, String> pair = tags.get(i);

            sb.append(pair.first);
            sb.append("=");
            sb.append(pair.second);
            sb.append('\0');
        }
        sb.append('\0');

        byte[] rt = null;
        try {
            rt = sb.toString().getBytes("UnicodeLittleUnmarked");
        } catch (Exception e) {
            Log.e("TAGS", e.toString());
        }

        return rt;
    }

    public HashMap<String, Vector<String>> toHashMap() {

        HashMap<String, Vector<String>> rt = new HashMap<String, Vector<String>>();

        for (Pair<String, String> p : tags) {
            // set key
            String key = p.first;
            // set valuse
            String value = p.second;

            if (rt.containsKey(key)) {
                Vector<String> v = rt.get(key);
                v.add(value);

            } else {
                Vector<String> v = new Vector<>();
                v.add(value);

                rt.put(key, v);
            }
        }
        return rt;
    }

    public void fromHashMap(HashMap<String, Vector<String>> m) {

        for (HashMap.Entry<String, Vector<String>> p : m.entrySet()) {
            // set key
            String key = p.getKey();
            // set value
            StringBuffer sb = new StringBuffer();
            for (String s : p.getValue()) {
                sb.append(s);
                sb.append(',');
            }
            String value = sb.toString();
            // add into Tag
            addItem(key, value);
        }
    }

    public void clear() {
        tags.clear();
    }

    public void fromUnicodeBuffer(byte[] unicodeBuffer) {

        try {

            String str = new String(unicodeBuffer, "UnicodeLittleUnmarked");
            String[] strs = str.split("=|\0");
            int c = strs.length;
            if (c % 2 == 0) {
                for (int i = 0; i < c; i = i + 2) {
                    addItem(strs[i], strs[i + 1]);
                }
                return;
            }

        } catch (Exception e) {
            Log.e("TAGS", e.toString());
        }
    }

    public void fromString(String tags) {

        String[] theTags = tags.split("=|\0");
        int c = theTags.length;
        if (c % 2 == 0) {
            for (int i = 0; i < c; i = i + 2) {
                addItem(theTags[i], theTags[i + 1]);
            }
            return;
        }
    }


    public void addItem(String key, String value) {
        tags.add(Pair.create(key, value));
    }

    public ArrayList<Pair<String, String>> getTags() {
        return tags;
    }
}

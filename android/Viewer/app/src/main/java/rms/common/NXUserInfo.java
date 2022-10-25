package rms.common;

import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by aning on 8/8/2016.
 */
public class NXUserInfo {

    // extra
    private int userId;
    private String ticket;
    private String tenantId;
    private long ttl;
    private String name;
    private String email;
    // memberships
    private String id;
    private int type;
    // raw json string
    private String rawJSON;

    public NXUserInfo() {
        ticket = null;
        tenantId = null;
        ttl = -1;
        name = null;
        email = null;
        id = null;
        type = -1;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public int getUserId() {
        return userId;
    }

    public void setTicket(String ticket) {
        this.ticket = ticket;
    }

    public String getTicket() {
        return ticket;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTtl(long ttl) {
        this.ttl = ttl;
    }

    /**
     * any exceptions occured will be resulted to return Now Time
     */
    public long getTtl() {
        if (ttl == -1) {
            return System.currentTimeMillis();
        }

        return ttl;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getEmail() {
        return email;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getId() {
        return id;
    }

    public void setType(int type) {
        this.type = type;
    }

    public int getType() {
        return type;
    }

    public String getRawJSON() {
        return rawJSON;
    }

    public void setRawJSON(String rawJSON) {
        this.rawJSON = rawJSON;
    }

    public static NXUserInfo parseUserInfo(String jsonText) {
        NXUserInfo userInfo = new NXUserInfo();
        userInfo.setRawJSON(jsonText);
        try {

            JSONObject jsonObject = new JSONObject(jsonText);
            JSONObject extraJsonObject = jsonObject.getJSONObject("extra");
            int userId = extraJsonObject.getInt("userId");
            userInfo.setUserId(userId);
            String ticket = extraJsonObject.getString("ticket");
            userInfo.setTicket(ticket);
            String tenantId = extraJsonObject.getString("tenantId");
            userInfo.setTenantId(tenantId);
            long ttl = extraJsonObject.getLong("ttl");
            userInfo.setTtl(ttl);
            String name = extraJsonObject.getString("name");
            userInfo.setName(name);
            String email = extraJsonObject.getString("email");
            userInfo.setEmail(email);
            JSONArray jsonArray = extraJsonObject.getJSONArray("memberships");
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObj = (JSONObject) jsonArray.get(i);
                String id = jsonObj.getString("id");
                userInfo.setId(id);
                int type = jsonObj.getInt("type");
                userInfo.setType(type);
            }

        } catch (JSONException e) {
            e.printStackTrace();
        }

        return userInfo;
    }

}



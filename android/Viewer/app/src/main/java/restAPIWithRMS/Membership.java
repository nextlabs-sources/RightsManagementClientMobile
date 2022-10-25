package restAPIWithRMS;

import android.util.Base64;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.security.KeyPair;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import commonUtils.keyManager.DHManager;
import rms.common.NXUserInfo;

public class Membership {
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";
    static final String RMS_SERVICE_NAME = "/rs/membership";

    Request request = new Request();
    Response response = new Response();

    public void invokeToRMS(String rmsServer, NXUserInfo userInfo) throws Exception {
        request.userInfo = userInfo;

        URL url = new URL(rmsServer + RMS_SERVICE_NAME);
        // set head info
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, ""); // now ignore the certificate.

        InputStream is = HttpsPut.sendRequest(url, headInfo, request.generateJsonBody(), null);

        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder stringBuffer = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            stringBuffer.append(line);
        }
        reader.close();
        response.parseJsonData(stringBuffer.toString());
    }

    public String getPrivateKey() {
        return request.privateKey;
    }

    class Request {
        private NXUserInfo userInfo;
        private String privateKey;

        public String generateJsonBody() {
            String result = null;
            KeyPair keyPair = DHManager.generateDHKeyPair();
            privateKey = Base64.encodeToString(keyPair.getPrivate().getEncoded(), Base64.DEFAULT);
            try {
                JSONObject membershipJson = new JSONObject();

                JSONObject parameters = new JSONObject();
                parameters.put("userId", userInfo.getUserId());
                parameters.put("ticket", userInfo.getTicket());
                parameters.put("membership", userInfo.getId());

                String publicKey = Base64.encodeToString(keyPair.getPublic().getEncoded(), Base64.DEFAULT);
                parameters.put("publicKey", publicKey);
                membershipJson.put("parameters", parameters);

                result = membershipJson.toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }

            return result;
        }
    }

    public String getCertificates() {
        return response.certificates;
    }

    class Response {
        private String certificates;

        public void parseJsonData(String responseData) {
            try {
                JSONObject jsData = new JSONObject(responseData);
                int statusCode = jsData.getInt("statusCode");
                String message = jsData.getString("message");

                if (statusCode == 200 && "OK".equals(message)) {
                    JSONObject results = jsData.getJSONObject("results");
                    certificates = results.getString("certficates");
                } else {
                    throw new RuntimeException("can't get the right response!!");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

}

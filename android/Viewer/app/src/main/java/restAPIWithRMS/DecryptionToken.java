package restAPIWithRMS;


import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import appInstance.ViewerApp;
import nxl.bridge.NxlFingerPrint;
import rms.common.NXUserInfo;

/**
 * Created by aning on 8/18/2016.
 */
public class DecryptionToken {
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";
    static final String RMS_SERVICE_NAME = "/rs/token";

    Request request = new Request();
    Response response = new Response();

    public void invokeToRMS(String rmsServer, NXUserInfo userInfo, NxlFingerPrint fingerPrint, String tenantId, String ml) throws Exception {
        request.userInfo = userInfo;
        request.tenantId = tenantId;
        request.ownerId = fingerPrint.ownerId;
        request.duid = fingerPrint.duid;
        request.ml = ml;
        request.aggrementKey = fingerPrint.rootAgreementKey;
        request.publicKeyInCA = fingerPrint.icaAgreementKey;

        URL url = new URL(rmsServer + RMS_SERVICE_NAME);
        // set head info
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, ""); // now ignore the certificate.

        InputStream is = HttpsPost.sendRequest(url, headInfo, request.generateJsonBody(), null);

        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder stringBuffer = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            stringBuffer.append(line);
        }
        reader.close();
        response.parseJsonData(stringBuffer.toString());
    }

    class Request {
        private NXUserInfo userInfo;
        private String tenantId;
        private String ownerId;
        private String duid;
        private String ml;
        private String aggrementKey;
        private String publicKeyInCA;

        public String generateJsonBody() {
            String result = null;
            //  String agreement = ViewerApp.getInstance().getSession().getAgreement();

            try {
                JSONObject decryptionTokenJson = new JSONObject();

                JSONObject parameters = new JSONObject();
                parameters.put("userId", userInfo.getUserId());
                parameters.put("ticket", userInfo.getTicket());
                parameters.put("tenant", tenantId);
                parameters.put("owner", ownerId);
                parameters.put("agreement", aggrementKey);
                parameters.put("duid", duid);
                parameters.put("ml", ml);

                decryptionTokenJson.put("parameters", parameters);
                result = decryptionTokenJson.toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }

            return result;
        }

    }

    public String getToken() {
        return response.token;
    }

    class Response {
        private String token = null;

        public void parseJsonData(String responseData) {
            try {
                JSONObject jsData = new JSONObject(responseData);
                int statusCode = jsData.getInt("statusCode");
                String message = jsData.getString("message");

                if (statusCode == 200 && "OK".equals(message)) {
                    JSONObject results = jsData.getJSONObject("results");
                    token = results.getString("token");

                } else {
                    throw new RuntimeException("can't get the right response!!");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}

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
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import appInstance.ViewerApp;
import commonUtils.keyManager.DHManager;
import rms.common.NXUserInfo;

/**
 * Created by aning on 8/18/2016.
 */
public class EncryptionTokens {
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";
    static final String RMS_SERVICE_NAME = "/rs/token";

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

    public List<String> getAgreements() {
        return request.agreements;
    }

    class Request {
        private NXUserInfo userInfo;
        private List<String> agreements;

        public String generateJsonBody() {
            String result = null;
            String certificates = ViewerApp.getInstance().getSession().getCertificates();
            List<String> pubKeys = DHManager.extractPubKey(certificates);
            agreements = DHManager.getAgreementsPublicKey(pubKeys);
            // String  agreement = DHManager.getAgreementPublicKey(pubKeys);
            // get the last public key

            try {
                JSONObject encryptionTokenJson = new JSONObject();

                JSONObject parameters = new JSONObject();
                parameters.put("userId", userInfo.getUserId());
                parameters.put("ticket", userInfo.getTicket());
                parameters.put("membership", userInfo.getId());
                // agreement.
                if (agreements != null && agreements.size() > 0) {
                    parameters.put("agreement", agreements.get(agreements.size() - 1));
                }

                parameters.put("count", "100");

                encryptionTokenJson.put("parameters", parameters);

                result = encryptionTokenJson.toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }

            return result;
        }
    }

    public Map<String, String> getMapTokens() {
        return response.mapTokens;
    }

    public int getMl() {
        return Integer.valueOf(response.ml);
    }

    class Response {

        private String ml;
        private Map<String, String> mapTokens = new HashMap<>();

        public void parseJsonData(String responseData) {
            try {
                JSONObject jsData = new JSONObject(responseData);
                int statusCode = jsData.getInt("statusCode");
                String message = jsData.getString("message");

                if (statusCode == 200 && "OK".equals(message)) {
                    JSONObject results = jsData.getJSONObject("results");
                    ml = results.getString("ml");
                    JSONObject tokensJson = results.getJSONObject("tokens");

                    String duid = null;
                    String token = null;
                    Iterator iter = tokensJson.keys();
                    while (iter.hasNext()) {
                        duid = (String) iter.next();
                        token = tokensJson.getString(duid);
                        mapTokens.put(duid, token);
                    }

                } else {
                    throw new RuntimeException("can't get the right response!!");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}

package restAPIWithRMS;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.InputStream;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

public class RouterLoginURL {
    private static final String RMS_SERVICE_NAME = "/router/rs/q/tenant/";

    Response response = new Response();

    public Response invokeToRMS(String rmServer, String tenant, Listener listener) throws Exception {

        // set uri
        URL url = new URL(rmServer + RMS_SERVICE_NAME + tenant); // testskydrm.com
        // URL url = new URL("https://testskydrm.com");

        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        // send request
        String result = HttpsGet.sendGetRequest(url, headInfo, listener);
        response.parseJson(result);
        return response;
    }

    public class Response {
        private String loginPageUrl = null;

        // status
        int errorCode;
        String errorMsg;

        public String getLoginPageUrl() {
            return loginPageUrl;
        }

        public int getErrorCode() {
            return errorCode;
        }

        public String getErrorMsg() {
            return errorMsg;
        }

        private void parseJson(String json) {
            // {"statusCode":200,"message":"OK","results":{"server":"https://rmtest.nextlabs.solutions/rms"}}
            try {
                JSONObject jsonObject = new JSONObject(json);
                errorCode = jsonObject.getInt("statusCode");
                errorMsg = jsonObject.getString("message");
                JSONObject resultJsonObject = jsonObject.getJSONObject("results");
                loginPageUrl = resultJsonObject.getString("server");
            } catch (JSONException e) {
                e.printStackTrace();
            }

        }
    }
}

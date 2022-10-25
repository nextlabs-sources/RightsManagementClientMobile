package restAPIWithRMS;

import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;

import java.io.InputStream;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

@Deprecated
public class GetAuthUrl {
    static final String RMS_SERVICE_NAME = "/RMS/service/GetAuthURL";
    static final String RMS_SERVICE_PREFIX = "https://";
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";

    Response response = new Response();

    public Response invokeToRMS(String rmServer, String certificate, Listener listener) throws Exception {

//        // set uri
//        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
//        // set headinfo
//        Map<String, String> headInfo = new HashMap<>();
//        headInfo.put(HEADER_CERT_KEY, certificate);
//        // send request
//        InputStream ins = HttpsGet.sendGetRequest(url, headInfo, listener);
//        response.parseXml(ins);
        return response;
    }

    public class Response {
        private String AuthURL;

        public String getAuthURL() {
            return AuthURL;
        }

        private void parseXml(InputStream inputStream) throws Exception {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(inputStream, "utf-8");

            int eventType = parser.next();
            while (eventType != parser.END_DOCUMENT) {
                if (parser.getName().equalsIgnoreCase("AuthURL")) {
                    AuthURL = parser.nextText();
                }
                eventType = parser.next();
            }
        }
    }
}

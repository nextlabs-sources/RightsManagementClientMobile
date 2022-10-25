package restAPIWithRMS;

import android.provider.DocumentsContract;
import android.util.Xml;

import com.google.gson.JsonIOException;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.xmlpull.v1.XmlPullParser;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;

import commonUtils.xml.XmlParseTemplate;
import rms.common.NXClassifyInfo;
import rms.common.NXClientInfo;
import rms.common.NXLabel;
import rms.common.NXValue;
import rms.common.NXWatermarkInfo;

/**
 * Created by aning on 8/10/2016.
 */
public class HeartBeat2 {
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";
    static final String RMS_SERVICE_NAME = "/rs/heartbeat?tenant=skydrm.com";

    Request request = new Request();
    Response response = new Response();


    public void invokeToRMS(String rmsServer, String ticket, String userId) throws Exception {
        request.ticket = ticket;
        request.userId = userId;

        URL url = new URL(rmsServer + RMS_SERVICE_NAME);
        // set head info
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, ""); // now ignore the certificate.

        InputStream is = HttpsPost.sendRequest(url, headInfo, request.generateJson(), null);

        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder stringBuffer = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            stringBuffer.append(line);
        }
        reader.close();
        response.rawNetworkContent = stringBuffer.toString();
        response.parseJsonData(stringBuffer.toString());
    }

    /**
     * I know this function may be eccentric, but as requirements, we must support that response can be used at no network environment
     * the current solution is: if in no network environment, then parseResponse use latest cache xml file
     *
     * @param rawJsonResponse use getRawNetStreamContent(); or unserialize file from disk
     * @throws Exception
     */
    public void parseResponseManually(String rawJsonResponse) throws Exception {
        response.clear();
        //  InputStream ins = new ByteArrayInputStream(rawXMLResponse.getBytes(Charset.forName("UTF-8")));
        response.parseJsonData(rawJsonResponse);
    }

    public String getRawNetStreamContent() {
        return response.rawNetworkContent;
    }

    public String setRawNetStreamContent(String responseJson) {
        return response.rawNetworkContent = responseJson;
    }

    class Request {
        private String ticket = null;
        private int platformId = 0;
        private String userId = null;

        public String generateJson() {
            String result = null;
            try {
                JSONObject jsText = new JSONObject();
                JSONObject jsParameter = new JSONObject();

                jsParameter.put("ticket", ticket);

                JSONArray jsonArrayObjects = new JSONArray();
                JSONObject policyBundle = new JSONObject();
                policyBundle.put("name", "policyBundle");
                policyBundle.put("serialNumber", "");
                jsonArrayObjects.put(policyBundle);

                JSONObject clientConfig = new JSONObject();
                clientConfig.put("name", "clientConfig");
                clientConfig.put("serialNumber", "");
                jsonArrayObjects.put(clientConfig);

                JSONObject classifyConfig = new JSONObject();
                classifyConfig.put("name", "classifyConfig");
                classifyConfig.put("serialNumber", "");
                jsonArrayObjects.put(classifyConfig);

                JSONObject watermarkConfig = new JSONObject();
                watermarkConfig.put("name", "watermarkConfig");
                watermarkConfig.put("serialNumber", "");
                jsonArrayObjects.put(watermarkConfig);

                jsParameter.put("objects", jsonArrayObjects);
                jsParameter.put("platformId", platformId);
                jsParameter.put("userId", userId);

                jsText.put("parameters", jsParameter);

                result = jsText.toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return result;
        }
    }

    class Response {

        private NXClassifyInfo classifyInfo = new NXClassifyInfo();
        private NXWatermarkInfo watermarkInfo = new NXWatermarkInfo();
        private NXClientInfo clientInfo = new NXClientInfo();
        private String rawNetworkContent;

        public void clear() {
            // todo
        }

        public void parseJsonData(String data) {
            try {
                JSONObject jsData = new JSONObject(data);
                int statusCode = jsData.getInt("statusCode");
                String message = jsData.getString("message");

                if (statusCode == 200 && "OK".equals(message)) {

                    JSONObject results = jsData.getJSONObject("results");
                    JSONObject classifyConfig = results.getJSONObject("classifyConfig");
                    classifyInfo.serialNumber = classifyConfig.getString("serialNumber");
                    parseXML(classifyConfig.getString("content"));

                    //  JSONObject watermarkConfig = results.getJSONObject("watermarkConfig");  // the json from rms format error !!!
                    String watermarkConfig = results.getString("watermarkConfig");
                    JSONObject watermarkConfigJSO = new JSONObject(watermarkConfig);
                    watermarkInfo.serialNumber = watermarkConfigJSO.getString("serialNumber");

                    // parse watermark content
                    //   JSONObject watermarkContent = watermarkConfigJSO.getJSONObject("content"); // the json from rms format error !!!
                    String watermarkContent = watermarkConfigJSO.getString("content");
                    JSONObject watermarkContentJSO = new JSONObject(watermarkContent);

                    watermarkInfo.text = watermarkContentJSO.getString("text");
                    watermarkInfo.transparentRatio = watermarkContentJSO.getInt("transparentRatio");
                    watermarkInfo.fontName = watermarkContentJSO.getString("fontName");
                    watermarkInfo.fontSize = watermarkContentJSO.getInt("fontSize");
                    watermarkInfo.fontColor = watermarkContentJSO.getString("fontColor");
                    watermarkInfo.rotation = watermarkContentJSO.getString("rotation");
                    watermarkInfo.bRepeat = watermarkContentJSO.getBoolean("repeat");
                    watermarkInfo.density = watermarkContentJSO.getString("density");

                    JSONObject clientConfig = results.getJSONObject("clientConfig");
                    clientInfo.serialNumber = clientConfig.getString("serialNumber");

                    // parse client content
                    // JSONObject clientContent = clientConfig.getJSONObject("content");
//                    String clientContent = clientConfig.getString("content");
//                    JSONObject clientContentJSO = new JSONObject(clientContent);
//                    clientInfo.platformId = clientContentJSO.getInt("platformId");
//                    clientInfo.heartbeatInterval = clientContentJSO.getLong("heartbeatInterval");
//                    clientInfo.logInterval = clientContentJSO.getLong("logInterval");
//                    clientInfo.bypassFilter = clientContentJSO.getString("bypassFilter");
//                    JSONObject protection = clientContentJSO.getJSONObject("protection");
//                    clientInfo.bProtectionEnabled = protection.getBoolean("enabled");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }

        }

        private void parseXML(String xmlData) throws Exception {

            InputStream ins = new ByteArrayInputStream(xmlData.getBytes());
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(ins, "utf-8");
            XmlParseTemplate.moveToTag(parser, "Classify");
            XmlParseTemplate.parse(parser, "Classify", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("Profiles")) {
                        parseProfile(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("LabelList")) {
                        parseLabels(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseProfile(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "Profiles", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("Default")) {
                        classifyInfo.profile_default = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseLabels(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "LabelList", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("Label")) {
                        classifyInfo.labels.add(parseLabel(parser));
                        return true;
                    }
                    return false;
                }
            });
        }

        private NXLabel parseLabel(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "Label");
            NXLabel label = new NXLabel();

            label.defaultValue = Integer.valueOf(parser.getAttributeValue(null, "default-value"));
            label.bMultiSelect = Boolean.valueOf(parser.getAttributeValue(null, "multi-select"));
            label.bMandatory = Boolean.valueOf(parser.getAttributeValue(null, "mandatory"));
            label.displayName = parser.getAttributeValue(null, "display-name");
            label.name = parser.getAttributeValue(null, "name");
            label.id = Integer.valueOf(parser.getAttributeValue(null, "id"));

            while (parser.next() != XmlPullParser.END_TAG) {
                if (parser.getEventType() != XmlPullParser.START_TAG) {
                    continue;
                }
                String name = parser.getName();
                if (name.equalsIgnoreCase("VALUE")) {
                    NXValue value = new NXValue();
                    value.labelValue = parser.getAttributeValue(null, "value");
                    value.priority = Integer.valueOf(parser.getAttributeValue(null, "priority"));
                    label.value = value;
                } else {
                    XmlParseTemplate.skipTag(parser);
                }
            }
            return label;
        }

    }
}



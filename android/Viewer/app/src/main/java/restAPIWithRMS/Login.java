package restAPIWithRMS;

import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlSerializer;

import java.io.InputStream;
import java.io.StringWriter;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import commonUtils.xml.XmlParseTemplate;


public class Login {
    static final String RMS_SERVICE_NAME = "/RMS/service/Login";
    static final String RMS_SERVICE_PREFIX = "https://";
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";

    Request request = new Request();
    Response response = new Response();

    /**
     * call Login to RMS
     *
     * @return - true: login ok. later user can get getSid()
     * - false: login error , later user can call getErrorCode() and getErrorMsg()
     * @throws Exception
     */
    public boolean invokeToRMS(String rmServer, String user, String password, String domain, String idpType, int agentId, String certificate) throws Exception {
        // set request params;
        request.user = user;
        request.password = password;
        request.domain = domain;
        request.idpType = idpType;
        request.agentId = agentId;
        // set uri
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, certificate);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), null);
        response.pareseXml(ins);
        return response.result;

    }

    public Response invokeToRMS(String rmServer, String certificate, Request request, Listener listener) throws Exception {

        // set uri
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, certificate);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), listener);
        response.pareseXml(ins);
        return response;
    }


    public class Request {
        public String user;
        public String password;
        public String domain;
        public String idpType;
        public int agentId;
        int tenantId = 2046; // no document , but is requeired
        int version = 1; // no document , but is requeired

        public String generateXml() {
            XmlSerializer serializer = Xml.newSerializer();
            StringWriter writer = new StringWriter(1024);
            try {
                serializer.setOutput(writer);
                serializer.startDocument("UTF-8", null);
                // LogService
                serializer.startTag(null, "LoginService");
                serializer.attribute(null, "tenantId", Integer.toString(tenantId));
                serializer.attribute(null, "agentId", Integer.toString(agentId));
                serializer.attribute(null, "version", Integer.toString(version));
                {
                    //LoginRequest
                    serializer.startTag(null, "LoginRequest");
                    {
                        writeTag(serializer, "UserName", user);
                        writeTag(serializer, "Password", password);
                        writeTag(serializer, "Domain", domain);
                        writeTag(serializer, "IdpType", idpType);
                    }
                    serializer.endTag(null, "LoginRequest");
                }
                serializer.endTag(null, "LoginService");
                serializer.endDocument();
                return writer.toString();

            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }

        private void writeTag(XmlSerializer serializer, String tagName, String tagText) throws Exception {
            serializer.startTag(null, tagName);
            serializer.text(tagText);
            serializer.endTag(null, tagName);
        }
    }

    public class Response {
        public boolean result;
        int errorCode = 0;
        String errorString = "ok";
        String sid;
        String principalName;

        public String getSID() {
            return sid;
        }

        public String getPrincipalName() {
            return principalName;
        }

        public int getErrorCode() {
            return errorCode;
        }

        public void setErrorCode(int code) {
            errorCode = code;
        }

        public String getErrorMessage() {
            return errorString;
        }

        public void setErrorMessage(String msg) {
            errorString = msg;
        }


        private void pareseXml(InputStream inputStream) throws Exception {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(inputStream, "utf-8");
            parser.nextTag();

            XmlParseTemplate.moveToTag(parser, "LoginResponse");
            XmlParseTemplate.parse(parser, "LoginResponse", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("LoginResult")) {
                        result = Boolean.parseBoolean(XmlParseTemplate.readText(parser));
                        if (result) {
                            errorCode = 0;
                            errorString = "ok,no error occurs";
                        } else {
                            XmlParseTemplate.moveToTag(parser, "Error");
                            parseLoginResult_Error(parser);
                        }
                        return true;
                    } else if (subTag.equalsIgnoreCase("UId")) {
                        sid = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("PrincipalName")) {
                        principalName = XmlParseTemplate.readText(parser);
                        return true;
                    }

                    return false;
                }
            });
        }

        private void parseLoginResult_Error(XmlPullParser parser) throws Exception {
            // parse Error tag
            XmlParseTemplate.parse(parser, "Error", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("ErrorCode")) {
                        errorCode = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("ErrorMessage")) {
                        errorString = XmlParseTemplate.readText(parser);
                        return true;
                    }
                    return false;
                }
            });
        }
    }


}

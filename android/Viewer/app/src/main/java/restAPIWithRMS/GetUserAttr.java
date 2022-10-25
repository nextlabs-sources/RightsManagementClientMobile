package restAPIWithRMS;

import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;

import java.io.InputStream;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import commonUtils.xml.XmlParseTemplate;
import errorHandler.ErrorCode;

public class GetUserAttr {
    static final String RMS_SERVICE_NAME = "/RMS/service/UserAttributesService";
    static final String RMS_SERVICE_PREFIX = "https://";
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";
    static final String GET_USER_ATTRIBUTE_REQUEST = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<p:UserAttributeRequest authRequestId=\"[authRequestId]\"\n" +
            "   xmlns:p=\"http://nextlabs.com/rms/rmc\" xmlns:types=\"http://nextlabs.com/rms/rmc/types\"\n" +
            "   xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n" +
            "   xsi:schemaLocation=\"http://nextlabs.com/rms/rmc UserAttributeService.xsd \">\n" +
            "</p:UserAttributeRequest>\n";

    Request request = new Request();
    Response response = new Response();

    public Response invokeToRMS(String rmServer, String certificate, String authReqId, Listener listener) throws Exception {

        request.authReqId = authReqId;
        // set uri
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, certificate);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), listener);
        response.parseXml(ins);
        return response;
    }

    private class Request {
        private String authReqId;

        public String generateXml() {
            return GET_USER_ATTRIBUTE_REQUEST.replace("[authRequestId]", authReqId);
        }
    }

    public class Response {
        // need these fields
        String lastName;
        String uid;
        String displayName;
        String givenName;
        String fullName;
        String userPrincipalName;
        String email;

        // status
        int errorCode;
        String errorMsg;

        public String getLastName() {
            return lastName;
        }

        public String getUid() {
            return uid;
        }

        public String getDisplayName() {
            return displayName;
        }

        public String getGivenName() {
            return givenName;
        }

        public String getFullName() {
            return fullName;
        }

        public String getUserPrincipalName() {
            return userPrincipalName;
        }

        public String getEmail() {
            return email;
        }

        public int getErrorCode() {
            return errorCode;
        }

        public String getErrorMsg() {
            return errorMsg;
        }

        private void parseXml(InputStream ins) throws Exception {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(ins, "utf-8");
            XmlParseTemplate.moveToTag(parser, "rmc:UserAttributeResponse");

            XmlParseTemplate.parse(parser, "rmc:UserAttributeResponse", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {

                    if (subTag.equalsIgnoreCase("attributes")) {
                        parseAttributes(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("status")) {
                        parseStatus(parser);
                        return true;
                    }
                    return false;

                }
            });
        }

        private void parseAttributes(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "attributes", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {   // subTag ---- attribute
                    if (subTag.equalsIgnoreCase("attribute")) {
                        parserAttribute(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseStatus(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "status", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {

                    if (subTag.equalsIgnoreCase("code")) {
                        errorCode = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("message")) {
                        errorMsg = XmlParseTemplate.readText(parser);
                        return true;
                    }

                    return false;
                }
            });
        }

        private void parserAttribute(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "attribute");
            String name = parser.getAttributeValue(null, "name");
            if (name != null) {
                if (name.equalsIgnoreCase("lastName")) {
                    lastName = parser.getAttributeValue(null, "value");
                    parser.next();  // skip end tag
                } else if (name.equalsIgnoreCase("uid")) {
                    uid = parser.getAttributeValue(null, "value");
                    parser.next();
                } else if (name.equalsIgnoreCase("displayName")) {
                    displayName = parser.getAttributeValue(null, "value");
                    parser.next();
                } else if (name.equalsIgnoreCase("givenName")) {
                    givenName = parser.getAttributeValue(null, "value");
                    parser.next();
                } else if (name.equalsIgnoreCase("fullName")) {
                    fullName = parser.getAttributeValue(null, "value");
                    parser.next();
                } else if (name.equalsIgnoreCase("userPrincipalName")) {
                    userPrincipalName = parser.getAttributeValue(null, "value");
                    parser.next();
                } else if (name.equalsIgnoreCase("email")) {
                    email = parser.getAttributeValue(null, "value");
                    parser.next();
                }

            }
        }

    }
}

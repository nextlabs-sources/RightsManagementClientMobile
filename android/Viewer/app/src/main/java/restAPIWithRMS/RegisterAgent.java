package restAPIWithRMS;

import android.os.Build;
import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlSerializer;

import java.io.InputStream;
import java.io.StringWriter;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import commonUtils.xml.XmlParseTemplate;


public class RegisterAgent {

    static final String RMS_SERVICE_NAME = "/RMS/service/RegisterAgent";
    static final String RMS_SERVICE_PREFIX = "https://";
    // the following two strings are fixed that is used to first communicate with RMS, it is document required ,and will be used as http request header
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";
    static final String HEADER_CERT_VALUE = "MIIDmzCCAoOgAwIBAgIEI8+FCTANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExEjAQBgNVBAcTCVNhbiBNYXRlbzERMA8GA1UEChMITmV4dExhYnMxGjAYBgNVBAsTEVJpZ2h0cyBNYW5hZ2VtZW50MR8wHQYDVQQDExZSaWdodHMgTWFuYWdlbWVudCBUZW1wMB4XDTE1MDUyNzE0MDI0MVoXDTI1MDUyNDE0MDI0MVowfjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRIwEAYDVQQHEwlTYW4gTWF0ZW8xETAPBgNVBAoTCE5leHRMYWJzMRowGAYDVQQLExFSaWdodHMgTWFuYWdlbWVudDEfMB0GA1UEAxMWUmlnaHRzIE1hbmFnZW1lbnQgVGVtcDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPUFAKjEmwL/oWQpafK5vOz8/dOEf9mmcjKawhxNhJJ5R+4olKHF9ZaKMve542ehSKngA53buaPsvP96ix7j8O8E2DHnYqbR5I9jNfZarIWjAwfO94TDvQovuIFBCWMnJXsRUtVm36cF6WpQdqctIbgvSbjGbgYacqGZ6QaaWrySGxupjyB8lfD6dYBG5lXFRcFA7QQVbNAGM7Xis2S3sPZOch4VJK7faX2xRyW6sIKL0FU8W9HCbm2PjG+XBr+dmsP3lk6HOqlSEy55HRYldMI/KCSlTGIcUHjH0qpiBxceSHILgY+YOqJ3l6/d8k9ui3MK2XGUhNFgwwLYFruk1l8CAwEAAaMhMB8wHQYDVR0OBBYEFGKcZJB9ZVJ6q/T2DNJIUoQEqx6sMA0GCSqGSIb3DQEBCwUAA4IBAQA9oFoR9GYVvba1WTdq2sl7kqTxqTPkUtD5LGi5A7q1yxMkAwsR2kW00L5dbRmADT7PjE3x42V2ZHHuYhDjGg/zm+2xHVrUWl2ZxHodmHz6+qDbdAZ3+9U4Zz7nt2oxDFghp/eE1adXa2kfAIZzn8VVamD6TS9O0R/KyXToYgpjLmz6QD9GFsz5wGbVsnJGWTxfiNjX3LnFIkqJU8rHn1DcMyB3/xd3ytUJzKrAnD8f46JpfR1amJOQAxiDy5+kW1OnclGBImS9iisvCmwU3+UNixbFAAxymBA9VvAO90sw0tHcLN7M1NSpenVlAnJTHhGuLSepk8gv4jAEsa9+DPKR";


    private Request request;
    private Response response;

    public RegisterAgent() {
        request = new Request();
        response = new Response();
    }

    /**
     * Remote call to rights management server and get its response over network.
     * -This function can not be called in UI thread ,as Android required, use it at background thread
     *
     * @param rmServer like :https://lam-javapc4.qapf1.qalab01.nextlabs.com:9443/RMS/service
     * @return class instance of Response
     * @throws Exception
     */
    public Response invokeToRMS(String rmServer, Listener listener) throws Exception {
        // set uri
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, HEADER_CERT_VALUE);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), listener);
        response.pareseXml(ins);
        return response;

    }


    public class Request {

        //String host = "Android";
        //like: Nexus 10-google-samsung:R12345678
        String host = "Android_" + Build.MODEL + "-" + Build.BRAND + ":" + Build.SERIAL;
        String type = "DESKTOP"; // one of DESKTOP,FILE_SERVER,PORTAL,ACTIVE_DIRECTORY

//        int version_major = 0; //Major version of the agent.
//        int version_minor = 0; //Minor version of the agent.
//        int version_maintenance = 0;//Maintenance version of the agent.
//        int version_patch = 0; //Build number of the agent.
//        int version_build = 0; //Build number of the agent.

//        String osInformation_osType = "";//
//        String osInformation_osVersion = "";//
//
//        String hardwareDetails_cpu = "";
//        int hardwareDetails_memoryAmount = 0;
//        String hardwareDetails_memoryUnits = "";
//        String hardwareDetails_macAddressList = "";
//        int hardwareDetails_deviceId = 0;
//
//        int groupInformation_groupId = 0;
//        String groupInformation_groupName = "";
//
//        String tenantId = "";


        public String generateXml() {

            XmlSerializer serializer = Xml.newSerializer();
            StringWriter writer = new StringWriter(1024);
            try {
                serializer.setOutput(writer);
                serializer.startDocument("UTF-8", null);
                // tag RegisterAgentRequest
                serializer.startTag("", "RegisterAgentRequest");
                {
                    // tag RegistrationData
                    serializer.startTag("", "RegistrationData");
                    {
                        {
                            writeTag(serializer, "host", host);
                            writeTag(serializer, "type", type);
                            serializer.startTag("", "version");
                            {
//                                String version = ViewerApp.getInstance().getVersionName();
//                                String[] s = version.split("\\.", 2);
//                                int majorVersion = Integer.parseInt(s[0]);
//                                int minorVersion = Integer.parseInt(s[1]);

                                writeTag(serializer, "major", Integer.toString(7));
                                writeTag(serializer, "minor", Integer.toString(0));
                                writeTag(serializer, "maintenance", Integer.toString(0));
                                writeTag(serializer, "patch", Integer.toString(0));
                                writeTag(serializer, "build", Integer.toString(0));
                            }
                            serializer.endTag("", "version");

                            //todo: TBD ,currently the above tags is enough to make communication with RMS. if others tag is needed in future, tell Mr.Keng to continue this work
                        }
                    }
                    serializer.endTag("", "RegistrationData");
                }
                serializer.endTag("", "RegisterAgentRequest");
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
        //  StartupConfiguration
        int SC_id; //Specifies the id of the agent
        //  StartupConfiguration commProfile
        int SC_C_id;
        String SC_C_name;
        String SC_C_createdDate;
        String SC_C_modifiedDate;
        // StartupConfiguration commProfile heartBeatFrequency
        int SC_C_HBF_time = 1;
        String SC_C_HBF_unit = "minutes"; // days hours minutes seconds milliseconds

        // StartupConfiguration commProfile logLimit
        int SC_C_LL_logLimit; // define the size limit for the activity logs

        // StartupConfiguration commProfile logFrequency
        int SC_C_LF_time; //  second unit
        String SC_C_LF_timeunit; // days hours minutes seconds milliseconds

        String SC_C_passwordHash; // contains the hash of the password that is used to stop and start Policy Controller

        // Ignore:StartupConfiguration commProfile currentActivityJournalingSettings
        // Ignore:StartupConfiguration commProfile customActivityJournalingSettings

        // StartupConfiguration agentProfile
        int SC_A_id;
        String SC_A_name;
        String SC_A_createdDate;
        String SC_A_modifiedDate;
        boolean SC_A_logViewingEnabled;  //indicate whether viewing of logs is enabled.
        boolean SC_A_trayIconEnabled;    //indicate whether the Tray Icon is enabled.

        // ignore:StartupConfiguration ClassificationProfile

        int SC_registrationId; // This is the registration id for the client

        // certificate
        String certificate; //This is the certificate  for the client.

        // ignore:fault


        public int getHeartBeatFrequency_SecondUnit() {
            int delta = 1;
            if (SC_C_HBF_unit.equalsIgnoreCase("days")) {
                delta = 24 * 60 * 60 * 1000;
            } else if (SC_C_HBF_unit.equalsIgnoreCase("hours")) {
                delta = 60 * 60 * 1000;
            } else if (SC_C_HBF_unit.equalsIgnoreCase("minutes")) {
                delta = 60 * 1000;
            } else if (SC_C_HBF_unit.equalsIgnoreCase("seconds")) {
                delta = 1000;
            } else if (SC_C_HBF_unit.equalsIgnoreCase("milliseconds")) {
                delta = 1;
            }
            return SC_C_HBF_time * delta / 1000;
        }

        public int getAgentId() {
            return SC_id;
        }

        public String getCommProfileName() {
            return SC_C_name;
        }

        public String getCommProfileModifiedDate() {
            return SC_C_modifiedDate;
        }

        public String getAgentProfileName() {
            return SC_A_name;
        }

        public String getAgentProfileModifiedDate() {
            return SC_A_modifiedDate;
        }

        public String getAgentCertification() {
            return certificate;
        }

        private void pareseXml(InputStream inputStream) throws Exception {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(inputStream, "utf-8");

            XmlParseTemplate.moveToTag(parser, "RegisterAgentResponse");
            XmlParseTemplate.parse(parser, "RegisterAgentResponse", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("StartupConfiguration")) {
                        parseStartupConfiguration(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("certificate")) {
                        certificate = XmlParseTemplate.readText(parser);
                        return true;
                    }
                    return false;
                }
            });

        }

        private void parseStartupConfiguration(XmlPullParser parser) throws Exception {

            XmlParseTemplate.parse(parser, "StartupConfiguration", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("id")) {
                        SC_id = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("commProfile")) {
                        parseStartupConfiguration_commProfile(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("agentProfile")) {
                        parseStartupConfiguration_agentProfile(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("registrationId")) {
                        SC_registrationId = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseStartupConfiguration_commProfile(XmlPullParser parser) throws Exception {

            XmlParseTemplate.parse(parser, "commProfile", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("id")) {
                        SC_C_id = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("name")) {
                        SC_C_name = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("createdDate")) {
                        SC_C_createdDate = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("modifiedDate")) {
                        SC_C_modifiedDate = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("heartBeatFrequency")) {
                        parseStartupConfiguration_commProfile_heartBeatFrequency(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("logLimit")) {
                        SC_C_LL_logLimit = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("logFrequency")) {
                        parseStartupConfiguration_commProfile_logFrequency(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("passwordHash")) {
                        SC_C_passwordHash = XmlParseTemplate.readText(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseStartupConfiguration_commProfile_heartBeatFrequency(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "heartBeatFrequency", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("time")) {
                        SC_C_HBF_time = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("time-unit")) {
                        SC_C_HBF_unit = XmlParseTemplate.readText(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseStartupConfiguration_commProfile_logFrequency(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "logFrequency", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("time")) {
                        SC_C_LF_time = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("time-unit")) {
                        SC_C_LF_timeunit = XmlParseTemplate.readText(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseStartupConfiguration_agentProfile(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "agentProfile", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("id")) {
                        SC_A_id = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("name")) {
                        SC_A_name = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("createdDate")) {
                        SC_A_createdDate = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("modifiedDate")) {
                        SC_A_modifiedDate = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("logViewingEnabled")) {
                        SC_A_logViewingEnabled = Boolean.parseBoolean(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("trayIconEnabled")) {
                        SC_A_trayIconEnabled = Boolean.parseBoolean(XmlParseTemplate.readText(parser));
                        return true;
                    }
                    return false;
                }
            });
        }
    }
}

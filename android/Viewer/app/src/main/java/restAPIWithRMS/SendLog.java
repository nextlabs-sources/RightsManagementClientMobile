package restAPIWithRMS;

import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlSerializer;

import java.io.InputStream;
import java.io.StringWriter;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import appInstance.ViewerApp;
import commonUtils.xml.XmlParseTemplate;


public class SendLog {

    static final String RMS_SERVICE_NAME = "/RMS/service/SendLog";
    static final String RMS_SERVICE_PREFIX = "https://";
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";

    Response response = new Response();


    public Response invokeToRMS(String rmServer, String certificate, Request request) throws Exception {
        // sanity check
        // set URI
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set head info
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, certificate);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), null);

        response.parseXml(ins);

        return response;
    }


    public static class Request {
        static public final String LOG_TYPE_EVALUATION = "Evaluation";
        static public final String LOG_TYPE_OPERATION = "Operation";
        static public final String SESSION_TYPE_CONSOLE = "Console";
        static public final String SESSION_TYPE_REMOTE = "Remote";
        static private final int TENANT_ID = 3647;
        static private final int VERSION = 1;
        static private int UNIQUE = 0;


        // <logService>
        int logService_attr_tenantId = TENANT_ID; // not document defined ,use 111 for current use
        int logService_attr_agentId;
        int logService_attr_version = VERSION; // 1 by default
        //<logRequest> <logs>
        //<log>
        long log_attr_uid;  // The high 32 bits is the AgentId.  The low 32 bits is a unique id defined by agent
        String log_attr_timestamp; //YYYY-MM-DDTHH:MM:SS+/-HH:MM
        String log_attr_type;  //"Evaluation" or "Operation"
        //<rights>
        // Mandatory – when type is “Evaluation”;
        // Optional – when type is “Operation”;
        List<String> rights;//  A list of rights granted, separated by “,”. If no right is granted, the text is “None”
        //<operation>
        // Mandatory – when type is “Operation”; Optional – when type is “Evaluation”;
        // like : “Encrypt”, “Decrypt”, “Classify”
        String operation;
        //<Environment>
        // Mandatory – when type is “Evaluation”;
        // Optional – when type is “Operation”;
        EnvironmentTag envTag;
        //<User>   // Mandatory;
        String user_Name;   // Mandatory like administrator@qapf1.qalab01.nextlabs.com
        String user_SID;    // Mandatory
        String user_Context;    // Mandatory    Unique user id used in policy bundle
        List<Attribute> user_Attributes; // Optional
        //<Host>    Mandatory;
        HostTag hostTag;
        //<Application> Mandatory – when type is “Evaluation”;Optional – when type is “Operation”;
        ApplicationTag appTag;
        //<Resource>    Mandatory;
        String res_Path; //Mandatory; The path of the resource.
        List<Tag> res_Tags; // Mandatory; The tags in this resource.
        //<HitPolicies> Mandatory;
        List<Policy> policies; //


        public void setEvaluationLog(int agentId,
                                     List<String> rights,
                                     String userName,  //   username@domain
                                     String sid,
                                     String hostNme,  //  hostNmae.domain
                                     String nxDocPath,
                                     List<Tag> nxDocPathTags,
                                     List<Policy> hitPolicies) {
            // prepare params
            logService_attr_agentId = agentId;

            log_attr_uid = getLogUid(agentId);
            log_attr_timestamp = getCurrentTimestampWithISO8601();
            log_attr_type = LOG_TYPE_EVALUATION;

            this.rights = rights;

            envTag = new EnvironmentTag();
            envTag.secondsSinceLastHeartbeat = -1;
            envTag.sessionType = SESSION_TYPE_REMOTE;

            operation = null;

            this.user_Name = userName;
            this.user_SID = sid;
            user_Context = String.valueOf(agentId);
            user_Attributes = null;

            hostTag = new HostTag();
            hostTag.host_Name = hostNme;

            appTag = new ApplicationTag();
            appTag.app_Path = getAppPath();

            res_Path = nxDocPath;
            res_Tags = nxDocPathTags;
            policies = hitPolicies;
        }

        public void setOperationLog(int agentId,
                                    String operation,
                                    String userName,  //   username@domain
                                    String sid,
                                    String hostNme,  //  hostNmae.domain
                                    String nxDocPath,
                                    List<Tag> nxDocPathTags,
                                    List<Policy> hitPolicies) {
            // prepare params
            logService_attr_agentId = agentId;

            log_attr_uid = getLogUid(agentId);
            log_attr_timestamp = getCurrentTimestampWithISO8601();
            log_attr_type = LOG_TYPE_OPERATION;

            this.rights = null;
            this.operation = operation;
            this.envTag = null;

            user_Name = userName;
            user_SID = sid;
            user_Context = String.valueOf(agentId);
            user_Attributes = null;


            HostTag hostTag = new HostTag();
            hostTag.host_Name = hostNme;

            this.appTag = null;


            res_Path = nxDocPath;
            res_Tags = nxDocPathTags;

            policies = hitPolicies;
        }

        private long getLogUid(int agentId) {
            long logId = ((long) agentId << 31);
            logId += new Random().nextInt();
            return logId;
        }

        private String getCurrentTimestampWithISO8601() {
            Date date = new Date();
            // in android ,SimpleDataFormat class dose not supprot ISO8601 's XXX  use this instead
            String formatted = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ").format(date);
            return formatted.substring(0, 22) + ":" + formatted.substring(22);
        }

        private String getAppPath() {
            return ViewerApp.getInstance().getPackageName();
        }

        //<log>
        // </logs></logRequest></logService>
        public String generateXml() {
            XmlSerializer serializer = Xml.newSerializer();
            StringWriter writer = new StringWriter(1024);
            try {
                serializer.setOutput(writer);
                serializer.startDocument("UTF-8", null);

                serializer.startTag(null, "logService");
                serializer.attribute(null, "tenantId", String.valueOf(logService_attr_tenantId));
                serializer.attribute(null, "agentId", String.valueOf(logService_attr_agentId));
                serializer.attribute(null, "version", String.valueOf(logService_attr_version));
                //<logService>
                {
                    serializer.startTag(null, "logRequest");
                    //<logRequest>
                    {
                        //<logs>
                        serializer.startTag(null, "logs");
                        {
                            generateLogTag(serializer);
                        }
                        //</logs>
                        serializer.endTag(null, "logs");
                    }
                    //</logRequest>
                    serializer.endTag(null, "logRequest");
                }
                //</logService>
                serializer.endTag(null, "logService");


                serializer.endDocument();
                return writer.toString();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }

        private void generateLogTag(XmlSerializer serializer) throws Exception {
            serializer.startTag(null, "log");
            serializer.attribute(null, "uid", String.valueOf(log_attr_uid));
            serializer.attribute(null, "timestamp", log_attr_timestamp);
            serializer.attribute(null, "type", log_attr_type);
            //<log>
            {
                if (rights != null) {
                    writeTag(serializer, "Rights", rightsToString());
                }
                if (operation != null) {
                    writeTag(serializer, "Operation", operation);
                }
                if (envTag != null) {
                    serializer.startTag(null, "Environment");
                    {
                        writeTag(serializer, "SessionType", envTag.sessionType);
                        writeTag(serializer, "SecondsSinceLastHeartbeat", String.valueOf(envTag.secondsSinceLastHeartbeat));
                    }
                    serializer.endTag(null, "Environment");
                }

                serializer.startTag(null, "User");
                {
                    writeTag(serializer, "Name", user_Name);
                    writeTag(serializer, "Sid", user_SID);
                    writeTag(serializer, "Context", user_Context);
                    generateUserAttributesTag(serializer);
                }
                serializer.endTag(null, "User");
                if (hostTag == null) {
                    throw new IllegalArgumentException("hostTag must be provided,it is mandatory");
                }
                serializer.startTag(null, "Host");
                {
                    writeTag(serializer, "Name", hostTag.host_Name);
                    // for android , ignore ipv4
                    serializer.startTag(null, "ipv4");
                    serializer.endTag(null, "ipv4");
                }
                serializer.endTag(null, "Host");

                if (appTag != null) {
                    serializer.startTag(null, "Application");
                    {
                        writeTag(serializer, "Image", appTag.app_Path);
                        writeTag(serializer, "Publisher", appTag.app_Publisher);
                    }
                    serializer.endTag(null, "Application");
                }
                //<Resource>
                serializer.startTag(null, "Resource");
                {
                    writeTag(serializer, "Path", res_Path);

                    serializer.startTag(null, "Tags");
                    for (Tag t : res_Tags) {
                        serializer.startTag(null, "Tag");
                        serializer.attribute(null, "Name", t.Name);
                        serializer.attribute(null, "Value", t.Value);
                        serializer.endTag(null, "Tag");
                    }
                    serializer.endTag(null, "Tags");
                }
                serializer.endTag(null, "Resource");
                //<HitPolicies>
                serializer.startTag(null, "HitPolicies");
                {
                    for (Policy p : policies) {
                        serializer.startTag(null, "Policy");
                        serializer.attribute(null, "Id", String.valueOf(p.Id));
                        serializer.attribute(null, "Name", p.Name);
                        serializer.endTag(null, "Policy");
                    }
                }
                serializer.endTag(null, "HitPolicies");


            }
            //</log>
            serializer.endTag(null, "log");
        }

        private String rightsToString() {
            if (rights.size() == 0) {
                return "None";
            } else {
                StringBuilder sb = new StringBuilder();
                for (String s : rights) {
                    sb.append(s);
                    sb.append(',');
                }
                return sb.substring(0, sb.length() - 1); // eliminate the last ',';
            }
        }

        private void generateUserAttributesTag(XmlSerializer serializer) throws Exception {
            serializer.startTag(null, "Attributes");
            {
                if (user_Attributes != null) {
                    for (Attribute attr : user_Attributes) {
                        serializer.startTag(null, "Attribute");
                        serializer.attribute(null, "Name", attr.Name);
                        serializer.attribute(null, "Value", attr.Value);
                        serializer.attribute(null, "Type", attr.Type);
                        serializer.endTag(null, "Attribute");
                    }
                }
            }
            serializer.endTag(null, "Attributes");
        }

        private void writeTag(XmlSerializer serializer, String tagName, String tagText) throws Exception {
            serializer.startTag(null, tagName);
            serializer.text(tagText);
            serializer.endTag(null, tagName);
        }

        class EnvironmentTag {
            // Optional Console or Remote
            public String sessionType;
            // Mandatory; The seconds elapsed since last heartbeat.
            // If the value is “-1”, it means either there is no heart beat at all, or too many seconds have passed.
            public int secondsSinceLastHeartbeat = -1;
        }

        class HostTag {
            String host_Name; // Mandatory; Host’s FQDN (Windows) , like: rmc64-o13-01.qapf1.qalab01.nextlabs.com
            List<String> host_ipv4s; // Optional; Host’s IPv4 address. If there are multiple ipv4 addresses, they are separated by “,”
        }

        class ApplicationTag {
            // Mandatory; The image path
            String app_Path;
            // Optional; The publisher of this application (from signature)
            String app_Publisher = "Nextlabs Android Viewer";
        }

        public class Attribute {
            // Tag name : Attribute , attribute: Name,Value,Type
            public String Name; // Mandatory
            public String Value; // Mandatory
            public String Type;  // Optional; Default is String
        }

        public class Tag {
            // Tag name : Tag , attribute: Name,Value,Type
            public String Name; // Mandatory
            public String Value; // Mandatory
        }

        public class Policy {
            // Tag name: policy , attribute: Id, Name
            public int Id;  // Mandatory
            public String Name;  //Mandatory

        }
    }

    public static class Response {
        String response = "unknown";    // "Success" or "Failed"
        int errorCode = -1;
        String errorMessage = "ok";

        public boolean isSuccess() {
            return response.equalsIgnoreCase("Success");
        }

        public void parseXml(InputStream inputStream) throws Exception {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(inputStream, "utf-8");

            XmlParseTemplate.moveToTag(parser, "logService");
            XmlParseTemplate.moveToTag(parser, "logResponse");
            XmlParseTemplate.parse(parser, "logResponse", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("response")) {
                        response = XmlParseTemplate.readText(parser);
                        return true;

                    } else if (subTag.equalsIgnoreCase("fault")) {
                        parseFault(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseFault(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "fault", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("errorCode")) {
                        errorCode = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("errorMessage")) {
                        errorMessage = XmlParseTemplate.readText(parser);
                    }
                    return false;
                }
            });
        }
    }


}

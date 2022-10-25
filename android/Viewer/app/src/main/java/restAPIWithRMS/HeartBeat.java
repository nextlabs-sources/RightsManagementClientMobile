package restAPIWithRMS;

import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlSerializer;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.StringWriter;
import java.net.URL;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Stack;

import commonUtils.xml.XmlParseTemplate;
import restAPIWithRMS.dataTypes.NXClassifyProfile;
import restAPIWithRMS.dataTypes.NXKey;
import restAPIWithRMS.dataTypes.NXKeyRing;
import restAPIWithRMS.dataTypes.NXLabel;
import restAPIWithRMS.dataTypes.NXPolicyUserGroupInfo;
import restAPIWithRMS.dataTypes.NXUserMap;
import restAPIWithRMS.dataTypes.NXValue;

/**
 * history:
 * 12/4/2015 parse for label classification
 */
public class HeartBeat {

    static final String RMS_SERVICE_NAME = "/RMS/service/HeartBeat";
    static final String RMS_SERVICE_PREFIX = "https://";
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";

    Request request = new Request();
    Response response = new Response();

    public void invokeToRMS(String rmServer,
                            String sid,
                            String agentId,

                            String agentProfileName,
                            String agentProfileModifiedDate,
                            String commProfileName,
                            String commProfileModifiedDate,
                            String certificate) throws Exception {
        // set Request
        request.sid = sid;
        request.agentId = agentId;
        request.agentProfileName = agentProfileName;
        request.agentProfileModifiedDate = agentProfileModifiedDate;
        request.commProfileName = commProfileName;
        request.commProfileModifiedDate = commProfileModifiedDate;
        request.certificate = certificate;
        // set URI
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, certificate);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), null);
        response.classifyLabels.clear();
        response.keyRings.clear();

        // as requirements , it must hold raw XML string and later it will be used as param to be pass to Policy Engine
        // keep raw data
        BufferedReader reader = new BufferedReader(new InputStreamReader(ins));
        StringBuilder buffer = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            buffer.append(line);
        }
        reader.close();
        response.rawNetworkContent = buffer.toString();

        ins = new ByteArrayInputStream(buffer.toString().getBytes(Charset.forName("UTF-8")));
        response.parseXml(ins);
    }

    /**
     * I know this function may be eccentric, but as requirements, we must support that response can be used at no network environment
     * the current solution is: if in no network environment, then parseResponse use latest cache xml file
     *
     * @param rawXMLResponse use getRawNetStreamContent(); or unserialize file from disk
     * @throws Exception
     */
    public void parseResponseManually(String rawXMLResponse) throws Exception {
        response.clear();
        InputStream ins = new ByteArrayInputStream(rawXMLResponse.getBytes(Charset.forName("UTF-8")));
        response.parseXml(ins);
    }

    public String getRawNetStreamContent() {
        return response.rawNetworkContent;
    }

    public String setRawNetStreamContent(String responseXml) {
        return response.rawNetworkContent = responseXml;
    }

    public List<NXKeyRing> getKeyRings() {
        return response.keyRings;
    }

    public List<String> getSupportedCadFormats() {
        return response.supportedCadFormats;
    }


    /**
     *
     */
    public List<NXLabel> getLabelsByLoginUser(String userName) {
        Set<Integer> group = null;
        for (NXUserMap u : response.PolicyBundleUserGroup) {
            if (u.idName.equalsIgnoreCase(userName)) {
                group = u.group;
                break;
            }
        }
        if (group == null) {
            return getLabels();
        }
        // find first GroupLabel
        String groupName = null;
        for (int i : group) {
            for (NXPolicyUserGroupInfo info : response.PolicyUserGroupInfos) {
                if (i == info.usergroupId) {
                    groupName = info.groupValue;
                    break;
                }
            }
            if (groupName != null) {
                break;
            }
        }
        if (groupName == null) {
            return getLabels();
        }
        // Build labelList by groupName;
        Set<Integer> labelIDs = null;
        for (NXClassifyProfile p : response.classifyProfiles) {
            if (p.name.equalsIgnoreCase(groupName)) {
                labelIDs = p.labelIDs;
            }
        }
        if (labelIDs == null || labelIDs.isEmpty()) {
            return getLabels();
        }
        List<NXLabel> rt = new ArrayList<>();
        Stack<Integer> subLabelIds = new Stack();
        // add main labels
        for (NXLabel label : response.classifyLabels) {
            if (labelIDs.contains(label.id)) {
                rt.add(label);
                // check if need add sub Labels
                for (NXValue v : label.values) {
                    if (v.subValueId != -1) {
                        // if exist in stack, ignore
                        boolean isExist = false;
                        for (int i : subLabelIds) {
                            if (i == v.subValueId) {
                                isExist = true;
                                break;
                            }
                        }
                        if (!isExist) {
                            subLabelIds.add(v.subValueId);
                        }
                    }
                }
            }
        }
        // add sublabels
        while (!subLabelIds.isEmpty()) {
            int i = subLabelIds.pop();
            for (NXLabel label : response.classifyLabels) {
                if (i == label.id) {
                    rt.add(label);
                    // check if need add sub Labels
                    for (NXValue v : label.values) {
                        if (v.subValueId != -1) {
                            subLabelIds.add(v.subValueId);
                        }
                    }
                    break;
                }
            }
        }

        return rt;


    }

    public List<NXLabel> getLabels() {
        return response.classifyLabels;
    }

    private class Request {
        String sid;
        String agentId;
        String agentProfileName;
        String agentProfileModifiedDate;
        String commProfileName;
        String commProfileModifiedDate;
        String certificate;

        public String generateXml() {
            XmlSerializer serializer = Xml.newSerializer();
            StringWriter writer = new StringWriter(1024);
            try {
                serializer.setOutput(writer);
                serializer.startDocument("UTF-8", null);
                serializer.startTag(null, "HeartBeatRequest");
                {
                    writeTag(serializer, "agentId", agentId);
                    serializer.startTag(null, "heartbeat");
                    {
                        serializer.startTag(null, "profileStatus");
                        {
                            writeTag(serializer, "lastCommittedAgentProfileName", agentProfileName);
                            writeTag(serializer, "lastCommittedAgentProfileTimestamp", agentProfileModifiedDate);
                            writeTag(serializer, "lastCommittedCommProfileName", commProfileName);
                            writeTag(serializer, "lastCommittedCommProfileTimestamp", commProfileModifiedDate);

                        }
                        serializer.endTag(null, "profileStatus");

                        serializer.startTag(null, "policyAssemblyStatus");
                        serializer.attribute(null, "agentHost", "rmc64-o13-01");
                        serializer.attribute(null, "agentType", "DESKTOP");
                        serializer.attribute(null, "timestamp", "2014-04-24T12:32:42.071+08:00");
                        {
                            writeTag(serializer, "userSubjectTypes", "windowsSid");
                            writeTag(serializer, "agentCapabilities", "EMAIL");
                            serializer.startTag(null, "policyUsers");
                            {
                                writeTag(serializer, "userSubjectType", "windowsSid");
                                writeTag(serializer, "systemId", sid);
                            }
                            serializer.endTag(null, "policyUsers");
                        }
                        serializer.endTag(null, "policyAssemblyStatus");

                        serializer.startTag(null, "pluginData");
                        serializer.endTag(null, "pluginData");
                    }
                    serializer.endTag(null, "heartbeat");

                }
                serializer.endTag(null, "HeartBeatRequest");
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

    private class Response {
        int frequencyTime;
        String frequencyTimeUnit = "minutes";
        List<NXKeyRing> keyRings = new ArrayList<>();
        List<NXLabel> classifyLabels = new ArrayList<>();
        List<NXClassifyProfile> classifyProfiles = new ArrayList<>();
        List<NXUserMap> PolicyBundleUserGroup = new ArrayList<>();
        List<NXPolicyUserGroupInfo> PolicyUserGroupInfos = new ArrayList<>();
        List<String> supportedCadFormats = new ArrayList<>();
        String rawNetworkContent;

        public void clear() {
            keyRings.clear();
            classifyLabels.clear();
            classifyProfiles.clear();
            PolicyBundleUserGroup.clear();
            PolicyUserGroupInfos.clear();
        }

        public void parseXml(InputStream inputStream) throws Exception {
            clear();
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(inputStream, "utf-8");
            XmlParseTemplate.moveToTag(parser, "AgentUpdates");
            XmlParseTemplate.parse(parser, "AgentUpdates", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("commProfile")) {
                        parseCommProfile(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("policyDeploymentBundle")) {
                        parsePolicyDeploymentBundle(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("keyRings")) {
                        parseKeyRings(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("ClassificationProfile")) {
                        parseClassificationProfile(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("supportedCadFormats")) {
                        parseSupportedCadFormats(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseCommProfile(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "commProfile", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("heartBeatFrequency")) {
                        parseHeartBeatFrequency(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parsePolicyDeploymentBundle(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "policyDeploymentBundle", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("POLICYBUNDLE")) {
                        parsePolicyBundle(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parsePolicyBundle(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "POLICYBUNDLE", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("POLICYSET")) {
                        parsePolicySet(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("USERGROUPMAP")) {
                        parseUserGroupMap(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parsePolicySet(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "POLICYSET", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("POLICY")) {
                        parsePolicy(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parsePolicy(XmlPullParser parser) throws Exception {
            // notice: this method only parses user-group relevant infos
            parser.require(XmlPullParser.START_TAG, null, "POLICY");
            NXPolicyUserGroupInfo groupInfo = new NXPolicyUserGroupInfo();
            groupInfo.name = parser.getAttributeValue(null, "name");//
            // parse group id
            String groupStr = parser.getAttributeValue(null, "usergroup");
            if (groupStr != null) {
                groupInfo.usergroupId = Integer.parseInt(groupStr);
            }
            // parse group name from Policy's subTag
            while (parser.next() != XmlPullParser.END_TAG) {
                if (parser.getEventType() != XmlPullParser.START_TAG) {
                    continue;
                }
                // only care about tag:OBLIGATION, others skip
                if (!parser.getName().equalsIgnoreCase("OBLIGATION")) {
                    XmlParseTemplate.skipTag(parser);
                    continue;
                }
                //fix bug, attribute of name may not exist
                String attrName = parser.getAttributeValue(null, "name");
                if (attrName == null || !attrName.equalsIgnoreCase("OB_CLASSIFY")) {
                    XmlParseTemplate.skipTag(parser);
                    continue;
                }
                // sub tag OBLIGATION with attr name="OB_CLASSIFY"
                parser.require(XmlPullParser.START_TAG, null, "OBLIGATION");
                while (parser.next() != XmlPullParser.END_TAG) {
                    if (parser.getEventType() != XmlPullParser.START_TAG) {
                        continue;
                    }
                    if (!parser.getName().equalsIgnoreCase("PARAM")) {
                        XmlParseTemplate.skipTag(parser);
                        continue;
                    }
                    parser.require(XmlPullParser.START_TAG, null, "PARAM");
                    // parse the RARAM tag
                    String paramName = parser.getAttributeValue(null, "name");
                    String paramValue = parser.getAttributeValue(null, "value");
                    if (paramName != null && paramName.equalsIgnoreCase("Group") && paramValue != null) {
                        // parse Group Name
                        groupInfo.groupValue = paramValue;
                        PolicyUserGroupInfos.add(groupInfo);
                    }
                    // ignore others until meet tag end
                    while (parser.getEventType() != XmlPullParser.END_TAG) {
                        parser.next();
                    }

                }
            }
        }


        private void parseUserGroupMap(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "USERGROUPMAP", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("USERMAP")) {
                        parseUserMap(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseUserMap(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "USERMAP");
            NXUserMap userMap = new NXUserMap();
            userMap.idName = parser.getAttributeValue(null, "id");
            userMap.context = Long.parseLong(parser.getAttributeValue(null, "context"));
            while (parser.next() != XmlPullParser.END_TAG) {
                if (parser.getEventType() == XmlPullParser.TEXT) {
                    String intValues = parser.getText();
                    if (intValues == null) {
                        continue;
                    }
                    String[] values = intValues.split(",");
                    for (String v : values) {
                        userMap.group.add(Integer.parseInt(v.trim()));
                    }
                }
            }
            PolicyBundleUserGroup.add(userMap);

        }


        private void parseHeartBeatFrequency(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "heartBeatFrequency", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("time")) {
                        frequencyTime = Integer.parseInt(XmlParseTemplate.readText(parser));
                        return true;
                    } else if (subTag.equalsIgnoreCase("time-unit")) {
                        frequencyTimeUnit = XmlParseTemplate.readText(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseKeyRings(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "keyRings", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("KeyRing")) {
                        keyRings.add(parseKeyRing(parser));
                        return true;
                    }
                    return false;
                }
            });
        }

        private NXKeyRing parseKeyRing(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "KeyRing");
            NXKeyRing keyRing = new NXKeyRing();
            keyRing.keyRingName = parser.getAttributeValue(null, "KeyRingName");
            keyRing.lastModifiedDate = parser.getAttributeValue(null, "LastModifiedDate");

            while (parser.next() != XmlPullParser.END_TAG) {
                if (parser.getEventType() != XmlPullParser.START_TAG) {
                    continue;
                }
                String name = parser.getName();
                if (name.equalsIgnoreCase("Key")) {
                    keyRing.keys.add(parseKey(parser));
                } else {
                    XmlParseTemplate.skipTag(parser);
                }
            }
            return keyRing;
        }

        private NXKey parseKey(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "Key");
            NXKey key = new NXKey();
            while (parser.next() != XmlPullParser.END_TAG) {
                if (parser.getEventType() != XmlPullParser.START_TAG) {
                    continue;
                }
                String name = parser.getName();
                if (name.equalsIgnoreCase("KeyId")) {
                    key.keyId = XmlParseTemplate.readText(parser);
                } else if (name.equalsIgnoreCase("KeyData")) {
                    key.keyData = XmlParseTemplate.readText(parser);
                } else if (name.equalsIgnoreCase("KeyVersion")) {
                    key.keyVersion = Integer.parseInt(XmlParseTemplate.readText(parser));
                } else if (name.equalsIgnoreCase("TimeStamp")) {
                    key.timeStamp = XmlParseTemplate.readText(parser);
                } else {
                    XmlParseTemplate.skipTag(parser);
                }
            }
            return key;
        }

        private void parseClassificationProfile(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "ClassificationProfile", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("Classify")) {
                        parseClassify(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parseClassify(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "Classify", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("LabelList")) {
                        parseLabelList(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("Profiles")) {
                        pareseProfiles(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void pareseProfiles(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "Profiles", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    NXClassifyProfile profile = new NXClassifyProfile();
                    profile.name = subTag;
                    String intValues;
                    while (parser.next() != XmlPullParser.END_TAG) {
                        if (parser.getEventType() == XmlPullParser.TEXT) {
                            intValues = parser.getText();
                            if (intValues != null) {
                                String[] values = intValues.split(",");
                                for (String v : values) {
                                    profile.labelIDs.add(Integer.parseInt(v));
                                }

                            }
                        }
                    }
                    classifyProfiles.add(profile);
                    return true;
                }
            });
        }

        private void parseLabelList(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "LabelList", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("Label")) {
                        classifyLabels.add(parseLabel(parser));
                        return true;
                    }
                    return false;
                }
            });
        }

        private NXLabel parseLabel(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "Label");
            NXLabel label = new NXLabel();
            label.id = Integer.parseInt(parser.getAttributeValue(null, "id"));
            label.name = parser.getAttributeValue(null, "name");
            label.displayName = parser.getAttributeValue(null, "display-name");
            label.mandatory = Boolean.parseBoolean(parser.getAttributeValue(null, "mandatory"));
            label.multipleSelection = Boolean.parseBoolean(parser.getAttributeValue(null, "multi-select"));
            // wtf ,the field default-value is not mandatory
            String defaultValue = parser.getAttributeValue(null, "default-value");

            label.defaultValueId = defaultValue == null ? -1 : Integer.parseInt(defaultValue);
            while (parser.next() != XmlPullParser.END_TAG) {
                if (parser.getEventType() != XmlPullParser.START_TAG) {
                    continue;
                }
                String name = parser.getName();
                if (name.equalsIgnoreCase("VALUE")) {
                    label.values.add(parseLabelValue(parser));
                } else {
                    XmlParseTemplate.skipTag(parser);
                }
            }
            return label;
        }

        private NXValue parseLabelValue(XmlPullParser parser) throws Exception {
            parser.require(XmlPullParser.START_TAG, null, "VALUE");
            NXValue value = new NXValue();
            // wtf, some attribute may not appear in VALUE tag
            String priority = parser.getAttributeValue(null, "priority");
            if (priority != null) {
                value.priority = Integer.parseInt(priority);
            }
            String labelValue = parser.getAttributeValue(null, "value");
            if (labelValue != null) {
                value.labelValue = labelValue;
            }
            String subValueId = parser.getAttributeValue(null, "sub-label");
            if (subValueId != null) {
                value.subValueId = Integer.parseInt(subValueId);
            }
            // ignore others until meet tag end
            while (parser.getEventType() != XmlPullParser.END_TAG) {
                parser.next();
            }
            return value;
        }

        private void parseSupportedCadFormats(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "supportedCadFormats", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("nonAssembly")) {
                        String s = XmlParseTemplate.readText(parser);
                        String[] ss = s.split(",");
                        if (ss.length == 0) {
                            return true;
                        }
                        supportedCadFormats.clear();
                        for (String format : ss) {
                            supportedCadFormats.add(format);
                        }
                        return true;
                    }
                    return false;
                }
            });
        }
    }
}

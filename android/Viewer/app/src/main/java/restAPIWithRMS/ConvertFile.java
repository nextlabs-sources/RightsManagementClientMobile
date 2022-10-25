package restAPIWithRMS;

import android.util.Base64;
import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlSerializer;

import java.io.InputStream;
import java.io.StringWriter;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import commonUtils.CryptoHelper;
import commonUtils.xml.XmlParseTemplate;

/**
 *
 */
public class ConvertFile {
    static final String RMS_SERVICE_NAME = "/RMS/service/ConvertFile";
    static final String RMS_SERVICE_PREFIX = "https://";
    static final String HEADER_CERT_KEY = "X-NXL-S-CERT";

    Request request = new Request();
    Response response = new Response();

    /**
     * Remote call RMS through Https
     *
     * @return - true, no error occurs at send request, get response, parse response and errorCode not set
     * - false, others
     * @throws Exception
     */
    public boolean invokeToRMS(String rmServer,
                               String certificate,
                               int agentId,
                               String fileName,
                               byte[] fileContent,
                               String toFormat,
                               boolean isNxl,
                               Listener listener
    ) throws Exception {
        // sanity check
        // prepare
        request.agentId = agentId;
        request.fileName = fileName;
        request.toFormat = toFormat;
        request.isNxl = isNxl;
        request.checksum = CryptoHelper.md5WithHexifyResult(fileContent, false);
        request.binaryFile = Base64.encodeToString(fileContent, Base64.DEFAULT);

        // set URI
        URL url = new URL(RMS_SERVICE_PREFIX + rmServer + RMS_SERVICE_NAME);
        // set headinfo
        Map<String, String> headInfo = new HashMap<>();
        headInfo.put(HEADER_CERT_KEY, certificate);
        // send request
        InputStream ins = HttpsPost.sendRequest(url, headInfo, request.generateXml(), listener);
        // parse result
        response.parseXml(ins);
        return response.errorCode == -1;
    }

    /**
     * @return Converted file
     * @throws Exception - errorCode is set
     *                   - checksum mistach
     */
    public byte[] getConvertedFile() throws Exception {
        // sanity check
        if (response.errorCode != -1) {
            throw new RuntimeException("convert request error occurs,error code:" + response.errorCode + "  error message:" + response.errorMessage);
        }
        byte[] rtValue = Base64.decode(response.fileContentByBase64Encoded, Base64.DEFAULT);
        // checksum check
        String checksum = CryptoHelper.md5WithHexifyResult(rtValue, false);
        if (!checksum.equalsIgnoreCase(response.checksum)) {
            throw new RuntimeException("mismatch the md5 checksum of the converted file's content between local calculated and RMS calculated");
        }

        return rtValue;
    }

    public String getConvertedFileName() throws Exception {
        // sanity check
        if (response.errorCode != -1) {
            throw new RuntimeException("convert request error occurs,error code:" + response.errorCode + "  error message:" + response.errorMessage);
        }

        return response.fileName;
    }

    class Request {
        int tenantId = 111; // not document defined ,use 111 for current use
        int agentId;
        int Version = 1; // 1 by default
        String fileName;
        String toFormat = "hsf";    //hsf by default , accept hsf, hwf
        boolean isNxl;  // false by default
        String binaryFile;  // Base64 encoded string  of the file to be converted
        String checksum;    // md5 of orignal file

        public String generateXml() {
            XmlSerializer serializer = Xml.newSerializer();
            StringWriter writer = new StringWriter(1024);
            try {
                serializer.setOutput(writer);
                serializer.startDocument("UTF-8", null);

                serializer.startTag(null, "convertFileService");
                serializer.attribute(null, "tenantId", String.valueOf(tenantId));
                serializer.attribute(null, "agentId", String.valueOf(agentId));
                serializer.attribute(null, "Version", String.valueOf(Version));
                {
                    serializer.startTag(null, "convertFileRequest");
                    {
                        writeTag(serializer, "fileName", fileName);
                        writeTag(serializer, "toFormat", toFormat);
                        writeTag(serializer, "isNxl", String.valueOf(isNxl));
                        writeTag(serializer, "binaryFile", binaryFile);
                        writeTag(serializer, "checksum", checksum);

                    }
                    serializer.endTag(null, "convertFileRequest");
                }
                serializer.endTag(null, "convertFileService");
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

    class Response {
        int errorCode = -1;
        String errorMessage = "ok";

        String fileName;
        String fileContentByBase64Encoded; // Base64 encoded;
        String checksum; // md5   the value from decoded content of fileContentByBase64Encoded;

        public void parseXml(InputStream inputStream) throws Exception {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(inputStream, "utf-8");

            XmlParseTemplate.moveToTag(parser, "convertFileResponse");
            XmlParseTemplate.parse(parser, "convertFileResponse", new XmlParseTemplate.SubTagHandler() {
                @Override
                public boolean handle(XmlPullParser parser, String subTag) throws Exception {
                    if (subTag.equalsIgnoreCase("fileName")) {
                        fileName = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("binaryFile")) {
                        fileContentByBase64Encoded = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("checksum")) {
                        checksum = XmlParseTemplate.readText(parser);
                        return true;
                    } else if (subTag.equalsIgnoreCase("error")) {
                        parserError(parser);
                        return true;
                    }
                    return false;
                }
            });
        }

        private void parserError(XmlPullParser parser) throws Exception {
            XmlParseTemplate.parse(parser, "convertFileResponse", new XmlParseTemplate.SubTagHandler() {
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

package appInstance.remoteRepo.sharepointonline;

import android.util.Log;

import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.StringReader;
import java.io.Writer;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.List;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

/**
 * Created by aning on 6/2/2015.
 */

public class AuthenticationManager {

    private static final String TAG = "AuthenticationManager";
    private static final int CYCLE_COUNT = 3;
    /* Microsoft Online Security Token Service (STS) */
    private static final String STS = "https://login.microsoftonline.com/extSTS.srf";
    private static final String LOGIN = "/_forms/default.aspx?wa=wsignin1.0";
    private static final String SHAREPOINT_ONLINE_URL = "https://nextlabs.sharepoint.com";
    private static final String GET_ROOT_FOLDER = "/_api/web/lists?$filter=BaseTemplate eq 101&$select=Title,Created,RootFolder";
    private static final String REQUEST_XML = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:a=\"http://www.w3.org/2005/08/addressing\" xmlns:u=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"><s:Header><a:Action s:mustUnderstand=\"1\">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action><a:ReplyTo><a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address></a:ReplyTo><a:To s:mustUnderstand=\"1\">https://login.microsoftonline.com/extSTS.srf</a:To><o:Security s:mustUnderstand=\"1\" xmlns:o=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"><o:UsernameToken><o:Username>[username]</o:Username><o:Password>[password]</o:Password></o:UsernameToken></o:Security></s:Header><s:Body><t:RequestSecurityToken xmlns:t=\"http://schemas.xmlsoap.org/ws/2005/02/trust\"><wsp:AppliesTo xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\"><a:EndpointReference><a:Address>[endpoint]</a:Address></a:EndpointReference></wsp:AppliesTo><t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType><t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType><t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType></t:RequestSecurityToken></s:Body></s:Envelope>";

    private LoginActivity mLoginActivity;
    private String mUsername;
    private String mPassword;
    private String mUrl;

    public String sharepointOnlineAuth() {

        try {
            String result = requestToken();
            String token = extractToken(result);
            String cookie = extractCookie(token);
            return cookie;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "";
    }

    // fill in the soap package with user name, password and url
    private String generateSAML() {
        mLoginActivity = LoginActivity.getmInstance();
        mUsername = mLoginActivity.getUsername();
        mPassword = mLoginActivity.getPassword();
        mUrl = mLoginActivity.getUrl();
        // fill in the soap package.
        String saml = REQUEST_XML.replace("[username]", mUsername);
        saml = saml.replace("[password]", mPassword);
        saml = saml.replace("[endpoint]", mUrl);
        return saml;
    }

    // Send SAML Request to STS（Microsoft online Security Token Service）
    private String requestToken() throws XPathExpressionException, SAXException,
            ParserConfigurationException, IOException {

        String saml = generateSAML();
        URL url = new URL(STS);

        try {
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, new TrustManager[]{new MyTrustManager()}, new SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            HttpsURLConnection.setDefaultHostnameVerifier(new MyHostnameVerifier());
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();

        } catch (KeyManagementException e) {
            e.printStackTrace();
        }

        HttpsURLConnection urlConn = (HttpsURLConnection) url.openConnection();
        urlConn.setDoOutput(true);
        urlConn.setDoInput(true);
        urlConn.setRequestMethod("POST");
        urlConn.addRequestProperty("Content-Type", "text/xml; charset=utf-8");

        // write the SAML info into server
        OutputStream out = urlConn.getOutputStream();
        Writer wout = new OutputStreamWriter(out);
        wout.write(saml);

        wout.flush();
        wout.close();

        // receive SAML response including security token
        InputStream in = urlConn.getInputStream();
        int c;
        StringBuilder sb = new StringBuilder("");
        while ((c = in.read()) != -1)
            sb.append((char) (c));
        in.close();
        String result = sb.toString();

        return result;
    }

    // parse token from the SAML response
    private String extractToken(String result) throws SAXException, IOException, ParserConfigurationException, XPathExpressionException {

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        // parse xml file
        Document document = db.parse(new InputSource(new StringReader(result)));
        // query xml document
        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();
        Log.d("the text is: ", result);
        String token = xp.evaluate("//BinarySecurityToken/text()", document.getDocumentElement());
        return token;
    }

    // send security token to SPO (SharePoint Online)
    private String extractCookie(String token) throws IOException {

        URL url = new URL(SHAREPOINT_ONLINE_URL + LOGIN);
        try {
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, new TrustManager[]{new MyTrustManager()}, new SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            HttpsURLConnection.setDefaultHostnameVerifier(new MyHostnameVerifier());
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (KeyManagementException e) {
            e.printStackTrace();
        }

        String Cookies = "";
        boolean reDirect = false;
        int cycleCount = 0;
        do {
            cycleCount++;
            HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
            connection.setDoOutput(true);
            connection.setDoInput(true);
            connection.setRequestMethod("POST");
            connection.addRequestProperty("Accept", "application/x-www-form-urlencoded");
            connection.addRequestProperty("User-Agent", "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0)");
            connection.addRequestProperty("Content-Type", "text/xml; charset=utf-8");
            connection.setInstanceFollowRedirects(false);

            // write the token into server
            OutputStream out = connection.getOutputStream();
            Writer wout = new OutputStreamWriter(out);
            wout.write(token);
            wout.flush();
            wout.close();

            // get and parse the cookie
            List<String> cookies = connection.getHeaderFields().get("Set-Cookie");
            for (String str : cookies) {
                if (str.contains("rtFa")) {
                    String[] str1 = str.split(";");
                    Cookies += str1[0];
                    Cookies += ";";
                } else if (str.contains(("FedAuth"))) {
                    String[] str2 = str.split(";");
                    Cookies += str2[0];
                }
            }
            if (Cookies.equals("")) {
                reDirect = true;
                continue;
            } else
                break;
        } while (reDirect && cycleCount <= CYCLE_COUNT);

        return Cookies;
    }

    public boolean verifySiteUrl(String siteUrl, String cookie) {
        String Path = siteUrl + GET_ROOT_FOLDER;
        boolean isRightUrl = true;
        try {
            if (Path.contains(" ")) {
                Path = Path.replaceAll(" ", "%20");
            }
            URL url = new URL(Path);

            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, new TrustManager[]{new MyTrustManager()}, new SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            HttpsURLConnection.setDefaultHostnameVerifier(new MyHostnameVerifier());
            HttpsURLConnection urlConn = (HttpsURLConnection) url.openConnection();

            urlConn.setRequestProperty("Cookie", cookie);
            urlConn.setRequestMethod("GET");
            urlConn.setRequestProperty("Content-type", "application/atom+xml");
            urlConn.setDoInput(true);
            urlConn.getInputStream();
        } catch (IOException e) {
            if (e.toString().contains("FileNotFoundException")) {
                isRightUrl = false;
            }
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (KeyManagementException e) {
            e.printStackTrace();
        }

        return isRightUrl;
    }

    private class MyHostnameVerifier implements HostnameVerifier {
        @Override
        public boolean verify(String hostname, SSLSession session) {
            // TODO Auto-generated method stub
            return true;
        }
    }

    private class MyTrustManager implements X509TrustManager {
        @Override
        public void checkClientTrusted(X509Certificate[] chain, String authType)
                throws CertificateException {
            // Auto-generated method stub
        }

        @Override
        public void checkServerTrusted(X509Certificate[] chain, String authType)
                throws CertificateException {
            // TODO Auto-generated method stub
        }

        @Override
        public X509Certificate[] getAcceptedIssuers() {
            // TODO Auto-generated method stub
            return null;
        }
    }
}

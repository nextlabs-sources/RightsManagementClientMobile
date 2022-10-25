package appInstance.remoteRepo.sharepointonline;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.StringReader;
import java.io.SyncFailedException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Map;
import java.util.TimeZone;

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

import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.RemoteRepoInfo;
import errorHandler.ErrorCode;

/**
 * Created by aning on 6/2/2015.
 */

public class SharePointOnlineSdk {

    private static final String TAG = "SharePointOnlineSdk";
    private static final String LATEST_REV = null;
    private static final String METHOD_GET = "GET";
    private static final String METHOD_POST = "POST";
    private static boolean bAuthSuccessful = false;
    private static Account AuthAccount = null;
    private Account mAccount = null;
    private boolean isCancel = false;
    private InputStream mSharepointonlineInputStream = null;
    private OutputStream mSharepointonlineOutputStream = null;
    private String mCookie;
    private String mfilePath = "";

    public SharePointOnlineSdk(String url, String userName, String token) {
        Account account = new Account();
        account.setUrl(url);
        account.setUsername(userName);
        account.setCookie(token);
        mAccount = account;
    }

    public static void startAuth(Activity mActivity) {
        ResetAuthStatus();
        Intent intent = new Intent();
        intent.setClass(mActivity, LoginActivity.class);
        mActivity.startActivity(intent);
    }

    public static boolean GetAuthStatus() {
        return bAuthSuccessful;
    }

    public static void ResetAuthStatus() {
        bAuthSuccessful = false;
    }

    public static void SetAuthStatus(boolean bAuthStatus) {
        bAuthSuccessful = bAuthStatus;
    }

    public static Account GetAuthAccount() {
        return AuthAccount;
    }

    public static void SetAuthAccount(Account account) {
        AuthAccount = account;
    }

    public nxl.types.NxFileBase GetMetaInfo(nxl.types.INxFile File) {
        String path = File.getCloudPath();

        if (path.equals("/")) {
            return GetRoot();  // get sites and rootsite list
        } else if (File.isSite()) {
            return GetChildSiteAndLists(File); // get children sites and lists of default site
        } else {
            return GetFoldersAndFiles(File); // get all folders and files of a list.
        }
    }

    public boolean getRepositoryInfo(RemoteRepoInfo info) {
        try {
            // get the user nad email
            String userInfo = GetCurrentUserInfo();
            String userId = parseGetCurrentUserId(userInfo);
            String detailInfo = GetCurrentUserInfoDetail(userId);
            Map<String, String> infoMap = parseGetUserDetailInfo(detailInfo);
            info.displayName = infoMap.get("user");
            info.email = infoMap.get("email");

            // get the total space and used space.
            String siteQuota = GetSiteQuota();
            Map<String, String> quotaMap = parseGetSiteQuota(siteQuota);
            info.remoteTotalSpace = Long.valueOf(quotaMap.get("Storage"));
            info.remoteUsedSpace = (long) (info.remoteTotalSpace * Float.parseFloat(quotaMap.get("StoragePercentageUsed")));

            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public void parseDocLists(String xmlDoc, nxl.types.NxFileBase rt, nxl.types.INxFile File) throws Exception {

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();

        try {
            Element root = document.getDocumentElement();
            NodeList entryList = document.getElementsByTagName("entry");
            int size = entryList.getLength();
            for (int i = 0; i < entryList.getLength(); i++) {
                Element entry = (Element) entryList.item(i);
                String Time = xp.evaluate("content/properties/Created/text()", entry);
                String Name = xp.evaluate("content/properties/Title/text()", entry);
                String CloudPath = xp.evaluate("id/text()", entry);

                nxl.types.NxFileBase folder = new nxl.types.NXFolder();
                if (File == null)
                    fillFileParmas(folder, "/" + Name, CloudPath + "/RootFolder", 0, Name, Time);
                else
                    fillFileParmas(folder, File.getLocalPath() + "/" + Name, CloudPath + "/RootFolder", 0, Name, Time);

                rt.addChild(folder);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void parseSites(String xmlDoc, nxl.types.NxFileBase rt, nxl.types.INxFile File) throws Exception {

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();

        try {
            Element root = document.getDocumentElement(); // get root node
            NodeList entryList = root.getElementsByTagName("entry");

            for (int i = 0; i < entryList.getLength(); i++) {
                Element entry = (Element) entryList.item(i);
                String Name = xp.evaluate("content/properties/Title/text()", entry);
                String Time = xp.evaluate("content/properties/Created/text()", entry);
                String CloudPath = xp.evaluate("id/text()", entry);

                nxl.types.NxFileBase site = new nxl.types.NXSite();
                if (File == null)
                    fillFileParmas(site, "/%" + Name, CloudPath, 0, "%" + Name, Time);
                else
                    fillFileParmas(site, File.getLocalPath() + "/%" + Name, CloudPath, 0, "%" + Name, Time);

                rt.addChild(site);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void parseChildFolders(String xmlDoc, nxl.types.NxFileBase rt, nxl.types.INxFile File) throws Exception {

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();

        try {
            Element root = document.getDocumentElement();
            NodeList entryList = root.getElementsByTagName("entry");

            for (int i = 0; i < entryList.getLength(); i++) {
                Element entry = (Element) entryList.item(i);
                String Name = xp.evaluate("content/properties/Name/text()", entry);
                String CloudPath = xp.evaluate("id/text()", entry);

                nxl.types.NxFileBase folder = new nxl.types.NXFolder();
                fillFileParmas(folder, File.getLocalPath() + "/" + Name, CloudPath, 0, Name, "");
                rt.addChild(folder);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void parseChildFiles(String xmlDoc, nxl.types.NxFileBase rt, nxl.types.INxFile File) throws Exception {

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();

        try {
            Element root = document.getDocumentElement();
            NodeList entryList = root.getElementsByTagName("entry");

            for (int i = 0; i < entryList.getLength(); i++) {
                Element entry = (Element) entryList.item(i);
                String Name = xp.evaluate("content/properties/Name/text()", entry);
                String Length = xp.evaluate("content/properties/Length/text()", entry);
                String Time = xp.evaluate("content/properties/TimeLastModified/text()", entry);
                String CloudPath = xp.evaluate("id/text()", entry);

                nxl.types.NxFileBase file = new nxl.types.NXDocument();
                fillFileParmas(file, File.getLocalPath() + "/" + Name, CloudPath, Long.valueOf(Length), Name, Time);
                rt.addChild(file);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private String parseGetCurrentUserId(String xmlDoc) throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();
        String userId = null;
        try {
            Element root = document.getDocumentElement();
            NodeList entryList = root.getElementsByTagName("content");

            for (int i = 0; i < entryList.getLength(); i++) {
                Element entry = (Element) entryList.item(i);
                userId = xp.evaluate("properties/Id/text()", entry);
            }
            return userId;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    @SuppressWarnings("unchecked")
    private Map<String, String> parseGetUserDetailInfo(String xmlDoc) throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        XPathFactory xpf = XPathFactory.newInstance();
        XPath xp = xpf.newXPath();

        Map detailInfo = new HashMap<String, String>();
        try {
            Element root = document.getDocumentElement();
            NodeList entryList = root.getElementsByTagName("content");
            for (int i = 0; i < entryList.getLength(); i++) {
                Element entry = (Element) entryList.item(i);
                String user = xp.evaluate("properties/Title/text()", entry);
                String email = xp.evaluate("properties/EMail/text()", entry);
                detailInfo.put("user", user);
                detailInfo.put("email", email);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return detailInfo;
    }

    @SuppressWarnings("unchecked")
    private Map<String, String> parseGetSiteQuota(String xmlDoc) throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document document = db.parse(new InputSource(new StringReader(xmlDoc)));

        Map quotaInfo = new HashMap<String, String>();
        try {
            Element root = document.getDocumentElement();
            NodeList childNodes = root.getChildNodes();
            for (int i = 0; i < childNodes.getLength(); i++) {
                if (childNodes.item(i).getNodeName().equals("d:Storage")) {
                    quotaInfo.put("Storage", childNodes.item(i).getTextContent());
                } else if (childNodes.item(i).getNodeName().equals("d:StoragePercentageUsed")) {
                    quotaInfo.put("StoragePercentageUsed", childNodes.item(i).getTextContent());
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return quotaInfo;
    }

    private nxl.types.NxFileBase GetRoot() {
        try {
            String xmlRootFolders = GetRootFolders();
            String xmlRootSites = GetRootSites();

            if (xmlRootFolders == null || xmlRootSites == null) {
                return null;
            }

            nxl.types.NxFileBase rt = GetRootBase();

            parseSites(xmlRootSites, rt, null);
            parseDocLists(xmlRootFolders, rt, null);

            return rt;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }
        return null;
    }

    private nxl.types.NxFileBase GetChildSiteAndLists(nxl.types.INxFile File) {

        try {
            String xmlChildrenSites = GetChildrenSites(File.getCloudPath());
            String xmlLists = GetDocLists(File.getCloudPath());

            if (xmlLists == null || xmlChildrenSites == null) {
                return null;
            }
            nxl.types.NxFileBase rt = GetBase(File);

            parseSites(xmlChildrenSites, rt, File);
            parseDocLists(xmlLists, rt, File);

            return rt;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return null;
    }


    private nxl.types.NxFileBase GetFoldersAndFiles(nxl.types.INxFile File) {
        try {
            String xmlFolders = GetFolders(File.getCloudPath());
            String xmlFiles = GetFiles(File.getCloudPath());

            if (xmlFolders == null || xmlFiles == null) {
                return null;
            }

            nxl.types.NxFileBase rt = GetBase(File);

            parseChildFolders(xmlFolders, rt, File);
            parseChildFiles(xmlFiles, rt, File);

            return rt;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return null;
    }

    public String GetAuthCookie() {
        return mCookie;
    }

    public void SetAuthCookie(String cookie) {
        mCookie = cookie;
    }

    private String GetRootFolders() {
        return GetResources(mAccount.getUrl() + "/_api/web/lists?$filter=BaseTemplate eq 101&$select=Title,Created,RootFolder", METHOD_GET);
    }

    private String GetRootSites() {
        return GetResources(mAccount.getUrl() + "/_api/web/webs?$select=Title,Created", METHOD_GET);
    }

    private String GetFolders(String CloudPath) {
        return GetResources(CloudPath + "/Folders?$filter=Name ne 'Forms'", METHOD_GET);
    }

    private String GetFiles(String CloudPath) {
        return GetResources(CloudPath + "/Files", METHOD_GET);
    }

    private String GetDocLists(String CloudPath) {
        return GetResources(CloudPath + "/lists?$select=BaseTemplate,Title,Hidden,Id&$filter=BaseTemplate eq 101", METHOD_GET);
    }

    // used to get the user id (will be used to get detail info.)
    private String GetCurrentUserInfo() {
        return GetResources(mAccount.getUrl() + "/_api/web/CurrentUser", METHOD_GET);
    }

    // get the user and email
    private String GetCurrentUserInfoDetail(String userId) {
        return GetResources(mAccount.getUrl() + "/_api/web/SiteUserInfoList/Items" + "(" + userId + ")", METHOD_GET);
    }

    // get used Space and total space
    private String GetSiteQuota() {
        return GetResources(mAccount.getUrl() + "/_api/site/usage", METHOD_GET);
    }

    private String GetChildrenSites(String CloudPath) {
        return GetResources(CloudPath + "/webs", METHOD_GET);
    }

    private nxl.types.NxFileBase GetRootBase() {
        nxl.types.NxFileBase rt = new nxl.types.NXFolder();
        fillFileParmas(rt, "/", "/", 0, "root", "");
        return rt;
    }

    private nxl.types.NxFileBase GetBase(nxl.types.INxFile File) {
        nxl.types.NxFileBase rt = null;
        if (File.isSite()) {
            rt = new nxl.types.NXSite();
        } else {
            rt = new nxl.types.NXFolder();
        }
        fillFileParmas(rt, File.getLocalPath(), File.getCloudPath(), File.getSize(), File.getName(), "");
        return rt;
    }

    private String GetResources(String Path, String method) {
        InputStream in = null;
        String ret = "";
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

            String cookie = mAccount.getCookie();
            urlConn.setRequestProperty("Cookie", cookie);
            urlConn.setRequestMethod(method);
            Log.d("cookie", cookie);
            urlConn.setRequestProperty("Content-type", "application/atom+xml");
            urlConn.setDoInput(true);
            in = urlConn.getInputStream();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();

        } catch (KeyManagementException e) {
            e.printStackTrace();
        }

        if (null == in) {
            return ret;
        }
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));
        String line = null;
        StringBuffer result = new StringBuffer();
        try {
            while ((line = bufferedReader.readLine()) != null) {
                result.append(line);
            }
            in.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        ret = result.toString();
        return ret;
    }

    public void StartDownloadFile(String CloudPath) {
        isCancel = false;
        try {
            mfilePath = CloudPath + "/$value";
            if (mfilePath.contains(" "))
                mfilePath = mfilePath.replaceAll(" ", "%20");
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    public void StartUploadFile(String CloudPath, String fileName, boolean bUpdate) {
        try {
            if (bUpdate) {
                mfilePath = CloudPath + "/Files/Add(overwrite=true,url='%@')";
            } else {
                mfilePath = CloudPath + "/Files/Add(overwrite=false,url='%@')";
            }

            mfilePath = mfilePath.replace("%@", fileName);
            if (mfilePath.contains(" "))
                mfilePath = mfilePath.replaceAll(" ", "%20");
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    public boolean DownloadFile(String LocalPath, long fileSize, IUpdateDownLoadFile update) {
        boolean b = false;
        try {
            InputStream inputStream = OpenhttpsConnection(mfilePath);
            File local = new File(LocalPath);
            Helper.makeSureDocExist(local);
            //File output stream
            OutputStream outputStream = new FileOutputStream(local);
            b = copyStreamToOutput(inputStream, outputStream, fileSize, LocalPath, update);
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }
        return b;
    }

    private String parseDigestValue(String result) {

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        try {
            DocumentBuilder db = dbf.newDocumentBuilder();
            // parse xml file
            Document document = db.parse(new InputSource(new StringReader(result)));
            // query xml document
            XPathFactory xpf = XPathFactory.newInstance();
            XPath xp = xpf.newXPath();
            Log.d("the text is: ", result);
            String value = xp.evaluate("//FormDigestValue/text()", document.getDocumentElement());

            return value;
        } catch (SAXException e) {
            e.printStackTrace();
        } catch (ParserConfigurationException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (XPathExpressionException e) {
            e.printStackTrace();
        }

        return "";
    }

    private String GetContextInfo() {
        return GetResources(mAccount.getUrl() + "/_api/contextinfo", METHOD_POST);
    }

    public boolean UploadFile(File localFile, long fileSize, IUpdateUploadFile update) {
        // 1. get the FormDigestValue node first.
        String contextInfo = GetContextInfo();
        String DigestValue = parseDigestValue(contextInfo);

        boolean b = false;
        long totalRead = 0;

        try {
            b = true;
            URL url = new URL(mfilePath);
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, new TrustManager[]{new MyTrustManager()}, new SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            HttpsURLConnection.setDefaultHostnameVerifier(new MyHostnameVerifier());

            HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
            conn.setDoOutput(true);
            conn.setDoInput(true);
            conn.setUseCaches(false);
            String cookie = mAccount.getCookie();
            conn.setRequestProperty("Cookie", cookie);
            conn.setRequestProperty("Connection", "Keep-Alive");
            conn.setRequestProperty("Content-Length", String.valueOf(fileSize));
            conn.setRequestProperty("X-RequestDigest", DigestValue);
            conn.setRequestProperty("Content-Type", "application/x-javascript; charset=" + "UTF-8");
            conn.setRequestMethod("POST");

            conn.connect();
            mSharepointonlineOutputStream = conn.getOutputStream();
            InputStream is = new FileInputStream(localFile);
            DataOutputStream dos = new DataOutputStream(mSharepointonlineOutputStream);
            byte[] bytes = new byte[1024];
            int len = 0;
            while ((len = is.read(bytes)) != -1) {
                dos.write(bytes, 0, len);

                totalRead += len;
                long newValue = (long) (totalRead / (double) fileSize * 100);
                if (newValue > 100) {
                    newValue = 100;
                }
                update.onUpdate(newValue);
            }
            is.close();
            dos.flush();

            String result = "";
            if (conn.getResponseCode() == HttpURLConnection.HTTP_OK) {
                BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream(), "utf-8"));
                String inputLine;
                while ((inputLine = in.readLine()) != null) {
                    result += inputLine;
                }
                in.close();
                Log.d(TAG, result);
            } else {
                b = false;
                ErrorCode.SHARE_POINT_ONLINE_UPLOAD_REQUEST_ERROR = conn.getResponseCode();
            }

        } catch (IOException e) {
            e.printStackTrace();
            b = false;
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            b = false;
        } catch (KeyManagementException e) {
            e.printStackTrace();
            b = false;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
            b = false;
        }

        return b;
    }

    private boolean copyStreamToOutput(InputStream input, OutputStream output, long fileSize, String localPath, IUpdateDownLoadFile update) {
        BufferedOutputStream bos = null;
        long totalRead = 0;
        long lastListened = 0;

        boolean bException = false;
        boolean b = true;

        try {
            bos = new BufferedOutputStream(output);

            byte[] buffer = new byte[4096];
            int read;
            while (true) {
                read = input.read(buffer);
                if (read < 0) {
                    break;
                }

                bos.write(buffer, 0, read);

                totalRead += read;

                long newValue = (long) (totalRead / (double) fileSize * 100);
                if (newValue > 100) {
                    newValue = 100;
                }

                if (isCancel) {
                    try {
                        // close stream at non-UI thread
                        if (mSharepointonlineInputStream != null) {
                            mSharepointonlineInputStream.close();
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                update.onUpdate(newValue);
            }

            bos.flush();
            output.flush();
            // Make sure it's flushed out to disk
            try {
                if (output instanceof FileOutputStream) {
                    ((FileOutputStream) output).getFD().sync();
                }
            } catch (SyncFailedException e) {
                b = false;
            }

        } catch (IOException e) {
            b = false;
            bException = true;
        } finally {
            if (bos != null) {
                try {
                    bos.close();
                } catch (IOException e) {
                }
            }
            try {
                output.close();
            } catch (IOException e) {
            }
            try {
                input.close();
            } catch (IOException e) {
            }

            if (bException) {
                Helper.deleteFile(new File(localPath));
            }
        }

        return b;
    }


    public void AbortTask() {
        isCancel = true;
    }

    public void AbortUploadTask() {
        try {
            if (mSharepointonlineOutputStream != null) {
                mSharepointonlineOutputStream.close();
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    private InputStream OpenhttpsConnection(String stringUrl) {

        int response = -1;
        try {

            URL url = new URL(stringUrl);

            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, new TrustManager[]{new MyTrustManager()}, new SecureRandom());

            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            HttpsURLConnection.setDefaultHostnameVerifier(new MyHostnameVerifier());
            HttpsURLConnection urlConn = (HttpsURLConnection) url.openConnection();

            String cookie = mAccount.getCookie();
            urlConn.setRequestProperty("Cookie", cookie);
            urlConn.setDoInput(true);
            response = urlConn.getResponseCode();
            if (response == HttpsURLConnection.HTTP_OK) {
                mSharepointonlineInputStream = urlConn.getInputStream();
            }
        } catch (IOException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();

        } catch (KeyManagementException e) {
            e.printStackTrace();
        }
        return mSharepointonlineInputStream;
    }

    private void fillFileParmas(nxl.types.NxFileBase Base, String LocalPath, String CloudPath, long Size, String Name, String Time) {
        Base.setLocalPath(LocalPath);
        Base.setCloudPath(CloudPath);
        Base.setSize(Size);
        Base.setName(Name);
        Base.setLastModifiedTime(Time);
        if (!Time.isEmpty()) {
            DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
            df.setTimeZone(TimeZone.getTimeZone("UTC"));
            try {
                Base.setLastModifiedTimeLong(df.parse(Time).getTime());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public interface IUpdateDownLoadFile {
        void onUpdate(long newValue);
    }

    public interface IUpdateUploadFile {
        void onUpdate(long newValue);
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

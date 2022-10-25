package appInstance.remoteRepo.sharepoint;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.HttpVersion;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.NTCredentials;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.client.params.AuthPolicy;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.entity.FileEntity;
import org.apache.http.entity.HttpEntityWrapper;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpParams;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.HTTP;
import org.apache.http.util.EntityUtils;
import org.json.JSONArray;
import org.json.JSONObject;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FilterOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.StringReader;
import java.io.SyncFailedException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Map;
import java.util.TimeZone;

import javax.net.ssl.SSLContext;
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
import appInstance.remoteRepo.sharepoint.util.NTLMSchemeFactory;
import errorHandler.ErrorCode;

/**
 * Created by wwu on 6/1/2015.
 */
public class SharePointSdk {
    private static final String TAG = "SharePointSdk";
    private static boolean bAuthSuccessful = false;
    private static Account AuthAccount = null;
    private Account account = null;
    private HttpUriRequest DownloadFileRequest = null;
    private HttpPost UploadFileRequest = null;

    public SharePointSdk(String Url, String UserName, String Password) {
        Account thisAccount = new Account();
        thisAccount.Url = Url;
        thisAccount.Username = UserName;
        thisAccount.Password = Password;
        account = thisAccount;
    }

    public static void StartAuth(Activity mActivity) {
        Intent intent = new Intent();
        intent.setClass(mActivity, LoginActivity.class);
        mActivity.startActivity(intent);
    }

    public static boolean NTLMAuth(String Url, String Domain, String UserName, String Password) {
        DefaultHttpClient httpclient = getNewHttpClient(Url);
        httpclient.getAuthSchemes().register(AuthPolicy.NTLM, new NTLMSchemeFactory());
        httpclient.getCredentialsProvider().setCredentials(new AuthScope(AuthScope.ANY_HOST, AuthScope.ANY_PORT),
                new NTCredentials(UserName, Password, "", Domain));

        try {
            HttpUriRequest httpget = new HttpGet(appInstance.remoteRepo.sharepoint.util.EncodeUrl.stringByAddingPercentEscapesUsingEncoding(Url + "/_api/Site"));
            HttpResponse response = httpclient.execute(httpget);
            int StatusCode = response.getStatusLine().getStatusCode();
            if (StatusCode == HttpStatus.SC_OK) {
                Account thisAccount = new Account();
                thisAccount.Url = Url;
                if (Domain.isEmpty()) {
                    thisAccount.Username = UserName;
                } else {
                    thisAccount.Username = Domain + "\\" + UserName;
                }
                thisAccount.Password = Password;

                AuthAccount = thisAccount;

                bAuthSuccessful = true;
                return true;
            }
        } catch (IOException e) {

        } catch (Exception e) {

        }

        return false;
    }

    private static DefaultHttpClient getNewHttpClient(String Path) {
        String tempPath = Path.toLowerCase();
        if (tempPath.startsWith("http://")) {
            return new DefaultHttpClient();
        }

        try {
            KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
            trustStore.load(null, null);

            MySSLSocketFactory sf = new MySSLSocketFactory(trustStore);
            sf.setHostnameVerifier(SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);

            HttpParams params = new BasicHttpParams();
            HttpProtocolParams.setVersion(params, HttpVersion.HTTP_1_1);
            HttpProtocolParams.setContentCharset(params, HTTP.UTF_8);

            SchemeRegistry registry = new SchemeRegistry();
            registry.register(new Scheme("http", PlainSocketFactory.getSocketFactory(), 80));
            registry.register(new Scheme("https", sf, 443));

            ClientConnectionManager ccm = new ThreadSafeClientConnManager(params, registry);

            return new DefaultHttpClient(ccm, params);
        } catch (Exception e) {
            return new DefaultHttpClient();
        }
    }

    public static boolean GetAuthStatus() {
        return bAuthSuccessful;
    }

    public static void ResetAuthStatus() {
        bAuthSuccessful = false;
    }

    public static Account GetAuthAccount() {
        return AuthAccount;
    }

    public nxl.types.NxFileBase GetMetaInfo(nxl.types.INxFile File) {
        String path = File.getCloudPath();

        if (path.equals("/")) {
            return GetRoot();
        } else if (File.isSite()) {
            return GetWebsAndFolders(File);
        } else {
            return GetFoldersAndFiles(File);
        }
    }

    public boolean getRepositoryInfo(RemoteRepoInfo info) {
        try {
            // get the user nad email
            boolean canGetUserInfo = true;
            String userId = GetCurrentUserId();
            Map<String, String> infoMap = GetRepoDetailInfo(userId);
            if (infoMap != null) {
                info.displayName = infoMap.get("Title");
                info.email = infoMap.get("EMail");
            } else {
                canGetUserInfo = false;
            }

            // get the total space and used space.
            boolean canGetSiteQuota = true;
            Map<String, String> quotaMap = GetRepoSiteQuota();
            if (quotaMap != null) {
                if (quotaMap.size() > 0) {
                    info.remoteTotalSpace = Long.valueOf(quotaMap.get("Storage"));
                    info.remoteUsedSpace = (long) (info.remoteTotalSpace * Float.parseFloat(quotaMap.get("StoragePercentageUsed")));
                }
            } else {
                canGetSiteQuota = false;
            }
            return canGetUserInfo || canGetSiteQuota;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public void StartDownloadFile(String CloudPath) {
        try {
            DownloadFileRequest = new HttpGet(CloudPath + "/$value");
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    public void StartUploadFile(String CloudPath, String fileName, boolean bUpdate) {
        try {

            fileName = Uri.encode(fileName, "utf-8");
            if (bUpdate) {
                UploadFileRequest = new HttpPost(CloudPath + "/Files/Add(url='" + fileName + "',overwrite=true)");
            } else {
                UploadFileRequest = new HttpPost(CloudPath + "/Files/Add(url='" + fileName + "',overwrite=false)");
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    public boolean DownloadFile(String CloudPath, String LocalPath, long fileSize, IUpdateDownLoadFile update) {
        boolean b = false;

        try {
            DefaultHttpClient httpclient = getNewHttpClient(CloudPath);
            setAuth(httpclient);

            HttpResponse response = httpclient.execute(DownloadFileRequest);
            int StatusCode = response.getStatusLine().getStatusCode();
            if (StatusCode == HttpStatus.SC_OK) {
                InputStream inputStream = response.getEntity().getContent();
                File local = new File(LocalPath);
                Helper.makeSureDocExist(local);
                //File output stream
                OutputStream outputStream = new FileOutputStream(local);
                b = copyStreamToOutput(inputStream, outputStream, fileSize, update, LocalPath);
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }

        DownloadFileRequest = null;
        return b;
    }

    private boolean copyStreamToOutput(InputStream input, OutputStream output, long fileSize, IUpdateDownLoadFile updatet, String LocalPath) {
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

                updatet.onUpdate(newValue);
                ;
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
                Helper.deleteFile(new File(LocalPath));
            }
        }

        return b;
    }

    public boolean UploadFile(String CloudPath, File localFile, long fileSize, IUpdateUploadFile update) {
        boolean b = false;

        try {
            String contextInfo = GetResources(account.Url + "/_api/contextinfo");
            String DigestValue = parseDigestValue(contextInfo);
            UploadFileRequest.setHeader("X-RequestDigest", DigestValue);
            HttpEntity httpentity = new FileEntity(localFile, "binary/octet-stream");
            UploadFileRequest.setEntity(new ProgressHttpEntity(httpentity, fileSize, update));

            DefaultHttpClient httpclient = getNewHttpClient(CloudPath);
            setAuth(httpclient);

            HttpResponse response = httpclient.execute(UploadFileRequest);
            int StatusCode = response.getStatusLine().getStatusCode();
            if (StatusCode == HttpStatus.SC_OK) {
                return true;
            } else {
                b = false;
                ErrorCode.SHARE_POINT_UPLOAD_REQUEST_ERROR = StatusCode;
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }

        UploadFileRequest = null;
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

    public void AbortTask() {
        try {
            if (DownloadFileRequest != null) {
                DownloadFileRequest.abort();
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    public void AbortUploadTask() {
        try {
            if (UploadFileRequest != null) {
                UploadFileRequest.abort();
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    private nxl.types.NxFileBase GetRoot() {
        try {
            String JSONRootFolders = GetRootFolders();
            String JSONRootSites = GetRootSites();

            JSONObject json = null;
            JSONArray results = null;
            nxl.types.NxFileBase rt = GetRootBase();
            if (JSONRootFolders != null) {
                json = new JSONObject(JSONRootFolders);
                results = json.getJSONObject("d").getJSONArray("results");

                for (int i = 0; i < results.length(); i++) {
                    String Name = ((JSONObject) results.opt(i)).getString("Title");
                    String Time = ((JSONObject) results.opt(i)).getString("Created");
                    String CloudPath = ((JSONObject) results.opt(i)).getJSONObject("RootFolder").getJSONObject("__deferred").getString("uri");

                    nxl.types.NxFileBase folder = new nxl.types.NXFolder();
                    fillFileParmas(folder, "/" + Name, CloudPath, 0, Name, Time);
                    rt.addChild(folder);
                }
            }

            if (JSONRootSites != null) {
                json = new JSONObject(JSONRootSites);
                results = json.getJSONObject("d").getJSONArray("results");

                for (int i = 0; i < results.length(); i++) {
                    String Name = ((JSONObject) results.opt(i)).getString("Title");
                    String Time = ((JSONObject) results.opt(i)).getString("Created");
                    String CloudPath = ((JSONObject) results.opt(i)).getJSONObject("__metadata").getString("uri");

                    nxl.types.NxFileBase site = new nxl.types.NXSite();
                    fillFileParmas(site, "/%" + Name, CloudPath, 0, "%" + Name, Time);
                    rt.addChild(site);
                }
            }


            return rt;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return null;
    }

    private nxl.types.NxFileBase GetFoldersAndFiles(nxl.types.INxFile File) {
        try {
            String JSONFolders = GetFolders(File.getCloudPath());
            String JSONFiles = GetFiles(File.getCloudPath());

            JSONObject json = null;
            JSONArray results = null;
            nxl.types.NxFileBase rt = GetBase(File);

            if (JSONFolders != null) {
                json = new JSONObject(JSONFolders);
                results = json.getJSONObject("d").getJSONArray("results");

                for (int i = 0; i < results.length(); i++) {
                    String Name = ((JSONObject) results.opt(i)).getString("Name");
                    String CloudPath = ((JSONObject) results.opt(i)).getJSONObject("__metadata").getString("uri");

                    nxl.types.NxFileBase folder = new nxl.types.NXFolder();
                    fillFileParmas(folder, File.getLocalPath() + "/" + Name, CloudPath, 0, Name, File.getLastModifiedTime());
                    rt.addChild(folder);
                }
            }

            if (JSONFiles != null) {
                json = new JSONObject(JSONFiles);
                results = json.getJSONObject("d").getJSONArray("results");

                for (int i = 0; i < results.length(); i++) {
                    String Name = ((JSONObject) results.opt(i)).getString("Name");
                    Long Size = ((JSONObject) results.opt(i)).getLong("Length");
                    String Time = ((JSONObject) results.opt(i)).getString("TimeLastModified");
                    String CloudPath = ((JSONObject) results.opt(i)).getJSONObject("__metadata").getString("uri");

                    nxl.types.NxFileBase file = new nxl.types.NXDocument();
                    fillFileParmas(file, File.getLocalPath() + "/" + Name, CloudPath, Size, Name, Time);
                    rt.addChild(file);
                }
            }

            return rt;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return null;
    }

    private nxl.types.NxFileBase GetWebsAndFolders(nxl.types.INxFile File) {
        try {
            String JSONWebs = GetWebs(File.getCloudPath());
            String JSONFolders = GetFoldersOfWeb(File.getCloudPath());

            JSONObject json = null;
            JSONArray results = null;
            nxl.types.NxFileBase rt = GetBase(File);

            if (JSONWebs != null) {
                json = new JSONObject(JSONWebs);
                results = json.getJSONObject("d").getJSONArray("results");

                for (int i = 0; i < results.length(); i++) {
                    String Name = ((JSONObject) results.opt(i)).getString("Title");
                    String Time = ((JSONObject) results.opt(i)).getString("Created");
                    String CloudPath = ((JSONObject) results.opt(i)).getJSONObject("__metadata").getString("uri");

                    nxl.types.NxFileBase site = new nxl.types.NXSite();
                    fillFileParmas(site, File.getLocalPath() + "/%" + Name, CloudPath, 0, "%" + Name, Time);
                    rt.addChild(site);
                }
            }

            if (JSONFolders != null) {
                json = new JSONObject(JSONFolders);
                results = json.getJSONObject("d").getJSONArray("results");

                for (int i = 0; i < results.length(); i++) {
                    String Name = ((JSONObject) results.opt(i)).getString("Title");
                    String Time = ((JSONObject) results.opt(i)).getString("Created");
                    String CloudPath = ((JSONObject) results.opt(i)).getJSONObject("RootFolder").getJSONObject("__deferred").getString("uri");

                    nxl.types.NxFileBase folder = new nxl.types.NXFolder();
                    fillFileParmas(folder, File.getLocalPath() + "/" + Name, CloudPath, 0, Name, Time);
                    rt.addChild(folder);
                }
            }

            return rt;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return null;
    }

    private String GetCurrentUserId() {
        String userId = null;
        try {
            String jsonUserInfo = GetCurrentUserInfo();
            if (jsonUserInfo == null) {
                return null;
            }
            JSONObject json = new JSONObject(jsonUserInfo);
            userId = json.getJSONObject("d").getString("Id");//   String Name = ((JSONObject) results.opt(i)).getString("Title");
            String test = null;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }

        return userId;
    }

    private Map<String, String> GetRepoDetailInfo(String userId) {
        Map<String, String> map = new HashMap<>();
        try {
            String jsonUserInfo = GetCurrentUserInfoDetail(userId);
            if (jsonUserInfo == null) {
                return null;
            }
            JSONObject json = new JSONObject(jsonUserInfo);
            map.put("Title", json.getJSONObject("d").getString("Title"));
            map.put("EMail", json.getJSONObject("d").getString("EMail"));
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }

        return map;
    }

    private Map<String, String> GetRepoSiteQuota() {
        Map<String, String> map = new HashMap<>();
        try {
            String jsonUserInfo = GetSiteQuota();
            if (jsonUserInfo == null) {
                return null;
            }
            JSONObject json = new JSONObject(jsonUserInfo);
            map.put("Storage", json.getJSONObject("d").getString("Storage"));
            map.put("StoragePercentageUsed", json.getJSONObject("d").getString("StoragePercentageUsed"));
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }

        return map;
    }

    private void setAuth(DefaultHttpClient httpclient) {
        int pBackslash = account.Username.indexOf('\\');
        if (pBackslash != -1) {
            String Domain = account.Username.substring(0, pBackslash);
            String Username = account.Username.substring(pBackslash + 1);

            httpclient.getAuthSchemes().register(AuthPolicy.NTLM, new NTLMSchemeFactory());
            httpclient.getCredentialsProvider().setCredentials(new AuthScope(AuthScope.ANY_HOST, AuthScope.ANY_PORT),
                    new NTCredentials(Username, account.Password, "", Domain));
        }
    }

    private String GetRootFolders() {
        return GetResources(account.Url + "/_api/web/lists?$filter=BaseTemplate eq 101&$select=Title,Created,RootFolder", true);
    }

    private String GetRootSites() {
        return GetResources(account.Url + "/_api/web/webs?$select=Title,Created", true);
    }

    private String GetFolders(String CloudPath) {
        return GetResources(CloudPath + "/Folders", false);
    }

    private String GetWebs(String CloudPath) {
        return GetResources(CloudPath + "/webs?$select=Title,Created", false);
    }

    private String GetFoldersOfWeb(String CloudPath) {
        return GetResources(CloudPath + "/lists?$filter=BaseTemplate%20eq%20101&$select=Title,Created,RootFolder", false);
    }

    private String GetFiles(String CloudPath) {
        return GetResources(CloudPath + "/Files?$filter=Exists%20eq%20true", false);
    }

    // used to get the user id (will be used to get detail info.)
    private String GetCurrentUserInfo() {
        return GetResources(account.Url + "/_api/web/CurrentUser", true);
    }

    // get the user and email
    private String GetCurrentUserInfoDetail(String userId) {
        return GetResources(account.Url + "/_api/web/SiteUserInfoList/Items" + "(" + userId + ")", true);
    }

    // get used Space and total space
    private String GetSiteQuota() {
        return GetResources(account.Url + "/_api/site/usage", true);
    }

    private String GetResources(String Path, Boolean bNeedEnCode) {
        DefaultHttpClient httpclient = getNewHttpClient(Path);
        setAuth(httpclient);

        try {
            HttpUriRequest httpget = null;

            if (bNeedEnCode) {
                httpget = new HttpGet(appInstance.remoteRepo.sharepoint.util.EncodeUrl.stringByAddingPercentEscapesUsingEncoding(Path));
            } else {
                httpget = new HttpGet(Path);
            }

            httpget.addHeader("Accept", "application/json;odata=verbose");
            HttpResponse response = httpclient.execute(httpget);
            int StatusCode = response.getStatusLine().getStatusCode();
            if (StatusCode == HttpStatus.SC_OK) {
                return EntityUtils.toString(response.getEntity());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private String GetResources(String CloudPath) {
        DefaultHttpClient httpclient = getNewHttpClient(CloudPath);
        setAuth(httpclient);
        try {
            HttpPost httpPost = new HttpPost(CloudPath);
            HttpResponse response = httpclient.execute(httpPost);
            int StatusCode = response.getStatusLine().getStatusCode();
            if (StatusCode == HttpStatus.SC_OK) {
                return EntityUtils.toString(response.getEntity());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private nxl.types.NxFileBase GetRootBase() {
        nxl.types.NxFileBase rt = new nxl.types.NXFolder();
        fillFileParmas(rt, "/", "/", 0, "root", "");
        return rt;
    }

    private nxl.types.NxFileBase GetBase(nxl.types.INxFile File) {
        nxl.types.NxFileBase rt = new nxl.types.NXFolder();
        fillFileParmas(rt, File.getLocalPath(), File.getCloudPath(), File.getSize(), File.getName(), File.getLastModifiedTime());
        return rt;
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

    public static class MySSLSocketFactory extends SSLSocketFactory {
        SSLContext sslContext = SSLContext.getInstance("TLS");

        public MySSLSocketFactory(KeyStore truststore) throws NoSuchAlgorithmException, KeyManagementException, KeyStoreException, UnrecoverableKeyException {
            super(truststore);

            TrustManager tm = new X509TrustManager() {
                public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
                }

                public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
                }

                public X509Certificate[] getAcceptedIssuers() {
                    return null;
                }
            };

            sslContext.init(null, new TrustManager[]{tm}, null);
        }

        @Override
        public Socket createSocket(Socket socket, String host, int port, boolean autoClose) throws IOException, UnknownHostException {
            return sslContext.getSocketFactory().createSocket(socket, host, port, autoClose);
        }

        @Override
        public Socket createSocket() throws IOException {
            return sslContext.getSocketFactory().createSocket();
        }
    }

    public static class ProgressHttpEntity extends HttpEntityWrapper {
        private final IUpdateUploadFile update;
        private final long length;

        public ProgressHttpEntity(HttpEntity wrapped, long fileSize, IUpdateUploadFile update) throws Exception {
            super(wrapped);
            this.update = update;
            this.length = fileSize;
        }

        public void writeTo(OutputStream out) throws IOException {
            this.wrappedEntity.writeTo(new CountingOutputStream(out));
        }

        private class CountingOutputStream extends FilterOutputStream {
            private long transferred = 0L;

            public CountingOutputStream(OutputStream out) {
                super(out);
            }

            public void write(byte[] b, int off, int len) throws IOException {
                this.out.write(b, off, len);
                transferred += (long) len;
                updateProgress();
            }

            public void write(int b) throws IOException {
                super.write(b);
                ++transferred;
                updateProgress();
            }

            private void updateProgress() {
                long newValue = (long) (transferred / (double) length * 100);
                if (newValue > 100) {
                    newValue = 100;
                }

                update.onUpdate(newValue);
                ;
            }
        }
    }
}

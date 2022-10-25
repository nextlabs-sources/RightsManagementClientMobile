package restAPIWithRMS;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.List;
import java.util.Map;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import appInstance.ViewerApp;

public class HttpsGet {
    static private final boolean DEBUG = ViewerApp.DEBUG;

    static {
        if (DEBUG) {
            try {
                HttpsURLConnection.setDefaultHostnameVerifier(new HostnameVerifier() {
                    @Override
                    public boolean verify(String hostname, SSLSession session) {
                        return true;
                    }
                });

                TrustManager[] trustAllCerts = new TrustManager[]{new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers() {
                        return null;
                    }

                    @Override
                    public void checkClientTrusted(X509Certificate[] arg0, String arg1) throws CertificateException {
                        // Not implemented
                    }

                    @Override
                    public void checkServerTrusted(X509Certificate[] arg0, String arg1) throws CertificateException {
                        // Not implemented
                    }
                }};
                SSLContext sc = SSLContext.getInstance("TLS");
                sc.init(null, trustAllCerts, new java.security.SecureRandom());
                HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    static public String sendGetRequest(URL url, Map<String, String> headInfo, Listener listener) throws Exception {

        __callback(listener, "sanity check");

        // sanity check
        if (url == null) {
            throw new NullPointerException("uri is null");
        }
        if (headInfo == null) {
            throw new NullPointerException("headInfo is nul");
        }

        HttpsURLConnection urlConn = (HttpsURLConnection) url.openConnection();
        urlConn.setRequestMethod("GET");
//        urlConn.addRequestProperty("Accept", "application/x-www-form-urlencoded");
//        urlConn.addRequestProperty("User-Agent", "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0)");
//        urlConn.addRequestProperty("Content-Type", "text/xml; charset=utf-8");

        if (!headInfo.isEmpty()) {
            for (Map.Entry<String, String> e : headInfo.entrySet()) {
                urlConn.addRequestProperty(e.getKey(), e.getValue());
            }
        }

        urlConn.connect();

        int errorCode = urlConn.getResponseCode(); // for test.
        if (urlConn.getResponseCode() != HttpURLConnection.HTTP_OK) {
            throw new RuntimeException("POST request not worked" + "-" + String.valueOf(urlConn.getResponseCode()));
        }

        InputStream in = urlConn.getInputStream();
        int c;
        StringBuilder response = new StringBuilder("");
        while ((c = in.read()) != -1)
            response.append((char) (c));
        in.close();

        return response.toString();

    }

    static private void __callback(Listener listener, String state) {
        if (listener != null) {
            listener.currentState(state);
        }
    }

    static private void __callback(Listener listener, int current, int total) {
        if (listener != null) {
            listener.progress(current, total);
        }
    }
}

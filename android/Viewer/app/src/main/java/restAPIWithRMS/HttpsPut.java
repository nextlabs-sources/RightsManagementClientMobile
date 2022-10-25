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

/**
 * this class is designed to support basic https put request,as client side
 */
public class HttpsPut {
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

    static public InputStream sendRequest(URL url, Map<String, String> headInfo, String postInfo, Listener listener) throws Exception {
        __callback(listener, "sanity check");

        // sanity check
        if (url == null) {
            throw new NullPointerException("uri is null");
        }
        if (headInfo == null) {
            throw new NullPointerException("headInfo is nul");
        }
        if (postInfo == null) {
            throw new NullPointerException("postInfo string is nul");
        }

        HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();


        __callback(listener, "config http header");

        conn.setDoOutput(true);
        conn.setDoInput(true);

        conn.setRequestMethod("PUT");
        conn.setDefaultUseCaches(false);
        conn.setUseCaches(false);
        // add header
        // add default header
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "application/json");
        conn.setRequestProperty("Charset", "UTF-8");
        conn.addRequestProperty("Content-Length", Integer.toString(postInfo.length()));

        if (!headInfo.isEmpty()) {
            for (Map.Entry<String, String> e : headInfo.entrySet()) {
                conn.addRequestProperty(e.getKey(), e.getValue());
            }
        }


        OutputStream os = conn.getOutputStream();
        int total = postInfo.length();
        int blockSize = 0x100;
        int current = 0;
        byte[] data = postInfo.getBytes("UTF-8");

        __callback(listener, "write http request body ");

        while (current < total) {
            if (current + blockSize <= total) {
                os.write(data, current, blockSize);
                current += blockSize;
            } else {
                os.write(data, current, total - current);
                current += total - current;
            }

            __callback(listener, current, total);
        }
        os.flush();
        os.close();
        // result

        __callback(listener, "waiting for the response of http server ....");

        if (conn.getResponseCode() != HttpURLConnection.HTTP_OK) {
            throw new RuntimeException("PUT request not worked" + "-" + String.valueOf(conn.getResponseCode()));
        }

        __callback(listener, "analyzing http response");

        // Response header
        Map<String, List<String>> map = conn.getHeaderFields();
        for (Map.Entry<String, List<String>> entry : map.entrySet()) {
            if (DEBUG) {
                System.out.println("Key : " + entry.getKey() + " ,Value : " + entry.getValue());
            }
        }
        // Response body
        BufferedReader in = new BufferedReader(new InputStreamReader(
                conn.getInputStream()));
        String inputLine;
        StringBuffer response = new StringBuffer();

        while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
        }
        in.close();
        conn.disconnect();

        return new ByteArrayInputStream(response.toString().getBytes("utf-8"));

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
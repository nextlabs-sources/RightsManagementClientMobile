package commonUtils;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiManager;
import android.util.Log;

import java.lang.reflect.Method;


public class NetworkStatus {

    private static final String TAG = "Network";
    private Context mContext;

    public NetworkStatus(Context context) {
        mContext = context;
    }

    @Deprecated
    public static boolean isNetworkAvailable(Context context) {
        ConnectivityManager connectivityManager
                = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    public boolean isNetworkAvailable() {
        ConnectivityManager connectivityManager
                = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    @Deprecated
    public boolean isWifiOn() {
        WifiManager wifiManager = (WifiManager) mContext.getSystemService(Context.WIFI_SERVICE);

        if (wifiManager.isWifiEnabled()) {
            Log.e(TAG, "wifi is on!!");
            return true;
        } else {
            Log.e(TAG, "wifi is off!!");
            return false;
        }

    }

    @Deprecated
    public boolean isGprsOn() {
        ConnectivityManager connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        boolean isOpen = false;

        try {
            Method method = connectivityManager.getClass().getMethod("getMobileDataEnabled", null);
            isOpen = (Boolean) method.invoke(connectivityManager, null);
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }

        Log.e(TAG, "gprs is " + isOpen);

        return isOpen;
    }
}

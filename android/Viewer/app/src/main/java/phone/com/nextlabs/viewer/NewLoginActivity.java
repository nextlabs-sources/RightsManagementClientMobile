package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.net.http.SslError;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.JavascriptInterface;
import android.webkit.SslErrorHandler;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.nextlabs.viewer.R;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import appInstance.ViewerApp;
import restAPIWithRMS.Listener;
import rms.common.NXUserInfo;

// our JavascriptInterface
class AjaxHandler {

    private static final String TAG = "AjaxHandler";
    public boolean bLoginSuccess = false;
    private final Context context;
    private NewLoginActivity newLoginActivity;

    public AjaxHandler(Context context, NewLoginActivity activity) {
        this.context = context;
        this.newLoginActivity = activity;
    }

    @JavascriptInterface
    public void showToast(String toast) {
        Log.w(TAG, toast);
        // Toast.makeText(context, toast, Toast.LENGTH_SHORT).show();
    }

    @JavascriptInterface
    public void ajaxBegin() {
        Log.w(TAG, "AJAX Begin");
        // Toast.makeText(context, "AJAX Begin", Toast.LENGTH_SHORT).show();
    }

    @JavascriptInterface
    public void ajaxDone() {
        Log.w(TAG, "AJAX Done");
        // Toast.makeText(context, "AJAX Done", Toast.LENGTH_SHORT).show();
    }

    @JavascriptInterface
    public void getAjaxResponse(String result) {

        try {
            JSONObject jsonObject = new JSONObject(result);
            int statusCode = jsonObject.getInt("statusCode");
            String message = jsonObject.getString("message");

            if (statusCode == 200 && "Authorized".equals(message)) {
                bLoginSuccess = true;
                // save the user info.
                NXUserInfo userInfo = NXUserInfo.parseUserInfo(result);
                // create a new session:
                ViewerApp.getInstance().getSession().newSession(userInfo, newLoginActivity.getTenantID());

            } else {
                Toast.makeText(context, "can't get the ajax response.", Toast.LENGTH_SHORT).show();
            }

        } catch (JSONException e) {
            e.printStackTrace();
        }

    }

}

public class NewLoginActivity extends Activity {

    private static final String TAG = "NewLoginActivity";
    //  private static final String RMS_SERVICE_PREFIX = "https://";

    public static final String RM_SERVER = "https://rmtest.nextlabs.solutions";
    private String tenantID = "skydrm.com";

    private static final String rmsServer = "pf1-w1201.qapf1.qalab01.nextlabs.com:8443";

    //  private static final String rmsServer = "lam-javapc1.qapf1.qalab01.nextlabs.com:9443";
    public WebView mWebView;
    private boolean loginSuccess = false;
    private ProgressDialog progressBar;
    private String result = null;

    private ImageView mImageView;
    private TextView mTextView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_new_login);

        initUI();
        initWebView();
        tryLogin();
    }

    @Override
    // Override onKeyDown(int keyCoder,KeyEvent event) of Activity.
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if ((keyCode == KeyEvent.KEYCODE_BACK) && mWebView != null && mWebView.canGoBack()) {
            // goBack() indicates back to previous page when user click other link address in one page.
            mWebView.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    private void doEdit() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View editView = LayoutInflater.from(this).inflate(R.layout.login_edit, null);
        final EditText et_tenantId = (EditText) editView.findViewById(R.id.ev_tenantId);
        et_tenantId.setText("skydrm.com");

        builder.setCancelable(false);
        builder.setView(editView);
        builder.setPositiveButton(R.string.ok, null);
        builder.setNegativeButton(R.string.Reset, null);
        builder.setTitle(R.string.title_popup_dialog);
        builder.setMessage(getString(R.string.dialog_edit_msg));

        final AlertDialog dialog = builder.create();
        dialog.show();

        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String input = et_tenantId.getText().toString();
                if (!input.isEmpty()) {
                    tenantID = input;
                    tryLogin();
                    dialog.dismiss();
                } else {
                    // Toast.makeText(NewLoginActivity.this, "please input the tenant ID!", Toast.LENGTH_SHORT).show();
                }
            }
        });

        dialog.getButton(AlertDialog.BUTTON_NEGATIVE).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                et_tenantId.setText("skydrm.com");
            }
        });

        final Button positiveButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
        et_tenantId.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s.toString().isEmpty()) {
                    positiveButton.setEnabled(false);
                } else {
                    positiveButton.setEnabled(true);
                }
            }
        });

    }

    public String getTenantID() {
        return tenantID;
    }

    private void initUI() {
        mImageView = (ImageView) findViewById(R.id.refresh);
        mImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                tryLogin();
            }
        });

        mTextView = (TextView) findViewById(R.id.loginEdit);
        mTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                doEdit();
            }
        });
    }

    private void tryLogin() {
        class LoginAsyncTask extends AsyncTask<Void, String, Boolean> {

            @Override
            protected void onPreExecute() {
                super.onPreExecute();
                progressBar = ProgressDialog.show(NewLoginActivity.this, null, getString(R.string.loading));
            }

            @Override
            protected Boolean doInBackground(Void... params) {

                return ViewerApp.getInstance().getUserLoginUrl_2(RM_SERVER, tenantID, new Listener() {
                    @Override
                    public void progress(int current, int total) {
                    }

                    @Override
                    public void currentState(String state) {
                        publishProgress(state);
                    }
                });

            }

            @Override
            protected void onPostExecute(Boolean result) {
                if (result) {
                    mWebView.loadUrl(ViewerApp.getInstance().sessionGetUserLoginUrl_2());

                } else {
                    // todo, error handler
                    Toast.makeText(NewLoginActivity.this, "get auth Url failed, please check the networks.", Toast.LENGTH_SHORT).show();
                    progressBar.dismiss();
                }

            }
        }

        new LoginAsyncTask().execute();
    }

    private void initWebView() {
        mWebView = (WebView) findViewById(R.id.login_webView);
        mWebView.getSettings().setJavaScriptEnabled(true);
        mWebView.getSettings().setAllowFileAccess(true);
        mWebView.getSettings().setBuiltInZoomControls(true);

        mWebView.getSettings().setCacheMode(WebSettings.LOAD_NO_CACHE);
        mWebView.clearHistory();
        mWebView.clearFormData();
        mWebView.clearCache(true);

        final AjaxHandler ajaxHandle = new AjaxHandler(this, this);
        mWebView.addJavascriptInterface(ajaxHandle, "ajaxHandler");

        // clean cache cookies.
        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.removeAllCookie();


        mWebView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return false;
            }

            // need to authenticate for browser.
//            @Override
//            public void onReceivedClientCertRequest(WebView view, ClientCertRequest request) {
//                request.proceed()
//            }

            @Override
            public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                handler.proceed();
            }

            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                Log.d(TAG, url);

            }

            @Override
            public void onPageFinished(WebView view, String url) {
                Log.d(TAG, url);

                // use js to intercept the ajax get the info.
//                view.loadUrl("javascript:$(document).ajaxSend(function (event, request, settings) { " +
//                        "ajaxHandler.showToast(\"onTestajaxSend\");" +
//                        "ajaxHandler.showToast(settings.url); " +
//                        "ajaxHandler.showToast(settings.data); " +
//                        "});");
                view.loadUrl("javascript:$( document).ajaxSuccess(function( event, xhr, settings ) {" +
                        "ajaxHandler.showToast(\"onTestajaxSuccess\");" +
                        "ajaxHandler.showToast(settings.url); " +
                        "ajaxHandler.getAjaxResponse(xhr.responseText); " +
                        "});");

                progressBar.dismiss();

                if (ajaxHandle.bLoginSuccess) {
                    // close browser and switch into main page
                    mWebView.removeAllViews();
                    mWebView.destroy();
                    NewLoginActivity.this.setResult(Activity.RESULT_OK);
                    NewLoginActivity.this.finish();
                }
                super.onPageFinished(view, url);

            }

            @Override
            public void onLoadResource(WebView view, String url) {
                Log.d(TAG, url);
            }

            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                Toast.makeText(NewLoginActivity.this, "load failed", Toast.LENGTH_SHORT).show();
                // todo, how to handle this case, popup a alert to prompt user to select cancel or retry？
            }
        });
    }

}


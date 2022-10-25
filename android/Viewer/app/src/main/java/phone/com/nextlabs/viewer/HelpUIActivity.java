package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import commonUtils.AppVersionHelper;

public class HelpUIActivity extends Activity {

    private final static String NEXTLABS_URL = "http://www.nextlabs.com";
    private TextView mBack;
    private ImageView mLogoImage;
    private TextView mTv_info;
    private TextView mTv_version;
    private TextView mTv_contact;
    private TextView mTv_name;

    private int mScreenWidth;
    private int mScreenHeight;
    private Context mContext;
    private WebView mWebView;
    private boolean isClickContactUs = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_help_ui);

        mContext = this;
        DisplayMetrics dm = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(dm);
        mScreenWidth = dm.widthPixels;
        mScreenHeight = dm.heightPixels;

        initUI();
    }

    private void initUI() {
        mBack = (TextView) findViewById(R.id.tv_help_back);

        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                HelpUIActivity.this.finish();
            }
        });

        mLogoImage = (ImageView) findViewById(R.id.help_image);
        mTv_info = (TextView) findViewById(R.id.help_textview1);
        mTv_version = (TextView) findViewById(R.id.help_textview2);
        mTv_contact = (TextView) findViewById(R.id.help_textview3);
        mTv_contact.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                isClickContactUs = true;
                View view = (View) LayoutInflater.from(mContext).inflate(R.layout.help_contact_webview, null);
                setContentView(view);
                mWebView = (WebView) findViewById(R.id.help_webView);
                // set support javascript
                mWebView.getSettings().setJavaScriptEnabled(true);
                // set can access file
                mWebView.getSettings().setAllowFileAccess(true);
                // set support zoom in zoom out
                mWebView.getSettings().setBuiltInZoomControls(true);

                // directly open url in activity instead of calling browser
                mWebView.setWebViewClient(new WebViewClient() {
                    @Override
                    public boolean shouldOverrideUrlLoading(WebView view, String url) {
                        view.loadUrl(url);
                        return true;
                    }
                });
                mWebView.loadUrl(NEXTLABS_URL);
            }
        });
        mTv_name = (TextView) findViewById(R.id.help_textview4);

        int versionCode = AppVersionHelper.getVersionCode(HelpUIActivity.this);
        mTv_version.setText("version " + versionCode);

        setControlMargin(mLogoImage);
        setControlMargin(mTv_info);
        setControlMargin(mTv_version);
        setControlMargin(mTv_name);
        setControlMargin(mTv_contact);
    }

    private void setControlMargin(Object object) {
        RelativeLayout.LayoutParams lp = null;
        if (object instanceof ImageView) {
            lp = (RelativeLayout.LayoutParams) ((ImageView) object).getLayoutParams();
//            lp.width = mScreenWidth / 3;
//            lp.height = mScreenHeight / 5;
            lp.setMargins(0, mScreenHeight / 10, 0, 0);
            ((ImageView) object).setLayoutParams(lp);
        } else if (object instanceof TextView) {
            lp = (RelativeLayout.LayoutParams) ((TextView) object).getLayoutParams();
            if (((TextView) object).getText().equals("NEXTLABS")) {
                lp.setMargins(0, 0, 0, mScreenHeight / 40);
            } else {
                lp.setMargins(0, mScreenHeight / 40, 0, 0);
            }
            ((TextView) object).setLayoutParams(lp);
        }
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

    @Override
    public void onBackPressed() {
        if (isClickContactUs) {
            Intent intent = getIntent();
            finish();
            startActivity(intent);
            isClickContactUs = false;
        } else {
            super.onBackPressed();
        }
    }

}

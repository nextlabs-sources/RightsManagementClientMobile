package appInstance.remoteRepo.sharepointonline;

import android.app.Activity;
import android.app.ProgressDialog;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import appInstance.remoteRepo.sharepoint.SharePointSdk;
import errorHandler.ErrorCode;
import errorHandler.GenericError;

public class LoginActivity extends Activity {
    static private final boolean DEBUG = ViewerApp.DEBUG;
    public static EditText mEditTextUsername;
    private static LoginActivity mInstance;
    private Button mButton;
    private EditText mEditTextPassword;
    private EditText mEditTextUrl;
    private AuthenticationManager mAuthenticationManager;
    private View mView;
    private ProgressDialog mProgressDialog;
    private Account account;
    private TextView mBack;

    public static LoginActivity getmInstance() {
        return mInstance;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sharepoint_online);

        mBack = (TextView) findViewById(R.id.tv_back);
        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                LoginActivity.this.finish();
            }
        });

        mInstance = this;
        mButton = (Button) findViewById(R.id.sharepointonline_sign_in_button);

        mEditTextUsername = (EditText) findViewById(R.id.sharepointonline_username);
        mEditTextPassword = (EditText) findViewById(R.id.sharepointonline_password);
        mEditTextUrl = (EditText) findViewById(R.id.sharepointonline_url);

        if (DEBUG) {
            mEditTextUrl.setText("https://nextlabs.sharepoint.com");
            mEditTextUsername.setText("AllenNing@nextlabs.onmicrosoft.com");
            mEditTextPassword.setText("NDS_19861206abc");
        }

        mButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                bind();
            }
        });
    }

    private void bind() {
        // check input
        boolean paraError = false;
        View focusView = null;
        if (TextUtils.isEmpty(mEditTextUrl.getText().toString())) {
            GenericError.showUI(LoginActivity.this, ErrorCode.USER_NOT_INPUT_ERROR, getString(R.string.error_not_input_url), true, false, false, null);
            focusView = mEditTextUrl;
            paraError = true;
        } else if (TextUtils.isEmpty(mEditTextUsername.getText().toString())) {
            GenericError.showUI(LoginActivity.this, ErrorCode.USER_NOT_INPUT_ERROR, getString(R.string.error_not_input_userName), true, false, false, null);
            focusView = mEditTextUsername;
            paraError = true;
        } else if (TextUtils.isEmpty(mEditTextPassword.getText().toString())) {
            GenericError.showUI(LoginActivity.this, ErrorCode.USER_NOT_INPUT_ERROR, getString(R.string.error_not_input_password), true, false, false, null);
            focusView = mEditTextPassword;
            paraError = true;
        }
        if (paraError) {
            focusView.requestFocus();
            return;
        }

        account = new Account();
        account.setUsername(getUsername());
        account.setUrl(getUrl());
        new GetCookieAsyncTask().execute();
    }

    public String getUsername() {
        return mEditTextUsername.getText().toString();
    }

    public String getPassword() {
        return mEditTextPassword.getText().toString();
    }

    public String getUrl() {
        return mEditTextUrl.getText().toString();
    }

    private class GetCookieAsyncTask extends AsyncTask<Void, Void, Boolean> {
        private boolean isNetworkAvailable = true;
        private boolean canGetCookie = true;
        private boolean isRightUrl = true;

        @Override
        protected Boolean doInBackground(Void... params) {
            if (ViewerApp.networkStatus.isNetworkAvailable()) {
                mAuthenticationManager = new AuthenticationManager();
                String cookie = mAuthenticationManager.sharepointOnlineAuth();
                if (!TextUtils.isEmpty(cookie)) {
                    account.setCookie(cookie);
                    if (mAuthenticationManager.verifySiteUrl(account.getUrl(), cookie)) {
                        return isRightUrl;
                    } else {
                        return isRightUrl = false;
                    }
                } else {
                    return canGetCookie = false;
                }
            } else {
                return isNetworkAvailable = false;
            }

        }

        @Override
        protected void onPostExecute(Boolean result) {
            mProgressDialog.dismiss();
            if (result) {
                finish();
                SharePointOnlineSdk.SetAuthAccount(account);
                SharePointOnlineSdk.SetAuthStatus(true);
            } else if (!isRightUrl) {
                GenericError.showUI(LoginActivity.this, ErrorCode.SHARE_POINT_ONLINE_LOGIN_ERROR, getString(R.string.error_sharePointOnline_site_url), true, false, false, null);
            } else if (!isNetworkAvailable) {
                GenericError.showUI(LoginActivity.this, ErrorCode.NETWORK_NOT_AVAILABLE_ERROR, getString(R.string.error_network_unreach_msg), true, false, false, null);
            } else {
                GenericError.showUI(LoginActivity.this, ErrorCode.SHARE_POINT_ONLINE_LOGIN_ERROR, getString(R.string.error_sharePointOnline_login), true, false, false, null);
            }
        }

        @Override
        protected void onPreExecute() {
            mProgressDialog = ProgressDialog.show(LoginActivity.this, "", getString(R.string.add_account));
        }
    }

}

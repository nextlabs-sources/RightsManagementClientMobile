package appInstance.remoteRepo.sharepoint;

import android.app.Activity;
import android.app.ProgressDialog;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import errorHandler.ErrorCode;
import errorHandler.GenericError;

/**
 * Created by wwu on 6/1/2015.
 */

public class LoginActivity extends Activity {
    static private final boolean DEBUG = ViewerApp.DEBUG;
    private Button mSignInButton;
    private EditText mUrlView;
    private EditText mUsernameView;
    private EditText mPasswordView;
    private TextView mBack;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sharepoint);

        mBack = (TextView) findViewById(R.id.tv_back);
        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                LoginActivity.this.finish();
            }
        });

        mSignInButton = (Button) findViewById(R.id.sharepoint_sign_in_button);
        mSignInButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                Add();
            }
        });

        mUrlView = (EditText) findViewById(R.id.sharepoint_url);
        mUsernameView = (EditText) findViewById(R.id.sharepoint_username);
        mPasswordView = (EditText) findViewById(R.id.sharepoint_password);


        if (DEBUG) {
            //todo: for test only
//            mUrlView.setText("https://rms-sp2013.qapf1.qalab01.nextlabs.com/sites/Dev");
//            mUsernameView.setText("qapf1\\abraham.lincoln");
//            mPasswordView.setText("abraham.lincoln");

            mUrlView.setText("https://rms-sp2013.qapf1.qalab01.nextlabs.com/sites/sc");
            mUsernameView.setText("qapf1\\administrator");
            mPasswordView.setText("123blue!");
        }

    }

    private void Add() {
        boolean paraError = false;
        View focusView = null;
        if (TextUtils.isEmpty(mUrlView.getText().toString())) {
            GenericError.showUI(LoginActivity.this, ErrorCode.USER_NOT_INPUT_ERROR, getString(R.string.error_not_input_url), true, false, false, null);
            focusView = mUrlView;
            paraError = true;
        } else if (TextUtils.isEmpty(mUsernameView.getText().toString())) {
            GenericError.showUI(LoginActivity.this, ErrorCode.USER_NOT_INPUT_ERROR, getString(R.string.error_not_input_userName), true, false, false, null);
            focusView = mUsernameView;
            paraError = true;
        } else if (TextUtils.isEmpty(mPasswordView.getText().toString())) {
            GenericError.showUI(LoginActivity.this, ErrorCode.USER_NOT_INPUT_ERROR, getString(R.string.error_not_input_password), true, false, false, null);
            focusView = mPasswordView;
            paraError = true;
        }
        if (paraError) {
            focusView.requestFocus();
            return;
        }

        LoginTask logintask = new LoginTask(this, mUrlView.getText().toString(), mUsernameView.getText().toString(), mPasswordView.getText().toString());
        logintask.execute((Void) null);
    }

    public class LoginTask extends AsyncTask<Void, Void, Boolean> {

        private String mUrl = "";
        private String mDomain = "";
        private String mUsername = "";
        private String mPassword = "";

        private Activity activity;
        private ProgressDialog progressDialog;
        private boolean isNetworkAvailable = true;

        LoginTask(Activity activity, String Url, String UserName, String password) {
            this.activity = activity;
            mUrl = Url;
            int pBackslash = UserName.indexOf('\\');
            if (pBackslash == -1) {
                mUsername = UserName;
            } else {
                mDomain = UserName.substring(0, pBackslash);
                mUsername = UserName.substring(pBackslash + 1);
            }
            mPassword = password;
        }

        @Override
        protected Boolean doInBackground(Void... params) {
            if (!mDomain.isEmpty()) {
                if (ViewerApp.networkStatus.isNetworkAvailable()) {
                    return SharePointSdk.NTLMAuth(mUrl, mDomain, mUsername, mPassword);
                } else {
                    return isNetworkAvailable = false;
                }

            }

            return true;
        }

        @Override
        protected void onPreExecute() {
            progressDialog = ProgressDialog.show(LoginActivity.this, "", getString(R.string.add_account));
        }

        @Override
        protected void onPostExecute(final Boolean success) {
            progressDialog.dismiss();
            if (TextUtils.isEmpty(mDomain)) {
                GenericError.showUI(LoginActivity.this, ErrorCode.SHARE_POINT_LOGIN_ERROR, getString(R.string.error_sharePoint_login), true, false, false, null);
                return;
            }
            if (success) {
                activity.finish();
            } else if (!isNetworkAvailable) {
                GenericError.showUI(LoginActivity.this, ErrorCode.NETWORK_NOT_AVAILABLE_ERROR, getString(R.string.error_network_unreach_msg), true, false, false, null);
            } else {
                GenericError.showUI(LoginActivity.this, ErrorCode.SHARE_POINT_LOGIN_ERROR, getString(R.string.error_sharePoint_login), true, false, false, null);
            }
        }
    }
}
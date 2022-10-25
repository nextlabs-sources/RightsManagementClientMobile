package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.TextView;
import android.widget.Toast;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import commonUtils.ProgressDialogEx;
import errorHandler.ErrorCode;
import errorHandler.GenericError;
import nxl.bridge.NxlCryptoTokenBlob;
import nxl.types.INxFile;

import java.io.File;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ProtectActivity extends Activity implements IRemoteRepo.IUploadFileCallback {
    private static String TAG = ProtectActivity.class.getSimpleName();
    private static final String NXL_FILE_SUFFIX = ".nxl";
    private static final String ERROR_CODE = "400";
    private static final String MSG_ALREADY_EXISTS = "resource_already_exists";
    private TextView mBack;
    private TextView mProtectOrShare;
    private TextView mTitleName;
    private TextView mTvFileName;

    private CheckBox mCbView;
    private CheckBox mCbEdit;
    private CheckBox mCbPrint;
    private CheckBox mCbShare;
    private CheckBox mCbDownload;
    private CheckBox mCbWatermark;

    private INxFile mClickFile;
    private INxFile mParentFolder;
    private File mCurrentFile;
    private File mSourceFile;
    private String mFilePath;
    private String mFileName;
    private boolean mIsNxlFile = false;

    private ICancelable uploadFileCancelHandler;
    private ProgressDialogEx mProgressDialog;
    private boolean mIsCancelUpload = false;
    private Map<String, String> mMapToken;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_protect);

        init();
    }

    private void initUI() {
        mBack = (TextView) findViewById(R.id.protect_back);
        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ProtectActivity.this.finish();
                overridePendingTransition(R.anim.in_from_left, R.anim.out_to_right);
            }
        });

        mProtectOrShare = (TextView) findViewById(R.id.file_protect);
//        mProtectOrShare.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                Toast.makeText(ProtectActivity.this,"click protect",Toast.LENGTH_SHORT).show();
//                protectFile();
//            }
//        });

        mTvFileName = (TextView) findViewById(R.id.fileName);
        mTvFileName.setText(mFileName);
        mTitleName = (TextView) findViewById(R.id.protect_name);
        // checkbox
        mCbView = (CheckBox) findViewById(R.id.cb_view);
        mCbEdit = (CheckBox) findViewById(R.id.cb_edit);
        mCbPrint = (CheckBox) findViewById(R.id.cb_print);
        mCbShare = (CheckBox) findViewById(R.id.cb_share);
        mCbDownload = (CheckBox) findViewById(R.id.cb_download);
        mCbWatermark = (CheckBox) findViewById(R.id.cb_watermark);
    }

    private void init() {
        Intent intent = getIntent();

        mClickFile = (INxFile) getIntent().getSerializableExtra("click_protect");
        mParentFolder = ViewerApp.getInstance().findParentThroughBoundService(mClickFile);
        mCurrentFile = (File) getIntent().getSerializableExtra("current_file");
        mFilePath = mCurrentFile.getPath();
        mFileName = mFilePath.substring(mFilePath.lastIndexOf('/') + 1);

        if (nxl.bridge.NxlUtils.isNxlFile(mFilePath, false)) {
            mIsNxlFile = true;
            //  TODO: 8/23/2016  1. get some rights 2. send Log to server
        }

        initUI();

        if (intent != null && intent.getAction() != null) {
            if (intent.getAction().equals("NXProtectToView")) {
                mTitleName.setText(getString(R.string.PROTECT));
                mProtectOrShare.setText(getString(R.string.protect));

                mProtectOrShare.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        Toast.makeText(ProtectActivity.this, "click protect", Toast.LENGTH_SHORT).show();
                        protectFile();
                    }
                });

            } else if (intent.getAction().equals("NXShareToView")) {
                mTitleName.setText(getString(R.string.PROTECT_AND_SHARE));
                mProtectOrShare.setText(getString(R.string.share));

                mProtectOrShare.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        Toast.makeText(ProtectActivity.this, "click share", Toast.LENGTH_SHORT).show();
                        // // TODO: 8/24/2016
                    }
                });

            }
        }

    }

    private void protectFile() {

        class GetTokenThread extends AsyncTask<Void, Void, Boolean> {
            @Override
            protected Boolean doInBackground(Void... params) {
                try {
                    ViewerApp.getInstance().getSession().startGetToken();
                    mMapToken = ViewerApp.getInstance().getSession().getMapTokens();
                } catch (Exception e) {
                    e.printStackTrace();
                    Log.d(TAG, "get the token failed!!");
                }

                return mMapToken.size() > 0;
            }

            @Override
            protected void onPostExecute(Boolean result) {
                super.onPostExecute(result);
                if (result) {
                    doProtect();
                } else {
                    Toast.makeText(ProtectActivity.this, "can't get the token from server", Toast.LENGTH_SHORT).show();
                }
            }
        }

        mIsCancelUpload = false;
        if (!mIsNxlFile) {
            mMapToken = ViewerApp.getInstance().getSession().getMapTokens();
            if (mMapToken.size() > 0) {
                doProtect();
            } else {
                new GetTokenThread().executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void) null);
            }

        } else {
            updateFile(mClickFile, mCurrentFile);
            showProgressBar();
        }

    }

    private void doProtect() {
        NxlCryptoTokenBlob tokenBlob = createTokenBlob();
        // convert to nxl file , is cipherPath file had existed , overwrite it
        String cipherPath = mFilePath + NXL_FILE_SUFFIX;
        String ownerId = ViewerApp.getInstance().getSession().getUserInfo().getId();
        if (!nxl.bridge.NxlUtils.convert(ownerId, mFilePath, cipherPath, tokenBlob, true)) {
            Log.d(TAG, "convert nxl file failed!");
        }

        // upload this new created cipher file to cloud
        upLoadFile(new File(cipherPath));
        showProgressBar();
    }

    private NxlCryptoTokenBlob createTokenBlob() {
        Set set = mMapToken.keySet();
        Iterator iterator = set.iterator();
        String duid = null;
        String encryptToken = null;
        while (iterator.hasNext()) {
            duid = (String) iterator.next();
            encryptToken = mMapToken.get(duid);
            if (encryptToken != null) {
                break;
            }
        }

        // remove the encrypt token after using it.
        iterator.remove();
        mMapToken.remove(duid);

        int ml = ViewerApp.getInstance().getSession().getMl();
        List<String> agreements = ViewerApp.getInstance().getSession().getAgreements();

        String aggrementKey = null;
        String publicKeyInCA = null;
        if (agreements.size() == 3) {
            aggrementKey = agreements.get(2);
            publicKeyInCA = agreements.get(1);
        } else {
            aggrementKey = agreements.get(agreements.size() - 1);
            publicKeyInCA = agreements.get(agreements.size() - 1);
        }

        return new NxlCryptoTokenBlob(aggrementKey, publicKeyInCA, ml, duid, encryptToken);
    }

    private void upLoadFile(File sourceFile) {
        mSourceFile = sourceFile;
        try {
            if (mParentFolder != null) {
                ViewerApp.getInstance().uploadFile(mParentFolder, sourceFile.getName(), sourceFile, this);
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }

    }

    private void updateFile(INxFile updateFile, File sourceFile) {
        mSourceFile = sourceFile;
        try {
            if (mParentFolder != null) {
                ViewerApp.getInstance().updateFile(mParentFolder, updateFile, sourceFile, this);
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }

    }

    private void showProgressBar() {

        mProgressDialog = new ProgressDialogEx(ProtectActivity.this);
        mProgressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        mProgressDialog.setMessage(getString(R.string.uploading));
        mProgressDialog.setCancelable(false);
        mProgressDialog.setButton(DialogInterface.BUTTON_NEGATIVE, getString(R.string.cancel), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                // ViewerApp.getInstance().getInterfaceOfRemoteRepo().cancelUpload();
                if (uploadFileCancelHandler != null) {
                    uploadFileCancelHandler.cancel();
                    mIsCancelUpload = true;
                } else {
                    Log.e(TAG, "fatal error, uploadFileCancelHandler should not null");
                }
                dialog.dismiss();
            }
        });
        mProgressDialog.show();
    }

    @Override
    public void cancelHandler(ICancelable handler) {
        uploadFileCancelHandler = handler;
    }

    @Override
    public void uploadFileProgress(long newValue) {
        mProgressDialog.setProgress((int) newValue);
    }

    @Override
    public void uploadFileFinished(boolean taskStatus, String cloudPath, String errorMsg) {
        mProgressDialog.dismiss();

        if (mIsCancelUpload) {
            mIsCancelUpload = false;
            return;
        }

        if (taskStatus) {
            // doSetting();
        } else {
            if (errorMsg.equals(ERROR_CODE) || errorMsg.equals(MSG_ALREADY_EXISTS)) {
                // todo, rename and then upload.
            } else {
                GenericError.showUI(ProtectActivity.this, ErrorCode.UPLOAD_FILE_FAILED_ERROR, getString(R.string.upload_file_failed), true, false, true, null);
            }
        }

    }
}

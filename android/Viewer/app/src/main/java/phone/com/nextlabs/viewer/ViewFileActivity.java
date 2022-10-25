package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.MediaStore;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.text.TextUtils;
import android.util.Base64;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.animation.AnimationUtils;
import android.webkit.MimeTypeMap;
import android.webkit.WebView;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.PopupWindow;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.artifex.mupdfdemo.MuPDFActivity;
import com.media.audioView;
import com.media.videoView;
import com.nextlabs.viewer.R;
import com.nextlabs.viewer.hps.AndroidMobileSurfaceView;
import com.nextlabs.viewer.hps.AndroidUserMobileSurfaceView;
import com.nextlabs.viewer.hps.ConvertFile;
import com.nextlabs.viewer.hps.MobileApp;
import com.nextlabs.viewer.hps.ViewerUtils;
import com.sap.ve.DVLCore;
import com.sap.ve.DVLScene;
import com.sap.ve.SDVLImage;
import com.sap.ve.SDVLProceduresInfo;
import com.sapUtilityForVDSView.CustomRenderer;
import com.sapUtilityForVDSView.GalleryAdapter;
import com.sapUtilityForVDSView.Surface;
import com.widgets.ViewFilePopupWindow;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import PolicyEngineWrapper.NXPolicyEngineWrapper;
import PolicyEngineWrapper.NXRights;
import PolicyEngineWrapper.NXRightsList;
import appInstance.ViewerApp;
import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import commonUtils.FileHelper;
import commonUtils.ScreenLocationUtils;
import commonUtils.SendLogHelper;
import commonUtils.viewFileUtils.viewFileHelper;
import database.BoundService;
import errorHandler.ErrorCode;
import errorHandler.GenericError;
import errorHandler.IErrorResult;
import nxl.bridge.NxlCryptoTokenBlob;
import nxl.bridge.NxlFingerPrint;
import nxl.fileFormat.Tags;
import nxl.types.INxFile;
import nxl.types.NxFileBase;
import restAPIWithRMS.DecryptionToken;
import restAPIWithRMS.dataTypes.NXKeyRing;
import restAPIWithRMS.dataTypes.NXLogRequestValue;

public class ViewFileActivity extends Activity
        implements AndroidMobileSurfaceView.Callback,
        Surface.IGetCore,
        Surface.IGetFilePath,
        MuPDFActivity.ITitleEvent {
    static private final boolean DEBUG = ViewerApp.DEBUG;
    static private final int MOBILE_SURFACE_GUI_ID = 0;
    static private final String TAG = "NX_ViewActivity";
    private static final String TMP_MAIL_PATH = "tmp/copyFromMailAttachment";
    private static final String TMP_DRIVE_PATH = "tmp/copyFromThirdPartyDrive";
    public static ViewFileActivity ViewFileActivityInstance;
    private static Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> mObligations;
    boolean bHSFView = false;
    private ViewerApp app = ViewerApp.getInstance();
    private View mDownloadProgress;
    private ProgressBar mProgressBar;
    private TextView mProgressValue;
    private TextView mContentViewBack;
    private Button btnSelect;
    private int downTouchX, upTouchX;
    private boolean bTouched;
    private RelativeLayout rlTitle;
    private TextView mFileName;
    //private FrameLayout mFrame;
    private FrameLayout mOverlayFrameLayout;
    private RelativeLayout mOverlayLayout;
    private AndroidUserMobileSurfaceView mSurfaceView;
    private ProgressDialog mProgress;
    private View mCurrentToolbarView;
    private View mNormalFile;
    private RelativeLayout mMainLayout;
    private Surface mVdsSurface;
    private String mfilePath;
    private String mPath = "";
    private boolean bNeedConvert = false;
    private String mTmpConvertPath = "";
    private boolean bConvertSucceed = false;
    private String mTmpDecryptPath = "";
    private String mTmpDecryptName = "";
    private boolean bDecryptSucceed = false;
    private DVLCore m_core;
    private boolean mModeSimpleShadowEnabled;
    private DVLScene m_dvlScene;
    private SDVLProceduresInfo m_dvlProceduresInfo;
    private RecyclerView m_recyclerView;
    private GalleryAdapter m_dvlImageAdapter;
    private List<SDVLImage> m_dvlImageData = new ArrayList<SDVLImage>();
    private Context mContext;
    private ViewFilePopupWindow mPopupListView;
    private boolean mFromDownload = false;
    private boolean isDownloadFinished = false;
    private MuPDFActivity muPDFParser = null;
    private Bundle msavedInstanceState = null;
    private String muPDFFilePath;
    // be used to render Text&Image file
    private WebView webView;
    // be used to render Video&Audio file
    private videoView videoView;
    private audioView audioView;

    // open file flag as third party.
    private boolean bAsThirdPartyOpen = false;

    private View viewBg;

    private INxFile clickFileName;
    private File workingFile;

    // file download and cancelhandler
    private ICancelable downLoadCancelHandler;
    private IRemoteRepo.IDownLoadCallback downLoadCallback = null;

    private Map<String, Integer> mOverlayTextColor;

    private boolean mIsActivityVisibility;
    private BroadcastReceiver mBroadcastReceive;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        msavedInstanceState = savedInstanceState;
        requestWindowFeature(Window.FEATURE_NO_TITLE);
//        mFrame = new FrameLayout(this);
//        mFrame.addView(LayoutInflater.from(getBaseContext()).
//                inflate(R.layout.activity_viewfile, null));
//        setContentView(mFrame);

        setContentView(R.layout.activity_viewfile);
        mContext = this;
        ViewFileActivityInstance = ViewFileActivity.this;

        initView();
        initEvent();
        initPopupWindow();

        downLoadCallback = new IRemoteRepo.IDownLoadCallback() {
            @Override
            public void cancelHandler(ICancelable handler) {
                downLoadCancelHandler = handler;
                // register BackButton response
            }

            @Override
            public void downloadFileFinished(boolean taskStatus, String localPath, String errorMsg) {
                // un register BackButton response
                RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) mMainLayout.getLayoutParams();
                lp.removeRule(RelativeLayout.CENTER_IN_PARENT);
                mMainLayout.removeView(mDownloadProgress);

                if (taskStatus) {
                    workingFile = new File(localPath);
                    btnSelect.setEnabled(true);
                    mFromDownload = taskStatus;

                    isDownloadFinished = true;
                    proceedRenderDocument(new File(localPath));
                } else {
                    // download failed.
                    Helper.deleteFile(new File(localPath));
                    if (mIsActivityVisibility) {
                        GenericError.showUI(ViewFileActivity.this, ErrorCode.DOWN_LOAD_FAILED, getString(R.string.down_load_failed), true, true, false, new IErrorResult() {
                            @Override
                            public void cancelHandler() {
                                finish();
                            }

                            @Override
                            public void okHandler() { // retry to download file.
                                try {
                                    final File document = app.getFile(clickFileName, downLoadCallback);
                                    if (document != null) {
                                        workingFile = document;
                                        proceedRenderDocument(document);
                                    } else {
                                        showProgressBar();
                                    }
                                } catch (Exception e) {
                                    if (DEBUG) {
                                        Log.e(TAG, e.toString());
                                        e.printStackTrace();
                                    }
                                }
                            }
                        });
                    }
                }
            }

            @Override
            public void downloadFileProgress(long newValue) {
                //Todo: this code is demo for UI thread to setup Progress bar
                mProgressValue.setText(Long.toString(newValue) + "%");
                mProgressBar.setProgress((int) newValue);
            }
        };

        Parser.parseIntent(getIntent(), new Parser.IntentResult() {

            @Override
            public void formHome(Intent intent) {
                clickFileName = (INxFile) intent.getSerializableExtra("click_file");
                setBackTextView();
                mFileName.setText(clickFileName.getName());
                try {
                    File document = app.getFile(clickFileName, downLoadCallback);
                    if (document != null) {
                        workingFile = document;
                        proceedRenderDocument(document);
                    } else {
                        // file is not cached at local, show UI and wait for network downloading
                        showProgressBar();
                    }
                } catch (Exception e) {
                    if (DEBUG) {
                        Log.e(TAG, e.toString());
                        e.printStackTrace();
                    }
                }
            }

            @Override
            public void viewToLogin(Intent intent) {  // open file viewer as third party software.
                bAsThirdPartyOpen = true;
                Uri uri = Uri.parse(intent.getStringExtra("NXVIEW"));
                if (uri.toString().startsWith("content://")) {
                    openFileOnMail(uri);
                } else if (uri.toString().startsWith("file://")) {
                    openFileOnDrive(uri);
                }
            }

            @Override
            public void normalView(Intent intent) {
                String path = intent.getStringExtra("NXVIEW");
                final List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
                for (BoundService oneservice : list) {
                    if (oneservice.type == BoundService.ServiceType.RECENT &&
                            oneservice.userID == app.getSessionUserID())
                        app.addCacheFile(oneservice.id, path, path, 100, "checksumetest", "0", "0", 0, 0, path);
                }
                int start = path.lastIndexOf("/");
                if (start != -1) {
                    mFileName.setText(path.substring(start + 1));
                } else {
                    mFileName.setText("View");
                }
                clickFileName = (INxFile) getIntent().getSerializableExtra("click_file");
                bAsThirdPartyOpen = getIntent().getBooleanExtra("as_third_party", false);
                setBackTextView();
                workingFile = new File(path);
                proceedRenderDocument(workingFile);
            }
        });

    }

    /**
     * check if current click file is nx format file
     *
     * @return boolean format value, if is nxfile return true
     */
    private boolean isNxFile() {
        return workingFile != null && nxl.bridge.NxlUtils.isNxlFile(workingFile.getPath(), false);
    }

    private void openFileOnMail(Uri uri) {

        String attachFileName = null;
        String scheme = uri.getScheme();
        if (scheme.equals("file")) {
            List<String> pathSegments = uri.getPathSegments();
            if (pathSegments.size() > 0) {
                attachFileName = pathSegments.get(pathSegments.size() - 1);
            }
        } else if (scheme.equals("content")) {
            Cursor cursor = getContentResolver().query(uri, new String[]{
                    MediaStore.MediaColumns.DISPLAY_NAME
            }, null, null, null);
            cursor.moveToFirst();
            int nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME);
            if (nameIndex >= 0) {
                attachFileName = cursor.getString(nameIndex);
            }
        } else {
            return;
        }

        if (attachFileName == null) {
            return;
        } else {
            mFileName.setText(attachFileName);
        }

        workingFile = viewFileHelper.copyData(mContext, uri, attachFileName, TMP_MAIL_PATH);
        if (workingFile == null) {
            return;
        }

        proceedRenderDocument(workingFile);
        setAttrPara();
    }

    private void openFileOnDrive(Uri uri) {
        String pathPrefix = "file://";
        String path = uri.toString().substring(pathPrefix.length());
        path = Uri.decode(path);
        int start = path.lastIndexOf("/");
        String fileName = path.substring(start + 1);
        if (start != -1) {
            mFileName.setText(fileName);
        } else {
            mFileName.setText("View");
        }

        workingFile = viewFileHelper.copyData(mContext, uri, fileName, TMP_DRIVE_PATH);
        if (workingFile == null) {
            return;
        }

        proceedRenderDocument(workingFile);
        setAttrPara();


    }

    private void setAttrPara() {
        nxl.types.NxFileBase file = new nxl.types.NXDocument();
        SimpleDateFormat modifyTime = new SimpleDateFormat("yyyy/MM/dd HH:mm");
        String result = modifyTime.format(new Date(workingFile.lastModified()));
        viewFileHelper.fillFileParameters(file, workingFile.getPath(), workingFile.length(), workingFile.getName(), result);
        clickFileName = file;
    }

    private void initView() {
        mOverlayTextColor = new HashMap<String, Integer>() {
            {
                put("Black", R.color.Black);
                put("Red", R.color.Red);
                put("Lime", R.color.Lime);
                put("Blue", R.color.Blue);
                put("Yellow", R.color.Yellow);
                put("Cyan / Aqua", R.color.Cyan);
                put("Magenta / Fuchsia", R.color.Magenta);
                put("Gray", R.color.Gray);
                put("Dim Gray", R.color.DimGray);
                put("Maroon", R.color.Maroon);
                put("Olive", R.color.Olive);
                put("Green", R.color.Green);
                put("Purple", R.color.Purple);
                put("Teal", R.color.Teal);
                put("Navy", R.color.Navy);
            }
        };
        mOverlayFrameLayout = (FrameLayout) findViewById(R.id.view_overlay);
        mOverlayLayout = (RelativeLayout) LayoutInflater.from(getBaseContext()).inflate(R.layout.overlay, null);
        mOverlayFrameLayout.removeAllViews();
        mOverlayFrameLayout.addView(mOverlayLayout);

        rlTitle = (RelativeLayout) findViewById(R.id.title);
        mFileName = (TextView) findViewById(R.id.view);
        bTouched = false;
        mMainLayout = (RelativeLayout) findViewById(R.id.view_file);

        m_recyclerView = (RecyclerView) findViewById(R.id.id_recyclerview_horizontal);
        m_recyclerView.setVisibility(View.GONE);

        if (muPDFParser != null) {
            muPDFParser.onCreate(msavedInstanceState, ViewFileActivity.this,
                    Intent.ACTION_VIEW, Uri.parse(muPDFFilePath));
        }

        btnSelect = (Button) this.findViewById(R.id.select);
        mContentViewBack = (TextView) findViewById(R.id.contentView_back);
        viewBg = findViewById(R.id.popup_background_view);
        viewBg.setVisibility(View.GONE);
    }

    private void initEvent() {

        btnSelect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                viewBg.setVisibility(View.VISIBLE);
                viewBg.startAnimation(AnimationUtils.loadAnimation(mContext,
                        R.anim.anim_popupwindow_enter));

                mPopupListView.showPopupWindow(getLayoutInflater().inflate(R.layout.activity_viewfile, null), viewFileHelper.getStatusBarHeight(mContext), rlTitle.getHeight());

            }
        });

        mContentViewBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //app.getInterfaceOfRemoteRepo().cancelDownload();
                if (downLoadCancelHandler != null && !isDownloadFinished) {
                    downLoadCancelHandler.cancel();
                }
                ViewFileActivity.this.finish();
                overridePendingTransition(R.anim.in_from_left, R.anim.out_to_right);
            }
        });

        final IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        mBroadcastReceive = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (Intent.ACTION_SCREEN_OFF.equals(action)) {
                    if (audioView != null) {
                        audioView.pause();
                    }

                    if (videoView != null) {
                        videoView.pausePlayVideo();
                    }
                }
            }
        };

        registerReceiver(mBroadcastReceive, filter);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);

        if (muPDFParser != null) {
            muPDFParser.onSaveInstanceState(outState);
        }
    }

    @Override
    protected void onStart() {
        super.onStart();

        if (muPDFParser != null) {
            muPDFParser.onStart();
        }
    }

    @Override
    protected void onStop() {
        super.onStop();

        if (muPDFParser != null) {
            muPDFParser.onStop();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        mIsActivityVisibility = false;
        //used to check whether the page from view page.
        ViewerApp.isFromViewPage = true;

        if (muPDFParser != null) {
            muPDFParser.onPause();
        }
    }

    @Override
    public boolean onSearchRequested() {
        if (muPDFParser != null) {
            return muPDFParser.onSearchRequested();
        }

        return super.onSearchRequested();
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        if (muPDFParser != null) {
            return muPDFParser.onPrepareOptionsMenu(menu);
        }

        return super.onPrepareOptionsMenu(menu);
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();

        if (muPDFParser != null) {
            muPDFParser.onBackPressed();
        }

        if (downLoadCancelHandler != null && !isDownloadFinished) {
            downLoadCancelHandler.cancel();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (muPDFParser != null) {
            muPDFParser.onDestroy();
        }

        if (audioView != null && audioView.getAudioPlayer().isPlaying()) {
            audioView.stopPlay();
        }

        // delete the temporary converted file
        if (bConvertSucceed) {
            if (!FileHelper.delFile(mTmpConvertPath)) {
                Log.d(TAG, "delete failed:" + mTmpConvertPath);
            }
        }
        // delete the temporary decrypt file
        if (bDecryptSucceed) {
            if (!FileHelper.delFile(mTmpDecryptPath)) {
                Log.d(TAG, "delete failed:" + mTmpDecryptPath);
            }

            int iPos = mTmpDecryptPath.lastIndexOf("/");
            FileHelper.delFile(getApplicationContext().getCacheDir().getPath() + "/ov" + mTmpDecryptPath.substring(iPos + 1));
        }

        if (bAsThirdPartyOpen) {
            if (!FileHelper.delFile(workingFile.getPath())) {
                Log.d(TAG, "delete failed:" + workingFile.getPath());
            }
        }

        String name = mFileName.getText().toString();
        if (name.endsWith(".vds") && m_core != null) {
            try {
                m_core.dispose();
            } finally {
                m_core = null;
            }
        }

        if (mBroadcastReceive != null) {
            unregisterReceiver(mBroadcastReceive);
        }
    }

    @Override
    public DVLCore getCore() {
        if (m_core != null) {
            return m_core;
        }
        return null;
    }

    @Override
    public String getFilePath() {
        return mfilePath;
    }

    @Override
    public void onSurfaceBind(boolean bindRet) {
        // Start load-file asynchronous task if MobileSurface::bind() was successful
        if (!bindRet) {
            Toast.makeText(getApplicationContext(), "C++ bind() failed to initialize", Toast.LENGTH_SHORT).show();
            return;
        }

        new LoadFileAsyncTask().execute(mPath);
    }

    @Override
    protected void onResume() {
        super.onResume();
        mIsActivityVisibility = true;
        if (bHSFView) {
            mSurfaceView.clearTouches();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Show our Operators/Modes/User Code menu options
        // These will get placed on the action bar if they can fit.

        if (bHSFView) {
            getMenuInflater().inflate(R.menu.toolbars, menu);
        }

        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle menu option selection

        switch (item.getItemId()) {
            case R.id.menu_operators:
                // Show operators toolbar
                mMainLayout.removeView(mCurrentToolbarView);
                mCurrentToolbarView = getLayoutInflater().inflate(R.layout.operators, null);
                mMainLayout.addView(mCurrentToolbarView);
                return true;
            case R.id.menu_modes:
                // Show user modes toolbar
                mMainLayout.removeView(mCurrentToolbarView);
                mCurrentToolbarView = getLayoutInflater().inflate(R.layout.modes, null);
                mMainLayout.addView(mCurrentToolbarView);
                return true;
            case R.id.menu_user_code:
                // Show user code toolbar
                mMainLayout.removeView(mCurrentToolbarView);
                mCurrentToolbarView = getLayoutInflater().inflate(R.layout.user_code, null);
                mMainLayout.addView(mCurrentToolbarView);
                return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);

        if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT && videoView != null) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            videoView.getSwitchScreenButton().setImageResource(R.drawable.spread_32);
            videoView.portraitDisplay();
        } else if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE && videoView != null) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
            videoView.getSwitchScreenButton().setImageResource(R.drawable.shrink_32);
            videoView.landscapeDisplay();
        }

        if (this.getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE) {
            if (bHSFView) {
                mMainLayout.removeAllViews();
                mMainLayout.addView(mSurfaceView);
                mMainLayout.addView(mCurrentToolbarView);
            }

            if (mPopupListView != null && mPopupListView.isShowing()) {
                mPopupListView.dismiss();
            }
            initPopupWindow();

        } else if (this.getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT) {
            if (bHSFView) {
                mMainLayout.removeAllViews();
                mMainLayout.addView(mSurfaceView);
                mMainLayout.addView(mCurrentToolbarView);
            }

            if (mPopupListView != null && mPopupListView.isShowing()) {
                mPopupListView.dismiss();
            }
            initPopupWindow();
        }
    }

    private void proceedRenderDocument(File file) {
        if (nxl.bridge.NxlUtils.isNxlFile(file.getPath(), false)) {
            parseNxlFile(file);
        } else {
            parseNormalFile(file, null, false);
        }
    }

    private void parseNxlFile(File document) {
        Parser.parseNxlFile(document, new Parser.NxlResult() {
//            @Override
//            public void grantViewRight(File file, byte[] blob,
//                                       Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> obligations) {
////                if (obligations.size() > 0) {
////                    showOverLay(obligations);
////                } else {
////                    mOverlayFrameLayout.setVisibility(View.GONE);
////                }
//                //show overlay later.
//                mOverlayFrameLayout.setVisibility(View.GONE);
//                // decrypt.
//                decryptFile(file, blob, obligations);
//            }

            @Override
            public void parseNxl(File file) {

                NxlFingerPrint fingerPrint = new NxlFingerPrint();
                if (nxl.bridge.NxlUtils.getNxlFingerPrint(file.getPath(), fingerPrint, 1)) {
                    decryptFile(file, fingerPrint);
                } else {
                    Log.d(TAG, "get the fingerPrint failed!");
                }

            }

            @Override
            public void reportToRMS(String filePath, NXRights rights, Tags tags) {
                NXLogRequestValue value = new NXLogRequestValue();
                value.agentId = app.sessionGetAgentId();
                value.rights = NXRightsList.getRightsList(rights);
                value.userName = app.getCurrentUser().name;
                value.sid = app.getSessionSid();
                value.hostNme = android.os.Build.MANUFACTURER;
                value.nxDocPath = filePath;
                value.nxDocPathTags = SendLogHelper.parseContent
                        .transferTagToLog(tags.toHashMap());
                value.hitPolicies = SendLogHelper.parseContent
                        .transferPolicyToLog(NXPolicyEngineWrapper.getHitPolicy());
                SendLogHelper logHelper = new SendLogHelper(value,
                        NXLogRequestValue.LogType.Evaluation);
                logHelper.reportToRMS();
            }

            @Override
            public void noViewRight() {
                GenericError.showUI(ViewFileActivity.this,
                        ErrorCode.NO_RIGHT,
                        getString(R.string.no_view_right),
                        true,
                        false,
                        true,
                        null);
            }
        });
    }

    private void parseNormalFile(final File document,
                                 final Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> obligations, final boolean bNxlFile) {

        Parser.parseRenderByFile(document, new Parser.RenderResult() {

            @Override
            public void notSupported(File file, String type) {
                hintUserOpenInOtherApp(file.getAbsolutePath(), type, bNxlFile);
            }

            @Override
            public void pdf(final File file, String type) {
                mOverlayFrameLayout.setVisibility(View.GONE);
                final CharSequence[] pdfItems =
                        ViewFileActivity.this.getResources().getStringArray(R.array.pdf_format);
                final AlertDialog.Builder builder = new AlertDialog.Builder(ViewFileActivity.this);
                builder.setTitle(ViewFileActivity.this.getResources().getString(R.string.title_popup_dialog));
                builder.setSingleChoiceItems(pdfItems, -1, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int item) {
                        if (item == 0) {
                            try {
                                Intent intent = new Intent();
                                intent.setPackage("com.artifex.mupdfdemo");
                                intent.setAction(Intent.ACTION_VIEW);
                                Uri pickedUri = Uri.fromFile(file);
                                intent.setDataAndType(pickedUri,
                                        Parser.parseMimeType(pickedUri.toString()));
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                                //todo:: maybe need to add overlay
                                if (obligations != null) {
                                    intent.putExtra("Overlay", getOverlay(obligations, false, ""));
                                }
                                startActivity(intent);
                            } catch (Exception e) {
                                GenericError.showUI(ViewFileActivity.this,
                                        ErrorCode.PDF_NOT_RENDER,
                                        getString(R.string.pdf_not_render),
                                        true, false, true, null);
                            }

                /*        muPDFParser = new MuPDFActivity(ViewFileActivity.this);
                        muPDFParser.onCreate(msavedInstanceState, ViewFileActivity.this, Intent.ACTION_VIEW, Uri.parse(FilePath));
                        mMainLayout.addView(muPDFParser.getDocView());
                        // mMainLayout.addView(muPDFParser.getBottonView());
                        muPDFFilePath = FilePath;
                        mMainLayout.setBackgroundColor(Color.BLACK);
                        if (!mFromDownload) {
                            controlTitleAnimation();
                        }*/
                        } else if (item == 1) {
                            bNeedConvert = true;
                            int agentId = ViewerApp.getInstance().sessionGetAgentId();
                            ConvertFile ConvertObj = new ConvertFile(ViewFileActivity.this,
                                    agentId, file.getName(), file.getPath(),
                                    Parser.FILE_EXTENSION_HSF,
                                    nxl.bridge.NxlUtils.isNxlFile(file.getPath(), false));
                            ConvertObj.Do(new ConvertFile.IConvertAsyncTask() {
                                @Override
                                public void onConvertFinish(String ConvertPath) {
                                    if (ConvertPath != null) {
                                        mTmpConvertPath = ConvertPath;
                                        bConvertSucceed = true;
                                        initialHSF(ConvertPath);

                                        //only show after inished
                                        if (nxl.bridge.NxlUtils.isNxlFile(workingFile.getPath(), false)) {
                                            showOverLay(mObligations);
                                        }
                                    } else {
                                        ViewFileActivity.this.finish();
                                    }
                                }
                            });
                        }
                        dialog.dismiss();
                    }
                });
                builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int id) {
                        ViewFileActivity.this.finish();
                    }
                });
                builder.setCancelable(false);
                builder.show();
            }

            @Override
            public void office(File file, String type) {
                try {
                    Intent intent = new Intent();
                    intent.setPackage("cn.wps.moffice_eng");
                    intent.setAction(Intent.ACTION_VIEW);
                    intent.setDataAndType(Uri.fromFile(file), type);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    // todo:for decrypt file, add overlay
                    if (obligations != null) {
                        getOverlay(obligations, true, Uri.decode(Uri.fromFile(file).toString()));
                    }
                    startActivity(intent);
                } catch (ActivityNotFoundException e) {
                    GenericError.showUI(ViewFileActivity.this, ErrorCode.OFFICE_NOT_RENDER, getString(R.string.office_not_render), true, false, true, null);
                }
            }

            @Override
            public void threeD(File file) {
                final String fileName = file.getName();
                final String FilePath = file.getPath();
                if (Parser.is3DFileNeedConvertFormat(fileName)) {
                    bNeedConvert = true;
                    int agentId = ViewerApp.getInstance().sessionGetAgentId();
                    new ConvertFile(ViewFileActivity.this, agentId, file.getName(), FilePath,
                            Parser.FILE_EXTENSION_HSF,
                            nxl.bridge.NxlUtils.isNxlFile(FilePath, false))
                            .Do(new ConvertFile.IConvertAsyncTask() {
                                @Override
                                public void onConvertFinish(String ConvertPath) {
                                    if (ConvertPath != null) {
                                        mTmpConvertPath = ConvertPath;
                                        bConvertSucceed = true;
                                        initialHSF(ConvertPath);
                                    } else {
                                        ViewFileActivity.this.finish();
                                    }
                                }
                            });
                } else {
                    if (fileName.isEmpty()) {
                        return;
                    }
                    String extension = fileName.substring(fileName.lastIndexOf(".") + 1).toLowerCase();
                    if (extension.equals(Parser.FILE_EXTENSION_HSF)) {
                        initialHSF(FilePath);
                    } else if (extension.equals(Parser.FILE_EXTENSION_VDS)) {
                        initialVDS(FilePath);
                    }
                }
                if (isNxFile()) {
                    showOverLay(mObligations);
                }
            }

            @Override
            public void audio(File file) {
                if (isNxFile()) {
                    showOverLay(mObligations);
                }
                audioView = new audioView(ViewFileActivity.this);
                audioView.init();
                RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) mMainLayout.getLayoutParams();
                lp.addRule(RelativeLayout.CENTER_IN_PARENT);
                mMainLayout.addView(audioView.getVideoView(), lp);
                audioView.startPlay(file.getPath());
            }

            @Override
            public void video(File file) {
                if (isNxFile()) {
                    showOverLay(mObligations);
                }
                videoView = new videoView(ViewFileActivity.this);
                videoView.init();
                RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) mMainLayout.getLayoutParams();
                lp.addRule(RelativeLayout.CENTER_IN_PARENT);
                mMainLayout.addView(videoView.getVideoView(), lp);
                videoView.StartPlayVideo(file);
            }

            @Override
            public void textOrImage(File file) {
                loadTextOrImageFile(file);
                if (isNxFile()) {
                    showOverLay(mObligations);
                }
            }
        });
    }

    private void setBackTextView() {
        mContentViewBack.setText(getString(R.string.back));
    }

    private void initPopupWindow() {
        //    mPopupListView = (PopupListView) LayoutInflater.from(this).inflate(R.layout.popuplistview_layout, null);
        mPopupListView = new ViewFilePopupWindow(ViewFileActivity.this);
        mPopupListView.setOnDismissListener(new PopupWindow.OnDismissListener() {
            @Override
            public void onDismiss() {
                if (viewBg != null) {
                    viewBg.startAnimation(AnimationUtils.loadAnimation(mContext,
                            R.anim.anim_popupwindow_exist));
                    viewBg.setVisibility(View.GONE);
                }
            }
        });
        //mPopupListView.initSelectList();
        mPopupListView.getListView().setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                switch (position) {
                    case 0:
                        selectItemProtect();
                        break;
                    case 1:
                        selectItemShare();
                        break;
                    case 2:
                        selectItemPrint();
                        break;
                    case 3:
                        selectItemProperty();
                        break;
                    default:
                        break;
                }
                mPopupListView.dismiss();
            }
        });
    }

    private void selectItemProtect() {
        Intent intent = new Intent();
        intent.setAction("NXProtectToView");
        intent.putExtra("click_protect", (NxFileBase) clickFileName);
        intent.putExtra("current_file", workingFile);
        intent.setClass(ViewFileActivity.this, ProtectActivity.class);
        ViewFileActivity.this.startActivity(intent);
    }

    private void selectItemProperty() {
//        Intent intent = new Intent();
//        intent.setAction("INFOFORWARD");
//        intent.putExtra("click_file", (NxFileBase) clickFileName);
//        intent.putExtra("current_file", workingFile);
//        intent.putExtra("as_third_party", bAsThirdPartyOpen);
//        intent.setClass(ViewFileActivity.this, Profileinfo_commonattributeActivity.class);
//        ViewFileActivity.this.startActivity(intent);
//        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        Toast.makeText(ViewFileActivity.this, "click property", Toast.LENGTH_SHORT).show();
    }

    private void selectItemShare() {
        Intent intent = new Intent();
        intent.setAction("NXShareToView");
        intent.putExtra("click_protect", (NxFileBase) clickFileName);
        intent.putExtra("current_file", workingFile);
        intent.setClass(ViewFileActivity.this, ProtectActivity.class);
        ViewFileActivity.this.startActivity(intent);
    }

    private void selectItemPrint() {
        Toast.makeText(ViewFileActivity.this, "click print", Toast.LENGTH_SHORT).show();
    }

    private boolean decryptFile(final File document, final NxlFingerPrint fingerPrint) {

        // create temporary file, like "/tmp/decryptFile/xxx
        mTmpDecryptName = document.getName().substring(0, document.getName().lastIndexOf("."));
        mTmpDecryptPath = getApplicationContext().getCacheDir().getPath() + "/deciphered_" + mTmpDecryptName;
        File mTmpLocal = null;
        try {
            mTmpLocal = new File(mTmpDecryptPath);
            if (!mTmpLocal.exists())
                mTmpLocal.createNewFile();
        } catch (IOException e) {
            Log.d(TAG, "create temporary file failed!");
            e.printStackTrace();
            return false;
        }

        class DecryptNxlFileAsyncTask extends AsyncTask<Void, Void, Boolean> {
            private String mNxlFilePath;
            private String mNormalFilePath;
            private NxlFingerPrint mFingerPrint;
            private boolean mOverWrite;
            private ProgressDialog decryptProgressDialog = null;

            public DecryptNxlFileAsyncTask(String nxlFilePath, String normalFilePath, NxlFingerPrint nxlFingerPrint, boolean bOverWrite) {
                mNxlFilePath = nxlFilePath;
                mNormalFilePath = normalFilePath;
                mFingerPrint = nxlFingerPrint;
                mOverWrite = bOverWrite;
            }

            @Override
            protected void onPreExecute() {
                decryptProgressDialog = ProgressDialog.show(ViewFileActivity.this, "", "Decrypting...", true);
            }

            @Override
            protected Boolean doInBackground(Void... params) {

                ViewerApp.Session2 session = ViewerApp.getInstance().getSession();
                // check the decrypt token if have existed.
                Map<String, String> mapDecryptToken = ViewerApp.getInstance().getSession().getMapDecryptTokens();
                Iterator iterator = mapDecryptToken.keySet().iterator();

                String decryptToken = null;
                while (iterator.hasNext()) {
                    String duid = (String) iterator.next();
                    if (duid != null && duid.equals(mFingerPrint.duid)) {
                        decryptToken = mapDecryptToken.get(duid);
                        break;
                    }
                }

                if (decryptToken != null) {
                    NxlCryptoTokenBlob tokenBlob = new NxlCryptoTokenBlob(mFingerPrint.rootAgreementKey, mFingerPrint.icaAgreementKey, session.getMl(), mFingerPrint.duid, decryptToken);
                    return nxl.bridge.NxlUtils.decrypt(mNxlFilePath, mNormalFilePath, tokenBlob, mOverWrite);
                } else {
                    // try to get the decrypt token by rest api.
                    DecryptionToken decryptionToken = new DecryptionToken();
                    NxlCryptoTokenBlob tokenBlob = null;
                    try {
                        decryptionToken.invokeToRMS(session.getCurrentServer(),
                                session.getUserInfo(),
                                mFingerPrint,
                                session.getTenantId(),
                                String.valueOf(session.getMl()));

                        if (decryptionToken.getToken() != null) {
                            // cache the decrypt token
                            mapDecryptToken.put(mFingerPrint.duid, decryptionToken.getToken());

                            tokenBlob = new NxlCryptoTokenBlob(mFingerPrint.rootAgreementKey, mFingerPrint.icaAgreementKey, session.getMl(), mFingerPrint.duid, decryptionToken.getToken());
                            return nxl.bridge.NxlUtils.decrypt(mNxlFilePath, mNormalFilePath, tokenBlob, mOverWrite);
                        } else {
                            Log.d(TAG, "can't get the decrypt token!");
                        }

                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                return false;
            }

            @Override
            protected void onPostExecute(Boolean result) {
                decryptProgressDialog.dismiss();

                if (!result) {
                    //error
                    GenericError.showUI(ViewFileActivity.this, ErrorCode.DECRYPT_FAILED, getString(R.string.decrypt_failed), true, false, true, null);

                } else {
                    // success
                    bDecryptSucceed = true;
                    parseNormalFile(new File(mNormalFilePath), null, true);
                }
            }
        }

        new DecryptNxlFileAsyncTask(document.getPath(), mTmpDecryptPath, fingerPrint, true).executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void) null);
        return true;
    }

//    private boolean decryptFile(final File document, byte[] keyBlob,
//                                final Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> obligations) {
//        // create temporary file, like "/tmp/decryptFile/xxx
//        mTmpDecryptName = document.getName().substring(0, document.getName().lastIndexOf("."));
//        mTmpDecryptPath = getApplicationContext().getCacheDir().getPath() + "/deciphered_" + mTmpDecryptName;
//        File mTmpLocal = null;
//        try {
//            mTmpLocal = new File(mTmpDecryptPath);
//            if (!mTmpLocal.exists())
//                mTmpLocal.createNewFile();
//        } catch (IOException e) {
//            Log.d(TAG, "create temporary file failed!");
//            e.printStackTrace();
//            return false;
//        }
//
//        class DecryptNxlFileAsyncTask extends AsyncTask<Void, Void, Boolean> {
//            private String mNxlFilePath;
//            private String mNormalFilePath;
//            private byte[] mKeyBlob;
//            private boolean mOverWrite;
//            private ProgressDialog decryptProgressDialog = null;
//
//            public DecryptNxlFileAsyncTask(String nxlFilePath, String normalFilePath, byte[] keyBlob, boolean bOverWrite) {
//                mNxlFilePath = nxlFilePath;
//                mNormalFilePath = normalFilePath;
//                mKeyBlob = keyBlob;
//                mOverWrite = bOverWrite;
//            }
//
//            @Override
//            protected void onPreExecute() {
//                decryptProgressDialog = ProgressDialog.show(ViewFileActivity.this, "", "Decrypting...", true);
//            }
//
//            @Override
//            protected Boolean doInBackground(Void... params) {
//                return nxl.fileFormat.Utils.decrypt(mNxlFilePath, mNormalFilePath, mKeyBlob, mOverWrite);
//            }
//
//            @Override
//            protected void onPostExecute(Boolean result) {
//                decryptProgressDialog.dismiss();
//
//                if (!result) {
//                    //error
//                    GenericError.showUI(ViewFileActivity.this, ErrorCode.DECRYPT_FAILED, getString(R.string.decrypt_failed), true, false, true, null);
//
//                } else {
//                    // success
//                    bDecryptSucceed = true;
//                    parseNormalFile(new File(mNormalFilePath), obligations, true);
//                }
//            }
//        }
//        new DecryptNxlFileAsyncTask(document.getPath(), mTmpDecryptPath, keyBlob, true)
//                .executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void) null);
//        return true;
//    }

    private void hintUserOpenInOtherApp(final String filePath, final String type, final boolean bNxlFile) {
        GenericError.showUI(ViewFileActivity.this, ErrorCode.FILE_FORMAT_NOT_SUPPORT, getString(R.string.format_not_supported_use_other_open),
                true,
                false,
                true,
                new IErrorResult() {
                    @Override
                    public void cancelHandler() {
                        finish();
                    }

                    @Override
                    public void okHandler() {
                        if (!bNxlFile) {
                            if (!filePath.isEmpty() && type != null && !type.isEmpty()) {
                                Log.i("test", type);
                                Intent fileOpenIntent = new Intent();
                                fileOpenIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                                fileOpenIntent.setAction(Intent.ACTION_VIEW);
                                File file = new File(filePath);
                                Uri.parse(filePath);
                                fileOpenIntent.setDataAndType(Uri.fromFile(file), type);
                                startActivity(fileOpenIntent);
                            }
                        }
                    }
                });
    }

    private void loadTextOrImageFile(File document) {
        Uri pickedUri = Uri.fromFile(document);
        String type = Parser.parseMimeType(pickedUri.toString());
        mNormalFile = getLayoutInflater().inflate(R.layout.view_normal_file, null);

        webView = (WebView) mNormalFile.findViewById(R.id.normalView);
        webView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                return ShowTitle(v, event);
            }
        });

        if (type.startsWith("image/")) {
            RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) mMainLayout.getLayoutParams();
            lp.addRule(RelativeLayout.CENTER_IN_PARENT);
            mMainLayout.addView(mNormalFile, lp);

            webView.setBackgroundColor(0);
            webView.getSettings().setUseWideViewPort(true);
            webView.getSettings().setLoadWithOverviewMode(true);
            webView.getSettings().setDisplayZoomControls(false);
            webView.getSettings().setBuiltInZoomControls(true);
            if (type.startsWith("image/gif") || type.startsWith("image/tiff")) {
                String gifFilePath = "file://" + document.getPath();
                String data = "<HTML><Div align=\"center\"  margin=\"0px\"><IMG src=\"" + gifFilePath + "\" margin=\"0px\"/></Div>";
                webView.loadDataWithBaseURL(gifFilePath, data, "text/html", "utf-8", null);
            } else if (type.startsWith("image/x-ms-bmp")) {
                // Desired Bitmap and the html code, where you want to place it
                Bitmap bitmap = BitmapFactory.decodeFile(document.getPath());
                String html = "<html><body><Div align=\"center\"  margin=\"0px\"><img src='{IMAGE_PLACEHOLDER}' +\"\" margin=\"0px\" /></Div></body></html>";
                // Convert bitmap to Base64 encoded image for webView.
                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
                byte[] byteArray = byteArrayOutputStream.toByteArray();
                String imageBase64 = Base64.encodeToString(byteArray, Base64.DEFAULT);
                String image = "data:image/png;base64," + imageBase64;
                // Use image for the img src parameter in your html and load to webView
                html = html.replace("{IMAGE_PLACEHOLDER}", image);
                String bmpFilePath = "file://" + document.getPath();
                webView.loadDataWithBaseURL(bmpFilePath, html, "text/html", "utf-8", "");
            } else {
                webView.loadUrl(pickedUri.toString());
            }
        } else if (type.startsWith("text/")) {
            mMainLayout.addView(mNormalFile);

            webView.setBackgroundColor(Color.WHITE);
            ViewGroup.LayoutParams vc = webView.getLayoutParams();
            vc.height = RelativeLayout.LayoutParams.MATCH_PARENT;
            vc.width = RelativeLayout.LayoutParams.MATCH_PARENT;
            webView.setLayoutParams(vc);
            webView.loadData(viewFileHelper.readTextFile(pickedUri), "text/", "UTF-8");
        }
    }

    private void initialHSF(String FilePath) {
        ViewerUtils.LoadNativeLibs();
        MobileApp.setFontDirectory(ViewerUtils.FONT_DIRECTORY_PATH);
        MobileApp.setMaterialsDirectory(ViewerUtils.MATERIAL_DIRECTORY_PATH);

        Context context = getApplication();

        int mobileSurfacePointer = 0;

        if (!bNeedConvert) {
            mProgress = ProgressDialog.show(ViewFileActivity.this, "", "Loading. Please wait...", true);
        } else {
            mProgress = ProgressDialog.show(ViewFileActivity.this, "", "save the converted file...", true);
        }
        mSurfaceView = new AndroidUserMobileSurfaceView(context, this, MOBILE_SURFACE_GUI_ID, mobileSurfacePointer);

        mPath = FilePath;

        mCurrentToolbarView = getLayoutInflater().inflate(R.layout.operators, null);

        mMainLayout.addView(mSurfaceView);
        mMainLayout.addView(mCurrentToolbarView);

        mSurfaceView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                return ShowTitle(v, event);
            }
        });

        bHSFView = true;
    }

    private void initialVDS(String FilePath) {
        m_core = new DVLCore(getApplicationContext());
        mfilePath = FilePath;
        mVdsSurface = new Surface(ViewFileActivity.this);
        mVdsSurface.setGetCoreCallBack(this);
        mVdsSurface.setGetFilePathCallBack(this);
        mMainLayout.addView(mVdsSurface);
        mVdsSurface.init();

        final CustomRenderer myRender = mVdsSurface.GetRender();
        myRender.startCalc(new Handler() {
            public void handleMessage(Message msg) {

                if (msg.what == CustomRenderer.CALC_FINISHED) {

                    m_dvlScene = myRender.getScene();
                    m_dvlProceduresInfo = (SDVLProceduresInfo) msg.obj;

                    for (int i = 0; i < m_dvlProceduresInfo.procedures.get(0).steps.size(); ++i) {
                        SDVLImage image = new SDVLImage();
                        m_dvlScene.RetrieveThumbnail(m_dvlProceduresInfo.procedures.get(0).steps.get(i).id, image);
                        m_dvlImageData.add(image);
                    }
                    ViewFileActivity.this.runOnUiThread(new Runnable() {
                        public void run() {
                            if (m_recyclerView.getVisibility() == View.GONE) {
                                m_recyclerView.setVisibility(View.VISIBLE);
                            }

                            LinearLayoutManager linearLayoutManager = new LinearLayoutManager(ViewFileActivity.this);
                            linearLayoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);
                            m_recyclerView.setLayoutManager(linearLayoutManager);
                            m_dvlImageAdapter = new GalleryAdapter(ViewFileActivity.this, m_dvlImageData);
                            m_dvlImageAdapter.setOnItemClickListener(new GalleryAdapter.OnItemClickListener() {
                                @Override
                                public void onItemClick(View view, int position) {
                                    m_dvlScene.ActivateStep(m_dvlProceduresInfo.procedures.get(0).steps.get(position).id, false, false);
                                }
                            });
                            m_recyclerView.setAdapter(m_dvlImageAdapter);
                        }
                    });
                }
            }
        });
    }

    public void TitleEvent(Boolean bShow) {
        if (bShow) {
            bTouched = true;
            btnSelect.setEnabled(true);
        } else {
            bTouched = false;
            btnSelect.setEnabled(false);
        }
    }

    private boolean ShowTitle(View v, MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
            downTouchX = (int) event.getX();
            return false;
        } else if (event.getAction() == MotionEvent.ACTION_UP) {
            upTouchX = (int) event.getX();
            if (downTouchX == upTouchX) {
                if (!bTouched) {
                    bTouched = true;
                    btnSelect.setEnabled(true);
                } else {
                    bTouched = false;
                    btnSelect.setEnabled(false);
                }
            }
        }
        return false;
    }

    public void toolbarButtonPressed(View view) {
        // Handle toolbar button press
        // These are connected from xml code via the
        // <ImageButton android:onClick="toolbarButtonPressed"> attribute
        // Calling the method on AndroidUserMobileSurfaceView calls down to the actions
        // in UserMobileSurface.h

        switch (view.getId()) {
            case R.id.orbitButton:
                mSurfaceView.setOperatorOrbit();
                break;
            case R.id.zoomAreaButton:
                mSurfaceView.setOperatorZoomArea();
                break;
            case R.id.selectButton:
                mSurfaceView.setOperatorSelectPoint();
                break;
            case R.id.selectAreaButton:
                mSurfaceView.setOperatorSelectArea();
                break;
            case R.id.flyButton:
                mSurfaceView.setOperatorFly();
                break;
            case R.id.simpleShadowButton:
                mModeSimpleShadowEnabled = !mModeSimpleShadowEnabled;
                mSurfaceView.onModeSimpleShadow(mModeSimpleShadowEnabled);
                break;
            case R.id.smoothButton:
                mSurfaceView.onModeSmooth();
                break;
            case R.id.hiddenLineButton:
                mSurfaceView.onModeHiddenLine();
                break;
            case R.id.frameRateButton:
                mSurfaceView.onModeFrameRate();
                break;
            case R.id.userCode1Button:
                mSurfaceView.onUserCode1();
                break;
            case R.id.userCode2Button:
                mSurfaceView.onUserCode2();
                break;
            case R.id.userCode3Button:
                mSurfaceView.onUserCode3();
                break;
            case R.id.userCode4Button:
                mSurfaceView.onUserCode4();
                break;
        }
    }

    private void showProgressBar() {
        mDownloadProgress = getLayoutInflater().inflate(R.layout.view_download_progress, null);
        mProgressBar = (ProgressBar) mDownloadProgress.findViewById(R.id.progress);
        mProgressValue = (TextView) mDownloadProgress.findViewById(R.id.textView_progress);
        TextView mProgressFileName = (TextView) mDownloadProgress.findViewById(R.id.textView_fileName);
        mProgressFileName.setText(clickFileName.getName());
        btnSelect.setEnabled(false);

        RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) mMainLayout.getLayoutParams();
        lp.addRule(RelativeLayout.CENTER_IN_PARENT);
        mMainLayout.addView(mDownloadProgress, lp);
    }

    private Bundle getOverlay(Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> obligations, boolean bWriteFile, String viewfile) {
        Bundle overlay = null;
        for (int i = 0; i < obligations.size(); ++i) {
            if (obligations.get(i).getKey().equals("OB_OVERLAY")) {
                overlay = new Bundle();
                try {
                    FileOutputStream fout = null;

                    if (bWriteFile) {
                        int iPos = viewfile.lastIndexOf("/");
                        String Path = getApplicationContext().getCacheDir().getPath() + "/ov" + viewfile.substring(iPos + 1);
                        File file = new File(Path);
                        if (!file.exists()) {
                            file.createNewFile();
                        }
                        fout = new FileOutputStream(Path);
                    }

                    for (int obItem = 0; obItem < obligations.get(i).getValue().size(); ++obItem) {
                        Map.Entry<String, String> targetEntry = obligations.get(i).getValue().get(obItem);

                        if (targetEntry.getKey().equals("Text")) {
                            String ovText = targetEntry.getValue().toString();
                            ovText = ovText.replace("\\n", "\n");
                            String userFullyName = app.getCurrentUser().name;
                            String userName = userFullyName.substring(0, userFullyName.indexOf("@"));
                            ovText = ovText.replace("$(User)", userName);
                            //obtain current time
                            SimpleDateFormat sDateFormat = new SimpleDateFormat("HH:mm:ss");
                            String date = sDateFormat.format(new java.util.Date());
                            ovText = ovText.replace("$(Time)", date);
                            overlay.putString("Text", ovText);

                            if (bWriteFile) {
                                String str = ovText + ";";
                                byte[] bytes = str.getBytes();
                                fout.write(bytes);
                            }
                        } else if (targetEntry.getKey().equals("Transparency")) {
                            overlay.putFloat("Transparency", Float.parseFloat(targetEntry.getValue()) / 100 >= 1.0f ? 1.0f : Float.parseFloat(targetEntry.getValue()) / 100);

                            if (bWriteFile) {
                                Float f = Float.parseFloat(targetEntry.getValue()) / 100 >= 1.0f ? 1.0f : Float.parseFloat(targetEntry.getValue()) / 100;
                                String str = f.toString() + ";";
                                byte[] bytes = str.getBytes();
                                fout.write(bytes);
                            }
                        } else if (targetEntry.getKey().equals("FontName")) {
                            overlay.putString("FontName", targetEntry.getValue().toString()); //fake value
                        } else if (targetEntry.getKey().equals("FontSize")) {
                            overlay.putString("FontSize", targetEntry.getValue().toString());

                            if (bWriteFile) {
                                String str = targetEntry.getValue().toString() + ";";
                                byte[] bytes = str.getBytes();
                                fout.write(bytes);
                            }
                        } else if (targetEntry.getKey().equals("TextColor")) {
                            overlay.putInt("TextColor", getResources().getColor(mOverlayTextColor.get(targetEntry.getValue()) != null ? mOverlayTextColor.get(targetEntry.getValue()) : R.color.Blue));

                            if (bWriteFile) {
                                Integer f = getResources().getColor(mOverlayTextColor.get(targetEntry.getValue()) != null ? mOverlayTextColor.get(targetEntry.getValue()) : R.color.Blue);
                                String str = f.toString() + ";";
                                byte[] bytes = str.getBytes();
                                fout.write(bytes);
                            }
                        } else if (targetEntry.getKey().equals("Rotation")) {
                            //  overlay.putString("Rotation", targetEntry.getValue().toString());
                            if (targetEntry.getValue().equals("Anticlockwise")) {
                                overlay.putFloat("Rotation", -45);

                                if (bWriteFile) {
                                    Float f = -45f;
                                    String str = f.toString();
                                    byte[] bytes = str.getBytes();
                                    fout.write(bytes);
                                }
                            } else {
                                overlay.putFloat("Rotation", 45);

                                if (bWriteFile) {
                                    Float f = 45f;
                                    String str = f.toString();
                                    byte[] bytes = str.getBytes();
                                    fout.write(bytes);
                                }
                            }
                        }
                    }
                    if (bWriteFile) {
                        fout.close();
                    }
                    break;
                } catch (Exception e) {
                }
            }
        }

        return overlay;
    }

    private void showOverLay(final Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> obligations) {
        for (int i = 0; i < obligations.size(); ++i) {
            if (obligations.get(i).getKey().equals("OB_OVERLAY")) {
                mOverlayFrameLayout.setVisibility(View.VISIBLE);
                final TextView overlayTextViewOriginal = (TextView) mOverlayLayout.findViewById(R.id.ovtxt);
                setOverlayParameters(overlayTextViewOriginal, obligations.get(i));
                mOverlayLayout.removeAllViews();
                mOverlayLayout.addView(overlayTextViewOriginal);
                final Map.Entry<String, Vector<Map.Entry<String, String>>> obligationsMap = obligations.get(i);
                overlayTextViewOriginal.post(new Runnable() {
                    @Override
                    public void run() {
                        DisplayMetrics screenMetrics = ScreenLocationUtils.getScreenMetrics(ViewFileActivity.this);
                        int hypotenuse = overlayTextViewOriginal.getWidth();
                        int tvWidth = (int) (hypotenuse / Math.sqrt(2));
                        int tvHeight = overlayTextViewOriginal.getHeight();
                        int halfHeight = tvWidth / 2;
                        overlayTextViewOriginal.setX(0);
                        overlayTextViewOriginal.setY(halfHeight);
                        int tx = (int) overlayTextViewOriginal.getX();
                        int ty = (int) overlayTextViewOriginal.getY();
                        mOverlayLayout.removeView(overlayTextViewOriginal);
                        for (int x = tx; x < screenMetrics.widthPixels; x = x + hypotenuse) {
                            for (int y = ty; y < screenMetrics.heightPixels; y = y + tvWidth + tvHeight) {
                                TextView tv = new TextView(ViewFileActivity.this);
                                setOverlayParameters(tv, obligationsMap);
                                tv.setX(x);
                                tv.setY(y);
                                tv.setGravity(Gravity.CENTER);
                                mOverlayLayout.addView(tv);
                            }
                        }
//                        mOverlayFrameLayout.removeAllViews();
//                        mOverlayFrameLayout.addView(mOverlayLayout);
                    }
                });
                break;
            }
        }
    }

    private void setOverlayParameters(TextView textView, Map.Entry<String, Vector<Map.Entry<String, String>>> obligationsMap) {
        for (int obItem = 0; obItem < obligationsMap.getValue().size(); ++obItem) {
            Map.Entry<String, String> targetEntry = obligationsMap.getValue().get(obItem);
            if (targetEntry.getKey().equals("Text")) {
                String ovText = targetEntry.getValue().toString();
                ovText = ovText.replace("\\n", "\n");
                String userFullyName = app.getCurrentUser().name;
                String userName = userFullyName.substring(0, userFullyName.indexOf("@"));
                ovText = ovText.replace("$(User)", userName);
                //obtain current time
                SimpleDateFormat sDateFormat = new SimpleDateFormat("HH:mm:ss");
                String date = sDateFormat.format(new java.util.Date());
                ovText = ovText.replace("$(Time)", date);
                textView.setText(ovText);
            } else if (targetEntry.getKey().equals("Transparency")) {
                textView.setAlpha(Float.parseFloat(targetEntry.getValue()) / 100 >= 1.0f ? 1.0f : Float.parseFloat(targetEntry.getValue()) / 100);
            } else if (targetEntry.getKey().equals("FontName")) {

            } else if (targetEntry.getKey().equals("FontSize")) {
                textView.setTextSize(Float.parseFloat(targetEntry.getValue()));
            } else if (targetEntry.getKey().equals("TextColor")) {
                textView.setTextColor(getResources().getColor(mOverlayTextColor.get(targetEntry.getValue()) != null ? mOverlayTextColor.get(targetEntry.getValue()) : R.color.Blue));
            } else if (targetEntry.getKey().equals("Rotation")) {
                if (targetEntry.getValue().equals("Anticlockwise")) {
                    textView.setRotation(-45);
                } else {
                    textView.setRotation(45);
                }
            }
        }
    }


    static private class Parser {
        static private final String VIEW_TO_VIEW = "NXInitViewToView";
        static private final String LOGIN_TO_VIEW = "NXLoginToView";
        static private final String VIEWENCRYPTFILE = "NXViewEncryptFile";
        static private final String HOME_TO_VIEW = "NXHomeToView";
        static private final String VIEW_TO_LOGIN = "NXInitViewToLogin";

        // 3D file format
        static private final String FILE_EXTENSION_JT = "jt";
        static private final String FILE_EXTENSION_HSF = "hsf";
        static private final String FILE_EXTENSION_VDS = "vds";
        static private final String FILE_EXTENSION_PRT = "prt";

        static private final String FILE_EXTENSION_PDF = "pdf";

        static public void parseIntent(Intent intent, IntentResult intentResult) {
            if (intent == null) {
                GenericError.showUI(ViewFileActivityInstance, ErrorCode.INTENT_IS_NULL, ViewFileActivityInstance.getString(R.string.intent_is_null), true, false, true, null);
                return;
            }
            String action = intent.getAction();
            if (TextUtils.equals(action, HOME_TO_VIEW)) {
                intentResult.formHome(intent);
                return;
            }
            if (TextUtils.equals(action, VIEW_TO_LOGIN)) {
                intentResult.viewToLogin(intent);
                return;
            }
            if (TextUtils.equals(action, VIEW_TO_VIEW) ||
                    TextUtils.equals(action, LOGIN_TO_VIEW) ||
                    TextUtils.equals(action, VIEWENCRYPTFILE)) {
                intentResult.normalView(intent);
                return;
            }
            GenericError.showUI(ViewFileActivityInstance, ErrorCode.INTENT_NOT_MATCH, ViewFileActivityInstance.getString(R.string.intent_not_match), true, false, true, null);
        }

        static public String parseMimeType(String url) {
            String type = null;
            String extension = MimeTypeMap.getFileExtensionFromUrl(url);
            if (extension != null) {
                type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase());
            }

            return type;
        }

        static public boolean is3DFileFormat(String fileName) {
            if (fileName == null || fileName.isEmpty()) {
                return false;
            }
            String extension = fileName.substring(fileName.lastIndexOf(".") + 1).toLowerCase();
            if (extension.equalsIgnoreCase(FILE_EXTENSION_HSF) || extension.equalsIgnoreCase(FILE_EXTENSION_JT) || extension.equalsIgnoreCase(FILE_EXTENSION_VDS) || extension.equalsIgnoreCase(FILE_EXTENSION_PDF) || extension.equalsIgnoreCase(FILE_EXTENSION_PRT)) {
                return true;
            }
            if (is3DFileNeedConvertFormat(fileName)) {
                return true;
            }
            return false;
        }

        static public boolean is3DFileNeedConvertFormat(String fileName) {
            if (fileName == null || fileName.isEmpty()) {
                return false;
            }

            List<String> listSupportedCadFormats = ViewerApp.getInstance().sessionGetSupportedCadFormats();
            if (listSupportedCadFormats == null || listSupportedCadFormats.size() == 0) {
                GenericError.showUI(ViewFileActivityInstance, ErrorCode.NOT_GET_SUPPORTED_CAD_FORMATS, ViewFileActivityInstance.getString(R.string.error_not_get_SupportedCadFormats), true, false, true, null);
                return false;
            }
            String extension = fileName.substring(fileName.lastIndexOf(".")).toLowerCase();
            for (String format : listSupportedCadFormats) {
                if (format.equalsIgnoreCase(extension)) {
                    return true;
                }
            }
            return false;
        }

        static public void parseRenderByFile(File file, RenderResult result) {
            try {
                if (file == null) {
                    GenericError.showUI(ViewFileActivityInstance, ErrorCode.FILL_NOT_EXIST, ViewFileActivityInstance.getString(R.string.file_is_null_or_not_exist), true, false, true, null);
                    return;
                }
                if (!file.exists()) {
                    GenericError.showUI(ViewFileActivityInstance, ErrorCode.FILL_NOT_EXIST, ViewFileActivityInstance.getString(R.string.file_is_null_or_not_exist), true, false, true, null);
                    return;
                }
                String type = parseMimeType(Uri.fromFile(file).toString());

                if (type == null) {
                    if (is3DFileFormat(file.getName())) {
                        result.threeD(file);
                    } else {
                        result.notSupported(file, null);
                    }
                } else if (type.startsWith("image/") || type.startsWith("text/")) {
                    result.textOrImage(file);
                } else if (type.endsWith("application/pdf")) {
                    result.pdf(file, type);
                } else if (type.equals("application/msword") || type.equals("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                        || type.equals("application/vnd.ms-powerpoint")
                        || type.equals("application/vnd.openxmlformats-officedocument.presentationml.presentation") ||
                        type.equals("application/vnd.ms-excel") ||
                        type.equals("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")) {
                    result.office(file, type);
                } else if (type.startsWith("video/")) {
                    result.video(file);
                } else if (type.startsWith("audio/")) {
                    result.audio(file);
                } else {
                    result.notSupported(file, type);// currentle, we do not support
                }

            } catch (Exception e) {
                e.printStackTrace();
            }

        }

        static public void parseNxlFile(File file, NxlResult result) {
            if (file == null || !file.exists()) {
                GenericError.showUI(ViewFileActivityInstance, ErrorCode.INVALID_FILE_PARAMETER, ViewFileActivityInstance.getString(R.string.invalid_file_parameter), true, false, true, null);
                return;
            }

            result.parseNxl(file);


            // ------------------------------------------------------------------

//            {//begin osm test;
//                NxlFingerPrint fingerPrint =new NxlFingerPrint();
//                nxl.bridge.NxlUtils.getNxlFingerPrint(file.getPath(),fingerPrint);
//
//
//            }//end osm test;
//
//            if (!nxl.bridge.NxlUtils.isNxlFile(file.getPath(), false)) {
//                GenericError.showUI(ViewFileActivityInstance, ErrorCode.NOT_NXL_FILE, ViewFileActivityInstance.getString(R.string.not_nxl_file), true, false, true, null);
//                return;
//            }
//
//            nxl.fileFormat.Tags tags = new nxl.fileFormat.Tags();
//            nxl.fileFormat.NextlabsKeyId keyId = new nxl.fileFormat.NextlabsKeyId();
//            byte[] keyBlob = null;
//            // get nextlabs key id
//            nxl.fileFormat.Utils.getNextlabsKeyId(file.getPath(), keyId);
//            List<NXKeyRing> rings = ViewerApp.getInstance().sessionGetKeyRings();
//            if (rings == null || rings.isEmpty()) {
//                GenericError.showUI(ViewFileActivityInstance, ErrorCode.RINGGS_IS_EMPTY, ViewFileActivityInstance.getString(R.string.rings_is_empty), true, false, true, null);
//                return;
//            }
//            // get nxl file 's keyBlob
//            keyBlob = nxl.fileFormat.Utils.getKeyBlobByNextlabsKeyId(rings, keyId);
//            if (keyBlob == null) {
//                GenericError.showUI(ViewFileActivityInstance, ErrorCode.CAN_NOT_GET_KEYBLOB, ViewFileActivityInstance.getString(R.string.keyBlob_is_empty), true, false, true, null);
//                return;
//            }
//            // ues keyBlob to getTags for a safe way
//            boolean bResult = nxl.fileFormat.Utils.getTags(file.getPath(), true, keyBlob, tags);
//            if (bResult) {
//                String content = ViewerApp.getInstance().sessionGetHeartBeatRawXml();
//                // comment it to test nxl parser
//                NXRights rights = NXPolicyEngineWrapper.GetRights(ViewerApp.getInstance().getSessionSid(), tags.toHashMap(), content);
//                //report log to rms server
//                result.reportToRMS(file.getPath(), rights, tags);
//
//                if (!rights.hasView()) {
//                    result.noViewRight();
//                } else {
//                    mObligations = rights.getObligations();
//                    result.grantViewRight(file, keyBlob, rights.getObligations());
//                }
//            } else {
//                GenericError.showUI(ViewFileActivityInstance, ErrorCode.CAN_NOT_GET_TAGS, ViewFileActivityInstance.getString(R.string.tags_is_empty), true, false, true, null);
//            }

            // ------------------------------------------------------------------

        }

        public interface IntentResult {

            void formHome(Intent intent);

            void viewToLogin(Intent intent);

            void normalView(Intent intent);
        }

        public interface RenderResult {

            void notSupported(File file, String type);

            void pdf(File file, String type);

            void office(File file, String type);

            void threeD(File file);

            void audio(File file);

            void video(File file);

            void textOrImage(File file);
        }

        public interface NxlResult {

//            void grantViewRight(File file, byte[] blob,
//                                Vector<Map.Entry<String, Vector<Map.Entry<String, String>>>> obligations);

            void reportToRMS(String filePath, NXRights rights, nxl.fileFormat.Tags tags);

            void noViewRight();

            void parseNxl(File file);
        }
    }

    private class LoadFileAsyncTask extends AsyncTask<String, Void[], Boolean> {
        @Override
        protected Boolean doInBackground(String... paths) {
            // Perform file load on separate thread
            return mSurfaceView.loadFile(paths[0]);
        }

        @Override
        protected void onPostExecute(Boolean result) {
            if (!result)
                Toast.makeText(getApplicationContext(),
                        "File failed to load", Toast.LENGTH_SHORT).show();

            if (mProgress != null) {
                mProgress.dismiss();
                mProgress = null;
            }
        }
    }
}


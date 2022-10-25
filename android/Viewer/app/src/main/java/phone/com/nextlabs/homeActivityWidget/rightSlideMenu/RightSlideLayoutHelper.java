package phone.com.nextlabs.homeActivityWidget.rightSlideMenu;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.support.v4.app.TaskStackBuilder;
import android.util.Log;
import android.util.SparseBooleanArray;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.nextlabs.viewer.R;

import java.io.File;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;
import java.util.Vector;

import PolicyEngineWrapper.NXPolicyEngineWrapper;
import PolicyEngineWrapper.NXRights;
import appInstance.ViewerApp;
import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import commonUtils.fileListUtils.FileUtils;
import errorHandler.ErrorCode;
import errorHandler.GenericError;
import errorHandler.IErrorResult;
import nxl.types.INxFile;
import nxl.types.NxFileBase;
import phone.com.nextlabs.viewer.ClassifyActivity;

public class RightSlideLayoutHelper {
    static final boolean DEBUG = ViewerApp.DEBUG;
    private final static String TAG = "RightSlide_NXFileHelper";
    private Activity mActivity;
    private INxFile mNxSrcFile;
    private File mLocalFile;
    private RelativeLayout mImageLayout;
    private Button mShareBtn;
    private Button mProtectBtn;
    private Button mClassifyBtn;
    private TextView mTitleFileName;
    private ImageView mTitleFileIcon;
    private RelativeLayout mToggleOfflineLayout;
    private ToggleButton mFavoriteToggle;
    private ToggleButton mOfflineToggle;
    private RelativeLayout mRightsLayout;
    private RelativeLayout mRightsLayoutDetailLayout;
    private TextView mReadRights;
    private ImageView mHasClassifyRights;
    private ImageView mHasViewRights;
    private RelativeLayout mSizeLayout;
    private TextView mAccountDetail;
    private TextView mDriveTypeDetail;
    private TextView mLocationDetail;
    private TextView mSizeDetail;
    private TextView mModifyTimeDetail;
    private TextView mInitializing;

    private OnOfflineStatusChanged onOfflineStatusChanged;
    private OnFavoriteStatusChanged onFavoriteStatusChanged;

    private ICancelable mDownloadFileCancelHandler;
    private ProgressBar mProgressBar;
    private ViewerApp app;
    private Vector<Downloader> mDownloaderVector;

    public RightSlideLayoutHelper(Activity activity) {
        mActivity = activity;
        app = ViewerApp.getInstance();
        initLayout();
        initEvent();
        mDownloaderVector = new Vector<>();
    }

    public void showRightMenu(INxFile nxfile) {
        mNxSrcFile = nxfile;
        //initial the local file statue. the value should be null when show the right menu;
        mLocalFile = null;

        Downloader downloader = null;
//        Log.e("teste", "mDownloadVector.size: " + mDownloaderVector.size());
        for (int i = 0; i < mDownloaderVector.size(); i++) {
            Downloader temp = mDownloaderVector.get(i);
            if (mNxSrcFile.getLocalPath().equals(temp.mLocalPath)) {
                downloader = temp;
                mProgressBar.setVisibility(View.VISIBLE);
                mProgressBar.setProgress(downloader.mProgressValue);
                if (!temp.mIsInitializeFinished) {
                    mInitializing.setVisibility(View.VISIBLE);
                }
                toggleBtnStatus(false);
                break;
            }
        }

        if (downloader == null) {
            mProgressBar.setVisibility(View.INVISIBLE);
            mInitializing.setVisibility(View.GONE);
            toggleBtnStatus(true);
        }

        getLocalFile();
        showStatus();
    }


    private void showStatus() {
        if (mNxSrcFile.isSite()) {
            mTitleFileIcon.setImageDrawable(mActivity.getResources().getDrawable(R.drawable.home_rightmenu_site));
            mTitleFileName.setText(mNxSrcFile.getName().substring(1));
        } else if (mNxSrcFile.isFolder()) {
            mTitleFileIcon.setImageDrawable(mActivity.getResources().getDrawable(R.drawable.home_rightmenu_folder));
            mTitleFileName.setText(mNxSrcFile.getName());
        } else {
            mTitleFileIcon.setImageDrawable(mActivity.getResources().getDrawable(R.drawable.home_rightmenu_file));
            mTitleFileName.setText(mNxSrcFile.getName());
        }

        if (mNxSrcFile.isSite() || mNxSrcFile.isFolder()) {
            mImageLayout.setVisibility(View.GONE);
            mSizeLayout.setVisibility(View.GONE);
            mRightsLayout.setVisibility(View.GONE);
            mSizeDetail.setVisibility(View.GONE);
            mToggleOfflineLayout.setVisibility(View.GONE);
        } else {
            mImageLayout.setVisibility(View.VISIBLE);
            mToggleOfflineLayout.setVisibility(View.VISIBLE);
            mOfflineToggle.setChecked(mNxSrcFile.isMarkedAsOffline());
            if (isNxFile()) {
                showRights();
            } else {
                mRightsLayout.setVisibility(View.GONE);
            }
            showProtectOption();
            mSizeLayout.setVisibility(View.VISIBLE);
            mSizeDetail.setVisibility(View.VISIBLE);
            //consider google driver specific file. The file has no file size.
            if (mNxSrcFile.getSize() == -1) {
                mSizeDetail.setText("");
            } else {
                mSizeDetail.setText(FileUtils.transparentFileSize(mNxSrcFile.getSize()));
            }
        }
        mFavoriteToggle.setChecked(mNxSrcFile.isMarkedAsFavorite());

        mAccountDetail.setText(mNxSrcFile.getService().account);
        mDriveTypeDetail.setText(mNxSrcFile.getService().alias);

        String Location = mNxSrcFile.getParent();
        if (mNxSrcFile.getService().alias.equals("SharePoint") || mNxSrcFile.getService().alias.equals("SharePoint Online")) {
            Location = Location.replaceAll("/%", "/");
            String accountID = mNxSrcFile.getService().accountID;
            int index = accountID.indexOf(".com");
            if (index != -1) {
                String value = accountID.substring(index + 4);
                Location = value + Location;
            } else {
                Location = accountID + Location;
            }
        }
        mLocationDetail.setText(Location);

        DateFormat modifyTime = new SimpleDateFormat("yyyy/MM/dd HH:mm");
        modifyTime.setTimeZone(TimeZone.getDefault());
        String result = modifyTime.format(new Date(mNxSrcFile.getLastModifiedTimeLong()));
        mModifyTimeDetail.setText(result);
    }

    private void initEvent() {
        mShareBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mNxSrcFile.isCached()) {
                    shareFile();
                } else {
                    getCloudFile(WhereFrom.SHARE);
                }
            }
        });
        mProtectBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mNxSrcFile.isCached()) {
                    protectFile();
                } else {
                    getCloudFile(WhereFrom.PROTECT);
                }
            }

        });
        mClassifyBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mNxSrcFile.isCached()) {
                    reclassifyFile();
                } else {
                    getCloudFile(WhereFrom.CLASSIFICATION);
                }
            }
        });
        mFavoriteToggle.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mFavoriteToggle.isChecked()) {
                    app.markAsFavorite(mNxSrcFile);
                } else {
                    app.unmarkAsFavorite(mNxSrcFile);
                }
                if (onFavoriteStatusChanged != null) {
                    onFavoriteStatusChanged.onFavoriteStatusChanged(mNxSrcFile, mFavoriteToggle.isChecked());
                }
            }
        });
        mOfflineToggle.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mOfflineToggle.isChecked()) {
                    app.markAsOffline(mNxSrcFile);
                    if (!mNxSrcFile.isCached()) {
                        getCloudFile(WhereFrom.DEFAULT);
                    } else {
                        getLocalFile();
                    }
                } else {
                    app.unmarkAsOffline(mNxSrcFile);
                    for (Downloader obj : mDownloaderVector) {
                        if (obj.mLocalPath.equals(mNxSrcFile.getLocalPath())) {
                            if (mDownloadFileCancelHandler != null) {
                                if (mInitializing.getVisibility() == View.VISIBLE) {
                                    mInitializing.setVisibility(View.GONE);
                                }
                                mDownloadFileCancelHandler.cancel();
                            }
                            obj.mProgressValue = 0;
                            mProgressBar.setProgress(0);
                            mDownloaderVector.remove(obj);
                            obj = null;
                            toggleBtnStatus(true);
                            break;
                        }
                    }
                }
                if (onOfflineStatusChanged != null) {
                    onOfflineStatusChanged.onOfflineStatusChanged(mNxSrcFile, mOfflineToggle.isChecked());
                }
            }
        });
    }

    public void setOnOfflineStatusChanged(OnOfflineStatusChanged callback) {
        onOfflineStatusChanged = callback;
    }

    public void setOnFavoriteStatusChanged(OnFavoriteStatusChanged callback) {
        onFavoriteStatusChanged = callback;
    }


    private void showRights() {
        if (isNxFile()) {
            mRightsLayout.setVisibility(View.VISIBLE);
            if (mNxSrcFile.isCached()) {
                getLocalFile();
                mReadRights.setVisibility(View.GONE);
                mRightsLayoutDetailLayout.setVisibility(View.VISIBLE);
                NXRights rights = getTargetFileRights();
                if (rights != null) {
                    if (rights.hasView()) {
                        mHasViewRights.setVisibility(View.VISIBLE);
                    } else {
                        mHasViewRights.setVisibility(View.GONE);
                    }
                    if (rights.hasClassify()) {
                        mHasClassifyRights.setVisibility(View.VISIBLE);
                    } else {
                        mHasClassifyRights.setVisibility(View.GONE);
                    }
                }
            } else {
                mRightsLayoutDetailLayout.setVisibility(View.GONE);
                mReadRights.setVisibility(View.VISIBLE);
                mReadRights.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        getCloudFile(WhereFrom.READRIGHTS);
                    }
                });
            }
        }
    }

    private void showProtectOption() {
        if (isNxFile()) {
            mClassifyBtn.setVisibility(View.VISIBLE);
            mProtectBtn.setVisibility(View.GONE);
        } else {
            mProtectBtn.setVisibility(View.VISIBLE);
            mClassifyBtn.setVisibility(View.GONE);
        }
    }

    private void shareFile() {
        Intent shareIntent = new Intent();
        shareIntent.setAction(Intent.ACTION_SEND);
        shareIntent.putExtra(Intent.EXTRA_STREAM, Uri.fromFile(mLocalFile));
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        shareIntent.setType("*/*");
        mLocalFile.setReadable(true, false);
        mActivity.startActivity(shareIntent);
    }

    private void protectFile() {
        Intent intent = new Intent();
        //todo change the action, and rewrite classify activity
        intent.setAction("NXProtectToView");
        intent.putExtra("click_protect", (NxFileBase) mNxSrcFile);
        intent.putExtra("current_file", mLocalFile);
        intent.setClass(mActivity, ClassifyActivity.class);
        mActivity.startActivity(intent);
    }

    private void reclassifyFile() {
        Intent intent = new Intent();
        //todo change the action, and rewrite classify activity
        intent.setAction("NXProtectToView");
        intent.putExtra("click_protect", (NxFileBase) mNxSrcFile);
        intent.putExtra("current_file", mLocalFile);
        intent.setClass(mActivity, ClassifyActivity.class);
        mActivity.startActivity(intent);
    }

    private NXRights getTargetFileRights() {
        String filePath = mLocalFile.getPath();
        nxl.fileFormat.Tags tags = new nxl.fileFormat.Tags();
        nxl.fileFormat.NextlabsKeyId keyId = new nxl.fileFormat.NextlabsKeyId();
        byte[] keyBlob = null;
        // get nextlabs key id
        nxl.fileFormat.Utils.getNextlabsKeyId(filePath, keyId);
        // get nxl file 's keyBlob
        keyBlob = nxl.fileFormat.Utils.getKeyBlobByNextlabsKeyId(app.sessionGetKeyRings(), keyId);
        // ues keyBlob to getTags for a safe way
        boolean bResult = nxl.fileFormat.Utils.getTags(filePath, true, keyBlob, tags);
        if (bResult) {
            String content = app.sessionGetHeartBeatRawXml();
            // comment it to test nxl parser
            return NXPolicyEngineWrapper.GetRights(app.getSessionSid(), tags.toHashMap(), content);
        }
        return null;
    }

    private boolean isNxFile() {
        if (mLocalFile != null) {
            String filePath = mLocalFile.getPath();
            return nxl.fileFormat.Utils.check(filePath, false);
        } else {
            return mNxSrcFile.getName().toLowerCase().endsWith(".nxl");
        }
    }

    //because of getFile has two situation, one for getting local file, one for getting cloud file
    private void getLocalFile() {
        try {
//            mLocalFile = app.getFile(mNxSrcFile, this);
            mLocalFile = app.getFile(mNxSrcFile, null);
        } catch (Exception e) {
            if (DEBUG) {
                Log.e(TAG, e.toString());
                e.printStackTrace();
            }
        }
    }

    private void getCloudFile(WhereFrom where) {
        Downloader downloader = null;
        for (int i = 0; i < mDownloaderVector.size(); i++) {
            Downloader temp = mDownloaderVector.get(i);
            if (mNxSrcFile.getLocalPath().equals(temp.mLocalPath)) {
                downloader = temp;
                mProgressBar.setVisibility(View.VISIBLE);
                mProgressBar.setProgress(downloader.mProgressValue);
            }
        }
        if (downloader == null) {
            downloader = new Downloader(mNxSrcFile.getLocalPath());
            downloader.mWhereFrom.put(where.value, true);
            mDownloaderVector.add(downloader);
        }
        try {
            mLocalFile = app.getFile(mNxSrcFile, downloader);
            if (mLocalFile == null) {
                downloader.mIsInitializeFinished = false;
                mInitializing.setVisibility(View.VISIBLE);
            }
        } catch (Exception e) {
            downloader.mWhereFrom.put(where.value, false);
            downloader.mIsInitializeFinished = true;
            mInitializing.setVisibility(View.GONE);
            if (DEBUG) {
                e.printStackTrace();
            }
        }
    }

    private void toggleBtnStatus(boolean isClickable) {
        float alpha = isClickable ? 1.0f : 0.5f;
        mShareBtn.setAlpha(alpha);
        mProtectBtn.setAlpha(alpha);
        mClassifyBtn.setAlpha(alpha);
        mReadRights.setAlpha(alpha);
        mShareBtn.setClickable(isClickable);
        mProtectBtn.setClickable(isClickable);
        mClassifyBtn.setClickable(isClickable);
        mReadRights.setClickable(isClickable);
    }

    private void initLayout() {
        mTitleFileName = (TextView) mActivity.findViewById(R.id.home_rightslide_titlefile);
        mTitleFileIcon = (ImageView) mActivity.findViewById(R.id.home_rightslide_titleimage);

        mImageLayout = (RelativeLayout) mActivity.findViewById(R.id.home_rightslide_imagelayout);
        mShareBtn = (Button) mActivity.findViewById(R.id.home_rightslide_share_item);
        mProtectBtn = (Button) mActivity.findViewById(R.id.home_rightslide_protect_item);
        mClassifyBtn = (Button) mActivity.findViewById(R.id.home_rightslide_classify_item);

        mToggleOfflineLayout = (RelativeLayout) mActivity.findViewById(R.id.home_rightslide_offlinelayout);
        mFavoriteToggle = (ToggleButton) mActivity.findViewById(R.id.home_rightslide_favoritetoggle);
        mOfflineToggle = (ToggleButton) mActivity.findViewById(R.id.home_rightslide_offlinetoggle);

        mRightsLayout = (RelativeLayout) mActivity.findViewById(R.id.home_rightslide_rightslayout);
        mRightsLayoutDetailLayout = (RelativeLayout) mActivity.findViewById(R.id.home_rightslide_rightsdetail);
        mReadRights = (TextView) mActivity.findViewById(R.id.home_rightslide_read);
        mHasClassifyRights = (ImageView) mActivity.findViewById(R.id.home_rightslide_classifyrights_checked);
        mHasViewRights = (ImageView) mActivity.findViewById(R.id.home_rightslide_viewrights_checked);

        mAccountDetail = (TextView) mActivity.findViewById(R.id.home_rightslide_accountvalue);
        mDriveTypeDetail = (TextView) mActivity.findViewById(R.id.home_rightslide_drivetypevalue);
        mLocationDetail = (TextView) mActivity.findViewById(R.id.home_rightslide_locationvalue);
        mSizeDetail = (TextView) mActivity.findViewById(R.id.home_rightslide_sizevalue);
        mModifyTimeDetail = (TextView) mActivity.findViewById(R.id.home_rightslide_modifiedvalue);
        mSizeLayout = (RelativeLayout) mActivity.findViewById(R.id.home_rightslide_sizelayout);

        mInitializing = (TextView) mActivity.findViewById(R.id.home_rightslide_initital);
        mProgressBar = (ProgressBar) mActivity.findViewById(R.id.home_rightslide_progress);
    }

    public interface OnOfflineStatusChanged {
        void onOfflineStatusChanged(INxFile nxFile, boolean isChanged);
    }

    public interface OnFavoriteStatusChanged {
        void onFavoriteStatusChanged(INxFile nxFile, boolean isChanged);
    }

    public class Downloader implements IRemoteRepo.IDownLoadCallback {
        private String mLocalPath;
        private int mProgressValue;
        private boolean mIsInitializeFinished;
        private SparseBooleanArray mWhereFrom;

        public Downloader(String filePath) {
            mLocalPath = filePath;
            mProgressBar.setProgress(0);
            mIsInitializeFinished = true;
            mWhereFrom = new SparseBooleanArray();
            for (int i = 0; i < 4; ++i) {
                mWhereFrom.put(i, false);
            }
            toggleBtnStatus(false);
        }

        public String getLocalPath() {
            return mLocalPath;
        }

        @Override
        public void downloadFileFinished(boolean taskStatus, String localPath, String errorMsg) {
            toggleBtnStatus(true);
            mProgressValue = 0;
            mProgressBar.setProgress(mProgressValue);
            if (taskStatus) {
                mLocalFile = new File(localPath);
                if (mWhereFrom.get(0)) {
                    mWhereFrom.put(0, false);
                    shareFile();
                } else if (mWhereFrom.get(1)) {
                    mWhereFrom.put(1, false);
                    protectFile();
                } else if (mWhereFrom.get(2)) {
                    mWhereFrom.put(2, false);
                    reclassifyFile();
                }
                showRights();
                //change icon from refresh to download
                if (onOfflineStatusChanged != null) {
                    onOfflineStatusChanged.onOfflineStatusChanged(mNxSrcFile, mOfflineToggle.isChecked());
                }
            } else {
                for (int i = 0; i < 4; ++i) {
                    mWhereFrom.put(i, false);
                }
                // download failed.
                GenericError.showUI(mActivity, ErrorCode.DOWN_LOAD_FAILED, mActivity.getString(R.string.rightmenu_download_failed), true, false, false, new IErrorResult() {
                    @Override
                    public void cancelHandler() {

                    }

                    @Override
                    public void okHandler() {

                    }
                });
                mIsInitializeFinished = true;
                mInitializing.setVisibility(View.GONE);
            }
        }

        @Override
        public void downloadFileProgress(long newValue) {
            if (mNxSrcFile.getLocalPath().equals(mLocalPath)) {
                mProgressValue = (int) newValue;
                mIsInitializeFinished = true;
                mInitializing.setVisibility(View.GONE);
                if (mProgressBar.getVisibility() == View.INVISIBLE) {
                    mProgressBar.setVisibility(View.VISIBLE);
                }
                Log.e("teste", "download file progress: " + newValue + " path: " + mNxSrcFile.getName());
                mProgressBar.setProgress((int) newValue);
            }
        }

        @Override
        public void cancelHandler(ICancelable handler) {
            mDownloadFileCancelHandler = handler;
        }
    }

    public enum WhereFrom {
        SHARE(0),
        PROTECT(1),
        CLASSIFICATION(2),
        READRIGHTS(3),
        DEFAULT(4);

        private int value = 0;

        WhereFrom(int type) {
            value = type;
        }

        public static WhereFrom valueOf(int value) {
            switch (value) {
                case 0:
                    return SHARE;
                case 1:
                    return PROTECT;
                case 2:
                    return CLASSIFICATION;
                case 3:
                    return READRIGHTS;
                default:
                    throw new IllegalArgumentException("error where from type");
            }
        }

        public int value() {
            return this.value;
        }
    }
}

package appInstance.remoteRepo.onedrive;

import android.app.Activity;
import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Locale;
import java.util.TimeZone;

import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoInfo;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveAuthClient;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveAuthException;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveAuthListener;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveConnectClient;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveConnectSession;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveDownloadOperation;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveDownloadOperationListener;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveOperation;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveOperationException;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveStatus;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.LiveUploadOperationListener;
import appInstance.remoteRepo.onedrive.sdk.com.microsoft.live.OverwriteOption;
import appInstance.remoteRepo.onedrive.util.Account;
import appInstance.remoteRepo.onedrive.util.JsonKeys;
import nxl.types.INxFile;
import nxl.types.NXDocument;
import nxl.types.NXFolder;
import nxl.types.NxFileBase;


public class NXOneDrive implements IRemoteRepo {
    public static final String CLIENT_ID = "00000000481767DB"; // use Nextlabs ones
    // Available options to determine security level of access
    public static final String[] SCOPES = {
            "wl.signin",
            "wl.basic",
            "wl.emails",
            "wl.offline_access",
            "wl.skydrive_update",
            "wl.contacts_create",
    };
    private static final String TAG = "NXOneDrive";

    private static LiveAuthClient sAuthClient;
    private static LiveConnectSession sConnectSession;
    private static LiveConnectClient sConnectClient;

    static public void init(Context context, final InitListener listener) {
        sAuthClient = new LiveAuthClient(context, CLIENT_ID);
        sAuthClient.initialize(Arrays.asList(SCOPES), new LiveAuthListener() {
            @Override
            public void onAuthComplete(LiveStatus status, LiveConnectSession session, Object userState) {
                if (status == LiveStatus.CONNECTED) {
                    sConnectSession = session;
                    sConnectClient = new LiveConnectClient(session);
                    if (listener != null) {
                        listener.result(true);
                    }
                }
                if (status == LiveStatus.UNKNOWN) {
                    if (listener != null) {
                        listener.result(false);
                    }
                }
            }

            @Override
            public void onAuthError(LiveAuthException exception, Object userState) {
                if (listener != null) {
                    listener.result(false);
                }
            }
        });
    }

    static public void fireOAuth2Authentication(Activity activity, final OAuth2Listener callback) {
        if (sAuthClient == null) {
            init(activity, null);
        }
        sAuthClient.login(activity, Arrays.asList(SCOPES), new LiveAuthListener() {
            @Override
            public void onAuthComplete(LiveStatus status, LiveConnectSession session, Object userState) {
                // login ok
                if (sConnectSession == null) {
                    // for login ok, to rebuilt connect session and client
                    sConnectSession = session;
                    sConnectClient = new LiveConnectClient(session);
                }
                callback.success();
            }

            @Override
            public void onAuthError(LiveAuthException exception, Object userState) {
                // login false
                callback.failed();
            }
        });
    }

    static public void signOut() {
        // notice, logout, should clear all static objects
        if (sAuthClient == null) {
            return;
        }
        sAuthClient.logout(new LiveAuthListener() {
            @Override
            public void onAuthComplete(LiveStatus status, LiveConnectSession session, Object userState) {
                // tbd
                sAuthClient = null;
                sConnectSession = null;
                sConnectClient = null;
            }

            @Override
            public void onAuthError(LiveAuthException exception, Object userState) {
                // tbd
            }
        });
    }

    static public String getAccessToken() {
        return sConnectSession.getAccessToken();
    }

    @Override
    public INxFile getFileMetaInfo(INxFile file) {
        INxFile rt = null;
        try {
            NxFileBase par = (NxFileBase) file;
            if (par.getLocalPath().equals("/")) {
                par.setCloudPath("me/skydrive");
            }

            String folderId = par.getCloudPath();
            if (folderId != null) {
                JSONArray data = getMetaInfo(folderId);
                if (data == null) {
                    rt = par;
                } else {
                    rt = packData(data, par);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }
        return rt;
    }

    private JSONArray getMetaInfo(String folderId) {
        JSONArray rt = null;
        try {
            LiveOperation operation = sConnectClient.get(folderId + "/files");
            JSONObject result = operation.getResult();
            if (result.has(JsonKeys.ERROR)) {
                JSONObject error = result.optJSONObject(JsonKeys.ERROR);
                String message = error.optString(JsonKeys.MESSAGE);
                String code = error.optString(JsonKeys.CODE);
            } else {
                rt = result.optJSONArray(JsonKeys.DATA);
            }

        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return rt;
    }

    @Override
    public void getFileMetaInfo(INxFile file, IGetFileMetaInfoCallback callback) {
        class asyncTask extends AsyncTask<INxFile, Void, INxFile> {
            protected String mErrorMsg = "null";
            IRemoteRepo.IGetFileMetaInfoCallback mCallBack;

            public asyncTask(IRemoteRepo.IGetFileMetaInfoCallback callback) {
                this.mCallBack = callback;
            }

            @Override
            protected INxFile doInBackground(INxFile... params) {
                INxFile rt = null;
                try {
                    NxFileBase par = (NxFileBase) params[0];
                    if (par.getLocalPath().equals("/")) {
                        par.setCloudPath("me/skydrive");
                    }

                    String folderId = par.getCloudPath();
                    if (folderId != null) {
                        JSONArray data = getMetaInfo(folderId);
                        if (data == null) {
                            mErrorMsg = "GetFileOrDirInfoAsyncTask getMetaInfo function return null";
                            rt = par;
                        } else {
                            mErrorMsg = "GetFileOrDirInfo success !";
                            rt = packData(data, par);
                        }
                    }
                } catch (Exception e) {
                    mErrorMsg = e.getMessage();
                }
                return rt;
            }

            @Override
            protected void onPostExecute(INxFile nxFileBase) {
                if (mCallBack != null) {
                    boolean boper = false;
                    if (nxFileBase != null) {
                        boper = true;
                    }
                    mCallBack.getFileMetaInfoFinished(boper, nxFileBase, mErrorMsg);
                }
            }

            private INxFile packData(JSONArray data, INxFile inxfile) {
                NxFileBase rt = new NXFolder();
                rt.setLocalPath(inxfile.getLocalPath());
                rt.setLastModifiedTime(inxfile.getLastModifiedTime());
                rt.setCloudPath(inxfile.getCloudPath());
                rt.setName(inxfile.getName());
                rt.setSize(inxfile.getSize());
                for (int i = 0; i < data.length(); i++) {
                    JSONObject oneObj = data.optJSONObject(i);
                    NxFileBase onefile = null;
                    String type = oneObj.optString("id");
                    //if (type.equals(NXFolder.TYPE)) {
                    //@todo kinds of file types
                    if (type.startsWith("folder")) {
                        onefile = new NXFolder();
                        fillFileParmas(onefile, oneObj, inxfile);
                        rt.addChild(onefile);
                    }
                    //file photo video audio album
                    else {
                        onefile = new NXDocument();
                        fillFileParmas(onefile, oneObj, inxfile);
                        rt.addChild(onefile);
                    }
                }
                return rt;
            }

            private void fillFileParmas(NxFileBase f, JSONObject node, INxFile inxfile) {
                String currentitem = node.optString("name");
                String currentUserPath = (inxfile.getLocalPath().equals("/") ? "" : inxfile.getLocalPath()) + "/" + currentitem;
                String currentFolderId = node.optString("id");

                f.setLocalPath(currentUserPath);
                f.setCloudPath(currentFolderId);
                f.setSize(node.optLong("size"));
                //f.setLastModifiedTime(node.optString("updated_time"));
                f.setName(currentitem);
                //f.setLastModifiedTime(node.optString("updated_time"));
                if (!node.optString("updated_time").isEmpty()) {
                    DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                    df.setTimeZone(TimeZone.getTimeZone("UTC"));
                    try {
                        f.setLastModifiedTimeLong(df.parse(node.optString("updated_time")).getTime());
                    } catch (Exception e) {
                        f.setLastModifiedTime(node.optString("updated_time"));
                        e.printStackTrace();
                    }
                } else {
                    f.setLastModifiedTime(node.optString("updated_time"));
                }
            }

        }

        // sanity check
        if (file == null)
            throw new NullPointerException("file is null");
        asyncTask task = new asyncTask(callback);
        task.execute(file);
    }

    @Override
    public void downloadFile(INxFile document, String localPath, IDownLoadCallback callback) {

        class DownLoadFileTask implements ICancelable {
            private final String TAG = "DownLoadFileTask";
            protected String mErrorMsg = "null";
            IRemoteRepo.IDownLoadCallback mCallback;
            INxFile document;
            private String mOneDriveFilePath;
            private String mLocalFilePath;
            private volatile LiveDownloadOperation mDownloadOperation = null;
            private volatile boolean mCanceled = false;

            public DownLoadFileTask(IRemoteRepo.IDownLoadCallback callback, INxFile document, String onedriveFilePath, String localFilePath) {
                this.mCallback = callback;
                this.document = document;
                this.mOneDriveFilePath = onedriveFilePath;
                this.mLocalFilePath = localFilePath;
            }

            @Override
            public void cancel() {
                mCanceled = true;
                if (mDownloadOperation != null) {
                    mDownloadOperation.cancel();
                }
            }

            public void preStartDownload() {
                if (mCallback != null) {
                    mCallback.cancelHandler(this);
                }
            }

            public void start() {
                try {
                    final File local = new File(mLocalFilePath);
                    Helper.makeSureDocExist(local);
                    mDownloadOperation = sConnectClient.downloadAsync(mOneDriveFilePath + "/content", local, new LiveDownloadOperationListener() {
                        @Override
                        public void onDownloadProgress(int totalBytes,
                                                       int bytesRemaining,
                                                       LiveDownloadOperation operation) {
                            mCallback.downloadFileProgress((long) ((totalBytes - bytesRemaining) / (float) totalBytes * 100));
                        }

                        @Override
                        public void onDownloadFailed(LiveOperationException exception,
                                                     LiveDownloadOperation operation) {
                            mErrorMsg = exception.getMessage();
                            // bug-fix for download failed, delete local cache
                            Helper.deleteFile(local);
                            mCallback.downloadFileFinished(false, mLocalFilePath, mErrorMsg);
                        }

                        @Override
                        public void onDownloadCompleted(LiveDownloadOperation operation) {
                            if (mCanceled) {
                                mErrorMsg = "user cancel download operater!";
                                mCallback.downloadFileFinished(false, mLocalFilePath, mErrorMsg);

                            } else {
                                mErrorMsg = "DownloadFile success!";
                                ((NxFileBase) document).setCached(true);
                                mCallback.downloadFileFinished(true, mLocalFilePath, mErrorMsg);
                            }
                        }
                    });
                } catch (Exception e) {
                    Log.e(TAG, e.toString());
                }
            }

        }

        DownLoadFileTask downloadTask = new DownLoadFileTask(callback, document, document.getCloudPath(), localPath);
        downloadTask.preStartDownload();
        downloadTask.start();
    }

    @Override
    public boolean isProgressSupported() {
        return true;
    }

    private void uploadAndUpdateFile(INxFile parentFolder, File localFile, IUploadFileCallback callback, boolean bUpdate) {
        class UpLoadFileTask implements ICancelable {
            private final String TAG = "UpLoadFileTask class";
            protected String mErrorMsg = "null";
            IRemoteRepo.IUploadFileCallback mCallback;
            private String mOneDriveFilePath;
            private File mLocalFile;
            private boolean bUpdate;
            private LiveOperation mUpLoadOperation = null;

            public UpLoadFileTask(IRemoteRepo.IUploadFileCallback callback, String onedriveFilePath, File localFile, boolean bUpdate) {
                this.mCallback = callback;
                this.mOneDriveFilePath = onedriveFilePath;
                this.mLocalFile = localFile;
                this.bUpdate = bUpdate;
            }

            @Override
            public void cancel() {
                cancelUpLoad();
            }

            public void cancelUpLoad() {
                if (mUpLoadOperation != null) {
                    mUpLoadOperation.cancel();
                }
            }

            public void preStartUpload() {
                if (mCallback != null) {
                    mCallback.cancelHandler(this);
                }
            }

            public void start() {
                try {
                    if (bUpdate) {
                        mUpLoadOperation = sConnectClient.uploadAsync(mOneDriveFilePath,
                                mLocalFile.getName(),
                                mLocalFile,
                                OverwriteOption.Overwrite,
                                new LiveUploadOperationListener() {
                                    @Override
                                    public void onUploadProgress(int totalBytes,
                                                                 int bytesRemaining,
                                                                 LiveOperation operation) {
                                        mCallback.uploadFileProgress((long) ((totalBytes - bytesRemaining) / (float) totalBytes * 100));
                                    }

                                    @Override
                                    public void onUploadFailed(LiveOperationException exception,
                                                               LiveOperation operation) {
                                        mErrorMsg = exception.getMessage();
                                        mCallback.uploadFileFinished(false, mLocalFile.getName(), mErrorMsg);
                                    }

                                    @Override
                                    public void onUploadCompleted(LiveOperation operation) {
                                        mErrorMsg = "UploadFile success!";
                                        mCallback.uploadFileFinished(true, mLocalFile.getName(), null);
                                    }
                                }, 0);

                    } else {
                        mUpLoadOperation = sConnectClient.uploadAsync(mOneDriveFilePath,
                                mLocalFile.getName(),
                                mLocalFile,
                                new LiveUploadOperationListener() {
                                    @Override
                                    public void onUploadProgress(int totalBytes,
                                                                 int bytesRemaining,
                                                                 LiveOperation operation) {
                                        mCallback.uploadFileProgress((long) ((totalBytes - bytesRemaining) / (float) totalBytes * 100));
                                    }

                                    @Override
                                    public void onUploadFailed(LiveOperationException exception,
                                                               LiveOperation operation) {
                                        mErrorMsg = exception.getMessage();
                                        mCallback.uploadFileFinished(false, mLocalFile.getName(), mErrorMsg);
                                    }

                                    @Override
                                    public void onUploadCompleted(LiveOperation operation) {
                                        if (operation.getRawResult() != null && operation.getRawResult().contains("error")) {
                                            try {
                                                JSONObject jsonObject = new JSONObject(operation.getRawResult()).getJSONObject("error");
                                                mErrorMsg = jsonObject.getString("code");
                                                mCallback.uploadFileFinished(false, mLocalFile.getName(), mErrorMsg);
                                            } catch (JSONException e) {
                                                e.printStackTrace();
                                            }

                                        } else {
                                            mErrorMsg = "UploadFile success!";
                                            mCallback.uploadFileFinished(true, mLocalFile.getName(), mErrorMsg);
                                        }

                                    }
                                });
                    }
                } catch (Exception e) {
                    mErrorMsg = e.getMessage();
                    mCallback.uploadFileFinished(false, mLocalFile.getName(), mErrorMsg);
                }
            }

        }
        UpLoadFileTask uploadTask = new UpLoadFileTask(callback, parentFolder.getCloudPath(), localFile, bUpdate);
        uploadTask.preStartUpload();
        uploadTask.start();
    }

    @Override
    public void uploadFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback) {
        uploadAndUpdateFile(parentFolder, localFile, callback, false);
    }

    @Override
    public void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IUploadFileCallback callback) {
        uploadAndUpdateFile(parentFolder, localFile, callback, true);
    }

    @Override
    public boolean getInfo(RemoteRepoInfo info) {

        boolean ret = true;
        try {

            LiveOperation userInfo = sConnectClient.get("me");
            JSONObject resultUserInfo = userInfo.getResult();
            if (resultUserInfo != null) {
                info.displayName = resultUserInfo.optString("name");
                info.email = resultUserInfo.optJSONObject("emails").optString("account");
            } else {
                ret = false;
            }

            LiveOperation quotaInfo = sConnectClient.get("me/skydrive/quota");
            JSONObject resultQuotaInfo = quotaInfo.getResult();
            if (resultQuotaInfo != null) {
                info.remoteTotalSpace = resultQuotaInfo.optLong("quota");
                info.remoteUsedSpace = info.remoteTotalSpace - resultQuotaInfo.optLong("available");
            } else {
                ret = false;
            }

            return ret;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private INxFile packData(JSONArray data, INxFile inxfile) {
        NxFileBase rt = new NXFolder();
        rt.setLocalPath(inxfile.getLocalPath());
        rt.setLastModifiedTime(inxfile.getLastModifiedTime());
        rt.setCloudPath(inxfile.getCloudPath());
        rt.setName(inxfile.getName());
        rt.setSize(inxfile.getSize());
        for (int i = 0; i < data.length(); i++) {
            JSONObject oneObj = data.optJSONObject(i);
            NxFileBase onefile = null;
            String type = oneObj.optString("id");
            //if (type.equals(NXFolder.TYPE)) {
            //@todo kinds of file types
            if (type.startsWith("folder")) {
                onefile = new NXFolder();
                fillFileParmas(onefile, oneObj, inxfile);
                rt.addChild(onefile);
            }
            //file photo video audio album
            else {
                onefile = new NXDocument();
                fillFileParmas(onefile, oneObj, inxfile);
                rt.addChild(onefile);
            }
        }
        return rt;
    }

    private void fillFileParmas(NxFileBase f, JSONObject node, INxFile inxfile) {
        String currentitem = node.optString("name");
        String currentUserPath = (inxfile.getLocalPath().equals("/") ? "" : inxfile.getLocalPath()) + "/" + currentitem;
        String currentFolderId = node.optString("id");

        f.setLocalPath(currentUserPath);
        f.setCloudPath(currentFolderId);
        f.setSize(node.optLong("size"));
        f.setLastModifiedTime(node.optString("updated_time"));
        f.setName(currentitem);

        if (!node.optString("updated_time").isEmpty()) {
            // 2016-03-14T08:43:31+0000
            DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssz", Locale.US);
            try {
                f.setLastModifiedTimeLong(df.parse(node.optString("updated_time")).getTime());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public interface InitListener {
        void result(boolean status);
    }

    public interface OAuth2Listener {
        void success();

        void failed();
    }

    public static class GetAccountAsyncTask extends AsyncTask<Void, Void, Account> {

        private IGetAccountAsyncTask callback = null;

        public void setCallback(IGetAccountAsyncTask callback) {
            this.callback = callback;
        }

        @Override
        protected Account doInBackground(Void... params) {
            try {
                JSONObject result = sConnectClient.get("me").getResult();
                if (result.has(JsonKeys.ERROR)) {
                    JSONObject error = result.optJSONObject(JsonKeys.ERROR);
                    String code = error.optString(JsonKeys.CODE);
                    String message = error.optString(JsonKeys.MESSAGE);
                    Log.e(TAG, code + ": " + message);
                }
                Account user = new Account(result);
                return user;

            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
            return null;
        }

        @Override
        protected void onPostExecute(Account account) {
            callback.onFinishGet(account);
        }

        public interface IGetAccountAsyncTask {
            void onFinishGet(Account account);
        }
    }
}

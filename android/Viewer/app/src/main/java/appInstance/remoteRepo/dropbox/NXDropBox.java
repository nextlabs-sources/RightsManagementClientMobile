package appInstance.remoteRepo.dropbox;

import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

import com.dropbox.client2.DropboxAPI;
import com.dropbox.client2.ProgressListener;
import com.dropbox.client2.android.AndroidAuthSession;
import com.dropbox.client2.exception.DropboxException;
import com.dropbox.client2.exception.DropboxFileSizeException;
import com.dropbox.client2.exception.DropboxIOException;
import com.dropbox.client2.exception.DropboxParseException;
import com.dropbox.client2.exception.DropboxPartialFileException;
import com.dropbox.client2.exception.DropboxServerException;
import com.dropbox.client2.exception.DropboxUnlinkedException;
import com.dropbox.client2.session.AppKeyPair;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.Locale;

import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoInfo;
import nxl.types.INxFile;
import nxl.types.NXDocument;
import nxl.types.NXFolder;
import nxl.types.NxFileBase;


public class NXDropBox implements IRemoteRepo {

    private static final String TAG = "NX_NXDropBox";
    // OnlyUsedFor Authentication
    static private DropboxAPI<AndroidAuthSession> sAuthenUesdOnly =
            new DropboxAPI<>(new AndroidAuthSession(new AppKeyPair(Config.NEXTLABS_GRANTED_KEY, Config.NEXTLABS_GRANTED_SECRET)));
    // DropboxAPI
    private DropboxAPI<AndroidAuthSession> mApi;

    public NXDropBox() {
        // build appKeyPair
        AppKeyPair appKeyPair = new AppKeyPair(Config.NEXTLABS_GRANTED_KEY, Config.NEXTLABS_GRANTED_SECRET);
        // build session with Android version
        AndroidAuthSession session = new AndroidAuthSession(appKeyPair);
        // init baseAPI
        mApi = new DropboxAPI<>(session);
    }

    static public void startOAuth2Authentication(Context context) {
        sAuthenUesdOnly.getSession().startOAuth2Authentication(context);
    }

    static public String getOAuth2Token() {
        return sAuthenUesdOnly.getSession().getOAuth2AccessToken();
    }

    /**
     * user session to judge if previous authentication has succeed
     * mApi.getSession().authenticationSuccessful() : use intend to check
     *
     * @return
     */
    static public Boolean oAuth2AuthenticationSuccessful() {
        if (sAuthenUesdOnly.getSession().authenticationSuccessful()) {
            sAuthenUesdOnly.getSession().finishAuthentication();
            return true;
        }
        return false;
    }

    public void SetOAuth2AccessToken(String oauth2AccessToken) {
        mApi.getSession().setOAuth2AccessToken(oauth2AccessToken);
    }

    @Override
    public INxFile getFileMetaInfo(INxFile file) {
        // sanity check
        if (file == null)
            return null;
        try {
            return getMetaInfo(file.getCloudPath());

        } catch (Exception e) {
            Log.v(TAG, e.toString());
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public void getFileMetaInfo(INxFile file, IGetFileMetaInfoCallback callback) {
        // sanity check
        if (file == null)
            throw new NullPointerException("file is null");
        if (callback == null)
            throw new NullPointerException("callback is null");

        GetFileOrDirInfoAsyncTask task = new GetFileOrDirInfoAsyncTask(this, callback);
        task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, file);
    }

    @Override
    public void downloadFile(INxFile document, String localPath, IDownLoadCallback callback) {
        new DownLoadFileAsyncTask(this, callback, document, document.getCloudPath(), localPath)
                .executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void) null);
    }


    @Override
    public boolean isProgressSupported() {
        return true;
    }


    @Override
    public void uploadFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback) {
        uploadAndUpdateFile(parentFolder, fileName, localFile, callback, false);
    }

    @Override
    public void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IUploadFileCallback callback) {
        uploadAndUpdateFile(parentFolder, updateFile.getName(), localFile, callback, true);
    }

    private INxFile getMetaInfo(String path) throws Exception {
        NxFileBase rt = null;

        if (!isLinked()) {
            throw new Exception("session is not link between s/c");
        }

        DropboxAPI.Entry entry = mApi.metadata(path, 0, null, true, null);
        rt = entry.isDir ? new NXFolder() : new NXDocument();

        fillFileParmas(rt, entry);
        for (DropboxAPI.Entry node : entry.contents) {
            NxFileBase file = node.isDir ? new NXFolder() : new NXDocument();
            fillFileParmas(file, node);
            rt.addChild(file);
        }

        return rt;
    }

    private void uploadAndUpdateFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback, boolean bUpdate) {
        String cloudPath = parentFolder.getCloudPath();
        if (!cloudPath.endsWith("/")) {
            cloudPath = cloudPath + "/";
        }
        cloudPath = cloudPath + fileName;

        new UploadFileAsyncTask(this, callback, cloudPath, localFile, bUpdate)
                .executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void) null);
    }

    public DropboxAPI.DropboxInputStream getFileStream(String path, String rev) throws DropboxException {
        return mApi.getFileStream(path, rev);
    }

    public boolean downLoadFile(DropboxAPI.DropboxInputStream inputStream,
                                String localFilePath,
                                ProgressListener listener) throws Exception {

        if (!isLinked()) {
            return false;
        }

        FileOutputStream outputStream = null;
        File local = new File(localFilePath);
        Helper.makeSureDocExist(local);

        //File output stream
        try {
            outputStream = new FileOutputStream(local);
            inputStream.copyStreamToOutput(outputStream, listener);
            return true;
        } finally {
            if (outputStream != null) {
                try {
                    outputStream.close();
                } catch (Exception e) {
                }
            }
        }
    }

    public DropboxAPI.UploadRequest putFileRequest(String path,
                                                   InputStream is,
                                                   long length,
                                                   String parentRev,
                                                   boolean autoRename,
                                                   ProgressListener listener) throws DropboxException {
        return mApi.putFileRequest(path, is, length, parentRev, autoRename, listener);
    }

    public DropboxAPI.UploadRequest putFileOverwriteRequest(String path,
                                                            InputStream is,
                                                            long length,
                                                            ProgressListener listener) throws DropboxException {
        return mApi.putFileOverwriteRequest(path, is, length, listener);
    }

    @Override
    public boolean getInfo(RemoteRepoInfo info) {
        try {
            DropboxAPI.Account account = mApi.accountInfo();
            info.displayName = account.displayName;
            info.email = account.email;
            info.remoteTotalSpace = account.quota;
            info.remoteUsedSpace = account.quotaNormal;
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    public boolean isLinked() {
        return mApi.getSession().isLinked();
    }


    private void fillFileParmas(NxFileBase f, DropboxAPI.Entry node) {
        f.setLocalPath(node.path);
        f.setCloudPath(node.path); // it is recommended to use this path for communication with cloud server
        f.setSize(node.bytes);
        f.setName(node.fileName());
        f.setLastModifiedTime(node.modified);
        if (node.modified != null) {
            try {
                //Mon, 19 Oct 2015 09:35:20 +0000
                //SimpleDateFormat df = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss z");
                SimpleDateFormat df = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss z", Locale.US);
                //df.setTimeZone(TimeZone.getTimeZone("UTC"));
                f.setLastModifiedTimeLong(df.parse(node.modified).getTime());
            } catch (Exception e) {
                e.printStackTrace();
                f.setLastModifiedTimeLong(0);
            }
        }
        // todo:add is deleted
        f.setDeletedByCloud(node.isDeleted);
    }

    static private class Config {
        // granted key & secret are hard-coded values
        // if it must change the key value, change the other place's val at AndoridManifest.xml either
        public static final String NEXTLABS_GRANTED_KEY = "7iw0a6cmfshsxxk";
        public static final String NEXTLABS_GRANTED_SECRET = "tiy7hlct3fnmsk2";
    }

    public static class GetAccountAsyncTask extends AsyncTask<Void, Void, DropboxAPI.Account> {

        private IGetAccountAsyncTask mCallBack = null;

        public void setCallBack(IGetAccountAsyncTask mCallBack) {
            this.mCallBack = mCallBack;
        }

        @Override
        protected DropboxAPI.Account doInBackground(Void... params) {
            DropboxAPI.Account account = null;
            try {
                account = sAuthenUesdOnly.accountInfo();
            } catch (Exception e) {
                //may be casued by javax.net.ssl.SSLPeerUnverifiedException: No peer certificate
                // try again
                try {
                    account = sAuthenUesdOnly.accountInfo();
                } catch (Exception ignored) {
                }
            }
            return account;
        }

        @Override
        protected void onPostExecute(DropboxAPI.Account account) {
            if (mCallBack != null) {
                mCallBack.onFinishGet(account);
            }
        }

        public interface IGetAccountAsyncTask {
            void onFinishGet(DropboxAPI.Account account);
        }
    }
}


class GetFileOrDirInfoAsyncTask extends AsyncTask<INxFile, Void, INxFile> {
    protected String mErrorMsg = "unknown";
    IRemoteRepo repo;
    IRemoteRepo.IGetFileMetaInfoCallback callback;

    public GetFileOrDirInfoAsyncTask(IRemoteRepo repo, IRemoteRepo.IGetFileMetaInfoCallback callback) {
        this.repo = repo;
        this.callback = callback;
    }

    @Override
    protected INxFile doInBackground(INxFile... params) {
        try {
            INxFile fs = repo.getFileMetaInfo(params[0]);
            if (fs != null) {
                mErrorMsg = "OK: get files meta info";
            }
            return fs;
        } catch (Exception e) {
            mErrorMsg = e.getMessage();
        }
        return null;
    }

    @Override
    protected void onPostExecute(INxFile file) {
        if (callback != null) {
            callback.getFileMetaInfoFinished(file != null ? true : false, file, mErrorMsg);
        }
    }
}

class DownLoadFileAsyncTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {
    private static final String TAG = "NX_DownLoadFileAT";
    IRemoteRepo repo;
    IRemoteRepo.IDownLoadCallback callback;
    INxFile document;
    String mDropboxFilePath;
    String mLocalFilePath;
    String mErrorMsg = "null";
    DropboxAPI.DropboxInputStream inputStream = null;
    boolean isCanceled = false;

    public DownLoadFileAsyncTask(IRemoteRepo repo, IRemoteRepo.IDownLoadCallback callback, INxFile doc, String dropboxFilePath, String localFilePath) {
        this.repo = repo;
        this.callback = callback;
        this.document = doc;
        this.mDropboxFilePath = dropboxFilePath;
        this.mLocalFilePath = localFilePath;

    }

    @Override
    public void cancel() {
        isCanceled = true;
        cancel(true);
    }

    @Override
    protected void onProgressUpdate(Long... values) {
        if (callback != null) {
            callback.downloadFileProgress(values[0]);
        }
    }

    @Override
    protected void onPreExecute() {
        if (callback != null) {
            callback.cancelHandler(this);
        }
    }

    /*
    11/18/2015 if downloading-stream disconnected suddenly ,delete the incomplete file at local disk
     */
    @Override
    protected Boolean doInBackground(Void... params) {
        NXDropBox dropBox = (NXDropBox) repo;
        boolean rt = false;
        mErrorMsg = "download file Failed";
        try {
            // check cancel sign
            if (isCanceled) {
                throw new DropboxPartialFileException(0);
            }
            inputStream = dropBox.getFileStream(mDropboxFilePath, null);
            // according to SDK ,dropBox.getFileStream will throw exception if error occurs
//            if (inputStream == null)
//                return false;

            // check cancel sign
            if (isCanceled) {
                throw new DropboxPartialFileException(0);
            }

            rt = dropBox.downLoadFile(inputStream, mLocalFilePath, new ProgressListener() {
                //To be called at background thread
                @Override
                public void onProgress(long current, long total) {
                    if (isCanceled) {
                        try {
                            // close stream at non-UI thread
                            if (inputStream != null) {
                                inputStream.close();
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                    long percentage = (long) (current / (double) total * 100);
                    publishProgress(percentage);
                }
            });
            if (rt) {
                mErrorMsg = "download file OK";
            }
            return rt;
        } catch (DropboxUnlinkedException e) {
            mErrorMsg = "The AuthSession wasn't properly authenticated or user unlinked.";
            e.printStackTrace();
        } catch (DropboxPartialFileException e) {
            mErrorMsg = "Download canceled";
            e.printStackTrace();
        } catch (DropboxIOException e) {
            mErrorMsg = "Network error.  Try again.";
            e.printStackTrace();
        } catch (DropboxParseException e) {
            mErrorMsg = "Dropbox error.  Try again.";
            e.printStackTrace();
        } catch (DropboxException e) {
            mErrorMsg = "Unknown Dropbox error.  Try again.";
            e.printStackTrace();
        } catch (Exception e) {
            mErrorMsg = "Unknown Java error.  Try again.";
            e.printStackTrace();
        } finally {
            if (inputStream != null) {
                try {
                    inputStream.close();
                } catch (Exception e) {
                }
            }
            if (isCanceled || !rt) {
                try {
                    Helper.deleteFile(new File(mLocalFilePath));
                } catch (Exception e) {
                }
            }
        }
        return false;
    }

    @Override
    protected void onPostExecute(Boolean result) {
        if (callback != null) {
            if (result) {
                ((NxFileBase) document).setCached(true);
            }
            callback.downloadFileFinished(result, mLocalFilePath, mErrorMsg);
        }
    }
}


class UploadFileAsyncTask
        extends AsyncTask<Void, Long, Boolean>
        implements ICancelable {
    protected String mCloudPath;
    protected String mErrorMsg = "null";
    IRemoteRepo repo;
    IRemoteRepo.IUploadFileCallback callback;
    boolean isCanceled = false;
    private File mFile;
    private long mFileLen;
    private boolean bUpdate;
    private DropboxAPI.UploadRequest mRequest = null;

    public UploadFileAsyncTask(IRemoteRepo repo, IRemoteRepo.IUploadFileCallback callback, String cloudPath, File localFile, boolean bUpdate) {
        this.repo = repo;
        this.callback = callback;
        this.mCloudPath = cloudPath;
        this.mFile = localFile;
        this.mFileLen = localFile.length();
        this.bUpdate = bUpdate;
    }


    public void abortTask() {
        isCanceled = true;
//        // mRequest may be null , caller may cancel this task before mRequest has constructed
//        if (mRequest != null) {
//            mRequest.abort();   // shit, this can not be called at UI thread
//        }
        cancel(true);
    }

    @Override
    public void cancel() {
        abortTask();
    }

    @Override
    protected void onPreExecute() {
        if (callback != null) {
            callback.cancelHandler(this);
        }
    }

    @Override
    protected void onPostExecute(Boolean status) {
        if (callback != null) {
            callback.uploadFileFinished(status, mCloudPath, mErrorMsg);
        }
    }

    @Override
    protected void onProgressUpdate(Long... values) {
        if (callback != null) {
            callback.uploadFileProgress(values[0]);
        }
    }

    @Override
    protected Boolean doInBackground(Void... params) {
        NXDropBox dropBox = (NXDropBox) repo;
        FileInputStream fis = null;
        try {
            // check cancel sign
            if (isCanceled) {
                throw new DropboxPartialFileException(0);
            }

            fis = new FileInputStream(mFile);

            // check cancel sign
            if (isCanceled) {
                throw new DropboxPartialFileException(0);
            }

            if (bUpdate) {
                mRequest = dropBox.putFileOverwriteRequest(mCloudPath, fis, mFileLen, new ProgressListener() {
                    @Override
                    public void onProgress(long current, long total) {
                        long percentage = (long) (current / (double) total * 100);
                        publishProgress(percentage);
                    }
                });
            } else {
                mRequest = dropBox.putFileRequest(mCloudPath, fis, mFileLen, null, false, new ProgressListener() {
                    @Override
                    public void onProgress(long current, long total) {
                        long percentage = (long) (current / (double) total * 100);
                        publishProgress(percentage);
                    }
                });
            }

            // check cancel sign
            if (isCanceled) {
                throw new DropboxPartialFileException(0);
            }

            mRequest.upload();
            mErrorMsg = "upload ok";
            return true;
        } catch (DropboxUnlinkedException e) {
            mErrorMsg = "This Dropbox account wasn't authenticated properly";
            e.printStackTrace();
        } catch (DropboxFileSizeException e) {
            mErrorMsg = "This file is to big to upload";
            e.printStackTrace();
        } catch (DropboxPartialFileException e) {
            mErrorMsg = "Upload canceled";
            e.printStackTrace();
        } catch (DropboxServerException e) {
            if (e.toString().contains("409 Conflict (conflict_file)")) {
                mErrorMsg = "resource_already_exists";
            }
            e.printStackTrace();
        } catch (DropboxIOException e) {
            mErrorMsg = "Network error, Try again";
            e.printStackTrace();
        } catch (DropboxParseException e) {
            mErrorMsg = "Dropbox error.  Try again.";
            e.printStackTrace();
        } catch (DropboxException e) {
            mErrorMsg = "Dropbox unknown error.  Try again.";
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (fis != null) {
                try {
                    fis.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return false;

    }


}
package appInstance.remoteRepo.sharepointonline.AsyncTask;

import android.os.AsyncTask;

import java.io.File;

import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.sharepointonline.SharePointOnlineSdk;
import errorHandler.ErrorCode;

/**
 * Created by aning on 6/25/2015.
 */
public class UploadFileAsyncTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {

    private static final String TAG = "UploadFileAsyncTask";

    protected String mCloudPath;
    private File mFile;
    private long mFileLen;
    private IRemoteRepo.IUploadFileCallback mCallback = null;
    private SharePointOnlineSdk sdk;

    public UploadFileAsyncTask(SharePointOnlineSdk sdk, nxl.types.INxFile document, String fileName, File localFile, boolean bUpdate) {
        this.mCloudPath = document.getCloudPath();
        this.mFile = localFile;
        this.mFileLen = mFile.length();
        this.sdk = sdk;
        sdk.StartUploadFile(mCloudPath, fileName, bUpdate);
    }

    public void setCallback(IRemoteRepo.IUploadFileCallback mCallback) {
        this.mCallback = mCallback;
    }

    @Override
    public void cancel() {
        sdk.AbortUploadTask();
    }

    protected void onPreExecute() {
        if (mCallback != null) {
            mCallback.cancelHandler(this);
        }
    }

    @Override
    protected void onPostExecute(Boolean status) {
        if (mCallback != null) {
            mCallback.uploadFileFinished(status, "", String.valueOf(ErrorCode.SHARE_POINT_ONLINE_UPLOAD_REQUEST_ERROR));
        }
    }

    @Override
    protected void onProgressUpdate(Long... values) {
        if (mCallback != null) {
            mCallback.uploadFileProgress(values[0]);
        }
    }

    @Override
    protected Boolean doInBackground(Void... params) {

        return sdk.UploadFile(mFile, mFileLen, new SharePointOnlineSdk.IUpdateUploadFile() {
            @Override
            public void onUpdate(long newValue) {
                publishProgress(newValue);
            }
        });
    }

}


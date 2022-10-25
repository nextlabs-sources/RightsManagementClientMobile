package appInstance.remoteRepo.sharepoint.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.sharepoint.SharePointSdk;
import nxl.types.NxFileBase;

public class DownLoadFileAsyncTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {

    private static final String TAG = "DownLoadFileAsyncTask";

    nxl.types.INxFile document;
    private String LocalPath;
    private String CloudPath;
    private IRemoteRepo.IDownLoadCallback mCallback;
    private SharePointSdk sdk;

    public DownLoadFileAsyncTask(SharePointSdk sdk, nxl.types.INxFile document, String LocalPath) {
        this.document = document;
        this.LocalPath = LocalPath;
        this.CloudPath = document.getCloudPath();
        this.sdk = sdk;
        sdk.StartDownloadFile(CloudPath);
    }

    public void setCallback(IRemoteRepo.IDownLoadCallback mCallback) {
        this.mCallback = mCallback;
    }

    @Override
    public void cancel() {
        sdk.AbortTask();
    }

    @Override
    protected void onProgressUpdate(Long... values) {
        if (mCallback != null) {
            mCallback.downloadFileProgress(values[0]);
        }
    }

    @Override
    protected void onPreExecute() {
        if (mCallback != null) {
            mCallback.cancelHandler(this);
        }
    }

    @Override
    protected void onPostExecute(Boolean result) {
        if (mCallback != null) {
            if (result) {
                ((NxFileBase) document).setCached(true);
            }

            mCallback.downloadFileFinished(result, LocalPath, "unknown");
        }
    }

    @Override
    protected Boolean doInBackground(Void... params) {
        return sdk.DownloadFile(CloudPath, LocalPath, document.getSize(), new appInstance.remoteRepo.sharepoint.SharePointSdk.IUpdateDownLoadFile() {
            @Override
            public void onUpdate(long newValue) {
                publishProgress(newValue);
            }
        });
    }
}

package appInstance.remoteRepo.googledrive.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import nxl.types.NxFileBase;

public class DownLoadFileTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {

    private static final String TAG = "DownLoadFileAsyncTask";

    nxl.types.INxFile document;
    private String LocalPath;
    private String CloudPath;
    private IRemoteRepo.IDownLoadCallback mCallback;
    private GoogleDriveSdk sdk;

    public DownLoadFileTask(GoogleDriveSdk sdk, nxl.types.INxFile document, String LocalPath) {
        this.sdk = sdk;
        this.document = document;
        this.LocalPath = LocalPath;
        this.CloudPath = document.getCloudPath();
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
    protected Boolean doInBackground(Void... params) {
        return sdk.DownloadFile(CloudPath, LocalPath, document.getSize(), new appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk.IUpdateDownLoadFile() {
            @Override
            public void onUpdate(long newValue) {
                publishProgress(newValue);
            }
        });
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
}


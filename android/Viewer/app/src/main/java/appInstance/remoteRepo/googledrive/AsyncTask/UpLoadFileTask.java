package appInstance.remoteRepo.googledrive.AsyncTask;

import android.os.AsyncTask;

import java.io.File;

import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;

public class UpLoadFileTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {
    private static final String TAG = "UpLoadFileTask";

    nxl.types.INxFile parentFolde;
    private String fileName;
    private File localFile;
    private IRemoteRepo.IUploadFileCallback mCallback;
    private GoogleDriveSdk sdk;

    public UpLoadFileTask(GoogleDriveSdk sdk, nxl.types.INxFile parentFolde, String fileName, File localFile) {
        this.sdk = sdk;
        this.parentFolde = parentFolde;
        this.fileName = fileName;
        this.localFile = localFile;
        sdk.StartUploadFile();
    }

    public void setCallback(IRemoteRepo.IUploadFileCallback mCallback) {
        this.mCallback = mCallback;
    }

    @Override
    public void cancel() {
        sdk.AbortUploadTask();
    }

    @Override
    protected void onPreExecute() {
        if (mCallback != null) {
            mCallback.cancelHandler(this);
        }
    }

    @Override
    protected void onPostExecute(Boolean status) {
        if (mCallback != null) {
            mCallback.uploadFileFinished(status, "", "unknown");
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
        return sdk.UploadFile(parentFolde, fileName, localFile, new appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk.IUpdateDownLoadFile() {
            @Override
            public void onUpdate(long newValue) {
                publishProgress(newValue);
            }
        });
    }
}

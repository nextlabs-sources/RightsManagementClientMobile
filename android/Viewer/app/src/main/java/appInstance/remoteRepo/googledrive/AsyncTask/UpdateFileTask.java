package appInstance.remoteRepo.googledrive.AsyncTask;

import android.os.AsyncTask;

import java.io.File;

import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;

public class UpdateFileTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {
    private static final String TAG = "UpdateFileTask";

    nxl.types.INxFile parentFolde;
    private String CloudPath;
    private File localFile;
    private IRemoteRepo.IUploadFileCallback mCallback;
    private GoogleDriveSdk sdk;

    public UpdateFileTask(GoogleDriveSdk sdk, nxl.types.INxFile parentFolde, nxl.types.INxFile updateFile, File localFile) {
        this.sdk = sdk;
        this.parentFolde = parentFolde;
        this.CloudPath = updateFile.getCloudPath();
        this.localFile = localFile;
        sdk.StartUpdatedFile();
    }

    public void setCallback(IRemoteRepo.IUploadFileCallback mCallback) {
        this.mCallback = mCallback;
    }

    @Override
    public void cancel() {
        sdk.AbortUpdateTask();
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
        return sdk.UpdateFile(parentFolde, CloudPath, localFile, new appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk.IUpdateDownLoadFile() {
            @Override
            public void onUpdate(long newValue) {
                publishProgress(newValue);
            }
        });
    }
}

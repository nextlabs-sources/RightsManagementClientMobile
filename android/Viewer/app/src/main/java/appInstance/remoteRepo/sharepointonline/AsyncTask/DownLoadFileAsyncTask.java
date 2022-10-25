package appInstance.remoteRepo.sharepointonline.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.sharepointonline.SharePointOnlineSdk;
import nxl.types.NxFileBase;

/**
 * Created by aning on 6/5/2015.
 */
public class DownLoadFileAsyncTask extends AsyncTask<Void, Long, Boolean> implements ICancelable {

    private static final String TAG = "DownLoadFileAsyncTask";
    nxl.types.INxFile document;
    private String LocalPath;
    private IRemoteRepo.IDownLoadCallback mCallback;
    private SharePointOnlineSdk sdk;

    public DownLoadFileAsyncTask(SharePointOnlineSdk sdk, nxl.types.INxFile document, String LocalPath) {
        this.LocalPath = LocalPath;
        this.document = document;
        this.sdk = sdk;
        sdk.StartDownloadFile(document.getCloudPath());
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

        return sdk.DownloadFile(LocalPath, document.getSize(), new SharePointOnlineSdk.IUpdateDownLoadFile() {
            @Override
            public void onUpdate(long newValue) {
                publishProgress(newValue);
            }
        });
    }

}

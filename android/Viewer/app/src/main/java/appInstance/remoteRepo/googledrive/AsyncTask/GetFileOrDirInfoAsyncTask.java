package appInstance.remoteRepo.googledrive.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;


public class GetFileOrDirInfoAsyncTask extends AsyncTask<nxl.types.INxFile, Void, nxl.types.NxFileBase> {

    private IRemoteRepo.IGetFileMetaInfoCallback mCallBack = null;
    private GoogleDriveSdk sdk = null;

    public GetFileOrDirInfoAsyncTask(GoogleDriveSdk sdk, IRemoteRepo.IGetFileMetaInfoCallback CallBack) {
        this.sdk = sdk;
        this.mCallBack = CallBack;
    }

    public void setCallBack(IRemoteRepo.IGetFileMetaInfoCallback mCallBack) {
        this.mCallBack = mCallBack;
    }

    @Override
    protected nxl.types.NxFileBase doInBackground(nxl.types.INxFile... params) {
        return sdk.GetMetaInfo(params[0]);
    }

    @Override
    protected void onPostExecute(nxl.types.NxFileBase nxFileBase) {
        if (mCallBack != null) {
            mCallBack.getFileMetaInfoFinished(nxFileBase != null ? true : false, nxFileBase, "unknown");
        }
    }
}
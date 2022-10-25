package appInstance.remoteRepo.sharepoint.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.sharepoint.SharePointSdk;

public class GetFileOrDirInfoAsyncTask extends AsyncTask<nxl.types.INxFile, Void, nxl.types.NxFileBase> {

    private IRemoteRepo.IGetFileMetaInfoCallback mCallBack = null;
    private SharePointSdk sdk = null;

    public GetFileOrDirInfoAsyncTask(SharePointSdk sdk, IRemoteRepo.IGetFileMetaInfoCallback CallBack) {
        this.mCallBack = CallBack;
        this.sdk = sdk;
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

package appInstance.remoteRepo.sharepointonline.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.sharepointonline.SharePointOnlineSdk;
import nxl.types.INxFile;
import nxl.types.NxFileBase;

/**
 * Created by aning on 6/4/2015.
 */
public class GetFileOrDirInfoAsyncTask extends AsyncTask<INxFile, Void, NxFileBase> {

    private IRemoteRepo.IGetFileMetaInfoCallback mCallBack = null;
    private SharePointOnlineSdk sdk = null;

    public GetFileOrDirInfoAsyncTask(SharePointOnlineSdk sdk, IRemoteRepo.IGetFileMetaInfoCallback CallBack) {
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

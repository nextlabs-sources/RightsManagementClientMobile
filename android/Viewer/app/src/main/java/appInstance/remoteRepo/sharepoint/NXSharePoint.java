package appInstance.remoteRepo.sharepoint;

import java.io.File;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoInfo;
import appInstance.remoteRepo.sharepoint.AsyncTask.UploadFileAsyncTask;
import nxl.types.INxFile;

public class NXSharePoint implements IRemoteRepo {
    private static final String TAG = "NXSharePoint";

    private SharePointSdk sdk = null;

    public NXSharePoint(String Url, String UserName, String Password) {
        sdk = new SharePointSdk(Url, UserName, Password);
    }

    @Override
    public INxFile getFileMetaInfo(INxFile file) {
        return sdk.GetMetaInfo(file);
    }

    @Override
    public void getFileMetaInfo(INxFile file, IGetFileMetaInfoCallback callback) {
        // sanity check
        if (file == null)
            throw new NullPointerException("file is null");
        appInstance.remoteRepo.sharepoint.AsyncTask.GetFileOrDirInfoAsyncTask task = new appInstance.remoteRepo.sharepoint.AsyncTask.GetFileOrDirInfoAsyncTask(sdk, callback);
        task.execute(file);
    }

    @Override
    public void downloadFile(INxFile document, String localPath, IDownLoadCallback callback) {
        appInstance.remoteRepo.sharepoint.AsyncTask.DownLoadFileAsyncTask DownloadAsyncTask = new appInstance.remoteRepo.sharepoint.AsyncTask.DownLoadFileAsyncTask(sdk, document, localPath) {
        };
        ;
        DownloadAsyncTask.setCallback(callback);
        DownloadAsyncTask.execute();
    }

    @Override
    public boolean isProgressSupported() {
        return true;
    }

    private void uploadAndupdateFile(INxFile document, String fileName, File localFile, IUploadFileCallback callback, boolean bUpdate) {
        appInstance.remoteRepo.sharepoint.AsyncTask.UploadFileAsyncTask UploadAsyncTask = new UploadFileAsyncTask(sdk, document, fileName, localFile, bUpdate) {
        };
        UploadAsyncTask.setCallback(callback);
        UploadAsyncTask.execute();
    }

    @Override
    public void uploadFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback) {
        uploadAndupdateFile(parentFolder, fileName, localFile, callback, false);
    }

    @Override
    public void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IUploadFileCallback callback) {
        uploadAndupdateFile(parentFolder, updateFile.getName(), localFile, callback, true);
    }

    @Override
    public boolean getInfo(RemoteRepoInfo info) {
        return sdk.getRepositoryInfo(info);
    }
}

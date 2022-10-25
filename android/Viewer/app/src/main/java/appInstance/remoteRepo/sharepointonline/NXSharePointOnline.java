package appInstance.remoteRepo.sharepointonline;

import android.util.Log;

import java.io.File;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoInfo;
import appInstance.remoteRepo.sharepointonline.AsyncTask.UploadFileAsyncTask;
import nxl.types.INxFile;

/**
 * Created by aning on 6/2/2015.
 */
public class NXSharePointOnline implements IRemoteRepo {
    private static final String TAG = "NXSharePointOnline";
    private SharePointOnlineSdk sdk = null;

    public NXSharePointOnline(String url, String userName, String token) {
        sdk = new SharePointOnlineSdk(url, userName, token);
    }

    @Override
    public INxFile getFileMetaInfo(INxFile file) {

        if (file == null)
            return null;
        try {
            return sdk.GetMetaInfo(file);
        } catch (Exception e) {
            Log.v(TAG, e.toString());
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public void getFileMetaInfo(INxFile file, IGetFileMetaInfoCallback callback) {
        // sanity check
        if (file == null)
            throw new NullPointerException("file is null");
        appInstance.remoteRepo.sharepointonline.AsyncTask.GetFileOrDirInfoAsyncTask task = new appInstance.remoteRepo.sharepointonline.AsyncTask.GetFileOrDirInfoAsyncTask(sdk, callback);
        task.execute(file);
    }

    @Override
    public void downloadFile(INxFile document, String localPath, IDownLoadCallback callback) {
        appInstance.remoteRepo.sharepointonline.AsyncTask.DownLoadFileAsyncTask DownloadAsyncTask = new appInstance.remoteRepo.sharepointonline.AsyncTask.DownLoadFileAsyncTask(sdk, document, localPath) {
        };
        DownloadAsyncTask.setCallback(callback);
        DownloadAsyncTask.execute();
    }

    @Override
    public boolean isProgressSupported() {
        return false;
    }

    private void uploadAndupdateFile(INxFile document, String fileName, File localFile, IUploadFileCallback callback, boolean bUpdate) {
        appInstance.remoteRepo.sharepointonline.AsyncTask.UploadFileAsyncTask UploadAsyncTask = new UploadFileAsyncTask(sdk, document, fileName, localFile, bUpdate) {
        };
        UploadAsyncTask.setCallback(callback);
        UploadAsyncTask.execute();
    }

    @Override
    public void uploadFile(INxFile document, String fileName, File localFile, IUploadFileCallback callback) {
        uploadAndupdateFile(document, fileName, localFile, callback, false);
    }

    @Override
    public void updateFile(INxFile document, INxFile updateFile, File localFile, IUploadFileCallback callback) {
        uploadAndupdateFile(document, updateFile.getName(), localFile, callback, true);
    }

    @Override
    public boolean getInfo(RemoteRepoInfo info) {
        return sdk.getRepositoryInfo(info);
    }
}

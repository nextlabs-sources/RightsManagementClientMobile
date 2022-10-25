package appInstance.remoteRepo.googledrive;

import java.io.File;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoInfo;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import nxl.types.INxFile;


public class NXGoogleDrive implements IRemoteRepo {
    private static final String TAG = "NXGoogleDrive";

    private GoogleDriveSdk sdk = null;

    public NXGoogleDrive(String UserName) {
        sdk = new GoogleDriveSdk(UserName);
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
        appInstance.remoteRepo.googledrive.AsyncTask.GetFileOrDirInfoAsyncTask task = new appInstance.remoteRepo.googledrive.AsyncTask.GetFileOrDirInfoAsyncTask(sdk, callback);
        task.execute(file);
    }

    @Override
    public void downloadFile(INxFile document, String localPath, IDownLoadCallback callback) {
        appInstance.remoteRepo.googledrive.AsyncTask.DownLoadFileTask DownloadAsyncTask = new appInstance.remoteRepo.googledrive.AsyncTask.DownLoadFileTask(sdk, document, localPath) {
        };
        DownloadAsyncTask.setCallback(callback);
        DownloadAsyncTask.execute();
    }

    @Override
    public boolean isProgressSupported() {
        return true;
    }

    @Override
    public void uploadFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback) {
        appInstance.remoteRepo.googledrive.AsyncTask.UpLoadFileTask UpLoadFileTask = new appInstance.remoteRepo.googledrive.AsyncTask.UpLoadFileTask(sdk, parentFolder, fileName, localFile) {

        };
        UpLoadFileTask.setCallback(callback);
        UpLoadFileTask.execute();
    }

    @Override
    public void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IUploadFileCallback callback) {
        appInstance.remoteRepo.googledrive.AsyncTask.UpdateFileTask UpdateFileTask = new appInstance.remoteRepo.googledrive.AsyncTask.UpdateFileTask(sdk, parentFolder, updateFile, localFile) {
        };
        UpdateFileTask.setCallback(callback);
        UpdateFileTask.execute();
    }

    @Override
    public boolean getInfo(RemoteRepoInfo info) {
        return sdk.getRepositoryInfo(info);
    }
}

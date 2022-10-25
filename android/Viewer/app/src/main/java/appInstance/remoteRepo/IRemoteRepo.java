package appInstance.remoteRepo;

import java.io.File;

import nxl.types.INxFile;


public interface IRemoteRepo {
    /**
     * Retrieve the immediate children( folder or document) indicated by {@param file}
     * - Background thread can use this method to update information
     *
     * @param file
     * @return
     */
    INxFile getFileMetaInfo(INxFile file);

    /**
     * Retrieve the immediate children( folder or document) indicated by {@param file}
     * -Async method , can be used by UI thread
     *
     * @param file
     * @param callback the caller must provide a callback interface to receive result
     */
    void getFileMetaInfo(INxFile file, IGetFileMetaInfoCallback callback);

    /**
     * Download a document (not a folder) to  {@param localPath}
     *
     * @param document
     * @param localPath
     * @param callback
     */
    void downloadFile(INxFile document, String localPath, IDownLoadCallback callback);

    void uploadFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback);

    void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IUploadFileCallback callback);


    boolean getInfo(RemoteRepoInfo info);

    /**
     * Determine if supports per
     * centage progress both for up and down load
     *
     * @return
     */
    boolean isProgressSupported();

    interface IGetFileMetaInfoCallback {
        void getFileMetaInfoFinished(boolean taskStatus, INxFile file, String errorMsg);
    }

    interface IDownLoadCallback {
        // before running Download task ,give caller a handler that can abort this task
        void cancelHandler(ICancelable handler);

        void downloadFileFinished(boolean taskStatus, String localPath, String errorMsg);

        void downloadFileProgress(long newValue);
    }

    interface IUploadFileCallback {

        // before running Download task ,give caller a handler that can abort this task
        void cancelHandler(ICancelable handler);

        void uploadFileFinished(boolean taskStatus, String cloudPath, String errorMsg);

        void uploadFileProgress(long newValue);

    }
}

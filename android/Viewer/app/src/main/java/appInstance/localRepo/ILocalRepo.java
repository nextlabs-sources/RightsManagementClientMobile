package appInstance.localRepo;

import java.io.File;
import java.util.List;

import appInstance.remoteRepo.IRemoteRepo;
import database.BoundService;
import nxl.types.INxFile;


public interface ILocalRepo {
    /**
     * first point to config this repo
     * - one local repo must associate a remote repo represented by BoundService
     */
    void install(File mountPoint, BoundService service) throws Exception;

    /**
     * point to delete this repo, be used when client want to delete this repo
     */
    void uninstall();

    /**
     * user will use it ,
     * - good point to prepare res
     */
    void activate();

    /**
     * user do not focus on it now
     * - good point to save/release res
     */
    void deactivate();

    /**
     * user can mark a file(folder or document) as favorite
     *
     * @param file
     */
    void markAsFavorite(INxFile file);

    void unmarkAsFavorite(INxFile file);

    /**
     * user can mark a file(folder or document) for which it can be accessed in offline mode
     * that means a file can get access from local not the remote
     *
     * @param file
     */
    void markAsOffline(INxFile file);

    void unmarkAsOffline(INxFile file);

    /**
     * Get a list holds all files  marked as favorite by client in this repo
     */
    List<INxFile> getFavoriteDocuments();

    /**
     * Get a list holds all files  marked as offline mode by client in this repo
     */
    List<INxFile> getOfflineDocuments();


    /**
     * mark a sign that the @{file} is managed by this repo
     */
    INxFile markSignByThisRepo(INxFile file);

    /**
     * a local repo must be associate with a bound service through which to indicate the remote repo
     *
     * @return
     */
    BoundService getLinkedService();


    /**
     * Get this repo's root immediately if cached , or ues asyn task
     * <p>
     * if {@param callback} is null , return local cache directly
     * </p>
     */
    INxFile getRoot(IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception;

    /**
     * get the latest root from remote repo , not async method
     * this method can not be running at UI thread
     */
    INxFile syncRoot();

    /**
     * get local repo's working folder directly ,
     * working folder is the current working folder in which client point
     */
    INxFile getWorkingFolder() throws Exception;

    /**
     * Mandatory to get latest info from remote repo
     * <p/>
     * <p>
     * Typical usage: UI will mandatorily refresh the current working folder
     * </p>
     *
     * @param callback
     * @throws Exception {@param callback} is null
     */
    void syncWorkingFolder(IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception;

    /**
     * get a document content, if not cached at local, download it
     *
     * @param document
     * @param callback
     * @throws Exception {@param document} can not downcast to NxDocument
     *                   {@param callback} is null
     */

    File getDocument(INxFile document, IRemoteRepo.IDownLoadCallback callback) throws Exception;

    void uploadFile(INxFile parentFolder, String fileName, File localFile, IRemoteRepo.IUploadFileCallback callback) throws Exception;

    void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IRemoteRepo.IUploadFileCallback callback) throws Exception;

    /**
     * use this method to get contents of {@param folder}
     *
     * @param folder
     * @param callback
     * @param isChangeWorkingFolder true, change this reps is working folder as {@param folder}
     * @return
     * @throws Exception
     */
    List<INxFile> listFolder(INxFile folder, IRemoteRepo.IGetFileMetaInfoCallback callback, boolean isChangeWorkingFolder) throws Exception;

    /**
     * Get parent of current working folder
     */
    INxFile uptoParent();

    INxFile getParent(INxFile child);

    /**
     * clear the file that stored local, but not marked as OFFLINE&FAVORITE
     */
    void clearCache();

    long calCacheSize();

    void getRepoInfo(IRepoInfoCallback callback);

    interface IRepoInfoCallback {
        void result(boolean status, RepoInfo info, String errorMsg);
    }
}

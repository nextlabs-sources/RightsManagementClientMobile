package appInstance.localRepo;

import android.os.AsyncTask;
import android.util.Log;

import java.io.File;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import appInstance.ExecutorPools;
import appInstance.ViewerApp;
import appInstance.localRepo.helper.Helper;
import appInstance.localRepo.internals.Cache;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoFactory;
import database.BoundService;
import errorHandler.ErrorCode;
import nxl.Utils;
import nxl.types.INxFile;
import nxl.types.NXDocument;
import nxl.types.NxFileBase;

/**
 * Notice:
 * - the File to be returned to UI must call markSignByThisRepo
 * - a responsibility to maintain CurrentWorkingFolder(CWF),calling some methods may trigger CFW changed.
 * - any action that trigger CFW changed ,fire a async task to refresh CFW
 * any method that may affect the CWF must call cache.onChangeWorkingFolder
 * History:
 * - 11/13/2015  change duty of background-update-task onto LocalRepoBase from Cache
 */
public class LocalRepoBase implements ILocalRepo {
    static private final String TAG = "NX_LRepo";
    static private final boolean DEBUG = ViewerApp.DEBUG;
    private File mountPoint;   //   /CallerDefined/cache/[sid]/[service]/
    private BoundService service;   // each repo must be bound with a service to hold basic information of RemoteRepo
    private IRemoteRepo remoteRepo; // local repo must link with a remote repo, 1 v.s. 1
    private Cache cache = new Cache();      // the actual docs will be got from cache object
    private Set<INxFile> favorites = new HashSet<>();
    private Set<INxFile> offlines = new HashSet<>();
    private boolean isActive = false;
    // current refresh,
    volatile private INxFile refreshingFolder = null;

    /**
     * @param mountPoint the base is used by this file system as a beginning point that every items installed
     *                   the caller can change this mount point, for example: use SD-card or others
     */
    @Override
    public void install(File mountPoint, BoundService service) throws Exception {
        // sanity check
        if (mountPoint == null || !mountPoint.exists()) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "mountPoint");
        }
        if (service == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_SERVICE_INVALID);
        }
        this.service = service;
        // associate a cloud disk
        remoteRepo = RemoteRepoFactory.create(this.service);
        // amend mount base
        if (service.type == BoundService.ServiceType.SHAREPOINT | service.type == BoundService.ServiceType.SHAREPOINT_ONLINE) {
            mountPoint = new File(mountPoint,
                    service.alias + "_" + service.alias + "_" + URLEncoder.encode(service.accountID + "\n" + service.account, "UTF-8"));
        } else {
            mountPoint = new File(mountPoint, service.alias + "_" + service.accountID);
        }
        if (!Helper.makeSureDirExist(mountPoint)) {
            throw new RuntimeException(ErrorCode.E_FS_INSTALL_REPO + " " + mountPoint.getPath());
        }

        this.mountPoint = mountPoint;
        // int cache
        cache.init(this.mountPoint, service);
        // run prefetch task
        ExecutorPools.COMMON_POOL.execute(new PrefetchTask(cache.getCacheTree()));
    }

    @Override
    public void uninstall() {
        deactivate();
        Helper.RecursionDeleteFile(mountPoint);
    }

    @Override
    public void activate() {
        // fill favorite and offline
        if (!isActive) {
            collectTreeFeatures();
            isActive = true;
        }
    }

    @Override
    public void deactivate() {
        if (isActive) {
            //fix-bug: when doing the deactivate, user root as the current working folder
            cache.onChangeWorkingFolder(cache.getCacheTree());
            // fire async task to serialize cache tree into disk
            ExecutorPools.COMMON_POOL.execute(new Runnable() {
                @Override
                public void run() {
                    cache.serializeCacheTree();
                }
            });
            isActive = false;
        }
    }

    @Override
    public BoundService getLinkedService() {
        return service;
    }

    @Override
    public void markAsFavorite(INxFile file) {
        favorites.add(file);
        changeItemFeature(file, ItemFeatureOperate.SET_FAVORITE);
    }

    @Override
    public void unmarkAsFavorite(INxFile file) {
        favorites.remove(file);
        changeItemFeature(file, ItemFeatureOperate.UNSET_FAVORITE);
    }

    @Override
    public void markAsOffline(INxFile file) {
        offlines.add(file);
        changeItemFeature(file, ItemFeatureOperate.SET_OFFLINE);
    }

    @Override
    public void unmarkAsOffline(INxFile file) {
        offlines.remove(file);
        changeItemFeature(file, ItemFeatureOperate.UNSET_OFFLINE);
    }

    private void changeItemFeature(INxFile file, ItemFeatureOperate feature) {
        if (file == null) {
            return;
        }
        INxFile child = cache.getCacheTree().findNode(file.getLocalPath());
        if (child == null) {
            return;
        }
        switch (feature) {
            case SET_FAVORITE:
                ((NxFileBase) child).setMarkedAsFavorite(true);
                break;
            case UNSET_FAVORITE:
                ((NxFileBase) child).setMarkedAsFavorite(false);
                break;
            case SET_OFFLINE:
                ((NxFileBase) child).setMarkedAsOffline(true);
                break;
            case UNSET_OFFLINE:
                ((NxFileBase) child).setMarkedAsOffline(false);
                break;
        }
        // write change into Disk
        ExecutorPools.COMMON_POOL.execute(new Runnable() {
            @Override
            public void run() {
                cache.serializeCacheTree();
            }
        });
    }

    @Override
    public List<INxFile> getFavoriteDocuments() {
        return new ArrayList<>(favorites);
    }

    @Override
    public List<INxFile> getOfflineDocuments() {
        return new ArrayList<>(offlines);
    }

    @Override
    public INxFile getWorkingFolder() throws Exception {
        INxFile workingFolder = cache.getWorkingFolder();
        fireAsyncRefreshWorkingFolderTask(workingFolder);
        return workingFolder;
    }

    @Override
    public void syncWorkingFolder(IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        // do not change the current working folder
        fireAsyncTaskSyncFolder(cache.getWorkingFolder(), false, callback);
    }

    private void changeWorkingFolder(INxFile folder) {
        cache.onChangeWorkingFolder(folder);
        fireAsyncRefreshWorkingFolderTask(folder);
    }

    @Override
    public INxFile getRoot(IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        // try get from cache frist
        INxFile root = cache.getCacheTree();
        // root has children or callback is null
        if (!root.getChildren().isEmpty() || callback == null) {
            changeWorkingFolder(root);
            return root;
        }
        // cache-matching failed , call network to get latest one
        fireAsyncTaskSyncFolder(root, true, callback);
        return null;
    }

    @Override
    public INxFile syncRoot() {
        if (remoteRepo == null) {
            return cache.getCacheTree();
        }
        INxFile root = remoteRepo.getFileMetaInfo(cache.getCacheTree());
        if (root != null) {
            cache.onSyncFolder(root);
        }
        return cache.getCacheTree();
    }

    @Override
    public File getDocument(INxFile document, IRemoteRepo.IDownLoadCallback callback) throws Exception {
        // sanity check
        if (document.isFolder())
            throw new RuntimeException(ErrorCode.E_NXLF_PARAM_FOLDER_REQUIRED);
        if (!(document instanceof NXDocument)) {
            throw new RuntimeException(ErrorCode.E_NXLF_PARAM_FOLDER_REQUIRED);
        }
        // try to get from cache first
        File rt = cache.getDocument((NXDocument) document);
        if (rt != null) {
            return rt;
        }
        // download from cloud
        syncFile((NXDocument) document, callback);
        return null;

    }

    @Override
    public void uploadFile(INxFile parentFolder,
                           String fileName,
                           File localFile,
                           IRemoteRepo.IUploadFileCallback callback) throws Exception {
        // Sanity check
        if (callback == null)
            throw new NullPointerException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);

        remoteRepo.uploadFile(parentFolder, fileName, localFile, callback);

    }

    @Override
    public void updateFile(INxFile parentFolder,
                           INxFile updateFile,
                           File localFile,
                           IRemoteRepo.IUploadFileCallback callback) throws Exception {
        // Sanity check
        if (callback == null)
            throw new NullPointerException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);

        remoteRepo.updateFile(parentFolder, updateFile, localFile, callback);

    }

    @Override
    public List<INxFile> listFolder(INxFile folder, IRemoteRepo.IGetFileMetaInfoCallback callback, boolean isChangeWorkingFolder) throws Exception {
        // sanity check
        if (!folder.isFolder())
            throw new RuntimeException(ErrorCode.E_NXLF_PARAM_FOLDER_REQUIRED + "folder");
        // try get from cache first
        INxFile f = cache.tryToGetFromCache(folder);
        if (f != null && f.getChildren().size() > 0) {
            if (isChangeWorkingFolder) {
                changeWorkingFolder(f);
            }
            return f.getChildren();
        }

        // for failed of cache matching ,
        if (callback == null)
            throw new NullPointerException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);

        fireAsyncTaskSyncFolder(folder, isChangeWorkingFolder, callback);

        return null;
    }

    @Override
    public INxFile uptoParent() {
        INxFile parent = cache.findParentOfWorkingFolder();
        if (parent == null) {
            return null;
        }
        changeWorkingFolder(parent);
        return parent;
    }

    @Override
    public INxFile getParent(INxFile child) {
        if (child == null) {
            return null;
        }
        return cache.findNodeInTree(Helper.getParent(child));
    }

    @Override
    public INxFile markSignByThisRepo(INxFile file) {
        if (file == null) {
            return null;
        }
        NxFileBase f = (NxFileBase) file;
        Utils.attachService(f, service, true);
        return file;
    }

    @Override
    public void clearCache() {
        // find all docs exist at disk while not marked as offline&favorite
        INxFile root = cache.getCacheTree();
        final ArrayList<File> files = new ArrayList<>();

        Utils.EnumerateAllFiles(root, new Utils.OnEnumerate() {
            @Override
            public void onFileFound(INxFile file) {
                if (!file.isFolder() && !file.isMarkedAsOffline()) {
                    File absPath = new File(cache.getRootDir(), file.getLocalPath());
                    if (absPath.exists()) {
                        files.add(absPath);
                        ((NxFileBase) file).setCached(false);
                    }

                }
            }
        });
        // job
        if (files.isEmpty()) {
            return;
        }
        // task
        new DeleteFileTask(cache.getRootDir(), files).run();
    }

    @Override
    public long calCacheSize() {
        return calSize(false);
    }

    @Override
    public void getRepoInfo(final IRepoInfoCallback callback) {
        class AT extends AsyncTask<Void, Void, Boolean> {
            LocalRepoBase base;
            RepoInfo info = new RepoInfo();
            String errorMsg = "unknown";

            public AT(LocalRepoBase base) {
                this.base = base;
            }

            @Override
            protected Boolean doInBackground(Void... params) {
                // calc local
                File root = base.cache.getRootDir();
                //  total local size
                info.localTotalSize = root.getUsableSpace();
                //  cached size
                info.localCachedSize = base.calSize(false);
                //  offline size
                info.localOfflineSize = base.calSize(true);
                // calc remote
                return base.remoteRepo.getInfo(info);
            }

            @Override
            protected void onPostExecute(Boolean status) {
                if (status) {
                    callback.result(true, info, "OK");
                } else {
                    callback.result(false, info, errorMsg);

                }
            }
        }
        new AT(this).executeOnExecutor(ExecutorPools.COMMON_POOL);
    }

    private long calSize(final boolean bCountOffline) {
        long size = 0;
        // find all docs exist at disk while not marked as offline&favorite
        INxFile root = cache.getCacheTree();

        final ArrayList<File> files = new ArrayList<>();

        Utils.EnumerateAllFiles(root, new Utils.OnEnumerate() {
            @Override
            public void onFileFound(INxFile file) {
                if (file.isFolder()) {
                    return;
                }
                if (bCountOffline) {
                    if (file.isMarkedAsOffline()) {
                        File absPath = new File(cache.getRootDir(), file.getLocalPath());
                        if (absPath.exists()) {
                            files.add(absPath);
                        }
                    }
                } else {
                    if (!file.isMarkedAsOffline()) {
                        File absPath = new File(cache.getRootDir(), file.getLocalPath());
                        if (absPath.exists()) {
                            files.add(absPath);
                        }
                    }
                }

            }
        });
        // job
        for (File f : files) {
            size += f.length();
        }
        return size;
    }

    private void syncFile(NXDocument document, IRemoteRepo.IDownLoadCallback callback) throws Exception {
        // sanity check
        if (document == null) {
            throw new NullPointerException(ErrorCode.E_RT_PARAM_DOC_INVALID);
        }
        if (callback == null)
            throw new NullPointerException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);

        // downloading a file requires absPath
        remoteRepo.downloadFile(document, Helper.nxPath2AbsPath(cache.getRootDir(), document.getLocalPath()), callback); // must set a legal path
    }

    /**
     * get folder meta information from network
     * - markSign
     * - notify cache
     */
    private void fireAsyncTaskSyncFolder(INxFile folder, boolean isChangeWorkingFolder, IRemoteRepo.IGetFileMetaInfoCallback callback) {
        class AT extends AsyncTask<Void, Void, INxFile> {
            INxFile folder;
            LocalRepoBase base;
            IRemoteRepo.IGetFileMetaInfoCallback callback;
            boolean isChangeWorkingFolder;

            public AT(INxFile folder, LocalRepoBase base, IRemoteRepo.IGetFileMetaInfoCallback callback, boolean isChangeWorkingFolder) {
                this.folder = folder;
                this.base = base;
                this.callback = callback;
                this.isChangeWorkingFolder = isChangeWorkingFolder;
            }

            @Override
            protected INxFile doInBackground(Void... params) {
                return base.remoteRepo.getFileMetaInfo(folder);
            }

            @Override
            protected void onPostExecute(INxFile iNxFile) {
                if (iNxFile != null) {
                    if (isChangeWorkingFolder) {
                        base.changeWorkingFolder(iNxFile);
                    }
                    // tell cache about the new updating folder
                    cache.onSyncFolder(iNxFile);
                    /**
                     * bug-prone, return updated folder to UI , must make sure the node is a reference to CachedTree
                     */
                    INxFile rtNxFile = cache.findNodeInTree(iNxFile); // since iNxFile has updated in cache, it must ok
                    if (rtNxFile == null) {
                        if (DEBUG) {
                            Log.d(TAG, "on fireAsyncTaskSyncFolder, can not find this file in cached-tree" + iNxFile.getLocalPath());
                        }
                        callback.getFileMetaInfoFinished(false, null, "can not find this file in cached-tree");
                    } else {
                        callback.getFileMetaInfoFinished(true, rtNxFile, "ok");
                    }
                } else {
                    callback.getFileMetaInfoFinished(false, null, "update,failed");

                }
            }
        }
        new AT(folder, this, callback, isChangeWorkingFolder).executeOnExecutor(ExecutorPools.COMMON_POOL);
    }

    private void fireAsyncRefreshWorkingFolderTask(INxFile targetFolder) {
        try {
            if (!ExecutorPools.REPO_FORCE_REFRESHER.isShutdown()) {
                ExecutorPools.REPO_FORCE_REFRESHER.execute(new RefreshTask(targetFolder));
            }
        } catch (Exception ignored) {
        }
    }

    /**
     * traverse cached-tree and find all favorite&offline items
     */
    private void collectTreeFeatures() {
        INxFile root = cache.getCacheTree();
        final Set<INxFile> newFavorites = new HashSet<>();
        final Set<INxFile> newOfflines = new HashSet<>();

        Utils.EnumerateAllFiles(root, new Utils.OnEnumerate() {
            @Override
            public void onFileFound(INxFile file) {
                if (file.isMarkedAsFavorite()) {
                    newFavorites.add(file);
                }
                if (file.isMarkedAsOffline()) {
                    newOfflines.add(file);
                }
            }
        });

        // replace
        this.favorites = newFavorites;
        this.offlines = newOfflines;
    }

    public enum ItemFeatureOperate {
        SET_FAVORITE,
        SET_OFFLINE,
        UNSET_FAVORITE,
        UNSET_OFFLINE
    }

    class DeleteFileTask implements Runnable {
        File mountPoint;
        List<File> files;

        public DeleteFileTask(File mountPoint, List<File> files) {
            this.mountPoint = mountPoint;
            this.files = files;
        }

        @Override
        public void run() {
            try {
                for (File f : files) {
                    if (!f.delete()) {
                        Log.e(TAG, "failed to delete file:" + f.getAbsolutePath());
                    }
                }
            } catch (Exception e) {
                if (DEBUG) Log.e(TAG, e.toString());
            }
        }
    }

    class RefreshTask implements Runnable {
        private INxFile targetFolder;   // targetFolder may be not the latest folder, it that ,ignore this task

        public RefreshTask(INxFile targetFolder) {
            this.targetFolder = targetFolder;
        }

        @Override
        public void run() {
            try {
                INxFile latestWD = cache.getWorkingFolder();
                INxFile rf = refreshingFolder;
                // sanity check
                if (latestWD == null || targetFolder == null) {
                    return;
                }
                if (!targetFolder.getLocalPath().equals(latestWD.getLocalPath())) {
                    // target is not latest, ignore this task
                    if (DEBUG)
                        Log.v(TAG, "target task:[" + targetFolder.getLocalPath() + "]is running by previous same task, ignored and return");
                    return;
                }
                if (rf != null && targetFolder.getLocalPath().equals(rf.getLocalPath())) {
                    // target task is running by previous same task, return
                    if (DEBUG)
                        Log.v(TAG, "target task:[" + rf.getLocalPath() + "] is running by previous same task, return:");
                    return;
                }
                // Task
                refreshingFolder = targetFolder;
                if (DEBUG)
                    Log.v(TAG, "call of RefreshTask for refreshing working folder:" + targetFolder.getLocalPath());
                INxFile newFolder = null;
                try {
                    newFolder = remoteRepo.getFileMetaInfo(targetFolder);
                } finally {
                    refreshingFolder = null;
                }
                // update cache
                if (newFolder != null) {
                    cache.onSyncFolder(newFolder);
                }
            } catch (Exception e) {
                if (DEBUG) {
                    Log.e(TAG, e.toString());
                }
            }
        }
    }

    /**
     * task of retrieving all folder info under {@param targetFolder }
     */
    class PrefetchTask implements Runnable {
        INxFile targetFolder;

        public PrefetchTask(INxFile targetFolder) {
            this.targetFolder = targetFolder;
        }

        @Override
        public void run() {
            // sanity check
            if (targetFolder == null) {
                return;
            }
            if (!targetFolder.isFolder()) {
                return;
            }

            try {
                if (DEBUG) Log.d(TAG, "Prefetch:" + targetFolder.getLocalPath());
                INxFile newFolder;
                try {
                    newFolder = remoteRepo.getFileMetaInfo(targetFolder);
                } catch (Exception ignored) {
                    newFolder = null;
                }
                if (newFolder == null) {
                    return;
                }
                cache.onSyncFolder(newFolder); // notify local cache to update
                // subFolder task
                List<INxFile> subFolder = newFolder.getChildren();
                if (subFolder == null) {
                    return;
                }
                // prefetch subFolder
                for (INxFile f : subFolder) {
                    if (f != null && f.isFolder()) {
                        ExecutorPools.COMMON_POOL.submit(new PrefetchTask(f));
                    }
                }
            } catch (Exception ignored) {
            }
        }
    }
}


package appInstance.localRepo;

import android.os.AsyncTask;
import android.util.Log;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import appInstance.ExecutorPools;
import appInstance.ViewerApp;
import appInstance.localRepo.helper.Helper;
import appInstance.localRepo.internals.CacheGoogle;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoFactory;
import database.BoundService;
import errorHandler.ErrorCode;
import nxl.Utils;
import nxl.types.INxFile;
import nxl.types.NXDocument;
import nxl.types.NxFileBase;


public class FileSysGoogle implements ILocalRepo {

    private static final String TAG = "NX_fGoogleSys";

    private File mountPoint;   //   /CallerDefined/cache/[sid]/[service]/
    private CacheGoogle cache = new CacheGoogle();      // the actual docs will be got from cache object
    private BoundService service;   // one repo must bound with a service to hold basic information of RemoteRepo
    private IRemoteRepo remoteRepo;

    private Set<INxFile> favorites = new HashSet<>();
    private Set<INxFile> offlines = new HashSet<>();

    private boolean isActive = false;

    /**
     * @param mountPoint the base is used by this file system as a beginning point that every items installed
     *                   the caller can change this mount point, for example: use SD-card or others
     */
    @Override
    public void install(File mountPoint, BoundService service) throws Exception {
        this.mountPoint = mountPoint;
        this.service = service;
        // associate a cloud disk
        remoteRepo = RemoteRepoFactory.create(this.service);
        // amend mount base
        mountPoint = new File(mountPoint, service.alias + "_" + service.accountID);

        if (!Helper.makeSureDirExist(mountPoint)) {
            throw new RuntimeException("error: can not create path with mMountBase+ldapSid");
        }
        // int cache
        cache.init(mountPoint, service);
    }

    @Override
    public void uninstall() {
        deactivate();
        Helper.RecursionDeleteFile(mountPoint);
    }

    @Override
    public void activate() {
        if (!isActive) {
            cache.beginUpdate();    // background thread will work
            collectTreeFeatures();
            isActive = true;
        }
    }

    @Override
    public void deactivate() {
        if (isActive) {
            //fixbug: when deactivate , user root as the current working folder
            cache.onChangeWorkingFolder(cache.getCacheTree());
            // fire async task to serialize cache tree into disk
            ExecutorPools.COMMON_POOL.execute(new Runnable() {
                @Override
                public void run() {
                    cache.stopUpdate();
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
        changeItemFeature(file, LocalRepoBase.ItemFeatureOperate.SET_FAVORITE);
    }

    @Override
    public void unmarkAsFavorite(INxFile file) {
//        Log.d(TAG, "some one unmarkAsFavorite me");
        favorites.remove(file);
        changeItemFeature(file, LocalRepoBase.ItemFeatureOperate.UNSET_FAVORITE);
    }

    @Override
    public void markAsOffline(INxFile file) {
//        Log.d(TAG, "some one markAsOffline me");
        offlines.add(file);
        changeItemFeature(file, LocalRepoBase.ItemFeatureOperate.SET_OFFLINE);
    }

    @Override
    public void unmarkAsOffline(INxFile file) {
//        Log.d(TAG, "some one unmarkAsOffline me");
        offlines.remove(file);
        changeItemFeature(file, LocalRepoBase.ItemFeatureOperate.UNSET_OFFLINE);
    }

    @Override
    public List<INxFile> getFavoriteDocuments() {
//        Log.d(TAG, "some one getFavoriteDocuments me");
        return new ArrayList<>(favorites);
    }

    @Override
    public List<INxFile> getOfflineDocuments() {
        return new ArrayList<>(offlines);
    }

    private void changeItemFeature(INxFile file, LocalRepoBase.ItemFeatureOperate feature) {
        if (file == null) {
            return;
        }
        //INxFile child = cache.getCacheTree().findNode(file.getLocalPath());
        INxFile child = cache.findNode(cache.getCacheTree(), file);
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
    public INxFile getWorkingFolder() throws Exception {
        return markSignByThisRepo(cache.getWorkingFolder());
    }

    @Override
    public void syncWorkingFolder(IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        syncFolderAsyncTask(cache.getWorkingFolder(), true, callback);
    }

    @Override
    public INxFile getRoot(IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        // try get from cache frist
        INxFile root = cache.getCacheTree();
        if ((root != null && !root.getChildren().isEmpty()) ||
                callback == null) {
            cache.onChangeWorkingFolder(root);
            return markSignByThisRepo(root);
        }
        // cache match failed , call network to get latest one
        cache.createNewCacheTree();
        syncFolderAsyncTask(cache.getCacheTree(), true, callback);
        return null;
    }

    @Override
    public INxFile syncRoot() {
        cache.createNewCacheTree();
        if (remoteRepo == null) {
            return cache.getCacheTree();
        }
        // mark a sign before return
        return markSignByThisRepo(remoteRepo.getFileMetaInfo(cache.getCacheTree()));
    }

    @Override
    public File getDocument(INxFile document,
                            IRemoteRepo.IDownLoadCallback callback) throws Exception {
        // sanity check
        if (document.isFolder())
            throw new RuntimeException("document param error, it should be a document not folder");
        if (!(document instanceof NXDocument)) {
            throw new RuntimeException("document param error, it should be a document not folder");
        }

        // try to get from cache first
        File rt = cache.getFile((NXDocument) document);
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
            throw new NullPointerException("Client must provide callback");

        remoteRepo.uploadFile(parentFolder, fileName, localFile, callback);
    }

    @Override
    public void updateFile(INxFile parentFolder,
                           INxFile updateFile,
                           File localFile,
                           IRemoteRepo.IUploadFileCallback callback) throws Exception {
        // Sanity check
        if (callback == null)
            throw new NullPointerException("Client must provide callback");

        remoteRepo.updateFile(parentFolder, updateFile, localFile, callback);
    }

    @Override
    public List<INxFile> listFolder(INxFile folder, IRemoteRepo.IGetFileMetaInfoCallback callback, boolean isChangeWorkingFolder) throws Exception {
        // sanity check
        if (!folder.isFolder())
            throw new RuntimeException("folder param error");
        // try get from cache frist
        INxFile f = cache.retrieveFromCache(folder);
        if (f != null && f.getChildren().size() > 0) {
            if (isChangeWorkingFolder) {
                cache.onChangeWorkingFolder(f);
            }
            return markSignByThisRepo(f).getChildren();
        }

        // for failed of cache matching ,
        if (callback == null)
            throw new NullPointerException("Client must provide callback");

        syncFolderAsyncTask(folder, isChangeWorkingFolder, callback);

        return null;
    }

    @Override
    public INxFile uptoParent() {
        INxFile parent = getParent(cache.getWorkingFolder());
        cache.onChangeWorkingFolder(parent);
        return markSignByThisRepo(parent);
    }

    @Override
    public INxFile getParent(INxFile child) {
        // the parent may be deleted by cloud
        return markSignByThisRepo(cache.findParentNode(child));
    }

    @Override
    public INxFile markSignByThisRepo(INxFile file) {
        if (file == null) {
            return file;
        }
        NxFileBase f = (NxFileBase) file;
        f.setBoundService(service);
        for (INxFile i : f.getChildren()) {
            ((NxFileBase) i).setBoundService(service);
        }
        return file;
    }

    @Override
    public void clearCache() {
        // find all docs exist at disk while not marked as offline&favorite
        INxFile root = cache.getCacheTree();
        if (root == null) {
            return;
        }
        final ArrayList<File> files = new ArrayList<>();

        Utils.EnumerateAllFiles(root, new Utils.OnEnumerate() {
            @Override
            public void onFileFound(INxFile file) {
                if (!file.isFolder() && !file.isMarkedAsOffline()) {
                    String localPath = file.getLocalPath().substring(1);
                    File absPath = new File(cache.getRootDir() + "/" + file.getCloudPath(), localPath.contains("/") ? localPath.substring(localPath.lastIndexOf("/")) : file.getLocalPath());
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
        long size = 0;
        // find all docs exist at disk while not marked as offline&favorite
        INxFile root = cache.getCacheTree();
        if (root == null) {
            return 0;
        }
        final ArrayList<File> files = new ArrayList<>();

        Utils.EnumerateAllFiles(root, new Utils.OnEnumerate() {
            @Override
            public void onFileFound(INxFile file) {
                if (!file.isFolder() && !file.isMarkedAsOffline()) {
                    String localPath = file.getLocalPath().substring(1);
                    File absPath = new File(cache.getRootDir() + "/" + file.getCloudPath(), localPath.contains("/") ? localPath.substring(localPath.lastIndexOf("/")) : file.getLocalPath());
                    if (absPath.exists()) {
                        files.add(absPath);
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


    @Override
    public void getRepoInfo(final IRepoInfoCallback callback) {
        class AT extends AsyncTask<Void, Void, Boolean> {
            RepoInfo info = new RepoInfo();
            String error = "Null known";

            @Override
            protected Boolean doInBackground(Void... params) {
                // calc local
                File root = cache.getRootDir();
                //  total local size
                info.localTotalSize = root.getUsableSpace();
                //  cached size
                info.localCachedSize = calSize(false);
                //  offline size
                info.localOfflineSize = calSize(true);

                // calc remote
                return remoteRepo.getInfo(info);
            }

            @Override
            protected void onPostExecute(Boolean status) {
                callback.result(status, info, error);
            }
        }
        new AT().executeOnExecutor(ExecutorPools.COMMON_POOL);
    }

    private long calSize(final boolean bCountOffline) {
        long size = 0;
        // find all docs exist at disk while not marked as offline&favorite
        INxFile root = cache.getCacheTree();
        if (root == null) {
            return 0;
        }
        final ArrayList<File> files = new ArrayList<>();

        Utils.EnumerateAllFiles(root, new Utils.OnEnumerate() {
            @Override
            public void onFileFound(INxFile file) {
                if (file.isFolder()) {
                    return;
                }
                if (bCountOffline) {
                    if (file.isMarkedAsOffline()) {

                        String localPath = file.getLocalPath().substring(1);
                        File absPath = new File(cache.getRootDir() + "/" + file.getCloudPath(), localPath.contains("/") ? localPath.substring(localPath.lastIndexOf("/")) : file.getLocalPath());
                        if (absPath.exists()) {
                            files.add(absPath);
                        }
                    }
                } else {
                    if (!file.isMarkedAsOffline()) {

                        String localPath = file.getLocalPath().substring(1);
                        File absPath = new File(cache.getRootDir() + "/" + file.getCloudPath(), localPath.contains("/") ? localPath.substring(localPath.lastIndexOf("/")) : file.getLocalPath());
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
            throw new NullPointerException("Client must provide document");
        }
        if (callback == null)
            throw new NullPointerException("Client must provide callback");

        // downloading a file requires absPath
        remoteRepo.downloadFile(document, Helper.nxPath2AbsPath(cache.getRootDir(), "/" + document.getCloudPath() + "/" + document.getName()), callback); // must set a legal path
    }

    /**
     * get folder meta information through network
     * - markSign
     * - notify cache
     *
     * @param folder
     * @param isChangeWorkingFolder
     * @param callback
     */
    private void syncFolderAsyncTask(INxFile folder, boolean isChangeWorkingFolder, IRemoteRepo.IGetFileMetaInfoCallback callback) {
        class SyncFolderAsyncTask extends AsyncTask<Void, Void, INxFile> {
            INxFile folder;
            FileSysGoogle base;
            IRemoteRepo.IGetFileMetaInfoCallback callback;
            boolean isChangeWorkingFolder;

            public SyncFolderAsyncTask(INxFile folder, FileSysGoogle base, IRemoteRepo.IGetFileMetaInfoCallback callback, boolean isChangeWorkingFolder) {
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
                boolean bStatus = iNxFile != null ? true : false;
                if (bStatus) {
                    base.markSignByThisRepo(iNxFile);
                    base.cache.updateFolder(iNxFile);
                    if (isChangeWorkingFolder) {
                        base.cache.onChangeWorkingFolder(iNxFile);
                    }
                    callback.getFileMetaInfoFinished(true, cache.findNode(cache.getCacheTree(), iNxFile), "ok");
                } else {
                    if (!ViewerApp.networkStatus.isNetworkAvailable()) {
                        callback.getFileMetaInfoFinished(false, null, ErrorCode.E_IO_NO_NETWORK);
                        return;
                    }
                    callback.getFileMetaInfoFinished(false, null, "updated, failed");
                }
            }
        }
        new SyncFolderAsyncTask(folder, this, callback, isChangeWorkingFolder).execute();
    }

    /**
     * traverse cache tree and find favorite&offline item
     */
    private void collectTreeFeatures() {
        INxFile root = cache.getCacheTree();
        if (root == null) {
            return;
        }

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
                Log.e(TAG, e.toString());
            }
        }
    }
}


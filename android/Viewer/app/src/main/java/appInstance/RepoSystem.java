package appInstance;

import android.os.AsyncTask;
import android.support.annotation.Nullable;
import android.text.TextUtils;
import android.util.Log;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Stack;

import javax.annotation.Nonnull;

import appInstance.localRepo.ILocalRepo;
import appInstance.localRepo.LocalRepoFactory;
import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.IRemoteRepo;
import database.BoundService;
import errorHandler.ErrorCode;
import nxl.Utils;
import nxl.types.INxFile;
import nxl.types.NXFolder;

/**
 * Designed to maintain repositories
 * - cloud disk can be accessed from DateBase
 * - config whole system's mount point, i.e. where to store it
 * Knowledge:
 * -
 */
class RepoSystem {
    static private final boolean DEBUG = ViewerApp.DEBUG;
    private static final String TAG = "NX_FileSys";
    private File mountPoint;
    private List<ILocalRepo> stockRepos = new ArrayList<>();        // All repos system supported
    private List<ILocalRepo> livingRepos = new LinkedList<>();       // All activated local repos;
    private ILocalRepo focusedRepo = null;

    private NXFolder shadowRoot = new NXFolder("/", "/", "root", 0);
    private RunningMode repoMode = RunningMode.SYNTHETIC; // by default
    private FavoriteMode favoriteMode = new FavoriteMode();
    private OfflineMode offlineMode = new OfflineMode();

    public void changeState(RunningMode newRunningMode) {
        repoMode = newRunningMode;
    }

    public RunningMode getState() {
        return repoMode;
    }

    /**
     * According to requirement, each user has its own stockRepos, so distinguish each other by sid
     */
    public void create(File mountPoint, String sid) {
        this.mountPoint = new File(mountPoint, sid);        // amend mount point
        if (!Helper.makeSureDirExist(this.mountPoint)) {
            throw new RuntimeException(ErrorCode.E_FS_MOUNTPOINT_INVALID);
        }
    }

    /**
     * close repo system , save and release all resource
     */
    public void close() {
        for (ILocalRepo i : livingRepos) {
            i.deactivate();
        }
        // release all res
        livingRepos.clear();
        stockRepos.clear();
        focusedRepo = null;
    }

    public void attach(@Nullable List<BoundService> list) {
        if (list == null || list.isEmpty()) {
            return;
        }
        for (BoundService s : list) {
            attach(s);
        }

    }

    /**
     * an attached service detach from local repo system
     */
    public void detach(@Nullable BoundService service) {
        // sanity check
        if (service == null) {
            return;
        }
        ILocalRepo repo = findInStockRepo(service);
        if (repo == null) {
            return;
        }
        repo.deactivate();
        repo.uninstall();
        removeFromLivingRepo(repo);
        deleteInStockRepo(repo);
        if (focusedRepo == repo) {
            focusedRepo = null;
        }
    }

    public void activate() {
        if (livingRepos.isEmpty()) {
            for (ILocalRepo i : stockRepos) {
                if (i.getLinkedService().selected == 1) {
                    livingRepos.add(i);
                }
            }
        }
        for (ILocalRepo i : livingRepos) {
            i.activate();
        }
    }

    public void deactivate() {
        for (ILocalRepo i : livingRepos) {
            i.deactivate();
        }
    }

    public void activateRepo(BoundService service) throws Exception {
        // sanity check
        if (service == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_SERVICE_INVALID);
        }
        // avoid reactivate the same one
        if (findInLivingRepo(service) != null) {
            return;
        }

        ILocalRepo repo = findInStockRepo(service);
        // for this service not in repos , add it
        if (repo == null) {
            attach(service);
            // find again
            repo = findInStockRepo(service);
            if (repo == null) {
                throw new RuntimeException("this repo can not be used");
            }
        }
        repo.activate();
        addInLivingRepo(repo);
        if (livingRepos.size() == 1) {
            setFocusedRepo(repo);
            changeState(RunningMode.FOCUSED);
        } else {
            changeState(RunningMode.SYNTHETIC);
            setFocusedRepo(null);
        }
    }

    public void deactivateRepo(BoundService service) throws Exception {
        // sanity check
        if (service == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_SERVICE_INVALID);
        }
        ILocalRepo repo = findInLivingRepo(service);
        if (repo == null) {
            return;
        }
        repo.deactivate();
        removeFromLivingRepo(repo);
        if (repo == focusedRepo) {
            focusedRepo = null;
            changeState(RunningMode.SYNTHETIC);
        }
        if (livingRepos.size() == 1) {
            focusedRepo = livingRepos.get(0);
            changeState(RunningMode.FOCUSED);
        }

    }

    public boolean isInSyntheticRoot() {
        return repoMode == RunningMode.SYNTHETIC && livingRepos.size() > 1;
    }

    public
    @Nullable
    ILocalRepo getFocusedRepo() {
        return focusedRepo;
    }

    public void setFocusedRepo(ILocalRepo repo) {
        focusedRepo = repo;
    }

    public Map<ILocalRepo, List<INxFile>> getRootByLivingRepos() {
        HashMap<ILocalRepo, List<INxFile>> rt = new HashMap<>();

        NXFolder root = new NXFolder("/", "/", "root", 0);
        List<ILocalRepo> currentRepos = new ArrayList<>(livingRepos);
        for (ILocalRepo i : currentRepos) {
            try {
                INxFile repoRoot = i.getRoot(null);
                root.addChild(repoRoot.getChildren());
                rt.put(i, repoRoot.getChildren());
            } catch (Exception e) {
                if (DEBUG) {
                    Log.d(TAG, e.toString());
                    e.printStackTrace();
                }
            }
        }
        // change state
        changeState(currentRepos.size() > 1 ? RunningMode.SYNTHETIC : RunningMode.FOCUSED);
        //fix bug ,for focused mode,set the focusedRepo
        if (currentRepos.size() == 1) {
            focusedRepo = currentRepos.get(0);
        }
        // prepare shadow root
        shadowRoot.getChildren().clear();
        shadowRoot.addChild(root.getChildren());
        return rt;
    }

    public void refreshSpecificRoot(List<ILocalRepo> repos, IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        // sanity check
        if (callback == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);
        }
        if (repos == null || repos.size() == 0) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "invalid repos");
        }
        if (livingRepos.isEmpty()) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "no any livingRepo refreshRoot");
        }
        if (!livingRepos.containsAll(repos)) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "illegal repos, not the subset of livingrepo");
        }

        // change state
        changeState(livingRepos.size() > 1 ? RunningMode.SYNTHETIC : RunningMode.FOCUSED);

        // check network status
        if (!ViewerApp.networkStatus.isNetworkAvailable()) {
            callback.getFileMetaInfoFinished(false, null, ErrorCode.E_IO_NO_NETWORK);
            return;
        }
        // refresh
        new SyncRootAsyncTask(shadowRoot, repos, callback).executeOnExecutor(ExecutorPools.COMMON_POOL);
    }

    public void syncWorkingFolder(@Nonnull IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        switch (repoMode) {
            case FAVORITE:
                callback.getFileMetaInfoFinished(true, favoriteMode.currentWorkingFolder, "ok");
                break;
            case OFFLINE:
                callback.getFileMetaInfoFinished(true, offlineMode.currentWorkingFolder, "ok");
                break;
            case SYNTHETIC:
                if (livingRepos.isEmpty()) {
                    throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "no any livingRepo refreshRoot");
                }
                // check network status
                if (!ViewerApp.networkStatus.isNetworkAvailable()) {
                    callback.getFileMetaInfoFinished(false, null, ErrorCode.E_IO_NO_NETWORK);
                    break;
                }
                // fix-bug:avoid trigger ConcurrentModificationException
                // the following SyncRootAsyncTask is a time-heavily task, during recursion , livingRepos may be changed ,so copy it
                new SyncRootAsyncTask(shadowRoot, new ArrayList<>(livingRepos), callback).executeOnExecutor(ExecutorPools.COMMON_POOL);
                break;
            case FOCUSED:
                // check network status
                if (!ViewerApp.networkStatus.isNetworkAvailable()) {
                    callback.getFileMetaInfoFinished(false, null, ErrorCode.E_IO_NO_NETWORK);
                    break;
                }
                ILocalRepo repo = getFocusedRepo();
                if (repo != null) {
                    repo.syncWorkingFolder(callback);
                } else {
                    throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "null focused repo");
                }
                break;
        }
    }

    public List<INxFile> listFolder() throws Exception {
        NXFolder root = new NXFolder("/", "/", "root", 0);
        switch (repoMode) {
            case FAVORITE:
                return favoriteMode.listWorkingFolder();
            case OFFLINE:
                return offlineMode.listWorkingFolder();
            case SYNTHETIC:
                // for synthetic mode , always get each repo's root
                for (ILocalRepo i : livingRepos) {
                    try {
                        root.addChild(i.getRoot(null).getChildren());
                    } catch (Exception e) {
                        if (DEBUG) {
                            Log.d(TAG, e.toString());
                            e.printStackTrace();
                        }
                    }
                }
                break;
            case FOCUSED:
                if (focusedRepo == null) {
                    throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "focused repos is null");
                }
                try {
                    root.addChild(focusedRepo.getWorkingFolder().getChildren());
                } catch (Exception e) {
                    if (DEBUG) {
                        Log.d(TAG, e.toString());
                        e.printStackTrace();
                    }
                }
                break;

        }
        shadowRoot.getChildren().clear();
        shadowRoot.addChild(root.getChildren());
        return shadowRoot.getChildren();

    }

    public INxFile findWorkingFolder() throws Exception {
        switch (repoMode) {
            case FAVORITE:
                return favoriteMode.getWorkingFolder();
            case OFFLINE:
                return offlineMode.getWorkingFolder();
            case SYNTHETIC:
                return shadowRoot;
            case FOCUSED:
                if (focusedRepo == null) {
                    throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "focused repos is null");
                }
                return focusedRepo.getWorkingFolder();
        }
        throw new Exception(ErrorCode.E_RT_SHOULD_NEVER_REACH_HERE);
    }

    /**
     * must judge @{folder} is in which living repo , change focusedRepo as it, and then to do the remains
     * <p/>
     * - add support for FAVORITE&OFFLINE mode
     */
    public List<INxFile> enterFolder(INxFile folder, IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        // sanity check
        // find the folder is belong to which living repo
        BoundService service = folder.getService();
        if (service == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "can not get service of the folder");
        }
        ILocalRepo repo = findInLivingRepo(folder.getService());
        if (repo == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "can not get host repo of the folder");
        }

        // distinguish kinds of running mode
        if (repoMode == RunningMode.FAVORITE) {
            return favoriteMode.enterFolder(folder, repo.getLinkedService());
        } else if (repoMode == RunningMode.OFFLINE) {
            return offlineMode.enterFolder(folder, repo.getLinkedService());
        } else {
            setFocusedRepo(repo);
            changeState(RunningMode.FOCUSED); // change focused repo
            return repo.listFolder(folder, callback, true);
        }
    }

    public List<INxFile> getFavoriteFiles() {
        changeState(RunningMode.FAVORITE);
        return favoriteMode.getFavoriteFiles();
    }

    public List<INxFile> getOfflineFiles() {
        changeState(RunningMode.OFFLINE);
        return offlineMode.getOfflineFiles();
    }

    public INxFile getParent() {
        INxFile rt = null;
        switch (repoMode) {
            case FAVORITE:
                rt = favoriteMode.getParent();
                break;
            case OFFLINE:
                rt = offlineMode.getParent();
                break;
            case SYNTHETIC:
                rt = shadowRoot;
                break;
            /*
                FOCUSED MODE may change to SYNTHETIC
             */
            case FOCUSED:
                ILocalRepo repo = getFocusedRepo();
                if (repo != null) {
                    rt = repo.uptoParent();
                    // check if need to change to SYNTHETIC mode
                    if (rt.getLocalPath().equalsIgnoreCase("/") && livingRepos.size() > 1) {
                        changeState(RunningMode.SYNTHETIC);
                        try {
                            return listWorkingFolder();
                        } catch (Exception ignored) {
                        }
                    }
                }
                break;
        }
        return rt;
    }


    public INxFile getParent(INxFile child, boolean byService) {
        if (byService) {
            ILocalRepo repo = findInStockRepo(child.getService());
            if (repo != null) {
                return repo.getParent(child);
            }
            throw new RuntimeException("should never reach here");
        }

        INxFile rt = null;
        switch (repoMode) {
            case FAVORITE:
                rt = favoriteMode.getParent(child);
                break;
            case OFFLINE:
                rt = offlineMode.getParent(child);
                break;
            case SYNTHETIC:
                rt = shadowRoot;
                break;
            case FOCUSED:
                ILocalRepo repo = getFocusedRepo();
                if (repo != null) {
                    rt = repo.getParent(child);
                }
                break;
        }
        return rt;
    }

    public void clearCache(final ViewerApp.ClearCacheListener listener) {
        class ClearTask extends AsyncTask<Void, Void, Void> {
            @Override
            protected Void doInBackground(Void... params) {
                //long start = System.currentTimeMillis();
                try {
                    for (ILocalRepo i : stockRepos) {
                        i.clearCache();
                    }
                } catch (Exception ignored) {
                }
                // Log.v("TimeCal", "CleanCache:" + (System.currentTimeMillis() - start) + "s");
                return null;
            }

            @Override
            protected void onPostExecute(Void aVoid) {
                listener.finished();
            }
        }
        new ClearTask().executeOnExecutor(ExecutorPools.COMMON_POOL);
    }

    public void clearRepoCache(final BoundService boundService, final ViewerApp.ClearCacheListener listener) {
        class ClearTask extends AsyncTask<Void, Void, Void> {
            @Override
            protected Void doInBackground(Void... params) {
                //long start = System.currentTimeMillis();
                try {
                    ILocalRepo i = findInStockRepo(boundService);
                    if (i == null) {
                        return null;
                    }
                    i.clearCache();
                } catch (Exception ignored) {
                }
                //Log.v("TimeCal", "CleanCache:" + (System.currentTimeMillis() - start) + "s");
                return null;
            }

            @Override
            protected void onPostExecute(Void aVoid) {
                listener.finished();
            }
        }
        new ClearTask().executeOnExecutor(ExecutorPools.COMMON_POOL);
    }

    public long calReposCacheSize() {
        long size = 0;
        for (ILocalRepo i : stockRepos) {
            try {
                size += i.calCacheSize();
            } catch (Exception ignored) {

            }
        }
        return size;
    }

    public void getRepoInformation(BoundService boundService, ILocalRepo.IRepoInfoCallback callback) {
        ILocalRepo repo = findInStockRepo((boundService));
        if (repo == null) {
            throw new RuntimeException(ErrorCode.E_REPO_CANNOT_FIND_LOCAL_REPO + "assigned by boundService");
        }
        // check network status
        if (!ViewerApp.networkStatus.isNetworkAvailable()) {
            callback.result(false, null, ErrorCode.E_IO_NO_NETWORK);
            return;
        }
        repo.getRepoInfo(callback);
    }

    public int getSizeOfLivingRepo() {
        return livingRepos.size();
    }

    private INxFile listWorkingFolder() throws Exception {
        NXFolder root = new NXFolder("/", "/", "root", 0);
        switch (repoMode) {
            case SYNTHETIC:     // for synthetic mode , always get each repo's root
                for (ILocalRepo i : livingRepos) {
                    try {
                        root.addChild(i.getRoot(null).getChildren());
                    } catch (Exception e) {
                        if (DEBUG) {
                            Log.d(TAG, e.toString());
                            e.printStackTrace();
                        }
                    }
                }
                break;
            case FOCUSED:
                if (focusedRepo == null) {
                    throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "focused repos is null");
                }
                try {
                    root.addChild(focusedRepo.getWorkingFolder().getChildren());
                } catch (Exception e) {
                    if (DEBUG) {
                        Log.d(TAG, e.toString());
                        e.printStackTrace();
                    }
                }
                break;

        }
        shadowRoot.getChildren().clear();
        shadowRoot.addChild(root.getChildren());
        return shadowRoot;

    }

    /**
     * new service attaches into stockRepos
     * <p/>
     * if the service has exist in stockRepos , return directly
     */
    private void attach(BoundService service) {
        if (service == null) {
            return;
        }
        if (findInStockRepo(service) != null) { // has exist
            return;
        }

        try {
            ILocalRepo fs;
            fs = LocalRepoFactory.create(service.type);
            fs.install(mountPoint, service);
            stockRepos.add(fs);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
        }

    }

    /**
     * use BoundService.id to find ILocalRepo
     */
    private ILocalRepo findInStockRepo(BoundService service) {
        if (service == null) {
            return null;
        }
        for (ILocalRepo i : stockRepos) {
            if (i.getLinkedService() != null && i.getLinkedService().id == service.id) {
                return i;
            }
        }
        return null;
    }

    private void deleteInStockRepo(ILocalRepo repo) {
        if (repo == null) {
            return;
        }
        stockRepos.remove(repo);
    }

    public
    @Nullable
    ILocalRepo findInLivingRepo(BoundService service) {
        if (service == null) {
            return null;
        }
        for (ILocalRepo i : livingRepos) {
            if (i.getLinkedService() != null && i.getLinkedService().id == service.id) {
                return i;
            }
        }
        return null;
    }

    private void addInLivingRepo(ILocalRepo repo) {
        if (livingRepos == null) {
            livingRepos = new LinkedList<>();
            livingRepos.add(repo);
            return;
        }
        // check if had exist, avoid adding same one
        int id = repo.getLinkedService().id;
        for (ILocalRepo i : livingRepos) {
            if (i.getLinkedService().id == id) {
                return;
            }
        }
        // not exist ,add in
        livingRepos.add(repo);
    }

    private void removeFromLivingRepo(ILocalRepo repo) {
        livingRepos.remove(repo);
    }


    private class FavoriteMode {
        NXFolder root = new NXFolder("/", "/", "root", 0);
        INxFile currentWorkingFolder = root;

        public List<INxFile> getFavoriteFiles() {
            NXFolder root = new NXFolder("/", "/", "root", 0);
            for (ILocalRepo i : livingRepos) {
                try {
                    root.addChild(i.getFavoriteDocuments());
                } catch (Exception e) {
                    if (DEBUG) {
                        Log.d(TAG, e.toString());
                        e.printStackTrace();
                    }
                }
            }
            this.root.getChildren().clear();
            this.root.addChild(root.getChildren());
            currentWorkingFolder = root;
            return this.root.getChildren();
        }

        public List<INxFile> enterFolder(INxFile folder, BoundService service) {
            INxFile file = root.findNode(folder.getLocalPath());
            if (file != null) {
                currentWorkingFolder = file;
                Utils.attachService(file, service, true);
                return file.getChildren();
            } else {
                Log.e(TAG, "can not find the fild" + folder.getLocalPath());
                currentWorkingFolder = folder;
                return folder.getChildren();
            }
        }

        public INxFile getParent() {
            if (currentWorkingFolder == null) {
                currentWorkingFolder = root;
                return root;
            } else {
//                String f = Helper.getParent(currentWorkingFolder);
//                currentWorkingFolder = root.findNode(f);
//                return currentWorkingFolder;
                //fix bug, to find parent
                Stack<INxFile> workingStack = new Stack<>();
                INxFile rtParent = null;
                workingStack.push(root);
                while (!workingStack.isEmpty()) {
                    INxFile folder = workingStack.pop();
                    List<INxFile> children = folder.getChildren();
                    for (INxFile child : children) {
                        if (TextUtils.equals(currentWorkingFolder.getLocalPath(), child.getLocalPath())) {
                            //found the folder is parent
                            rtParent = folder;
                            break;
                        }
                        if (child.isFolder()) {
                            workingStack.push(child);
                        }
                    }
                }
                if (rtParent != null) {
                    currentWorkingFolder = rtParent;
                    return rtParent;
                } else {
                    currentWorkingFolder = root;
                    return root;
                }

            }
        }

        public INxFile getParent(INxFile child) {
            return root.findNode(child.getLocalPath());
        }

        public List<INxFile> listWorkingFolder() throws Exception {
            if (TextUtils.equals(currentWorkingFolder.getLocalPath(), root.getLocalPath())) {
                return getFavoriteFiles();
            }
            return currentWorkingFolder.getChildren();
        }

        public INxFile getWorkingFolder() {
            return currentWorkingFolder;
        }
    }

    private class OfflineMode {
        NXFolder root = new NXFolder("/", "/", "root", 0);
        INxFile currentWorkingFolder = null;

        public List<INxFile> getOfflineFiles() {
            NXFolder root = new NXFolder("/", "/", "root", 0);
            for (ILocalRepo i : livingRepos) {
                try {
                    root.addChild(i.getOfflineDocuments());
                } catch (Exception e) {
                    if (DEBUG) {
                        Log.d(TAG, e.toString());
                        e.printStackTrace();
                    }
                }
            }
            this.root.getChildren().clear();
            this.root.addChild(root.getChildren());
            return this.root.getChildren();
        }

        public List<INxFile> enterFolder(INxFile folder, BoundService service) {
            INxFile file = root.findNode(folder.getLocalPath());
            if (file != null) {
                currentWorkingFolder = file;
                Utils.attachService(file, service, true);
                return file.getChildren();
            } else {
                Log.e(TAG, "can not find the fild" + folder.getLocalPath());
                currentWorkingFolder = folder;
                return folder.getChildren();
            }
        }

        public INxFile getParent() {
            if (currentWorkingFolder == null) {
                currentWorkingFolder = root;
                return root;
            } else {
                String f = Helper.getParent(currentWorkingFolder);
                currentWorkingFolder = root.findNode(f);
                return currentWorkingFolder;
            }
        }

        public INxFile getParent(INxFile child) {
            return root.findNode(child.getLocalPath());
        }

        public List<INxFile> listWorkingFolder() throws Exception {
            return currentWorkingFolder.getChildren();
        }

        public INxFile getWorkingFolder() {
            return currentWorkingFolder;
        }
    }

}

class SyncRootAsyncTask extends AsyncTask<Void, Void, Void> {
    NXFolder root;
    IRemoteRepo.IGetFileMetaInfoCallback uiCallback;
    List<ILocalRepo> repos; // may trigger ConcurrentModificationException

    public SyncRootAsyncTask(NXFolder root, List<ILocalRepo> repos, IRemoteRepo.IGetFileMetaInfoCallback uiCallback) {
        this.root = root;
        this.repos = repos;
        this.root.getChildren().clear();
        this.uiCallback = uiCallback;
    }

    @Override
    protected Void doInBackground(Void... params) {
        for (ILocalRepo i : repos) {
            try {
                INxFile tree = i.syncRoot(); // get this repo 's root
                if (tree != null) {
                    root.addChild(tree.getChildren());
                }
            } catch (Exception e) {
                Log.e("SyncRootAsyncTask", e.toString());
                e.printStackTrace();
            }
        }
        return null;
    }

    @Override
    protected void onPostExecute(Void aVoid) {
        uiCallback.getFileMetaInfoFinished(true, root, "ok");
    }
}



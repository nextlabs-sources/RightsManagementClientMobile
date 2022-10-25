package appInstance.localRepo.internals;

import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import appInstance.ViewerApp;
import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoFactory;
import database.BoundService;
import nxl.types.INxFile;
import nxl.types.NXDocument;
import nxl.types.NXFolder;
import nxl.types.NxFileBase;

/**
 * every Cache object has a background thread to update current folder
 */
public class CacheGoogle implements IUpdatable {
    static private final boolean DEBUG = ViewerApp.DEBUG;
    static private final String TAG = "NX_CacheGoogle";
    static private final String CACHE = "directory.CACHE";
    static private final String ROOT = "ROOT";

    static private int UPDATE_PERIOD_SECOND = 60;

    private volatile INxFile mCacheTree = null; // used by multi-threads

    private INxFile mWorkingFolder; // a subTree from mCacheTree
    private File mCacheFile;    // mMountBase+CACHE
    private File mLocalFilesRoot;     // mMountBase+ROOT

    private IRemoteRepo mCloudService;
    private Thread mWorkingFolderUpdater;

    private ExecutorService updater = Executors.newSingleThreadExecutor();

    /**
     * - create a file :  directory.CACHE
     * - create a folder: ROOT
     * - recover the cacheTree
     */
    public void init(File newMountBase, BoundService service) throws Exception {
        //  CacheFile
        mCacheFile = new File(newMountBase, CACHE);
        if (!mCacheFile.exists() && !mCacheFile.createNewFile()) {
            throw new RuntimeException("error: can not create cache file");
        }
        //  LocalFilesRoot
        mLocalFilesRoot = new File(newMountBase, ROOT);
        if (!Helper.makeSureDirExist(mLocalFilesRoot))
            throw new RuntimeException("error: can not crate local file root dir");
        // TreeRoot
        mCacheTree = unserializeCacheTree();
        /*for first installled , mCacheTree is null ,so create a new one*/
        if (mCacheTree == null) {
            createNewCacheTree();
        }
        mCloudService = RemoteRepoFactory.create(service);
    }

    public void beginUpdate() {
        // TreeRoot
        mCacheTree = unserializeCacheTree();
        /*for first installed , mCacheTree is null ,so create a new one or sometimes ,failed by calling the method unserializeCacheTree*/
        if (mCacheTree == null) {
            createNewCacheTree();
        }
        // config a background task which is used to update the current working folder each time specified by UPDATE_PERIOD_SECOND
        mWorkingFolderUpdater = new Thread(new Runnable() {
            private long debugCallId = 0;   // for log ,not important

            @Override
            public void run() {
                try {
                    while (!Thread.interrupted()) {
                        if (DEBUG) Log.v(TAG, "call of Cache.Updater, callID:" + debugCallId++);
                        new UpdatePolicy().updateFolder(CacheGoogle.this, mCloudService, getWorkingFolder());
                        TimeUnit.SECONDS.sleep(UPDATE_PERIOD_SECOND);
                    }
                } catch (Exception e) {
                    if (DEBUG) {
                        Log.e(TAG, e.toString());
                    }
                }
            }
        });
        mWorkingFolderUpdater.start();
    }

    public void stopUpdate() {
        // destroy background thread
        if (mWorkingFolderUpdater != null && mWorkingFolderUpdater.isAlive()) {
            mWorkingFolderUpdater.interrupt();
            mWorkingFolderUpdater = null;
        }

        // write the cacheTree to disk
        serializeCacheTree();
    }

    public INxFile getCacheTree() {
        return mCacheTree;
    }

    public File getRootDir() {
        return mLocalFilesRoot;
    }

    public void createNewCacheTree() {
        mCacheTree = new NXFolder("/", "/", "root", 0);
    }

    public synchronized INxFile getWorkingFolder() {
        if (mCacheTree == null)
            return null;
        if (mWorkingFolder == null) {
            mWorkingFolder = mCacheTree;
            return mWorkingFolder;
        }
        return findNode(mCacheTree, mWorkingFolder);
    }

    public File getFile(NXDocument nxFile) {
        INxFile f = retrieveFromCache(nxFile);
        if (f != null) {
            String absPath = Helper.nxPath2AbsPath(getRootDir(), "/" + f.getCloudPath() + "/" + f.getName());
            if (absPath == null) {
                throw new RuntimeException("Can not get absolute path");
            }
            File rt = new File(absPath);
            if (rt.exists()) {
                nxFile.setCached(true);
            }
            return rt;
        }
        return null;
    }

    public INxFile retrieveFromCache(INxFile base) {
        INxFile f = findNode(mCacheTree, base);
        if (f != null && f instanceof NXDocument) {
            //test if exists at local
            if (new File(Helper.nxPath2AbsPath(getRootDir(), "/" + f.getCloudPath() + "/" + f.getName())).exists()) {
                return f;
            } else {
                return null;
            }

        }
        if (f != null && f instanceof NXFolder) {
            return f;
        }
        return null;
    }

    /**
     * Give a chance to change working folder
     * Typically this method will be called by repo system
     */
    public synchronized void onChangeWorkingFolder(INxFile folder) {
        // sanity check
        if (mCacheTree == null) {
            return;
        }
        if (folder == null) {
            mWorkingFolder = mCacheTree;
            return;
        }
        if (!folder.isFolder()) {
            // runtime exception
            return;
        }
        //make sure folder's local path exist in the Cache Tree
        mWorkingFolder = findNode(mCacheTree, folder);
        if (mWorkingFolder == null) {
            mWorkingFolder = mCacheTree;
        }
    }

    // this function was called when getting new folder info from cloud
    public synchronized void onSyncFolder(INxFile folder) {
        if (DEBUG) Log.v(TAG, Thread.currentThread().toString());
        // sanity check
        if (folder == null) return;
        if (!folder.isFolder()) return;
        if (mCacheTree == null) return;

        /**todo:
         *      1. normal update
         *      2. child doc had been deleted
         *      3. folder had been renamed
         *      4. folder had been removed
         */
        INxFile curRoot = findNode(mCacheTree, folder);
        if (curRoot == null) {
            Log.e(TAG, "New folder does not exist in mCacheTree, it is a bug");
            return;
        }
        //todo : if folder has been deleted by cloud
        if (folder.isDeletedByCloud()) {
            curRoot = findNode(mCacheTree, curRoot);
            if (curRoot != null) {
                Iterator<INxFile> iter = curRoot.getChildren().iterator();
                while (iter.hasNext()) {
                    INxFile node = iter.next();
                    INxFile deleted_node = findNode(folder, node);
                    if (deleted_node != null) {
                        Log.v(TAG, "the node has been delted by cloud" + node.getLocalPath());
                        iter.remove();
                        break;
                    }
                }
                return;
            }
        }

        List<INxFile> curChildren = curRoot.getChildren();
        if (curChildren.size() == 0) {
            List<INxFile> list = folder.getChildren();
            for (INxFile f : list) {
                curRoot.addChild(f);
            }
            return;
        }
        // main algo
        //1 delete node or update node's meta info
        Iterator<INxFile> iter = curRoot.getChildren().iterator();
        while (iter.hasNext()) {
            INxFile node = iter.next();
            INxFile newNode = findNode(folder, node);
            if (newNode == null) {
                Log.v(TAG, "current node has been removed" + node.getLocalPath());
                iter.remove();
            } else {
                //current node need to be updated the meta info
                //todo: check if need update
                boolean needUpdate = true;
                if (needUpdate) {
                    ((NxFileBase) node).setSize(newNode.getSize());
                    ((NxFileBase) node).setLastModifiedTimeLong(newNode.getLastModifiedTimeLong());
                } else {

                }
            }

        }
        iter = null;

        //2 add new node to current Tree
        Iterator<INxFile> iterForAdd = folder.getChildren().iterator();
        while (iterForAdd.hasNext()) {
            INxFile node = iterForAdd.next();
            // if node dose not exist at Tree, add it
            INxFile t = findNode(curRoot, node);
            if (t == null) {
                Log.v(TAG, "add new child:" + node.getLocalPath());
                curRoot.addChild(node);
            }
        }
        // serialize
        serializeCacheTree();
    }

    /**
     * Be called when a new {@param folder} will be insert into CacheTree
     * additional duty:
     * -  fire new threads to update the {@param folder} 's immediate subfolder
     *
     * @param folder
     */
    @Override
    public void updateFolder(INxFile folder) {
        if (folder == null) return;

        onSyncFolder(folder);

        for (INxFile i : folder.getChildren()) {
            if (i.isFolder()) {
                updater.submit(new FolderUpdater(this, this.mCloudService, i));
            }
        }
    }

    /**
     * download a cacheTree and link it with a INxFile
     *
     * @param document
     */
    @Override
    public void updateDocument(INxFile document) {
        //todo: not impl
    }

    private synchronized INxFile unserializeCacheTree() {
        INxFile rtValue;
        try {
            ObjectInputStream objectInputStream = new ObjectInputStream(new FileInputStream(mCacheFile));
            rtValue = (NxFileBase) objectInputStream.readObject();
            objectInputStream.close();
        } catch (Exception e) {
            rtValue = null;
        }
        return rtValue;
    }

    public synchronized void serializeCacheTree() {
        try {
            ObjectOutputStream objectOutputStream = new ObjectOutputStream(new FileOutputStream(mCacheFile));
            objectOutputStream.writeObject(mCacheTree);
            objectOutputStream.close();
        } catch (Exception e) {
            Log.e(TAG, "Error:serializeCacheTree" + e.toString());
            e.printStackTrace();
        }
    }

    public INxFile findParentNode(INxFile node) {
        if (node.getCloudPath() != null && node.getCloudPath().equals("/")) {
            return mCacheTree;
        }

        String parentPath = Helper.getParent(node);

        if (parentPath.length() > 1 && parentPath.endsWith("/"))
            parentPath = parentPath.substring(0, parentPath.length() - 1);

        return findParentNode(mCacheTree, node, parentPath);
    }

    private INxFile findParentNode(INxFile from, INxFile node, String ParentPath) {
        INxFile rt = null;

        // recursive way out
        if (from.getLocalPath().equalsIgnoreCase(ParentPath) && isContainsNode(from.getChildren(), node)) {
            return from;
        } else {
            List<INxFile> children = from.getChildren();
            for (INxFile obj : children) {
                // Match test
                if (ParentPath.regionMatches(true, 0, obj.getLocalPath(), 0, obj.getLocalPath().length())) {
                    rt = findParentNode(obj, node, ParentPath);
                    if (rt != null)
                        return rt;
                }
                continue;
            }
            return null;
        }
    }

    private boolean isContainsNode(List<INxFile> parent, INxFile node) {
        for (INxFile oneNode : parent) {
            if (oneNode.getCloudPath().equals(node.getCloudPath())) {
                return true;
            }
        }
        return false;
    }

    public INxFile findNode(INxFile from, INxFile node) {
        INxFile rt = null;
        String Localpath = node.getLocalPath();
        String Cloudpath = node.getCloudPath();

        // recursive way out
        if (from.getLocalPath().equalsIgnoreCase(Localpath) && from.getCloudPath().equals(Cloudpath))
            return from;
        else {
            List<INxFile> children = from.getChildren();
            for (INxFile obj : children) {
                //remove '/' sign
                if (Localpath.endsWith("/"))
                    Localpath = Localpath.substring(0, Localpath.length() - 1);
                // Match test
                if (Localpath.regionMatches(true, 0, obj.getLocalPath(), 0, obj.getLocalPath().length())) {
                    rt = findNode(obj, node);
                    if (rt != null)
                        return rt;
                }
                continue;
            }
            return null;
        }
    }

    /**
     * Designed to update current working folder 's immediate sub folders
     */
    static class FolderUpdater implements Runnable {
        IUpdatable target;
        IRemoteRepo operation;
        INxFile folder;

        public FolderUpdater(IUpdatable target, IRemoteRepo operation, INxFile folder) {
            this.target = target;
            this.operation = operation;
            this.folder = folder;
        }

        @Override
        public void run() {
            new UpdatePolicy().updateFolder(target, operation, folder);
        }
    }
}

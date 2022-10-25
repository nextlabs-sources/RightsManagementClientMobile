package appInstance.localRepo.internals;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import appInstance.ExecutorPools;
import appInstance.ViewerApp;
import appInstance.localRepo.helper.Helper;
import database.BoundService;
import nxl.Utils;
import nxl.types.INxFile;
import nxl.types.NXDocument;
import nxl.types.NXFolder;
import nxl.types.NxFileBase;


public class Cache {
    static private final boolean DEBUG = ViewerApp.DEBUG;
    static private final String TAG = "NX_Cache";
    static private final String CACHE = "directory.CACHE";
    static private final String ROOT = "ROOT";

    private volatile INxFile cachedTree = null; // used by multi-threads
    private INxFile workingFolder; // a subTree from mCacheTree
    private File cachedFile;    // mMountBase+CACHE
    private File localFilesRoot;     // mMountBase+ROOT
    private BoundService service; // bound service about LocalRepos' remote info

    private long serializingPoint = System.currentTimeMillis();

    /**
     * - create a file :  directory.CACHE
     * - create a folder: ROOT
     * - recover the cacheTree
     */
    public void init(File newMountBase, BoundService service) throws Exception {
        this.service = service;
        //  CacheFile
        cachedFile = new File(newMountBase, CACHE);
        if (!cachedFile.exists() && !cachedFile.createNewFile()) {
            throw new RuntimeException("error: can not create cache file");
        }
        //  LocalFilesRoot
        localFilesRoot = new File(newMountBase, ROOT);
        if (!Helper.makeSureDirExist(localFilesRoot))
            throw new RuntimeException("error: can not crate local file root dir");
        // TreeRoot
        cachedTree = deserializeCacheTree();
        /*for first installed , mCacheTree is null ,so create a new one,
        sometimes failed by calling the method deserializeCacheTree*/
        if (cachedTree == null) {
            cachedTree = new NXFolder("/", "/", "root", 0);
        }
        workingFolder = cachedTree;    // by default , working folder is the root
        Utils.attachService(cachedTree, service, true);// attach bound-service, to all items in cachedTree
    }

    public synchronized
    @NonNull
    INxFile getCacheTree() {
        return getCacheTree(false);
    }

    public synchronized File getRootDir() {
        return localFilesRoot;
    }


    public synchronized INxFile getWorkingFolder() {
        // sanity check
        if (cachedTree == null) {
            if (DEBUG) Log.e(TAG, "mCacheTree is null ,it's a bug");
            return null;
        }
        if (workingFolder == null) {
            workingFolder = cachedTree;
            return workingFolder;
        }

        return findNodeInTree(workingFolder.getLocalPath());

    }

    public synchronized
    @Nullable
    File getDocument(NXDocument doc) {
        INxFile f = tryToGetFromCache(doc);
        if (f != null) {
            String absPath = Helper.nxPath2AbsPath(getRootDir(), f.getLocalPath());
            File rt = new File(absPath);
            if (rt.exists()) {
                doc.setCached(true);
            }
            return rt;
        }
        return null;
    }

    /**
     * search from cacheTree if {@param base} has existed in
     * - for doc , its content must exist at Disk , and set the doc' cached filed
     * - for folder, the folder exists at the tree
     */
    public synchronized
    @Nullable
    INxFile tryToGetFromCache(INxFile base) {
        INxFile f = cachedTree.findNode(base.getLocalPath());
        if (f == null) {
            return null;
        }
        if (f instanceof NXDocument) {
            //test if exists at local
            if (new File(Helper.nxPath2AbsPath(getRootDir(), f.getLocalPath())).exists()) {
                ((NxFileBase) f).setCached(true);
                ((NxFileBase) f).setBoundService(service);
                return f;
            } else {
                return null;
            }
        }
        if (f instanceof NXFolder) {
            Utils.attachService(f, service, false);
            return f;
        }
        return null;
    }

    public synchronized void onChangeWorkingFolder(INxFile folder) {
        // sanity check
        if (folder == null || !folder.isFolder()) {
            return;
        }

        //make sure the {@param folder} is one member of the Root
        INxFile subNode = cachedTree.findNode(folder.getLocalPath());
        if (subNode == null) {
            if (DEBUG)
                Log.e(TAG, "change current working folder failed , folder dose not exist in Root ");
            return;
        }
        workingFolder = subNode;
        Utils.attachService(workingFolder, service, false);
    }

    /**
     * Be called when @{folder} from cloud been updated
     */
    public synchronized void onSyncFolder(final INxFile folder) {
        class UpdatePolicy {
            INxFile target;

            public UpdatePolicy(INxFile targetFolder) {
                this.target = targetFolder;
            }

            public void proceed(INxFile toBeUpdate) {
                List<INxFile> lOld = new LinkedList<>(target.getChildren());
                List<INxFile> lNew = new LinkedList<>(toBeUpdate.getChildren());

                if (lOld.isEmpty() && lNew.isEmpty()) {
                    // Both  empty        -- nothing to do
                    return;
                }
                if (lOld.isEmpty() && !lNew.isEmpty()) {
                    // lOld is empty while tobeU is not      -- copy lNew
                    ((NxFileBase) target).addChild(lNew);
                    Utils.attachService(target, service, false);
                    return;
                }
                if (!lOld.isEmpty() && lNew.isEmpty()) {
                    // lOld is not empty while lNew is      -- remove cur
                    for (INxFile i : lOld) {
                        removeNode(i);
                    }
                    ((NxFileBase) target).setChildren(lNew);
                    return;
                }
                // Both non-empty
                // -- significant algo begins:
                Iterator<INxFile> curIt = lOld.iterator();
                while (curIt.hasNext()) {
                    INxFile node = curIt.next();
                    // check if current updating node still exist at the newNode,
                    INxFile newNode = findThenDel(lNew, node);
                    if (newNode != null) {
                        updateNode(node, newNode);
                    } else {
                        removeNode(node);
                        curIt.remove();
                    }
                }
                // for rest files, those are additions , add them into current folder
                if (!lNew.isEmpty()) {
                    for (INxFile i : lNew) {
                        lOld.add(i);
                    }
                }

                ((NxFileBase) target).setChildren(lOld);
                Utils.attachService(target, service, false); // correct each item's bound-service
            }

            // if match , del the match node from list
            private INxFile findThenDel(List<INxFile> list, INxFile file) {
                Iterator<INxFile> it = list.iterator();
                while (it.hasNext()) {
                    INxFile i = it.next();
                    if (i.getLocalPath().equals(file.getLocalPath())) {
                        it.remove();
                        return i;
                    }
                }
                return null;
            }

            // old node need to update, modify some fileds
            private void updateNode(INxFile aOld, INxFile aNew) {
                if (aOld == null) {
                    return;
                }
                if (aNew == null) {
                    return;
                }
                // update
                ((NxFileBase) aOld).setCloudPath(aNew.getCloudPath());
                ((NxFileBase) aOld).setSize(aNew.getSize());
                ((NxFileBase) aOld).setLastModifiedTimeLong(aNew.getLastModifiedTimeLong());
            }

            private void removeNode(INxFile aOld) {
                // for next release
            }
        }

        // sanity check
        if (folder == null) return;
        if (!folder.isFolder()) return;
        if (cachedTree == null) return;

        INxFile targetRoot = cachedTree.findNode(folder.getLocalPath());
        if (targetRoot == null) {
            if (DEBUG) Log.e(TAG, "folder to be updated does not exist in mCacheTree");
            return;
        }


        new UpdatePolicy(targetRoot).proceed(folder);

        /**
         *  Serialize Policy, do it with interval at lest 120 seconds
         */
        long currentMillis = System.currentTimeMillis();
        if ((currentMillis - serializingPoint) > 120 * 1000) {
            serializingPoint = currentMillis;  //update serializepoint
            if (DEBUG) {
                Log.v(TAG, "serialize cacheTree into disk");
            }
            // serialize , write the cache tree into disk
            ExecutorPools.COMMON_POOL.execute(new Runnable() {
                @Override
                public void run() {
                    serializeCacheTree();
                }
            });
        }
    }

    public synchronized INxFile findParentOfWorkingFolder() {
        return findNodeInTree(Helper.getParent(workingFolder));
    }

    /**
     * find node in this tree specify by {@param file } and if find, attach service to it
     */
    public synchronized INxFile findNodeInTree(final INxFile file) {
        // sanity check
        if (file == null) return null;
        if (file.getLocalPath() == null) return null;

        INxFile tree = getCacheTree(true);
        INxFile rt = tree.findNode(file.getLocalPath());
        if (rt == null) {
            return null;
        }
        Utils.attachService(rt, service, false);
        return rt;
    }

    public synchronized INxFile findNodeInTree(final String path) {
        // sanity check
        if (path == null) return null;

        INxFile tree = getCacheTree(true);
        INxFile rt = tree.findNode(path);
        if (rt == null) {
            return null;
        }
        Utils.attachService(rt, service, false);
        return rt;
    }


    // restore CacheTree from Disk
    public synchronized INxFile deserializeCacheTree() {
        INxFile rtValue;
        try {
            ObjectInputStream objectInputStream = new ObjectInputStream(new FileInputStream(cachedFile));
            rtValue = (NxFileBase) objectInputStream.readObject();
            objectInputStream.close();
        } catch (Exception e) {
            rtValue = null;
            if (DEBUG) {
                Log.e(TAG, "Error: Cache::deserializeCacheTree" + e.toString());
            }
        }
        return rtValue;
    }

    // write CacheTree into Disk
    public synchronized void serializeCacheTree() {
        try {
            ObjectOutputStream objectOutputStream = new ObjectOutputStream(new FileOutputStream(cachedFile));
            objectOutputStream.writeObject(cachedTree);
            objectOutputStream.close();
        } catch (Exception e) {
            if (DEBUG) {
                Log.e(TAG, "Error: Cache::serializeCacheTree" + e.toString());
            }
            e.printStackTrace();
        }
    }


    private synchronized INxFile getCacheTree(boolean bFast) {
        if (cachedFile == null) {
            cachedTree = new NXFolder("/", "/", "root", 0);
            workingFolder = cachedTree;    // by default , working folder is the root
        }
        if (!bFast) {
            Utils.attachService(cachedTree, service, true);
        }
        return cachedTree;
    }

}

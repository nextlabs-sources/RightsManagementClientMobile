package nxl.types;


import java.io.Serializable;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import database.BoundService;

/**
 * - support serializable
 */
public abstract class NxFileBase implements Serializable, INxFile {
    private String mName;
    private String mLocalPath;
    private String mCloudPath; // may be cloudpath is not begin with '/'
    private long mSize;
    private boolean mIsDeletedByCloud = false;
    private String mLastModifiedTime;
    private long mLastModifiedTimeLong; //the number of milliseconds since January 1, 1970, 00:00:00 GMT
    private boolean mIsFolder;
    private boolean mIsSite = false;
    private List<INxFile> mChildren = new ArrayList<>();
    private BoundService mService;
    private boolean mIsFavorite;
    private boolean mIsOffline;
    private boolean mIsCached;

    public NxFileBase() {
        Date date = new Date();
        mLastModifiedTimeLong = date.getTime();
        this.mIsFavorite = false;
        this.mIsOffline = false;
        this.mIsCached = false;
    }

    @Override
    public boolean isFolder() {
        return mIsFolder;
    }

    protected void setIsFolder(boolean mIsFolder) {
        this.mIsFolder = mIsFolder;
    }

    @Override
    public boolean isSite() {
        return mIsSite;
    }

    protected void setSite(boolean mSite) {
        this.mIsSite = mSite;
    }

    @Override
    public boolean isDeletedByCloud() {
        return mIsDeletedByCloud;
    }

    public void setDeletedByCloud(boolean isDeleted) {
        mIsDeletedByCloud = isDeleted;
    }

    @Override
    public String getName() {
        return mName;
    }

    public void setName(String mName) {
        this.mName = mName;
    }

    @Override
    public String getLocalPath() {
        return mLocalPath;
    }

    public void setLocalPath(String mFullpath) {
        this.mLocalPath = mFullpath;
    }

    @Override
    public String getCloudPath() {
        return mCloudPath;
    }

    public void setCloudPath(String FullServicePath) {
        this.mCloudPath = FullServicePath;
    }

    @Override
    public long getSize() {
        return mSize;
    }

    public void setSize(long mSize) {
        this.mSize = mSize;
    }

    @Override
    public String getLastModifiedTime() {
        return mLastModifiedTime;
    }

    public void setLastModifiedTime(String time) {
        this.mLastModifiedTime = time;
    }

    @Override
    public long getLastModifiedTimeLong() {
        return mLastModifiedTimeLong;
    }

    public void setLastModifiedTimeLong(long time) {
        mLastModifiedTimeLong = time;
    }

    @Override
    public void addChild(INxFile child) {
        this.mChildren.add(child);
    }

    public void addChild(List<INxFile> children) {
        if (children == null) {
            return;
        }
        for (INxFile i : children) {
            this.mChildren.add(i);
        }
    }

    @Override
    public String getParent() {
        if (this.mLocalPath.equals("/")) {
            return "";
        } else {
            int ind = this.mLocalPath.lastIndexOf(47);
            return this.mLocalPath.substring(0, ind + 1);
        }
    }

    @Override
    public List<INxFile> getChildren() {
        return mChildren;
    }

    public void setChildren(List<INxFile> children) {
        mChildren = children;
    }

    @Override
    public BoundService getService() {
        return mService;
    }

    public void setBoundService(BoundService service) {
        mService = service;
    }

    @Override
    public INxFile findNode(String path) {
        return null;
    }

    @Override
    public boolean isMarkedAsFavorite() {
        return mIsFavorite;
    }

    public void setMarkedAsFavorite(boolean isFavorite) {
        mIsFavorite = isFavorite;
    }

    @Override
    public boolean isMarkedAsOffline() {
        return mIsOffline;
    }

    public void setMarkedAsOffline(boolean isOffline) {
        mIsOffline = isOffline;
    }

    @Override
    public boolean isCached() {
        return mIsCached;
    }

    public void setCached(boolean isCached) {
        mIsCached = isCached;
    }
}

package nxl.types;

import java.util.List;

import database.BoundService;

public interface INxFile {

    boolean isFolder();

    boolean isSite();

    @Deprecated
    boolean isDeletedByCloud();

    boolean isMarkedAsFavorite();

    boolean isMarkedAsOffline();

    boolean isCached();

    String getName();

    String getLocalPath();

    String getCloudPath();

    long getSize();

    @Deprecated
    String getLastModifiedTime();

    long getLastModifiedTimeLong();

    void addChild(INxFile child);

    String getParent();

    List<INxFile> getChildren();

    INxFile findNode(String path);

    BoundService getService();

}

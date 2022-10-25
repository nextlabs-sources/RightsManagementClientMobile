package commonUtils.fileListUtils.nxfileListHelper.baseMethod;

import java.util.List;

import commonMethod.sort.SortContext;
import nxl.types.INxFile;

/**
 * provide interface for NXFileList
 */
public interface IHandleNXFileList {
    /**
     * notify adapter that the data changed
     */
    void notifyDataChanged();

    /**
     * show all nodes under root
     */
    void showAllRootFiles();

    /**
     * show current node files.
     *
     * @throws Exception
     */
    void showCurrentNodeFiles() throws Exception;

    void closeRightMenu();

    /**
     * set file list sort type
     *
     * @param sortType the type of sort
     */
    void setSortType(SortContext.SortType sortType);

    void setOnFavoriteStatusChanged(OnFileFavoriteStatusChanged callback);

    void setOnOfflineStatusChanged(OnFileOfflineStatusChanged callback);

    interface OnFileFavoriteStatusChanged {
        void onFavoriteStatusChanged(INxFile node, boolean isChanged);
    }

    interface OnFileOfflineStatusChanged {
        void onOfflineStatusChanged(INxFile node, boolean isChanged);
    }

    /**
     * the interface to get sorted files.
     */
    interface IGetSortedNXFiles {
        List<INxFile> getSortedNXFiles(List<INxFile> nxFiles);
    }

}

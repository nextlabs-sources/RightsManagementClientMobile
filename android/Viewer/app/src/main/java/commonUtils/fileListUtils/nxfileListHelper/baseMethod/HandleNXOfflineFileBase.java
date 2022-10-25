package commonUtils.fileListUtils.nxfileListHelper.baseMethod;

/**
 * base class to implement common method
 */
public abstract class HandleNXOfflineFileBase implements IHandleNXFileList {
    /**
     * not needed in offline list
     *
     * @param callback callback for favorite change event
     */
    @Override
    public void setOnFavoriteStatusChanged(OnFileFavoriteStatusChanged callback) {

    }
}

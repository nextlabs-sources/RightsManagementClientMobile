package commonUtils.fileListUtils;

import nxl.types.INxFile;

/**
 * item in for recycler view list
 */
public class NXFileItem {
    private INxFile mNXFile;
    private String mTitle;

    public NXFileItem(INxFile nxFile, String title) {
        mNXFile = nxFile;
        mTitle = title;
    }

    public INxFile getNXFile() {
        return mNXFile;
    }

    public void setNXFile(INxFile nxFile) {
        mNXFile = nxFile;
    }

    public String getTitle() {
        return mTitle;
    }

    public void setTitle(String title) {
        mTitle = title;
    }
}

package appInstance.localRepo.sort.sortAlgorithm;

import android.content.Context;

import java.util.List;

import nxl.types.INxFile;

@Deprecated
public abstract class SortBase {
    private List<INxFile> mFiles;
    private Context mContext;

    public SortBase(List<INxFile> files, Context context) {
        mFiles = files;
        mContext = context;
    }

    public List<INxFile> doSort() {
        //DispatchList(mFiles);
        return mFiles;
    }

    abstract void onSortFile(List<INxFile> alFiles);

    public int onGetServiceCount() {
        return 0;
    }
}

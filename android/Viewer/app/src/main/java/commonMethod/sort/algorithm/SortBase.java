package commonMethod.sort.algorithm;

import android.content.Context;

import java.util.ArrayList;
import java.util.List;

import commonUtils.fileListUtils.NXFileItem;

/**
 * base class for sort algorithm
 */
public abstract class SortBase {
    private List<NXFileItem> mFiles;
    private Context mContext;

    public SortBase(List<NXFileItem> files, Context context) {
        mFiles = files;
        mContext = context;
    }

    public List<NXFileItem> doSort() {
        return new ArrayList<>();
    }

    abstract void onSortFile(List<NXFileItem> alFiles);

    public int onGetServiceCount() {
        return 0;
    }
}

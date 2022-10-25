package commonMethod.sort;

import android.content.Context;

import java.util.List;

import commonMethod.sort.algorithm.DriveSort;
import commonMethod.sort.algorithm.NameAscending;
import commonMethod.sort.algorithm.Newest;
import commonMethod.sort.algorithm.SortBase;
import commonUtils.fileListUtils.NXFileItem;

/**
 * context for sort algorithm
 */
public class SortContext {
    private SortBase mSortAlgorithm;

    public List<NXFileItem> DispatchSortAlgorithm(SortType type, List<NXFileItem> clickFileName, Context context) {
        switch (type) {
            case NAMEASCENDING:
                mSortAlgorithm = new NameAscending(clickFileName, context);
                break;
            case DRIVERTYPE:
                mSortAlgorithm = new DriveSort(clickFileName, context);
                break;
            case NEWEST:
                mSortAlgorithm = new Newest(clickFileName, context);
                break;
        }
        return mSortAlgorithm.doSort();
    }

    public int onGetServiceCount() throws Exception {
        if (mSortAlgorithm == null) {
            throw new Exception("the sort type should be sot as DRIVERTYPE");
        }
        return mSortAlgorithm.onGetServiceCount();
    }

    public enum SortType {
        NAMEASCENDING(0),
        DRIVERTYPE(1),
        NEWEST(2);

        private int value = 0;

        SortType(int type) {
            value = type;
        }

        public static SortType valueOf(int value) {
            switch (value) {
                case 0:
                    return NAMEASCENDING;
                case 1:
                    return DRIVERTYPE;
                case 2:
                    return NEWEST;
                default:
                    throw new IllegalArgumentException("value" + value + " is not a legal value to convert to SortType");
            }
        }

        public int value() {
            return this.value;
        }
    }
}

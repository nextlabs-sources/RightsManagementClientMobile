package commonMethod.sort.algorithm;

import android.content.Context;
import android.text.TextUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.NXFileItem;
import nxl.types.INxFile;

/**
 * implement sort by time algorithm
 */
public class Newest extends SortBase {
    private List<NXFileItem> mFiles;
    private Context mContext;

    public Newest(List<NXFileItem> files, Context context) {
        super(files, context);
        mContext = context;
        mFiles = files;
    }

    @Override
    public List<NXFileItem> doSort() {
        super.doSort();
        return DispatchList(mFiles);
    }

    @Override
    void onSortFile(List<NXFileItem> alFiles) {
        Collections.sort(alFiles, new SortFileNewest());
    }

    private List<NXFileItem> DispatchList(List<NXFileItem> alFiles) {
        List<NXFileItem> alTime = new ArrayList<>();
        List<NXFileItem> alEmptyTime = new ArrayList<>();
        for (NXFileItem content : alFiles) {
            String timeValue = FileUtils.ConvertTime(content.getNXFile(), false);
            if (TextUtils.isEmpty(timeValue)) {
                alEmptyTime.add(content);
            } else {
                alTime.add(content);
            }
        }
        alFiles.clear();
        onSortFile(alTime);
        alFiles.addAll(alTime);
        onSortFile(alEmptyTime);
        alFiles.addAll(alEmptyTime);

        List<NXFileItem> nxFileItems = new ArrayList<>();
        for (NXFileItem item : alFiles) {
            nxFileItems.add(new NXFileItem(item.getNXFile(), FileUtils.ConvertTime(item.getNXFile(), false)));
        }

        return nxFileItems;
    }


    @Override
    public int onGetServiceCount() {
        return 0;
    }

    public class SortFileNewest implements Comparator<NXFileItem> {
        @Override
        public int compare(NXFileItem f1, NXFileItem f2) {
            INxFile file1Node = f1.getNXFile();
            INxFile file2Node = f2.getNXFile();
            //should compare the fully time, so the pass parameter isBottomItem should be set to true which is fully time value.
            return FileUtils.ConvertTime(file2Node, true).compareTo(FileUtils.ConvertTime(file1Node, true));
        }
    }
}

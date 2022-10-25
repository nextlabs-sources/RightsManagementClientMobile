package commonMethod.sort.algorithm;

import android.content.Context;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.NXFileItem;
import nxl.types.INxFile;

/**
 * implement name ascending algorithm
 */
public class NameAscending extends SortBase {
    private List<NXFileItem> mFiles;
    private Context mContext;

    public NameAscending(List<NXFileItem> files, Context context) {
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
        Collections.sort(alFiles, new SortFileNameAscending());
    }

    private List<NXFileItem> DispatchList(List<NXFileItem> alFiles) {
        List<NXFileItem> alNormalName = new ArrayList<>();
        List<NXFileItem> alSpecificName = new ArrayList<>();
        for (NXFileItem content : alFiles) {
            INxFile temp = content.getNXFile();
            String letter = FileUtils.getLetter(temp.isSite() ? temp.getName().substring(1) : temp.getName());
            if (letter.equals("#")) {
                alSpecificName.add(content);
            } else {
                alNormalName.add(content);
            }
        }
        alFiles.clear();
        onSortFile(alSpecificName);
        alFiles.addAll(alSpecificName);
        onSortFile(alNormalName);
        alFiles.addAll(alNormalName);

        List<NXFileItem> nxFileItems = new ArrayList<>();
        for (NXFileItem item : alFiles) {
            INxFile temp = item.getNXFile();
            nxFileItems.add(new NXFileItem(item.getNXFile(), FileUtils.getLetter(temp.isSite() ? temp.getName().substring(1) : temp.getName())));
        }

        return nxFileItems;
    }

    @Override
    public int onGetServiceCount() {
        return 0;
    }

    private class SortFileNameAscending implements Comparator<NXFileItem> {
        @Override
        public int compare(NXFileItem file1, NXFileItem file2) {
            INxFile file1Node = file1.getNXFile();
            INxFile file2Node = file2.getNXFile();
            return (file1Node.isSite() ? file1Node.getName().substring(1) : file1Node.getName()).compareToIgnoreCase(file2Node.isSite() ? file2Node.getName().substring(1) : file2Node.getName());
        }
    }
}

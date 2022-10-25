package appInstance.localRepo.sort.sortAlgorithm;

import android.content.Context;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import nxl.types.INxFile;

@Deprecated
public class NameAscending extends SortBase {
    private List<INxFile> mFiles;
    private Context mContext;

    public NameAscending(List<INxFile> files, Context context) {
        super(files, context);
        mContext = context;
        mFiles = files;
    }

    @Override
    public List<INxFile> doSort() {
        super.doSort();
        DispatchList(mFiles);
        return mFiles;
    }

    @Override
    void onSortFile(List<INxFile> alFiles) {
        Collections.sort(alFiles, new SortFileNameAscending());
    }

    private void DispatchList(List<INxFile> alFiles) {
        ArrayList<INxFile> alNormalLetter = new ArrayList<>();
        ArrayList<INxFile> alSpecificalLetter = new ArrayList<>();
        for (INxFile content : alFiles) {
            if (isSpecificalLetter(content.getName())) {
                alSpecificalLetter.add(content);
            } else {
                alNormalLetter.add(content);
            }
        }
        alFiles.clear();
        onSortFile(alNormalLetter);
        alFiles.addAll(alNormalLetter);
        onSortFile(alSpecificalLetter);
        alFiles.addAll(alSpecificalLetter);
    }

    private boolean isSpecificalLetter(String name) {
        String nameLetter = name.trim().substring(0, 1).toUpperCase();
        return !nameLetter.matches("[A-Z]");
    }

    @Override
    public int onGetServiceCount() {
        return 0;
    }

    private class SortFileNameAscending implements Comparator<INxFile> {
        @Override
        public int compare(INxFile f1, INxFile f2) {
            return f1.getName().compareToIgnoreCase(f2.getName());
        }
    }
}

package appInstance.localRepo.sort.sortAlgorithm;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

import nxl.types.INxFile;

@Deprecated
public class Newest extends SortBase {
    private List<INxFile> mFiles;
    private Context mContext;

    public Newest(List<INxFile> files, Context context) {
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
        Collections.sort(alFiles, new SortFileNewest());
    }

    private void DispatchList(List<INxFile> alFiles) {
        ArrayList<INxFile> alTime = new ArrayList<>();
        ArrayList<INxFile> alEmptyTime = new ArrayList<>();
        for (INxFile content : alFiles) {
            String timeValue = ConvertTime(content);
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
    }

    private String ConvertTime(INxFile file) {
        if (TextUtils.isEmpty(file.getLastModifiedTime())) {
            return "";
        }
        try {
            SimpleDateFormat sdBottom = new SimpleDateFormat("yyyy/MM/dd HH:mm");
            return sdBottom.format(new Date(file.getLastModifiedTimeLong()));
        } catch (Exception e) {
            Log.e("Newest", e.toString());
        }
        return "";
    }

    @Override
    public int onGetServiceCount() {
        return 0;
    }

    public class SortFileNewest implements Comparator<INxFile> {
        @Override
        public int compare(INxFile f1, INxFile f2) {
            return ConvertTime(f2).compareTo(ConvertTime(f1));
        }
    }
}

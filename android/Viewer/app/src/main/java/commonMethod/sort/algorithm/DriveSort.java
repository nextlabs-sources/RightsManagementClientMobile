package commonMethod.sort.algorithm;

import android.content.Context;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import commonUtils.fileListUtils.NXFileItem;
import nxl.types.INxFile;

/**
 * implement drive sort algorithm
 */
public class DriveSort extends SortBase {
    private List<NXFileItem> mFiles;
    private Context mContext;

    private List<NXFileItem> mDropBoxDocs = new ArrayList<>();
    private List<NXFileItem> mGoogleDriveDocs = new ArrayList<>();
    private List<NXFileItem> mOneDriveDocs = new ArrayList<>();
    private List<NXFileItem> mSharePointDocs = new ArrayList<>();
    private List<NXFileItem> mSharePointOnlineDocs = new ArrayList<>();
    private List<NXFileItem> mDocs = new ArrayList<>();

    public DriveSort(List<NXFileItem> files, Context context) {
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
    public void onSortFile(List<NXFileItem> alFiles) {
        Collections.sort(alFiles, new SortFileNameAscending());
    }

    private List<NXFileItem> DispatchList(List<NXFileItem> alFiles) {
        mDropBoxDocs.clear();
        mGoogleDriveDocs.clear();
        mOneDriveDocs.clear();
        mSharePointDocs.clear();
        mSharePointOnlineDocs.clear();
        mDocs.clear();
        for (NXFileItem content : alFiles) {
            addToServiceDocs(content);
        }
        onSortFile(mDropBoxDocs);
        mDocs.addAll(mDropBoxDocs);
        onSortFile(mGoogleDriveDocs);
        mDocs.addAll(mGoogleDriveDocs);
        onSortFile(mOneDriveDocs);
        mDocs.addAll(mOneDriveDocs);
        onSortFile(mSharePointDocs);
        mDocs.addAll(mSharePointDocs);
        onSortFile(mSharePointOnlineDocs);
        mDocs.addAll(mSharePointOnlineDocs);

        List<NXFileItem> nxFileItems = new ArrayList<>();
        for (NXFileItem item : mDocs) {
            nxFileItems.add(new NXFileItem(item.getNXFile(), item.getNXFile().getService().alias));
        }
        return nxFileItems;
    }

    private void addToServiceDocs(NXFileItem file) {
        switch (file.getNXFile().getService().type) {
            case DROPBOX: {
                mDropBoxDocs.add(file);
            }
            break;
            case GOOGLEDRIVE: {
                mGoogleDriveDocs.add(file);
            }
            break;
            case ONEDRIVE: {
                mOneDriveDocs.add(file);
            }
            break;
            case SHAREPOINT: {
                mSharePointDocs.add(file);
            }
            break;
            case SHAREPOINT_ONLINE: {
                mSharePointOnlineDocs.add(file);
            }
            break;
        }
    }

    @Override
    public int onGetServiceCount() {
        int iService = 0;
        if (!mDropBoxDocs.isEmpty()) {
            iService++;
        }
        if (!mOneDriveDocs.isEmpty()) {
            iService++;
        }
        if (!mGoogleDriveDocs.isEmpty()) {
            iService++;
        }
        if (!mSharePointDocs.isEmpty()) {
            iService++;
        }
        if (!mSharePointOnlineDocs.isEmpty()) {
            iService++;
        }
        return iService;
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

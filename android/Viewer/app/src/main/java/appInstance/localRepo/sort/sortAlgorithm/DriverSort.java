package appInstance.localRepo.sort.sortAlgorithm;

import android.content.Context;

import java.util.ArrayList;
import java.util.List;

import nxl.types.INxFile;

/**
 * Created by eric on 12/1/2015.
 */
@Deprecated
public class DriverSort extends SortBase {
    private List<INxFile> mFiles;
    private Context mContext;

    private List<INxFile> mFavoriteDropBoxDocs = new ArrayList<INxFile>();
    private List<INxFile> mFavoriteGoogleDriveDocs = new ArrayList<INxFile>();
    private List<INxFile> mFavoriteOneDriveDocs = new ArrayList<INxFile>();
    private List<INxFile> mFavoriteSharePointDocs = new ArrayList<INxFile>();
    private List<INxFile> mFavoriteSharePointOnlineDocs = new ArrayList<INxFile>();
    private List<INxFile> mFavoriteDocs = new ArrayList<INxFile>();

    public DriverSort(List<INxFile> files, Context context) {
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
    public void onSortFile(List<INxFile> alFiles) {

    }

    private void DispatchList(List<INxFile> alFiles) {
        mFavoriteDropBoxDocs.clear();
        mFavoriteGoogleDriveDocs.clear();
        mFavoriteOneDriveDocs.clear();
        mFavoriteSharePointDocs.clear();
        mFavoriteSharePointOnlineDocs.clear();
        mFavoriteDocs.clear();
        for (INxFile content : alFiles) {
            addToServiceDocs(content);
        }
        mFavoriteDocs.addAll(mFavoriteDropBoxDocs);
        mFavoriteDocs.addAll(mFavoriteOneDriveDocs);
        mFavoriteDocs.addAll(mFavoriteSharePointDocs);
        mFavoriteDocs.addAll(mFavoriteSharePointOnlineDocs);
        mFavoriteDocs.addAll(mFavoriteGoogleDriveDocs);
    }

    private void addToServiceDocs(INxFile file) {
        switch (file.getService().type) {
            case DROPBOX: {
                mFavoriteDropBoxDocs.add(file);
            }
            break;
            case GOOGLEDRIVE: {
                mFavoriteGoogleDriveDocs.add(file);
            }
            break;
            case ONEDRIVE: {
                mFavoriteOneDriveDocs.add(file);
            }
            break;
            case SHAREPOINT: {
                mFavoriteSharePointDocs.add(file);
            }
            break;
            case SHAREPOINT_ONLINE: {
                mFavoriteSharePointOnlineDocs.add(file);
            }
            break;
        }
    }

    @Override
    public int onGetServiceCount() {
        int iService = 0;
        if (!mFavoriteDropBoxDocs.isEmpty()) {
            iService++;
        }
        if (!mFavoriteOneDriveDocs.isEmpty()) {
            iService++;
        }
        if (!mFavoriteGoogleDriveDocs.isEmpty()) {
            iService++;
        }
        if (!mFavoriteSharePointDocs.isEmpty()) {
            iService++;
        }
        if (!mFavoriteSharePointOnlineDocs.isEmpty()) {
            iService++;
        }
        return iService;
    }
}

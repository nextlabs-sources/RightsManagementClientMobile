package phone.com.nextlabs.homeActivityWidget;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.widget.AdapterView;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.imageableList.NXFileAdapter;
import com.imageableList.NXFileListView;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import appInstance.ViewerApp;
import appInstance.localRepo.ILocalRepo;
import appInstance.localRepo.sort.SortContext;
import appInstance.remoteRepo.IRemoteRepo;
import nxl.types.INxFile;
import nxl.types.NxFileBase;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.HomeRightMenuContent;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.RightSlideLayoutHelper;
import phone.com.nextlabs.viewer.ViewFileActivity;

/**
 * used as a list view UI component to display contents of specific repository
 * - sort and display,
 * - pull down refresh, syn content with remote repo
 */
public class FileListView implements IRemoteRepo.IGetFileMetaInfoCallback {
    private Activity mActivity;
    private int mResourceID;
    private View mCategoryView;
    private ViewerApp app = ViewerApp.getInstance();
    private NXFileListView mFileListView;
    private ArrayList<INxFile> mFileList = new ArrayList<>();
    private ArrayList<INxFile> mTempFileList = new ArrayList<>();
    private NXFileAdapter mFileListAdapter;

    private RelativeLayout mCategory;
    private TextView mCategoryBack;
    private TextView mCategoryName;

    private ProgressDialog mProgressDialog;
    private IGetSortNXFileArray mSortNXFileArray = null;

    private FrameLayout mAlphaLayout;

    private HomeRightMenuContent mHomeRightMenuContentObj;

    private SearchEditContent mSearchEditContent;

    private OnFileOfflineStatusChanged onFileOfflineStatusChanged;
    private OnFileFavoriteStatusChanged onFileFavoriteStatusChanged;
    private IOnGetChildList onGetChildList;

    private OnCategoryChanged onCategoryChanged;

    private List<INxFile> mAllValidNode = new ArrayList<>();
    private List<ILocalRepo> mAllEmptyRepo = new ArrayList<>();

    public FileListView(Activity activity, int resourceID, View categoryView) {
        mActivity = activity;
        mResourceID = resourceID;
        mCategoryView = categoryView;
        initValue();
        initEvent();
        initPullRefresh();
        fileListItemClick();
    }

    /**
     * get all activated repos
     *
     * @return a map of all repos include ILocalRepo interface and file node list
     */
    public void getAllActivatedReposRoot() {
        //empty the node list
        mAllValidNode.clear();
        mAllEmptyRepo.clear();
        mCategory.setVisibility(View.GONE);
        Iterator<Map.Entry<ILocalRepo, List<INxFile>>> it = app.getLivingReposRoot().entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<ILocalRepo, List<INxFile>> entry = it.next();
            if (entry.getValue() != null && !(entry.getValue().isEmpty())) {
                mAllValidNode.addAll(entry.getValue());
            } else {
                mAllEmptyRepo.add(entry.getKey());
            }
        }
        if (!mAllEmptyRepo.isEmpty()) {
            //invoke this function means there is no meta Info in the list, so we should show progressBar download meta info from net.
            mProgressDialog = ProgressDialog.show(mActivity, "", "Loading....");
            try {
                app.refreshRepos(mAllEmptyRepo, new IRemoteRepo.IGetFileMetaInfoCallback() {
                    @Override
                    public void getFileMetaInfoFinished(boolean taskStatus, INxFile file, String errorMsg) {
                        if (taskStatus) {
                            //download successful, add the meta info to node list.
                            //mAllValidNode.add(file);
                            for (INxFile f : file.getChildren()) {
                                mAllValidNode.add(f);
                            }
                            updateFileList(mSortNXFileArray.onGetNXFileArray(mAllValidNode));
                        } else {
                            Toast.makeText(mActivity, "Failed:" + errorMsg, Toast.LENGTH_SHORT).show();
                        }
                        mFileListView.onRefreshComplete();
                        if (mProgressDialog != null) {
                            mProgressDialog.dismiss();
                        }
                    }
                });
            } catch (Exception e) {
                mProgressDialog.dismiss();
                e.printStackTrace();
            }
        }
        updateFileList(mSortNXFileArray.onGetNXFileArray(mAllValidNode));
    }

    /**
     * @throws Exception
     */
    public void getWorkingDirListForSync() throws Exception {
        updateFileList(mSortNXFileArray.onGetNXFileArray(app.listWorkingFolder()));
    }

    public void setSortNXFileArrayCallBack(IGetSortNXFileArray callBack) {
        mSortNXFileArray = callBack;
    }

    public void updateFileList(List<INxFile> files) {
        mFileList.clear();
        mFileList.addAll(files);
        //It means that if search edit text's content empty we could do re-fresh.
        if (mSearchEditContent.isTextEmpty()) {
            mFileListAdapter.notifyDataSetChanged();
        }

        mTempFileList.clear();
        mTempFileList.addAll(files);
    }

    public NXFileListView getFileListView() {
        return mFileListView;
    }

    private void initValue() {
        // mHomeRightMenuContentObj = new HomeRightMenuContent(mActivity);
        mHomeRightMenuContentObj = HomeRightMenuContent.getInstance();
        mAlphaLayout = (FrameLayout) mActivity.findViewById(R.id.home_alpha_view);
        mFileListView = (NXFileListView) mActivity.findViewById(mResourceID);
        mFileListAdapter = new NXFileAdapter(mActivity, R.layout.nxfile_item, mFileList);
        mFileListView.setAdapter(mFileListAdapter);

        if (mCategoryView != null) {
            mCategory = (RelativeLayout) mCategoryView;
            mCategoryBack = (TextView) mCategoryView.findViewById(R.id.back);
            mCategoryName = (TextView) mCategoryView.findViewById(R.id.categoryName);
            initCategoryStatus();
        }

        mSearchEditContent = new SearchEditContent(mActivity, R.id.home_search_edit_view);
    }

    private void initEvent() {
        mSearchEditContent.setOnFilterData(new SearchEditContent.OnFilterData() {
            @Override
            public void onFilterData(String filterStr, boolean isEmpty) {
                List<INxFile> temp = new ArrayList<>();
                if (isEmpty) {
                    temp = mTempFileList;
                } else {
                    //for (INxFile file : mFileList)
                    for (INxFile file : mTempFileList) {
                        String name = file.getName();
                        if (name.toLowerCase().contains(filterStr.toLowerCase())) {
                            temp.add(file);
                        }
                    }
                }
                mFileList.clear();
                mFileList.addAll(temp);
                mFileListAdapter.notifyDataSetChanged();
            }
        });

        mFileListAdapter.setOnInfoItemClicked(new NXFileAdapter.OnInfoItemClicked() {
            @Override
            public void onInfoItemClicked(final INxFile nxfile, int position) {
                mAlphaLayout.setVisibility(View.VISIBLE);
                mAlphaLayout.setOnTouchListener(new View.OnTouchListener() {
                    @Override
                    public boolean onTouch(View v, MotionEvent event) {
                        switch (event.getAction()) {
                            case MotionEvent.ACTION_UP:
                                if (mHomeRightMenuContentObj != null) {
                                    mHomeRightMenuContentObj.toggleRightMenu(nxfile);
                                }
                                break;
                        }
                        return true;
                    }
                });
                if (mHomeRightMenuContentObj != null) {
                    mHomeRightMenuContentObj.toggleRightMenu(nxfile);
                }
            }
        });

        mHomeRightMenuContentObj.setOnOfflineStatusChanged(new RightSlideLayoutHelper.OnOfflineStatusChanged() {
            @Override
            public void onOfflineStatusChanged(INxFile nxFile, boolean isChanged) {
                if (onFileOfflineStatusChanged != null) {
                    onFileOfflineStatusChanged.onOfflineStatusChanged(nxFile, isChanged);
                }
            }
        });

        mHomeRightMenuContentObj.setOnFavoriteStatusChanged(new RightSlideLayoutHelper.OnFavoriteStatusChanged() {
            @Override
            public void onFavoriteStatusChanged(INxFile nxFile, boolean isChanged) {
                if (onFileFavoriteStatusChanged != null) {
                    onFileFavoriteStatusChanged.onFavoriteStatusChanged(nxFile, isChanged);
                }
            }
        });

        //compatible offline fragment
        if (mCategory != null) {
            handleCategoryBackEvent();
        }
    }

    public void setOnOfflineStatusChanged(OnFileOfflineStatusChanged callback) {
        onFileOfflineStatusChanged = callback;
    }

    public void setOnFavoriteStatusChanged(OnFileFavoriteStatusChanged callback) {
        onFileFavoriteStatusChanged = callback;
    }

    public void setSortType(SortContext.SortType type) {
        mFileListAdapter.setSortType(type);
    }

    private void handleCategoryBackEvent() {
        mCategoryBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // for BackButton clicked, return the parent info of current working folder
                INxFile parentNode = app.uptoParent();
                if (parentNode == null) {
                    return;
                }
                if (onCategoryChanged != null) {
                    onCategoryChanged.onCategoryChanged(false);
                }
                //for Root dir, hide category bar.
                if (parentNode.getLocalPath().equals("/")) {
                    if (onCategoryChanged != null) {
                        onCategoryChanged.onCategoryChanged(true);
                    }
                    mCategory.setVisibility(View.GONE);
                }
                try {
                    if (onGetChildList == null) {
                        Log.e("FileListView", "should set the node callback function");
                        return;
                    }
                    updateFileList(mSortNXFileArray.onGetNXFileArray(onGetChildList.onGetChildList(parentNode)));
                } catch (Exception e) {
                    Log.e("FileListView view", e.toString());
                }

                //INxFile parentTemp = app.getParent(workingDir);
                if (parentNode.getLocalPath().equals("/")) {
                    mCategoryBack.setText("root");
                } else {
                    if (parentNode.isSite()) {
                        mCategoryBack.setText(app.findParent(parentNode).getName().substring(1));
                    } else {
                        mCategoryBack.setText(app.findParent(parentNode).getName());
                    }
                }
                if (parentNode.isSite()) {
                    mCategoryName.setText(parentNode.getName().substring(1));
                } else {
                    mCategoryName.setText(parentNode.getName());
                }
            }
        });
    }

    private void initPullRefresh() {
        mFileListView.setOnRefreshListener(new NXFileListView.OnRefreshListener() {
            @Override
            public void onRefresh() {
                try {
                    app.syncWorkingFolder(FileListView.this);
                } catch (Exception e) {
                    Log.e("FileListView view", e.toString());
                    mFileListView.onRefreshComplete();
                }
            }
        });
    }

    private void fileListItemClick() {
        mFileListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                INxFile clickFileName = mFileList.get(position - 1);
                if (!clickFileName.isFolder()) {
                    Intent intent = new Intent();
                    intent.setAction("NXHomeToView");
                    intent.putExtra("click_file", (NxFileBase) clickFileName);
                    intent.setClass(mActivity, ViewFileActivity.class);
                    mActivity.startActivity(intent);
                } else {
                    try {
                        List<INxFile> folderContent = app.listFolder(clickFileName, FileListView.this);
                        if (folderContent != null) {
                            //folder had cached in the local disk.
                            //todo: display the content
                            handleCategoryEnterFolder(clickFileName);
                            updateFileList(mSortNXFileArray.onGetNXFileArray(folderContent));
                        } else {
                            //todo: not in cache , use network to download it display waiting UI
                            mProgressDialog = ProgressDialog.show(mActivity, "", "Loading...");
                        }
                    } catch (Exception e) {
                        Log.e("FileListView view", e.toString());
                    }
                }
            }
        });
    }

    /**
     * invoke in init function, to set category value and set visibility
     * for use case:
     * back from favorite/offline or other page to homeList page, should init category
     */
    private void initCategoryStatus() {
        try {
            INxFile currentNode = app.findWorkingFolder();
            handleCategoryEnterFolder(currentNode);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //set category when enter into folder
    private void handleCategoryEnterFolder(INxFile clickFileName) {
        INxFile parent = app.findParent(clickFileName);
        if (parent == null) {
            return;
        }
        if (onCategoryChanged != null) {
            onCategoryChanged.onCategoryChanged(false);
        }
        //if current clicked file's path is root, then set the category bar as GONE status.
        if (clickFileName.getLocalPath().equals("/")) {
            if (onCategoryChanged != null) {
                onCategoryChanged.onCategoryChanged(true);
            }
            mCategory.setVisibility(View.GONE);
            return;
        }
        //if current clicked file's parent file path is root, set the back item "/" as "root"
        //else set the back item as parent's file name..
        mCategory.setVisibility(View.VISIBLE);
        if (parent.getLocalPath().equals("/")) {
            mCategoryBack.setText("root");
        } else {
            if (parent.isSite()) {
                mCategoryBack.setText(parent.getName().substring(1));
            } else {
                mCategoryBack.setText(parent.getName());
            }
        }

        if (clickFileName.isSite()) {
            mCategoryName.setText(clickFileName.getName().substring(1));
        } else {
            mCategoryName.setText(clickFileName.getName());
        }
    }

    /**
     * for fired async loading routine, this interface will accept the loading result
     */
    @Override
    public void getFileMetaInfoFinished(boolean taskStatus, INxFile fileSys, String errorMsg) {
        try {
            if (taskStatus) {//download successful
                handleCategoryEnterFolder(fileSys);
                updateFileList(mSortNXFileArray.onGetNXFileArray(fileSys.getChildren()));
            } else {
                Toast.makeText(mActivity, "Failed:" + errorMsg, Toast.LENGTH_SHORT).show();
            }
        } finally {
            mFileListView.onRefreshComplete();
            if (mProgressDialog != null) {
                mProgressDialog.dismiss();
            }
        }
    }

    public void setOnGetChildList(IOnGetChildList callback) {
        onGetChildList = callback;
    }

    public void setOnCategoryChanged(OnCategoryChanged onCategoryChanged) {
        this.onCategoryChanged = onCategoryChanged;
    }

    public interface IGetSortNXFileArray {
        List<INxFile> onGetNXFileArray(List<INxFile> files);
    }

    public interface OnFileOfflineStatusChanged {
        void onOfflineStatusChanged(INxFile node, boolean isChanged);
    }

    public interface OnFileFavoriteStatusChanged {
        void onFavoriteStatusChanged(INxFile node, boolean isChanged);
    }

    public interface IOnGetChildList {
        List<INxFile> onGetChildList(INxFile parentNode);
    }

    //this callback dispatch the click event to UI to do some initial things.
    public interface OnCategoryChanged {
        void onCategoryChanged(boolean isRoot);
    }
}
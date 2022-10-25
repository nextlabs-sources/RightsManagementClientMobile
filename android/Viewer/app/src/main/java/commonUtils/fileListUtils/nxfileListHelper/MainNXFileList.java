package commonUtils.fileListUtils.nxfileListHelper;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.support.v4.widget.SwipeRefreshLayout;
import android.support.v7.widget.DefaultItemAnimator;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.imageableList.NXSwipeRefreshLayout;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import appInstance.ViewerApp;
import appInstance.localRepo.ILocalRepo;
import appInstance.remoteRepo.IRemoteRepo;
import commonMethod.sort.SortContext;
import commonUtils.fileListUtils.DividerItemDecoration;
import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.NXFileItem;
import commonUtils.fileListUtils.NXFileRecyclerViewAdapter;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.IHandleNXFileList;
import errorHandler.ErrorCode;
import errorHandler.GenericError;
import nxl.types.INxFile;
import nxl.types.NxFileBase;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.HomeRightMenuContent;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.RightSlideLayoutHelper;
import phone.com.nextlabs.viewer.ViewFileActivity;

/**
 * file list helper class to handle normal file list.
 */
public class MainNXFileList implements IHandleNXFileList, IRemoteRepo.IGetFileMetaInfoCallback {
    private ViewerApp app = ViewerApp.getInstance();
    private Activity mActivity;

    private RelativeLayout mCategoryLayout;
    private TextView mCategoryBack;
    private TextView mCategoryName;
    private View mMainView;

    private RecyclerView mNXFileRecyclerView;
    private NXFileRecyclerViewAdapter mNXFileAdapter;

    private List<INxFile> mAllValidNode = new ArrayList<>();
    private List<ILocalRepo> mAllEmptyRepo = new ArrayList<>();
    private List<NXFileItem> mNXFileItems = new ArrayList<>();

    private List<NXFileItem> mTempNXFileItems = new ArrayList<>();

    private SortContext mSortContext;
    private SortContext.SortType mSortType = SortContext.SortType.NAMEASCENDING;

    private OnFileFavoriteStatusChanged onFileFavoriteStatusChanged;

    private ICollapseSearchView collapseSearchView;
    private IHideKeyboard hideKeyboard;
    private OnFileOfflineStatusChanged onFileOfflineStatusChanged;
    private ProgressDialog mProgressDialog;
    //used for right menu alpha background
    private FrameLayout mAlphaLayout;
    //main show layout
    private FrameLayout mMainShowLayout;
    //used for enter empty folder case
    private View mEmptyFolderLayout;
    //used for enter normal folder case, normal means not empty
    private View mNormalLayout;
    //used for none repository, means no repository in database or no valid repository
    private View mNoneRepoLayout;
    //used for none search result
    private View mNoneSearchResult;
    private boolean mSearchMode = false;
    private HomeRightMenuContent mHomeRightMenuContentObj;
    private NXSwipeRefreshLayout mSwipeRefreshLayout;
    private String mRefreshPath;

    public MainNXFileList(Activity activity, View v) {
        mActivity = activity;
        mMainView = v;
        initData();
        initEvent();
    }

    @Override
    public void setOnFavoriteStatusChanged(OnFileFavoriteStatusChanged callback) {
        onFileFavoriteStatusChanged = callback;
    }

    @Override
    public void setOnOfflineStatusChanged(OnFileOfflineStatusChanged callback) {
        onFileOfflineStatusChanged = callback;
    }

    @Override
    public void setSortType(SortContext.SortType sortType) {
        mSortType = sortType;
        //refresh file list after sortType changed
        try {
            List<NXFileItem> temp = new ArrayList<>();
            temp.addAll(mNXFileItems);
            mNXFileItems.clear();
            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, temp, mActivity));

            //store to temp List, used to restore data, used in search case.
            mTempNXFileItems.clear();
            mTempNXFileItems.addAll(mNXFileItems);

            notifyDataChanged();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void closeRightMenu() {
        if (mHomeRightMenuContentObj.isShow()) {
            mHomeRightMenuContentObj.toggleRightMenu(null);
        }
    }

    public void handleSearchEvent(String filterStr, boolean isEmpty) {
        //restore data from temp list
        mNXFileItems.clear();
        mNXFileItems.addAll(mTempNXFileItems);
        //do search
        mSearchMode = true;
        try {
            List<NXFileItem> temp = new ArrayList<>();
            if (isEmpty) {
                temp.addAll(mNXFileItems);
            } else {
                for (NXFileItem file : mNXFileItems) {
                    String name = file.getNXFile().getName();
                    if (name.toLowerCase().contains(filterStr.toLowerCase())) {
                        temp.add(file);
                    }
                }
            }
            mNXFileItems.clear();
            mNXFileItems.addAll(temp);
            notifyDataChanged();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void showCorrectSubView(View v) {
        mEmptyFolderLayout.setVisibility(View.GONE);
        mNoneRepoLayout.setVisibility(View.GONE);
        mNoneSearchResult.setVisibility(View.GONE);
        mNormalLayout.setVisibility(View.GONE);

        v.setVisibility(View.VISIBLE);
    }

    /**
     * Refresh file list
     * this function control the source list to sorted list
     */
    @Override
    public void notifyDataChanged() {
        if (mSwipeRefreshLayout.isRefreshing()) {
            mSwipeRefreshLayout.setRefreshing(false);
        }

        if (app.getAllCloudServicesOfCurrentUser().size() == 0 || app.getSizeOfLivingRepo() == 0) {
            this.showCorrectSubView(mNoneRepoLayout);
        } else if (mNXFileItems.size() == 0) {
            if (mSearchMode) {
                this.showCorrectSubView(mNoneSearchResult);
            } else {
                this.showCorrectSubView(mEmptyFolderLayout);
            }
        } else {
            this.showCorrectSubView(mNormalLayout);
            mNXFileAdapter.notifyDataSetChanged();
        }
    }

    @Override
    public void showAllRootFiles() {
        mCategoryLayout.setVisibility(View.GONE);
        //clear the node list
        mAllValidNode.clear();
        mAllEmptyRepo.clear();
        //mCategory.setVisibility(View.GONE);
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
                            for (INxFile f : file.getChildren()) {
                                mAllValidNode.add(f);
                            }
                            mNXFileItems.clear();
                            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, FileUtils.translateINxList(mAllValidNode), mActivity));
                            notifyDataChanged();
                        } else {
                            if (errorMsg != null) {
                                if (!errorMsg.equals(ErrorCode.E_IO_NO_NETWORK)) {
                                    hintUpdateFailed(mActivity.getString(R.string.repo_update_failed));
                                } else {
                                    hintUpdateFailed(errorMsg);
                                }
                            }
                        }
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
        mNXFileItems.clear();
        mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, FileUtils.translateINxList(mAllValidNode), mActivity));

        //store to temp List, used to restore data, used in search case.
        mTempNXFileItems.clear();
        mTempNXFileItems.addAll(mNXFileItems);

        notifyDataChanged();
    }

    @Override
    public void showCurrentNodeFiles() throws Exception {
        mNXFileItems.clear();
        mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, FileUtils.translateINxList(app.listWorkingFolder()), mActivity));
        //store to temp List, used to restore data, used in search case.
        mTempNXFileItems.clear();
        mTempNXFileItems.addAll(mNXFileItems);
        notifyDataChanged();
    }

    public void unRegisterEvent() {
        mHomeRightMenuContentObj.setOnFavoriteStatusChanged(null);
        mHomeRightMenuContentObj.setOnOfflineStatusChanged(null);
    }

    private void initData() {
        //mHomeRightMenuContentObj = new HomeRightMenuContent(mActivity);
        mHomeRightMenuContentObj = HomeRightMenuContent.getInstance();
        mAlphaLayout = (FrameLayout) mActivity.findViewById(R.id.home_alpha_view);

        mMainShowLayout = (FrameLayout) mActivity.findViewById(R.id.home_main_files_framelayout);
        //should clear main layout, ensure there is no view in it, not effective but useful and safe.
        mMainShowLayout.removeAllViews();

        mEmptyFolderLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_empty_layout, null);
        mNormalLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_recyclerview_layout, null);
        mNoneRepoLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_nonerepo_layout, null);
        mNoneSearchResult = mActivity.getLayoutInflater().inflate(R.layout.nxfile_nonesearch_layout, null);

        // add 4 sub views first.
        mMainShowLayout.addView(mNormalLayout);
        mMainShowLayout.addView(mNoneRepoLayout);
        mMainShowLayout.addView(mEmptyFolderLayout);
        mMainShowLayout.addView(mNoneSearchResult);

        mNoneRepoLayout.setVisibility(View.GONE);
        mEmptyFolderLayout.setVisibility(View.GONE);
        mNoneSearchResult.setVisibility(View.GONE);

        mSwipeRefreshLayout = (NXSwipeRefreshLayout) mNormalLayout.findViewById(R.id.home_refresh_file_layout);

        mNXFileAdapter = new NXFileRecyclerViewAdapter(mActivity, mNXFileItems);
        mNXFileRecyclerView = (RecyclerView) mNormalLayout.findViewById(R.id.nxfile_recycler_view);
        mNXFileRecyclerView.setLayoutManager(new LinearLayoutManager(mActivity));
        mNXFileRecyclerView.setAdapter(mNXFileAdapter);
        //mNXFileRecyclerView.addItemDecoration(new DividerItemDecoration(mActivity, LinearLayoutManager.VERTICAL));
        mNXFileRecyclerView.addItemDecoration(new DividerItemDecoration(mActivity, null));
        mNXFileRecyclerView.setItemAnimator(new DefaultItemAnimator());
        mNXFileAdapter.notifyDataSetChanged();

        mCategoryLayout = (RelativeLayout) mMainView.findViewById(R.id.home_files_category_layout);
        mCategoryBack = (TextView) mMainView.findViewById(R.id.home_files_back);
        mCategoryName = (TextView) mMainView.findViewById(R.id.home_files_current_category);
        initCategoryStatus();
        //initialize sort context
        mSortContext = new SortContext();
    }

    private void initEvent() {
        fileListItemClickEvent();
        //set refresh color and event.
        mSwipeRefreshLayout.setColorSchemeResources(R.color.main_blue_light, R.color.main_blue_dark);
        mSwipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                mSwipeRefreshLayout.setRefreshing(true);
                try {
                    app.syncWorkingFolder(MainNXFileList.this);
                    mRefreshPath = app.findWorkingFolder().getLocalPath();
                } catch (Exception e) {
                    hintUpdateFailed(e.getMessage());
                    if (mSwipeRefreshLayout.isRefreshing()) {
                        mSwipeRefreshLayout.setRefreshing(false);
                    }
                    e.printStackTrace();
                }
                //test for bug 32758
//                new Handler().postDelayed(new Runnable() {
//                    @Override public void run() {
//                        mSwipeRefreshLayout.setRefreshing(false);
//                    }
//                }, 5000);
            }
        });

        mNXFileRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);
                if (hideKeyboard != null) {
                    hideKeyboard.onHideKeyboard();
                }
            }
        });

        mNXFileAdapter.setOnInfoItemClicked(new NXFileRecyclerViewAdapter.OnInfoItemClicked() {
            @Override
            public void onInfoItemClicked(int position) {
                final INxFile nxfile = mNXFileItems.get(position).getNXFile();
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

        //init favorite event for main home fragment
        mHomeRightMenuContentObj.setOnFavoriteStatusChanged(new RightSlideLayoutHelper.OnFavoriteStatusChanged() {
            @Override
            public void onFavoriteStatusChanged(INxFile nxFile, boolean isChanged) {
                try {
                    showCurrentNodeFiles();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
        //init offline event for main home fragment
        mHomeRightMenuContentObj.setOnOfflineStatusChanged(new RightSlideLayoutHelper.OnOfflineStatusChanged() {
            @Override
            public void onOfflineStatusChanged(INxFile nxFile, boolean isChanged) {
                try {
                    showCurrentNodeFiles();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        //register category back event
        handleCategoryBackEvent();

        mMainView.setFocusableInTouchMode(true);
        mMainView.requestFocus();
        mMainView.setOnKeyListener(new View.OnKeyListener() {
            @Override
            public boolean onKey(View v, int keyCode, KeyEvent event) {
                if (keyCode == KeyEvent.KEYCODE_BACK && event.getAction() == KeyEvent.ACTION_DOWN) {
                    try {
                        if (!app.findWorkingFolder().getLocalPath().equals("/")) {
                            //handle self-back event
                            categoryBackEvent();
                            return true;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                return false;
            }
        });
    }

    private void fileListItemClickEvent() {
        mNXFileAdapter.setOnItemClickListener(new NXFileRecyclerViewAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(View view, int position) {
                INxFile clickFileName = mNXFileItems.get(position).getNXFile();
                if (!clickFileName.isFolder()) {
                    //should remove swipe refresh action.
                    if (mSwipeRefreshLayout.isRefreshing()) {
                        mSwipeRefreshLayout.setRefreshing(false);
                    }
                    Intent intent = new Intent();
                    intent.setAction("NXHomeToView");
                    intent.putExtra("click_file", (NxFileBase) clickFileName);
                    intent.setClass(mActivity, ViewFileActivity.class);
                    mActivity.startActivity(intent);
                } else {
                    try {
                        if (mSwipeRefreshLayout.isRefreshing()) {
                            mSwipeRefreshLayout.setRefreshing(false);
                        }
                        List<INxFile> folderContent = app.listFolder(clickFileName, MainNXFileList.this);
                        if (folderContent != null) {
                            //folder had cached in the local disk.
                            handleCategoryEnterFolder(clickFileName);
                            mNXFileItems.clear();
                            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, FileUtils.translateINxList(folderContent), mActivity));

                            //store to temp List, used to restore data, used in search case.
                            mTempNXFileItems.clear();
                            mTempNXFileItems.addAll(mNXFileItems);

                            notifyDataChanged();
                        } else {
                            mRefreshPath = clickFileName.getLocalPath();
                            //not in cache , use network to download it display waiting UI
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
            if (mCategoryLayout != null) {
                mCategoryLayout.setVisibility(View.GONE);
            }
            e.printStackTrace();
        }
    }

    //set category when enter into folder
    private void handleCategoryEnterFolder(INxFile clickFileName) {
        if (collapseSearchView != null) {
            mSearchMode = false;
            collapseSearchView.onCollapseSearchView();
        }

        if (mSwipeRefreshLayout.isRefreshing()) {
            mSwipeRefreshLayout.setRefreshing(false);
        }
        mRefreshPath = clickFileName.getLocalPath();
        INxFile parent = app.findParent(clickFileName);
        if (parent == null) {
            return;
        }
        //if current clicked file's path is root, then set the category bar as GONE status.
        if (clickFileName.getLocalPath().equals("/")) {
            mCategoryLayout.setVisibility(View.GONE);
            return;
        }
        //if current clicked file's parent file path is root, set the back item "/" as "root"
        //else set the back item as parent's file name..
        mCategoryLayout.setVisibility(View.VISIBLE);
        /**
         * for bug 33050, should change all back text from name to "back" string.
         */
//        if (parent.getLocalPath().equals("/")) {
//            mCategoryBack.setText("root");
//        } else {
//            if (parent.isSite()) {
//                mCategoryBack.setText(parent.getName().substring(1));
//            } else {
//                mCategoryBack.setText(parent.getName());
//            }
//        }
        mCategoryBack.setText(mActivity.getString(R.string.category_back));

        if (clickFileName.isSite()) {
            mCategoryName.setText(clickFileName.getName().substring(1));
        } else {
            mCategoryName.setText(clickFileName.getName());
        }
    }

    private void handleCategoryBackEvent() {
        mCategoryBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                categoryBackEvent();
            }
        });
    }


    private void categoryBackEvent() {
        if (collapseSearchView != null) {
            mSearchMode = false;
            collapseSearchView.onCollapseSearchView();
        }
        if (mSwipeRefreshLayout.isRefreshing()) {
            mSwipeRefreshLayout.setRefreshing(false);
        }
        // for BackButton clicked, return the parent info of current working folder
        INxFile parentNode = app.uptoParent();
        if (parentNode == null) {
            return;
        }
        mRefreshPath = parentNode.getLocalPath();
        //for Root dir, hide category bar.
        if (parentNode.getLocalPath().equals("/")) {
            mCategoryLayout.setVisibility(View.GONE);
        }
        try {
            mNXFileItems.clear();
            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, FileUtils.translateINxList(parentNode.getChildren()), mActivity));

            //store to temp List, used to restore data, used in search case.
            mTempNXFileItems.clear();
            mTempNXFileItems.addAll(mNXFileItems);

            notifyDataChanged();
        } catch (Exception e) {
            Log.e("FileListView view", e.toString());
        }

        /**
         * for bug 33050
         */
//        INxFile parentTemp = app.findParent(parentNode);
//        if (parentTemp.getLocalPath().equals("/")) {
//            mCategoryBack.setText("root");
//        } else {
//            if (parentTemp.isSite()) {
//                mCategoryBack.setText(parentTemp.getName().substring(1));
//            } else {
//                mCategoryBack.setText(parentTemp.getName());
//            }
//        }
        mCategoryBack.setText(mActivity.getString(R.string.category_back));
        if (parentNode.isSite()) {
            mCategoryName.setText(parentNode.getName().substring(1));
        } else {
            mCategoryName.setText(parentNode.getName());
        }
    }

    /**
     * for fired async loading routine, this interface will accept the loading result
     */
    @Override
    public void getFileMetaInfoFinished(boolean taskStatus, INxFile fileSys, String errorMsg) {
        //clear refresh UI circle image
        if (mSwipeRefreshLayout.isRefreshing()) {
            mSwipeRefreshLayout.setRefreshing(false);
        } else {
            //that means refreshing had stop by force. we are not care about the result of the callback any more.
            //clear progressDialog
            if (mProgressDialog != null) {
                mProgressDialog.dismiss();
            } else {
                return;
            }
        }
        try {
            //download successful
            if (taskStatus) {
                //if had left refresh folder the return data would be useless
                if (mRefreshPath != null && !fileSys.getLocalPath().equals(mRefreshPath) || (fileSys.getService().selected == 0)) {
                    return;
                }
                handleCategoryEnterFolder(fileSys);
                mNXFileItems.clear();
                mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(mSortType, FileUtils.translateINxList(fileSys.getChildren()), mActivity));

                //store to temp List, used to restore data, used in search case.
                mTempNXFileItems.clear();
                mTempNXFileItems.addAll(mNXFileItems);

                notifyDataChanged();
            } else {
                //error msg is not used here, seems unnecessary. maybe return errorCode it would be okay.
                if (errorMsg != null) {
                    if (!errorMsg.equals(ErrorCode.E_IO_NO_NETWORK)) {
                        hintUpdateFailed(mActivity.getString(R.string.repo_update_failed));
                    } else {
                        hintUpdateFailed(errorMsg);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void setCollapseSearchViewCallback(ICollapseSearchView listener) {
        collapseSearchView = listener;
    }

    public interface ICollapseSearchView {
        void onCollapseSearchView();
    }

    public interface IHideKeyboard {
        void onHideKeyboard();
    }

    public void setHideKeyboard(IHideKeyboard callback) {
        hideKeyboard = callback;
    }

    private void hintUpdateFailed(final String msg) {
        GenericError.showUI(mActivity, ErrorCode.REPO_UPDATE_FAILED, msg,
                true,
                false,
                false,
                null);
    }

    private void hintUpdateFailed(final int errorCode, final String msg) {
        GenericError.showUI(mActivity, errorCode, msg,
                true,
                false,
                false,
                null);
    }
}

package commonUtils.fileListUtils.nxfileListHelper;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
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
import android.widget.Toast;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.remoteRepo.IRemoteRepo;
import commonMethod.sort.SortContext;
import commonUtils.fileListUtils.DividerItemDecoration;
import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.NXFileItem;
import commonUtils.fileListUtils.NXFileRecyclerViewAdapter;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.HandleNXFavoriteFileBase;
import nxl.types.INxFile;
import nxl.types.NxFileBase;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.HomeRightMenuContent;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.RightSlideLayoutHelper;
import phone.com.nextlabs.viewer.ViewFileActivity;

/**
 * file list class to handle favorite file list.
 */
public class FavoriteNXFileList extends HandleNXFavoriteFileBase implements IRemoteRepo.IGetFileMetaInfoCallback {
    private ViewerApp app = ViewerApp.getInstance();
    private Activity mActivity;

    private RelativeLayout mCategoryLayout;
    private TextView mCategoryBack;
    private TextView mCategoryName;
    private View mFavoriteView;

    private FrameLayout mFavoriteShowLayout;
    //used for enter normal folder case, normal means not empty
    private View mNormalLayout;
    //used for none search result
    private View mNoneSearchResult;
    //used for enter empty folder case
    private View mEmptyFolderLayout;

    private boolean mSearchMode = false;

    private RecyclerView mNXFileRecyclerView;
    private NXFileRecyclerViewAdapter mNXFileAdapter;

    private List<NXFileItem> mNXFileItems = new ArrayList<>();
    private List<NXFileItem> mTempNXFileItems = new ArrayList<>();

    private SortContext mSortContext;
    private SortContext.SortType mSortType = SortContext.SortType.DRIVERTYPE;


    private OnFileFavoriteStatusChanged onFileFavoriteStatusChanged;


    private ProgressDialog mProgressDialog;
    private FrameLayout mAlphaLayout;
    private HomeRightMenuContent mHomeRightMenuContentObj;

    private String mRefreshPath;
    private ICollapseSearchView collapseSearchView;
    private IHideKeyboard hideKeyboard;

    public FavoriteNXFileList(Activity activity, View v) {
        mActivity = activity;
        mFavoriteView = v;
        initData();
        initEvent();
    }

    @Override
    public void setSortType(SortContext.SortType sortType) {
        mSortType = sortType;
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
        mNoneSearchResult.setVisibility(View.GONE);
        mNormalLayout.setVisibility(View.GONE);
        v.setVisibility(View.VISIBLE);
    }

    @Override
    public void notifyDataChanged() {
        if (mNXFileItems.size() == 0) {
            if (mSearchMode) {
                showCorrectSubView(mNoneSearchResult);
            } else {
                showCorrectSubView(mEmptyFolderLayout);
            }
        } else {
            showCorrectSubView(mNormalLayout);
            mNXFileAdapter.notifyDataSetChanged();
        }
    }

    @Override
    public void showAllRootFiles() {
        try {
            mNXFileItems.clear();
            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getFavoriteFiles()), mActivity));

            //store to temp List, used to restore data, used in search case.
            mTempNXFileItems.clear();
            mTempNXFileItems.addAll(mNXFileItems);

            notifyDataChanged();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void showCurrentNodeFiles() throws Exception {
        mNXFileItems.clear();
        if (app.findWorkingFolder().getLocalPath().equals("/")) {
            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getFavoriteFiles()), mActivity));
        } else {
            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.NAMEASCENDING, FileUtils.translateINxList(app.getFavoriteFiles()), mActivity));
        }

        //store to temp List, used to restore data, used in search case.
        mTempNXFileItems.clear();
        mTempNXFileItems.addAll(mNXFileItems);

        notifyDataChanged();
    }

    private void initData() {
        mAlphaLayout = (FrameLayout) mActivity.findViewById(R.id.home_alpha_view);
        //mHomeRightMenuContentObj = new HomeRightMenuContent(mActivity);
        mHomeRightMenuContentObj = HomeRightMenuContent.getInstance();

        mFavoriteShowLayout = (FrameLayout) mActivity.findViewById(R.id.home_favorite_files_framelayout);
        mNormalLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_recyclerview_favorite, null);
        mNoneSearchResult = mActivity.getLayoutInflater().inflate(R.layout.nxfile_nonesearch_layout, null);
        mEmptyFolderLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_empty_layout, null);
        mFavoriteShowLayout.removeAllViews();

        // add 3 sub views first.
        mFavoriteShowLayout.addView(mNormalLayout);
        mFavoriteShowLayout.addView(mEmptyFolderLayout);
        mFavoriteShowLayout.addView(mNoneSearchResult);

        mEmptyFolderLayout.setVisibility(View.GONE);
        mNoneSearchResult.setVisibility(View.GONE);

        mNXFileAdapter = new NXFileRecyclerViewAdapter(mActivity, mNXFileItems);
        mNXFileRecyclerView = (RecyclerView) mNormalLayout.findViewById(R.id.nxfile_recycler_view);
        mNXFileRecyclerView.setLayoutManager(new LinearLayoutManager(mActivity));
        mNXFileRecyclerView.setAdapter(mNXFileAdapter);
        mNXFileRecyclerView.addItemDecoration(new DividerItemDecoration(mActivity, null));
        mNXFileRecyclerView.setItemAnimator(new DefaultItemAnimator());

        mCategoryLayout = (RelativeLayout) mFavoriteView.findViewById(R.id.home_files_category_layout);
        mCategoryBack = (TextView) mFavoriteView.findViewById(R.id.favorite_category_back);
        mCategoryName = (TextView) mFavoriteView.findViewById(R.id.favorite_current_category);

        initCategoryStatus();

        //initialize sort context
        mSortContext = new SortContext();
    }

    private void initEvent() {
        fileListItemClickEvent();

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

        mNXFileRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);
                if (hideKeyboard != null) {
                    hideKeyboard.onHideKeyboard();
                }
            }
        });

        //init favorite event for main home fragment
        mHomeRightMenuContentObj.setOnFavoriteStatusChanged(new RightSlideLayoutHelper.OnFavoriteStatusChanged() {
            @Override
            public void onFavoriteStatusChanged(INxFile nxFile, boolean isChanged) {
                try {
                    onFileFavoriteStatusChanged.onFavoriteStatusChanged(nxFile, isChanged);
                    showCurrentNodeFiles();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

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

        mFavoriteView.setFocusableInTouchMode(true);
        mFavoriteView.requestFocus();
        mFavoriteView.setOnKeyListener(new View.OnKeyListener() {
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

    private void categoryBackEvent() {
        if (collapseSearchView != null) {
            mSearchMode = false;
            collapseSearchView.onCollapseSearchView();
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
            //if the current node is root show favorite root list
            if (parentNode.getLocalPath().equals("/")) {
                mNXFileItems.clear();
                mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getFavoriteFiles()), mActivity));
                //store to temp List, used to restore data, used in search case.
                mTempNXFileItems.clear();
                mTempNXFileItems.addAll(mNXFileItems);
                notifyDataChanged();
            } else {
                mNXFileItems.clear();
                mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.NAMEASCENDING, FileUtils.translateINxList(parentNode.getChildren()), mActivity));
                //store to temp List, used to restore data, used in search case.
                mTempNXFileItems.clear();
                mTempNXFileItems.addAll(mNXFileItems);
                notifyDataChanged();
            }
        } catch (Exception e) {
            Log.e("FileListView view", e.toString());
        }

//        if (parentNode.getLocalPath().equals("/")) {
//            mCategoryBack.setText("root");
//        } else {
//            if (parentNode.isSite()) {
//                mCategoryBack.setText(app.findParent(parentNode).getName().substring(1));
//            } else {
//                mCategoryBack.setText(app.findParent(parentNode).getName());
//            }
//        }
        mCategoryBack.setText(mActivity.getString(R.string.category_back));
        if (parentNode.isSite()) {
            mCategoryName.setText(parentNode.getName().substring(1));
        } else {
            mCategoryName.setText(parentNode.getName());
        }
    }

    private void fileListItemClickEvent() {
        mNXFileAdapter.setOnItemClickListener(new NXFileRecyclerViewAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(View view, int position) {
                INxFile clickFileName = mNXFileItems.get(position).getNXFile();
                if (!clickFileName.isFolder()) {
                    Intent intent = new Intent();
                    intent.setAction("NXHomeToView");
                    intent.putExtra("click_file", (NxFileBase) clickFileName);
                    intent.setClass(mActivity, ViewFileActivity.class);
                    mActivity.startActivity(intent);
                } else {
                    try {
                        List<INxFile> folderContent = app.listFolder(clickFileName, FavoriteNXFileList.this);
                        if (folderContent != null) {
                            //folder had cached in the local disk.
                            handleCategoryEnterFolder(clickFileName);
                            mNXFileItems.clear();
                            mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.NAMEASCENDING, FileUtils.translateINxList(folderContent), mActivity));
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
     * initialize category layout visibility when enter favorite fragment
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
        if (collapseSearchView != null) {
            mSearchMode = false;
            collapseSearchView.onCollapseSearchView();
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
        mCategoryLayout.setVisibility(View.VISIBLE);
        //if current clicked file's parent file path is root, set the back item "/" as "root"
        //else set the back item as parent's file name..
//        mCategoryLayout.setVisibility(View.VISIBLE);
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

    public interface IHideKeyboard {
        void onHideKeyboard();
    }

    public void setHideKeyboard(IHideKeyboard callback) {
        hideKeyboard = callback;
    }

    /**
     * for fired async loading routine, this interface will accept the loading result
     */
    @Override
    public void getFileMetaInfoFinished(boolean taskStatus, INxFile fileSys, String errorMsg) {
        try {
            if (taskStatus) {//download successful
                //if had left refresh folder the return data would be useless
                if (mRefreshPath != null && !fileSys.getLocalPath().equals(mRefreshPath)) {
                    return;
                }

                handleCategoryEnterFolder(fileSys);
                mNXFileItems.clear();
                if (app.findWorkingFolder().getLocalPath().equals("/")) {
                    mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getFavoriteFiles()), mActivity));
                } else {
                    mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.NAMEASCENDING, FileUtils.translateINxList(fileSys.getChildren()), mActivity));
                }
                //mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.NAMEASCENDING, FileUtils.translateINxList(fileSys.getChildren()), mActivity));
                //store to temp List, used to restore data, used in search case.
                mTempNXFileItems.clear();
                mTempNXFileItems.addAll(mNXFileItems);
                notifyDataChanged();
            } else {
                Toast.makeText(mActivity, "Failed:" + errorMsg, Toast.LENGTH_SHORT).show();
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            //clear progressDialog
            if (mProgressDialog != null) {
                mProgressDialog.dismiss();
            }

        }
    }

    @Override
    public void setOnFavoriteStatusChanged(OnFileFavoriteStatusChanged callback) {
        onFileFavoriteStatusChanged = callback;
    }

    public void setCollapseSearchViewCallback(ICollapseSearchView listener) {
        collapseSearchView = listener;
    }

    public interface ICollapseSearchView {
        void onCollapseSearchView();
    }
}

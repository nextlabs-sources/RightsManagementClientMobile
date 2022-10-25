package commonUtils.fileListUtils.nxfileListHelper;

import android.app.Activity;
import android.content.Intent;
import android.support.v7.widget.DefaultItemAnimator;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import commonMethod.sort.SortContext;
import commonUtils.fileListUtils.DividerItemDecoration;
import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.NXFileItem;
import commonUtils.fileListUtils.NXFileRecyclerViewAdapter;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.HandleNXOfflineFileBase;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.IHandleNXFileList;
import nxl.types.INxFile;
import nxl.types.NxFileBase;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.HomeRightMenuContent;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.RightSlideLayoutHelper;
import phone.com.nextlabs.viewer.ViewFileActivity;

/**
 * file list class to handle offline file list.
 */
public class OfflineNXFileList extends HandleNXOfflineFileBase {
    private ViewerApp app = ViewerApp.getInstance();
    private Activity mActivity;
    private View mOfflineView;

    private RecyclerView mNXFileRecyclerView;
    private NXFileRecyclerViewAdapter mNXFileAdapter;

    private SortContext mSortContext;
    private SortContext.SortType mSortType = SortContext.SortType.DRIVERTYPE;

    private List<NXFileItem> mNXFileItems = new ArrayList<>();
    private List<NXFileItem> mTempNXFileItems = new ArrayList<>();

    private FrameLayout mAlphaLayout;
    private HomeRightMenuContent mHomeRightMenuContentObj;

    private FrameLayout mOfflineShowLayout;
    //used for enter normal folder case, normal means not empty
    private View mNormalLayout;
    //used for search mode that result is null.
    private View mNoneSearchResult;
    //used for none search result
    //used for enter empty folder case
    private View mEmptyFolderLayout;

    //used for marking searchMode
    private boolean mSearchMode = false;

    private OnFileOfflineStatusChanged onFileOfflineStatusChanged;


    public OfflineNXFileList(Activity activity, View v) {
        mActivity = activity;
        mOfflineView = v;
        initData();
        initEvent();
    }

//    @Override
//    public void setOnFavoriteStatusChanged(OnFileFavoriteStatusChanged callback){
//
//    }


    @Override
    public void setOnOfflineStatusChanged(OnFileOfflineStatusChanged callback) {
        onFileOfflineStatusChanged = callback;
    }

    @Override
    public void closeRightMenu() {
        if (mHomeRightMenuContentObj.isShow()) {
            mHomeRightMenuContentObj.toggleRightMenu(null);
        }
    }

    private void initData() {
        mAlphaLayout = (FrameLayout) mActivity.findViewById(R.id.home_alpha_view);
        //mHomeRightMenuContentObj = new HomeRightMenuContent(mActivity);
        mHomeRightMenuContentObj = HomeRightMenuContent.getInstance();

        mOfflineShowLayout = (FrameLayout) mActivity.findViewById(R.id.home_offline_files_framelayout);
        mNormalLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_recyclerview_offline, null);
        mEmptyFolderLayout = mActivity.getLayoutInflater().inflate(R.layout.nxfile_empty_layout, null);
        mNoneSearchResult = mActivity.getLayoutInflater().inflate(R.layout.nxfile_nonesearch_layout, null);

        mOfflineShowLayout.removeAllViews();
        mOfflineShowLayout.addView(mNormalLayout);

        //initial file recycler view
        mNXFileRecyclerView = (RecyclerView) mOfflineView.findViewById(R.id.nxfile_recycler_view);
        mNXFileAdapter = new NXFileRecyclerViewAdapter(mActivity, mNXFileItems);
        mNXFileRecyclerView.setLayoutManager(new LinearLayoutManager(mActivity));
        mNXFileRecyclerView.setAdapter(mNXFileAdapter);
        //mNXFileRecyclerView.addItemDecoration(new DividerItemDecoration(mActivity, LinearLayoutManager.VERTICAL));
        mNXFileRecyclerView.addItemDecoration(new DividerItemDecoration(mActivity, null));
        mNXFileRecyclerView.setItemAnimator(new DefaultItemAnimator());

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
        //init favorite event for main home fragment
        mHomeRightMenuContentObj.setOnOfflineStatusChanged(new RightSlideLayoutHelper.OnOfflineStatusChanged() {
            @Override
            public void onOfflineStatusChanged(INxFile nxFile, boolean isChanged) {
                try {
                    onFileOfflineStatusChanged.onOfflineStatusChanged(nxFile, isChanged);
                    showCurrentNodeFiles();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

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
    }

    /**
     * Offline files list only have one node, so just invoke this.
     */
    @Override
    public void showAllRootFiles() {
        mNXFileItems.clear();
        mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getOfflineFiles()), mActivity));

        //store to temp List, used to restore data, used in search case.
        mTempNXFileItems.clear();
        mTempNXFileItems.addAll(mNXFileItems);
        notifyDataChanged();
    }

    /**
     * This interface could ignore. offline files only have one node
     *
     * @throws Exception exception
     */
    @Override
    public void showCurrentNodeFiles() throws Exception {
        mNXFileItems.clear();
        mNXFileItems.addAll(mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getOfflineFiles()), mActivity));

        //store to temp List, used to restore data, used in search case.
        mTempNXFileItems.clear();
        mTempNXFileItems.addAll(mNXFileItems);
        notifyDataChanged();
    }

    /**
     * handle file list item click event
     * for offline file list only have file exclude folder.
     */
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
                }
            }
        });
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

    @Override
    public void notifyDataChanged() {
        mOfflineShowLayout.removeAllViews();
        if (mNXFileItems.size() == 0) {
            if (mSearchMode) {
                mOfflineShowLayout.addView(mNoneSearchResult);
            } else {
                mOfflineShowLayout.addView(mEmptyFolderLayout);
            }
        } else {
            mOfflineShowLayout.addView(mNormalLayout);
            mNXFileAdapter.notifyDataSetChanged();
        }
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
}

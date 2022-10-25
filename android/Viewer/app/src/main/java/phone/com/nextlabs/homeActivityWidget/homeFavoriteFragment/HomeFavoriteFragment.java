package phone.com.nextlabs.homeActivityWidget.homeFavoriteFragment;

import android.app.Activity;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.imageableList.NXFileListView;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.localRepo.sort.SortContext;
import nxl.types.INxFile;
import phone.com.nextlabs.homeActivityWidget.FileListView;
import phone.com.nextlabs.homeActivityWidget.layoutHelper.HomeLeftMenuView;

/**
 * favorite fragment for favorite
 */
public class HomeFavoriteFragment extends Fragment {
    private final static String TAG = "HomeFavoriteFragment";

    private ViewerApp app = ViewerApp.getInstance();

    private Activity mHomeActivity;
    private HomeLeftMenuView mLeftMenuView;

    private ImageButton mBack2Home;
    private TextView mTitleName;
    private TextView mDriveInfo;
    private OnBack2MainView onBack2MainView;
    private RelativeLayout mCategoryView;
    private View mMainView;

    private FileListView mFileListViewObj;
    private boolean disableRefresh = true;

    private SortContext mSortContext;
    private List<INxFile> mFavoriteDocs = new ArrayList<>();

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        //communicate with activity
        mHomeActivity = getActivity();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.home_favorite_fragment, null);
        mMainView = view;
        initView(view);
        return view;
    }

    private void initView(View view) {
        mBack2Home = (ImageButton) view.findViewById(R.id.home_normal_title_back);
        mTitleName = (TextView) view.findViewById(R.id.home_normal_title_name);
        mCategoryView = (RelativeLayout) view.findViewById(R.id.favorite_category);
        mLeftMenuView = (HomeLeftMenuView) mHomeActivity.findViewById(R.id.home_leftmenu_view);
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initData();
        initEvent();
    }

    private void initData() {
        mTitleName.setText(mHomeActivity.getString(R.string.favorite_title_name));
        mFavoriteDocs.clear();
        mFavoriteDocs.addAll(app.getFavoriteFiles());
        mSortContext = new SortContext();
        mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, mFavoriteDocs, mHomeActivity);

        mDriveInfo = (TextView) mHomeActivity.findViewById(R.id.favorite_service_count);
        try {
            mDriveInfo.setText("All Favorite " + mSortContext.onGetServiceCount() + " drives, " + mFavoriteDocs.size() + " items");
        } catch (Exception e) {
            mDriveInfo.setText("All Favorite 0 drives, " + mFavoriteDocs.size() + " items");
            e.printStackTrace();
        }

        mFileListViewObj = new FileListView(mHomeActivity, R.id.favorite_nxfile_list, mCategoryView);
        mFileListViewObj.setSortType(SortContext.SortType.DRIVERTYPE);
        mFileListViewObj.updateFileList(mFavoriteDocs);
        mFileListViewObj.setOnFavoriteStatusChanged(new FileListView.OnFileFavoriteStatusChanged() {
            @Override
            public void onFavoriteStatusChanged(INxFile node, boolean isMarked) {
                if (isMarked) {
                    mFavoriteDocs.add(node);
                } else {
                    mFavoriteDocs.remove(node);
                }

                try {
                    mDriveInfo.setText("All Favorite " + mSortContext.onGetServiceCount() + " drives, " + mFavoriteDocs.size() + " items");
                } catch (Exception e) {
                    mDriveInfo.setText("All Favorite 0 drives, " + mFavoriteDocs.size() + " items");
                    e.printStackTrace();
                }

                mFileListViewObj.updateFileList(mFavoriteDocs);
            }
        });
    }

    private void initEvent() {
        mBack2Home.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onBack2MainView.onBack2MainView();
            }
        });
        NXFileListView fileListView = mFileListViewObj.getFileListView();
        //support list view touch event
        fileListView.setOnParentViewClicked(new NXFileListView.OnParentViewClicked() {
            @Override
            public boolean onParentViewClicked(MotionEvent ev) {
                return mLeftMenuView.IsMenuShown();
            }
        });

        //disable pull refresh
        fileListView.setOnChangeRefresh(new NXFileListView.OnChangeRefresh() {
            @Override
            public boolean onChangeRefresh() {
                return !disableRefresh;
            }
        });

        mFileListViewObj.setOnCategoryChanged(new FileListView.OnCategoryChanged() {
            @Override
            public void onCategoryChanged(boolean isEnterRoot) {
                disableRefresh = isEnterRoot;
                if (isEnterRoot) {
                    mDriveInfo.setVisibility(View.VISIBLE);
                } else {
                    mDriveInfo.setVisibility(View.GONE);
                }
            }
        });

        mFileListViewObj.setSortNXFileArrayCallBack(new FileListView.IGetSortNXFileArray() {
            @Override
            public List<INxFile> onGetNXFileArray(List<INxFile> files) {
                return mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, files, mHomeActivity);
            }
        });

        mFileListViewObj.setOnGetChildList(new FileListView.IOnGetChildList() {
            @Override
            public List<INxFile> onGetChildList(INxFile parentNode) {
                if (parentNode.getLocalPath().equals("/")) {
                    return app.getFavoriteFiles();
                }
                return parentNode.getChildren();
            }
        });

        mMainView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mLeftMenuView.IsMenuShown()) {
                    mLeftMenuView.closeMenu();
                }
            }
        });
    }

    public void setOnBack2MainView(OnBack2MainView onBack2MainView) {
        this.onBack2MainView = onBack2MainView;
    }

    public interface OnBack2MainView {
        void onBack2MainView();
    }
}


package phone.com.nextlabs.homeActivityWidget.homeOfflineFragment;

import android.app.Activity;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
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

;

/**
 * Created by eric on 11/13/2015.
 */
public class HomeOfflineFragment extends Fragment {
    private final static String TAG = "HomeOfflineFragment";

    private ViewerApp app = ViewerApp.getInstance();

    private Activity mHomeActivity;

    private ImageButton mBack2Home;
    private TextView mTitleName;
    private TextView mDriveInfo;
    private OnBack2MainView onBack2MainView;
    private View mMainView;

    private FileListView mFileListViewObj;
    private HomeLeftMenuView mLeftMenuView;
    private SortContext mSortContext;

    private List<INxFile> mOfflineSortedDocs = new ArrayList<INxFile>();

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        //communicate with activity
        mHomeActivity = getActivity();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.home_offline_fragment, null);
        mMainView = view;
        initView(view);
        return view;
    }

    private void initView(View view) {
        mBack2Home = (ImageButton) view.findViewById(R.id.home_normal_title_back);
        mTitleName = (TextView) view.findViewById(R.id.home_normal_title_name);
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initData();
        initEvent();
    }

    private void initData() {
        mLeftMenuView = (HomeLeftMenuView) mHomeActivity.findViewById(R.id.home_leftmenu_view);
        mTitleName.setText(mHomeActivity.getString(R.string.offline_title_name));
        mOfflineSortedDocs.clear();
        mOfflineSortedDocs.addAll(app.getOfflineFiles());
        mSortContext = new SortContext();
        mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, mOfflineSortedDocs, mHomeActivity);

        mDriveInfo = (TextView) mHomeActivity.findViewById(R.id.offline_service_count);
        try {
            mDriveInfo.setText("All Offline " + mSortContext.onGetServiceCount() + " drives, " + mOfflineSortedDocs.size() + " items");
        } catch (Exception e) {
            mDriveInfo.setText("All Favorite 0 drives, " + mOfflineSortedDocs.size() + " items");
            e.printStackTrace();
        }


        mFileListViewObj = new FileListView(mHomeActivity, R.id.offline_nxfile_list, null);
        mFileListViewObj.setSortType(SortContext.SortType.DRIVERTYPE);
        mFileListViewObj.updateFileList(mOfflineSortedDocs);
        mFileListViewObj.setOnOfflineStatusChanged(new FileListView.OnFileOfflineStatusChanged() {
            @Override
            public void onOfflineStatusChanged(INxFile node, boolean isMarked) {
                if (isMarked) {
                    mOfflineSortedDocs.add(node);
                } else {
                    mOfflineSortedDocs.remove(node);
                }

                try {
                    mDriveInfo.setText("All Offline " + mSortContext.onGetServiceCount() + " drives, " + mOfflineSortedDocs.size() + " items");
                } catch (Exception e) {
                    mDriveInfo.setText("All Favorite 0 drives, " + mOfflineSortedDocs.size() + " items");
                    e.printStackTrace();
                }

                mFileListViewObj.updateFileList(mOfflineSortedDocs);
            }
        });
    }


    private void initEvent() {
        mBack2Home.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onBack2MainView.onBack2MainView();
                ;
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
                return false;
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

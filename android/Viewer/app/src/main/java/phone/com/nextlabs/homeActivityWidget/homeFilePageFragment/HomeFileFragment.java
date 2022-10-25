package phone.com.nextlabs.homeActivityWidget.homeFilePageFragment;

import android.app.Activity;
import android.app.Dialog;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;

import com.google.android.gms.common.GooglePlayServicesUtil;
import com.nextlabs.viewer.R;

import java.util.List;

import appInstance.ViewerApp;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import database.BoundService;
import phone.com.nextlabs.homeActivityWidget.layoutHelper.HomeLeftMenuView;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.HomeLeftMenuContent;


public class HomeFileFragment extends Fragment
        implements GoogleDriveSdk.IShowErrorDialog {
    // private HomeActivity mHomeActivity;
    private ImageButton mLeftMenuBtn;

    private HomeLeftMenuView mLeftMenuView;
    private View mMainView;

    private ViewerApp app = ViewerApp.getInstance();

    private FrameLayout mMainShowLayout;
    private View mPull2RefreshListView;
    private View mNullRepository;
    private View mSelectedRepository;

    private HomeListView mHomeListViewObj;
    private HomeEmptyView mHomeEmptyViewObj;

    private HomeLeftMenuContent mLeftMenuContentObj;

    private IResumeEvent mResumeEventCallback;
    private IPauseEvent mPauseEventCallback;

    @Override
    public void onAttach(Activity activity) {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.home_filelist_fragment, null);
        mMainView = view;
        initView(view);
        return view;
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initData();
        initEvent();
    }

    @Override
    public void onResume() {
        super.onResume();
        //start a thread to refresh UI.
        if (mResumeEventCallback != null) {
            mResumeEventCallback.onResumeEvent();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        // we must to stop mHandlerBackgroundUpdater
        if (mPauseEventCallback != null) {
            mPauseEventCallback.onPauseEvent();
        }
    }

    private void initView(View view) {
        mLeftMenuBtn = (ImageButton) view.findViewById(R.id.home_title_bar_menu_btn);

        mMainShowLayout = (FrameLayout) view.findViewById(R.id.home_show_layout);
        //mNullRepository = mHomeActivity.getLayoutInflater().inflate(R.layout.home_file_empty_view, null);
        //mPull2RefreshListView = mHomeActivity.getLayoutInflater().inflate(R.layout.pullto_refresh_listview, null);
    }

    private void initData() {
        GoogleDriveSdk.setIShowErrorDialog(this);
        //GoogleDriveSdk.setContext(mHomeActivity);

        //mLeftMenuView = (HomeLeftMenuView) mHomeActivity.findViewById(R.id.home_leftmenu_view);

        List<BoundService> bsList = app.getAllCloudServicesOfCurrentUser();
        mMainShowLayout.removeAllViews();
        if (bsList.isEmpty()) {
            mMainShowLayout.addView(mNullRepository);
            //mHomeEmptyViewObj = new HomeEmptyView(mHomeActivity, mNullRepository);
            mHomeListViewObj = null; //should release old object
        } else {
            mMainShowLayout.addView(mPull2RefreshListView);
            //mHomeListViewObj = new HomeListView(mHomeActivity, mPull2RefreshListView, this);
            mHomeListViewObj.setGetLeftMenuStatus(new HomeListView.IGetLeftMenuStatus() {
                @Override
                public boolean onGetLeftMenuStatusFinished() {
                    return mLeftMenuView.IsMenuShown();
                }
            });
        }


    }


    private void initEvent() {
        mLeftMenuBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mLeftMenuView.openMenu();
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

    @Override
    public void showGooglePlayServicesAvailabilityErrorDialog(final int connectionStatusCode) {
//        //mHomeActivity.runOnUiThread(new Runnable() {
//            @Override
//            public void run() {
//                Dialog dialog = GooglePlayServicesUtil.getErrorDialog(
//                        connectionStatusCode,
//                        //mHomeActivity,
//                        GoogleDriveSdk.REQUEST_GOOGLE_PLAY_SERVICES);
////                if (mFileListViewObj.getFileListViewProgressDialog() != null){
////                    mFileListViewObj.getFileListViewProgressDialog().dismiss();
////                }
//                dialog.show();
//            }
//        });
    }

    /**
     * set callback for resume event callback
     *
     * @param callback IResumeEvent
     */
    public void setResumeEventCallback(IResumeEvent callback) {
        mResumeEventCallback = callback;
    }

    /**
     * set callback for pause event callback
     *
     * @param callback IPauseEvent
     */
    public void setPauseEventCallback(IPauseEvent callback) {
        mPauseEventCallback = callback;
    }

    /**
     * dispatch resume event
     */
    public interface IResumeEvent {
        void onResumeEvent();
    }

    /**
     * dispatch pause event
     */
    public interface IPauseEvent {
        void onPauseEvent();
    }
}

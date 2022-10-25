package phone.com.nextlabs.homeActivityWidget.rightSlideMenu;

import android.app.Activity;
import android.content.Context;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import nxl.types.INxFile;

/**
 * main class handle right menu
 */
public class HomeRightMenuContent {
    RelativeLayout.LayoutParams mMenuParams;
    private Activity mActivity;
    private RelativeLayout mRightMenu;
    private boolean isShow;
    private TranslateAnimation mShowAnimation;
    private TranslateAnimation mHideAnimation;
    private FrameLayout mAlphaLayout;

    private RightSlideLayoutHelper mRightSlideLayoutHelperObj;
    private ScrollView mRightScrollView;

    private static HomeRightMenuContent mInstance = new HomeRightMenuContent();

    public static HomeRightMenuContent getInstance() {
        return mInstance;
    }

    private HomeRightMenuContent() {

    }

    @Deprecated
    private HomeRightMenuContent(Activity activity) {
        mActivity = activity;
        initData();
    }

    public void initialize(Activity activity) {
        mActivity = activity;
        initData();
    }

    private void initData() {
        mRightSlideLayoutHelperObj = new RightSlideLayoutHelper(mActivity);
        mAlphaLayout = (FrameLayout) mActivity.findViewById(R.id.home_alpha_view);
        mRightMenu = (RelativeLayout) mActivity.findViewById(R.id.home_rightslide_layout);
        mRightMenu.setVisibility(View.GONE);
        mRightScrollView = (ScrollView) mActivity.findViewById(R.id.home_rightslide_scrollview);

        isShow = false;
        mMenuParams = (RelativeLayout.LayoutParams) mRightMenu.getLayoutParams();
        WindowManager windowManager = (WindowManager) mActivity.getSystemService(Context.WINDOW_SERVICE);
        DisplayMetrics outMetrics = new DisplayMetrics();
        windowManager.getDefaultDisplay().getMetrics(outMetrics);
        mMenuParams.width = outMetrics.widthPixels * 2 / 3;    // Ensures constant width of content during menu sliding
        mRightMenu.setLayoutParams(mMenuParams);

        initRightMenuAnim();

        TextView btn = (TextView) mActivity.findViewById(R.id.home_rightslide_show);
        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mAlphaLayout.setVisibility(View.GONE);
                isShow = false;
                mRightMenu.startAnimation(mHideAnimation);
                mRightMenu.setVisibility(View.GONE);
            }
        });

        mRightMenu.setOnTouchListener(new OnRightSlideTouchListener(mActivity) {
            public void onSwipeRight() {
                //just close the menu
                toggleRightMenu(null);
            }
        });

        mRightScrollView.setOnTouchListener(new OnRightSlideTouchListener(mActivity) {
            public void onSwipeRight() {
                toggleRightMenu(null);
            }
        });
    }

    public void setOnOfflineStatusChanged(RightSlideLayoutHelper.OnOfflineStatusChanged callback) {
        mRightSlideLayoutHelperObj.setOnOfflineStatusChanged(callback);
    }

    public void setOnFavoriteStatusChanged(RightSlideLayoutHelper.OnFavoriteStatusChanged callback) {
        mRightSlideLayoutHelperObj.setOnFavoriteStatusChanged(callback);
    }

    public void toggleRightMenu(INxFile nxfile) {
        if (!isShow) {
            isShow = true;
            mRightMenu.startAnimation(mShowAnimation);
            mRightMenu.setVisibility(View.VISIBLE);
            mAlphaLayout.setVisibility(View.VISIBLE);
            mRightSlideLayoutHelperObj.showRightMenu(nxfile);

        } else {
            isShow = false;
            mRightMenu.startAnimation(mHideAnimation);
            mRightMenu.setVisibility(View.GONE);
            mAlphaLayout.setVisibility(View.GONE);
        }
    }

    public boolean isShow() {
        return isShow;
    }

    private void initRightMenuAnim() {
        mShowAnimation = new TranslateAnimation(Animation.RELATIVE_TO_SELF,
                1.0f, Animation.RELATIVE_TO_SELF, 0.0f,
                Animation.RELATIVE_TO_SELF, 0.0f, Animation.RELATIVE_TO_SELF,
                0.0f);
        mHideAnimation = new TranslateAnimation(Animation.RELATIVE_TO_SELF,
                0.0f, Animation.RELATIVE_TO_SELF, 1.0f,
                Animation.RELATIVE_TO_SELF, 0.0f, Animation.RELATIVE_TO_SELF,
                0.0f);
        mShowAnimation.setDuration(400);
        mHideAnimation.setDuration(400);
    }
}

package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.DisplayMetrics;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ViewFlipper;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import appInstance.ViewerApp;
import commonUtils.ScrollViewEx;

public class WelcomeActivity extends Activity implements GestureDetector.OnGestureListener {

    private static final String TAG = "WelcomeActivity";
    private static int SIGN = 17;

    private static final int LINEDOT_MARGIN_RATIO = 5;
    private static final int IMAGE_MARGIN_RATIO = 12;
    private static final int TEXTVIEW_MARGIN_RATIO = 16;
    LinearLayout mLinearLayout;
    private ViewFlipper flipper;
    private GestureDetector detector;
    private ArrayList<View> dots;
    private boolean isFlip = false;
    private int oldPosition = 0;


    private int mScreenWidth;
    private int mScreenHeight;
    private ImageView mWelcomePageImage;
    private ImageView mArrowRight;
    private TextView mSignIn;
    private TextView mTvInformation1;
    private TextView mTvInformation2;
    private Timer mTimer;
    private TimerTask mTimerTask;
    private List<ScrollViewEx> mScrollViewExList = new ArrayList<>();
    private View.OnClickListener listener = new View.OnClickListener() {

        @Override
        public void onClick(View view) {
            switchToLogin();
        }
    };


    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.activity_welcome);

        // gesture slide
        detector = new GestureDetector(this, this);
        flipper = (ViewFlipper) this.findViewById(R.id.Viewflipper);

        // get the width and height of screen.
        DisplayMetrics dm = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(dm);
        mScreenWidth = dm.widthPixels;
        mScreenHeight = dm.heightPixels;

        // display the dots
        dots = new ArrayList<>();
        dots.add(findViewById(R.id.dot_0));
        dots.add(findViewById(R.id.dot_1));
        dots.add(findViewById(R.id.dot_2));
        dots.add(findViewById(R.id.dot_3));

        flipper.addView(addView(R.layout.welc_1, R.id.scrollView1));
        flipper.addView(addView(R.layout.welc_2, R.id.scrollView2));
        flipper.addView(addView(R.layout.welc_3, R.id.scrollView3));
        flipper.addView(addView(R.layout.welc_4, R.id.scrollView4));

        for (ScrollViewEx scrollViewEx : mScrollViewExList) {
            scrollViewEx.setGestureDetector(detector);
        }


        final Handler handler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                super.handleMessage(msg);
                if (msg.what == SIGN) {
                    leftSlidShow();
                }
            }
        };


        mTimer = new Timer();
        mTimerTask = new TimerTask() {
            @Override
            public void run() {
                Message msg = new Message();
                msg.what = SIGN;
                if (!isFlip) {
                    handler.sendMessage(msg);
                }
            }
        };
        long DELAY = 4000; // 4s
        long PERIOD = 4000;
        mTimer.schedule(mTimerTask, DELAY, PERIOD);


        mArrowRight = (ImageView) findViewById(R.id.welcome_arrow);
        mArrowRight.setOnClickListener(listener);
        mSignIn = (TextView) findViewById(R.id.button_login);
        mSignIn.setOnClickListener(listener);
    }

    private void switchToLogin() {

        ViewerApp.getInstance().setWelcomeHadShowed();

//        Intent intent = new Intent();
//        intent.setAction("From_WelcomeActivity");
//        intent.setClass(WelcomeActivity.this, NewLoginActivity.class);
//        startActivity(intent);

        WelcomeActivity.this.finish();
        overridePendingTransition(R.anim.in_from_right, R.anim.out_to_left);
    }

    private View addView(int layout, int scrollView) {
        LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View view = inflater.inflate(layout, null);
        ScrollViewEx scrollViewEx = (ScrollViewEx) view.findViewById(scrollView);
        mScrollViewExList.add(scrollViewEx);

        // welcome page1
        mWelcomePageImage = (ImageView) view.findViewById(R.id.welcomPage1_image);
        setControlMargin(mWelcomePageImage, IMAGE_MARGIN_RATIO);
        mTvInformation1 = (TextView) view.findViewById(R.id.welcome_page1_textview1);
        setControlMargin(mTvInformation1, TEXTVIEW_MARGIN_RATIO);
        mTvInformation2 = (TextView) view.findViewById(R.id.welcome_page1_textview3);
        setControlMargin(mTvInformation2, TEXTVIEW_MARGIN_RATIO);

        // welcome page2
        mWelcomePageImage = (ImageView) view.findViewById(R.id.welcomPage2_image);
        setControlMargin(mWelcomePageImage, IMAGE_MARGIN_RATIO);
        mTvInformation1 = (TextView) view.findViewById(R.id.welcome_page2_textview1);
        setControlMargin(mTvInformation1, TEXTVIEW_MARGIN_RATIO);
        mTvInformation2 = (TextView) view.findViewById(R.id.welcome_page2_textview3);
        setControlMargin(mTvInformation2, TEXTVIEW_MARGIN_RATIO);

        // welcome page3
        mWelcomePageImage = (ImageView) view.findViewById(R.id.welcomPage3_image);
        setControlMargin(mWelcomePageImage, IMAGE_MARGIN_RATIO);
        mTvInformation1 = (TextView) view.findViewById(R.id.welcome_page3_textview1);
        setControlMargin(mTvInformation1, TEXTVIEW_MARGIN_RATIO);
        mTvInformation2 = (TextView) view.findViewById(R.id.welcome_page3_textview3);
        setControlMargin(mTvInformation2, TEXTVIEW_MARGIN_RATIO);

        // welcome page4
        mWelcomePageImage = (ImageView) view.findViewById(R.id.welcomPage4_image);
        setControlMargin(mWelcomePageImage, IMAGE_MARGIN_RATIO);
        mTvInformation1 = (TextView) view.findViewById(R.id.welcome_page4_textview1);
        setControlMargin(mTvInformation1, TEXTVIEW_MARGIN_RATIO);
        mTvInformation2 = (TextView) view.findViewById(R.id.welcome_page4_textview2);
        setControlMargin(mTvInformation2, TEXTVIEW_MARGIN_RATIO);

        // line dots
        mLinearLayout = (LinearLayout) findViewById(R.id.linearLayout_dot);
        setControlMargin(mLinearLayout, LINEDOT_MARGIN_RATIO);
        return view;
    }

    private void setControlMargin(Object object, int ratio) {
        RelativeLayout.LayoutParams lp = null;
        if (object instanceof ImageView) {
            lp = (RelativeLayout.LayoutParams) ((ImageView) object).getLayoutParams();
            lp.width = mScreenWidth / 2;
            lp.height = mScreenHeight / 4;
            lp.setMargins(0, mScreenHeight / ratio, 0, 0);
            ((ImageView) object).setLayoutParams(lp);
        } else if (object instanceof TextView) {
            lp = (RelativeLayout.LayoutParams) ((TextView) object).getLayoutParams();
            lp.setMargins(0, mScreenHeight / ratio, 0, 0);
            ((TextView) object).setLayoutParams(lp);
        } else if (object instanceof LinearLayout) {
            lp = (RelativeLayout.LayoutParams) ((LinearLayout) object).getLayoutParams();
            lp.setMargins(0, 0, 0, mScreenHeight / ratio);
            ((LinearLayout) object).setLayoutParams(lp);
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return this.detector.onTouchEvent(event);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mTimer != null) {
            mTimer.cancel();
            mTimer = null;
        }

        if (mTimerTask != null) {
            mTimerTask.cancel();
            mTimerTask = null;
        }
    }

    public boolean onDown(MotionEvent arg0) {
        return false;
    }

    /**
     * 用户按下触摸屏，快速移动后松开，由1个MotionEvent ACTION_DOWN,多个ACTION_MOVE,1个ACTION_UP触发
     * e1:第1个ACTION_DOWN MotionEvent
     * e2:最后一个ACTION_MOVE MotionEvent
     * velocityX:X轴上的移动速度，像素/秒
     * velocityY:Y轴上的移动速度，像素/秒
     * 触发条件：X轴的坐标位移大于FLING_MIN_DISTANCE,且移动速度大于FLING_MIN_VELOCITY个像素/秒
     */
    public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {

        isFlip = true;
        if (e1.getX() - e2.getX() > 120) {
            // Fling left
            leftSlidShow();
            return true;
        } else if (e1.getX() - e2.getX() < -120) {
            // set dot
            if (oldPosition - 1 >= 0) {
                // Fling right
                this.flipper.setInAnimation(AnimationUtils.loadAnimation(this, R.anim.push_right_in));
                this.flipper.setOutAnimation(AnimationUtils.loadAnimation(this, R.anim.push_right_out));
                this.flipper.showPrevious();

                dots.get(oldPosition--).setBackgroundResource(R.drawable.dot_normal);
            }

            return true;
        }
        return false;
    }

    private void leftSlidShow() {
        this.flipper.setInAnimation(AnimationUtils.loadAnimation(this, R.anim.push_left_in));
        this.flipper.setOutAnimation(AnimationUtils.loadAnimation(this, R.anim.push_left_out));
        this.flipper.showNext();

        // set dot
        if (oldPosition + 1 < dots.size()) {
            dots.get(++oldPosition).setBackgroundResource(R.drawable.dot_focused);
        } else {
            switchToLogin();
        }
    }

    public void onLongPress(MotionEvent e) {
    }

    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
        return false;
    }

    public void onShowPress(MotionEvent e) {
    }

    public boolean onSingleTapUp(MotionEvent e) {
        return false;
    }
}

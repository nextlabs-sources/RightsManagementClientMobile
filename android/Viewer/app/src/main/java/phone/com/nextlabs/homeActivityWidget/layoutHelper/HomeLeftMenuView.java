package phone.com.nextlabs.homeActivityWidget.layoutHelper;

import android.content.Context;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.MotionEvent;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;

public class HomeLeftMenuView extends HorizontalScrollView {
    // linear layout for scroll view
    private LinearLayout mLinearLayout;
    // left menu
    private ViewGroup mMenuView;
    // main menu
    private ViewGroup mMainView;
    //left slide width
    private int mMenuWidth;
    // screen width
    private int mScreenWidth;
    // main layout With the screen edge distance
    private int mMenuPaddingRight = 100;
    // only enter measure once
    private boolean mIsOnce = false;
    private boolean mIsShown = false;
    private float xDistance, yDistance, lastX, lastY;

    private boolean isScrollStop = false;
    private Context mContext;

    public HomeLeftMenuView(Context context, AttributeSet attrs) {
        super(context, attrs);

        mContext = context;
    }

    public int getMenuWidth() {
        return mMenuWidth;
    }

    public boolean IsMenuShown() {
        return mIsShown;
    }

    public void openMenu() {
        if (mIsShown)
            return;
        this.smoothScrollTo(0, 0);
        mIsShown = true;
    }

    public void closeMenu() {
        if (mIsShown) {
            this.smoothScrollTo(mMenuWidth, 0);
            mIsShown = false;
        }
    }

    public void setIsOnce(boolean isOnce) {
        mIsOnce = isOnce;
    }

    public void stopScroll(boolean stop) {
        isScrollStop = stop;
    }

    //set the slide menu height and weight, setting it every time once enter onMeasure
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        //only enter once
        if (!mIsOnce) {
            // get screen width
            WindowManager windowManager = (WindowManager) mContext
                    .getSystemService(Context.WINDOW_SERVICE);
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getMetrics(outMetrics);
            mScreenWidth = outMetrics.widthPixels;
            // translate dp to px
            mMenuPaddingRight = (int) TypedValue.applyDimension(
                    TypedValue.COMPLEX_UNIT_DIP, 100, mContext.getResources()
                            .getDisplayMetrics());

            // this means scrollview elements
            mLinearLayout = (LinearLayout) this.getChildAt(0);
            mMenuView = (ViewGroup) mLinearLayout.getChildAt(0); // the first element in layout
            mMainView = (ViewGroup) mLinearLayout.getChildAt(1);
            //setting the slide menu width. screenwidth - rightpadding
            mMenuWidth = mMenuView.getLayoutParams().width = mScreenWidth - mMenuPaddingRight;

            mMainView.getLayoutParams().width = mScreenWidth;
            mIsOnce = true;
        }
    }


    //set the view position
    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        super.onLayout(changed, l, t, r, b);
        if (changed) {
            //set the main layout in the center, hidden slide menu
            this.scrollTo(mMenuWidth, 0);
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent ev) {
        int action = ev.getAction();
        switch (action) {
            case MotionEvent.ACTION_UP:
                //get the current position of menus
                int scrollX = this.getScrollX();
                if (scrollX >= mMenuWidth / 3) {
                    this.smoothScrollTo(mMenuWidth, 0);
                } else {
                    this.smoothScrollTo(0, 0);
                }
                return true;
        }
        return super.onTouchEvent(ev);
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent ev) {
        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                xDistance = yDistance = 0f;
                lastX = ev.getX();
                lastY = ev.getY();

                break;
            case MotionEvent.ACTION_MOVE:
                final float curX = ev.getX();
                final float curY = ev.getY();
                xDistance += Math.abs(curX - lastX);
                yDistance += Math.abs(curY - lastY);
                lastX = curX;
                lastY = curY;
                if (xDistance < yDistance && !canScrollVertically(1)) {
                    return false;
                }
        }
        if (isScrollStop) {
            return false;
        }

        return super.onInterceptTouchEvent(ev);
    }


    @Override
    protected void onScrollChanged(int l, int t, int oldl, int oldt) {
        super.onScrollChanged(l, t, oldl, oldt);
        float scale = l * 1.0f / mMenuWidth; // 1 ~ 0
        float rightScaleX = 0.7f + 0.3f * scale;
        float rightScaleY = 0.7f + 0.3f * scale;
        float leftScaleX = 1.0f - scale * 0.3f;
        float leftScaleY = 1.0f - scale * 0.3f;
        float leftAlpha = 0.6f + 0.4f * (1 - scale);
        float rightAlpha = 1.0f - 0.6f * (1 - scale);

        mMenuView.setAlpha(leftAlpha);
        mMenuView.setScaleX(leftScaleX);
        mMenuView.setScaleY(leftScaleY);
        mMenuView.setTranslationX(mMenuWidth * scale * 0.6f);
        mMainView.setPivotX(0);
        mMainView.setPivotY(mMainView.getHeight() / 2);
        mMainView.setScaleX(rightScaleX);
        mMainView.setScaleY(rightScaleY);
        mMainView.setAlpha(rightAlpha);
        mIsShown = this.getScrollX() == 0;
    }
}

package com.widgets;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Path;
import android.graphics.Point;
import android.graphics.PointF;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.ShapeDrawable;
import android.graphics.drawable.shapes.PathShape;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.animation.AnimationUtils;
import android.widget.ListView;
import android.widget.PopupWindow;

import com.imageableList.NXSelect;
import com.imageableList.NXSelectPopAdapter;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

/**
 * ListView with popup style background (has triangle on top or bottom).
 * The anchor triangle  will show accurately below or above the anchor position.
 */
@SuppressLint("DrawAllocation")
public class PopupListView extends ListView {
    private static final String TAG = "PopupListView";
    /**
     * x of anchor triangle in the popup
     */
    private float mTriangleX;
    /**
     * border color
     */
    private int mBorderColor = 0xffffffff;
    /**
     * border width
     */
    private int mBorderWidth = 2;
    /**
     * background color
     */
    private int mBgColor = 0xFFFFFFFF;
    /**
     * background color in dark mode
     */
    private int mBgColorDark = 0xffe3e3e3;
    /**
     * anchor height
     */
    private float mAnchorHeight = 30;
    /**
     * anchor width
     */
    private float mAnchorWidth = 40;
    /**
     * If content under anchor
     */
    private boolean mShowDown = true;
    /**
     * Below items for draw
     */
    private ShapeDrawable mBorderDrawable;
    private Path mBorderPath;
    private ShapeDrawable mBgDrawable;
    private Path mBgPath;
    private int mWidth;
    private int mHeight;
    /**
     * Keep a record of original padding.
     */
    private int mPadding;
    /**
     * Is night mode.
     */
    private boolean mIsNightMode;
    /**
     * anchor x, y in screen
     */
    private int mAnchorYUp;
    private int mAnchorYDown;
    private int mAnchorX;

    /**
     * screen height & width
     */
    private int mScreenHeight;
    private int mScreenWidth;
    private float mDensity;
    private PopupWindow mPopupWindow;

    private List<NXSelect> mSelectList = new ArrayList<NXSelect>();
    private Context mContext;
    private Activity mActivity;
    private View mViewBg = null;
    private NXSelectPopAdapter mAdapter;
    private boolean mIsWindowSizeChanged = false;

    public PopupListView(Context context) {
        super(context);
        setFocusable(true);
        init(context);
    }

    public PopupListView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init(context);
    }

    public PopupListView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public void init(Context context) {
        mContext = context;
        mActivity = (Activity) mContext;
        mPadding = getPaddingBottom();
        DisplayMetrics dm = context.getResources().getDisplayMetrics();
        mScreenHeight = dm.heightPixels;
        mScreenWidth = dm.widthPixels;
        mDensity = dm.scaledDensity;

        mPopupWindow = new PopupWindow(this, 400, LayoutParams.WRAP_CONTENT);
        mPopupWindow.setFocusable(true);
        mPopupWindow.setTouchable(true);
        mPopupWindow.setAnimationStyle(R.style.Animations_PopUpMenu_Right);
        ColorDrawable dw = new ColorDrawable(0000000000);
        mPopupWindow.setBackgroundDrawable(dw);

        mPopupWindow.setOnDismissListener(new PopupWindow.OnDismissListener() {
            @Override
            public void onDismiss() {
                if (!mIsWindowSizeChanged && mViewBg != null) {
                    mViewBg.startAnimation(AnimationUtils.loadAnimation(mContext,
                            R.anim.anim_popupwindow_exist));
                    mViewBg.setVisibility(View.GONE);
                }
            }
        });

    }

    public void showPopupWindow(View v, View viewBg, int barHeight) {
        mViewBg = viewBg;
        createPopupWindow((int) (v.getY()), (int) (v.getY() + barHeight + v.getHeight()), (int) (v.getX() + v.getWidth() / 2));
    }

    private void createPopupWindow(int anchorYUp, int anchorYDown, int anchorX) {
        setAnchorYUp(anchorYUp);
        setAnchorYDown(anchorYDown);
        setAnchorX(anchorX);
        mAdapter = new NXSelectPopAdapter(mContext, R.layout.select_popup_item, getSelectList());
        setAdapter(mAdapter);
        show();
    }

    public PopupWindow getPopupWindow() {
        return mPopupWindow;
    }

    public List<NXSelect> getSelectList() {
        return mSelectList;
    }

    public void initSelectList() {
        mSelectList.clear();
        String[] popupString = mContext.getResources().getStringArray(R.array.select_display);
        mSelectList.add(new NXSelect(R.drawable.protect_icon, popupString[0]));
        mSelectList.add(new NXSelect(R.drawable.property_icon, popupString[1]));
        mSelectList.add(new NXSelect(R.drawable.share_icon, popupString[2]));
    }

    /**
     * Show as pop up window
     */
    public void show() {
        if (mPopupWindow != null) {
            mPopupWindow.dismiss();
        }

        Log.d(TAG, "mAnchorX=" + mAnchorX + " mWidth=" + mWidth + " mHeight=" + mHeight);

        if (mWidth <= 0 || mHeight <= 0) {
            // The first time we show the pop up window out of the screen to get the size of itself.
            mPopupWindow.showAtLocation(this, Gravity.LEFT | Gravity.TOP, mScreenWidth,
                    mScreenHeight);
        } else {
            // The second time we calculate the pop up window's right position.
            Point pos = getLayoutValue();
            mTriangleX = mAnchorX - pos.x;
            mPopupWindow.showAtLocation(this, Gravity.LEFT | Gravity.TOP, pos.x, pos.y);
        }
        mIsWindowSizeChanged = false;
    }

    /**
     * Calculate the pop up window's right position.
     *
     * @return
     */
    private Point getLayoutValue() {
        int x = mAnchorX - mWidth / 2;
        if (x < 10 * mDensity) {
            x = (int) (10 * mDensity);
        } else if (x + mWidth > mScreenWidth - 10 * mDensity) {
            x = (int) (mScreenWidth - mWidth - 10 * mDensity);
        }
        boolean showDown = mAnchorYDown + mHeight < mScreenHeight || mAnchorYDown <= mScreenHeight / 2;
        setShowDown(showDown);
        int y = showDown ? mAnchorYDown : mAnchorYUp - mHeight;
        return new Point(x, y);
    }

    /**
     * Init drawble path.
     *
     * @param width
     * @param height
     */
    private void initPath(int width, int height) {
        mBorderPath = new Path();
        mBgPath = new Path();

        if (mShowDown) {
            /**
             *    |<----------------width-------->|
             *    |<--archorX--->|
             *                                2
             *                               /\ (anchor)
             *     0/7-------------1   3-----------4           ----
             *     |                                            |            |
             *     |                                            |           height
             *     |                                            |            |
             *     6----------------------------- ----5           ---
             */
            PointF[] borderPoints = new PointF[]{new PointF(0, mAnchorHeight),
                    new PointF(mTriangleX - mAnchorWidth / 2, mAnchorHeight),
                    new PointF(mTriangleX, 0),
                    new PointF(mTriangleX + mAnchorWidth / 2, mAnchorHeight),
                    new PointF(width, mAnchorHeight),
                    new PointF(width, height),
                    new PointF(0, height),
                    new PointF(0, mAnchorHeight),
            };
            mBorderPath = createLIneToPath(borderPoints);

            PointF[] bgPoints = new PointF[]{new PointF(borderPoints[0].x + mBorderWidth, borderPoints[0].y + mBorderWidth),
                    new PointF(borderPoints[1].x + mBorderWidth, borderPoints[1].y + mBorderWidth),
                    new PointF(borderPoints[2].x, borderPoints[2].y + mBorderWidth),
                    new PointF(borderPoints[3].x - mBorderWidth, borderPoints[3].y + mBorderWidth),
                    new PointF(borderPoints[4].x - mBorderWidth, borderPoints[4].y + mBorderWidth),
                    new PointF(borderPoints[5].x - mBorderWidth, borderPoints[5].y - mBorderWidth),
                    new PointF(borderPoints[6].x + mBorderWidth, borderPoints[6].y - mBorderWidth),
                    new PointF(borderPoints[7].x + mBorderWidth, borderPoints[7].y + mBorderWidth),
            };
            mBgPath = createLIneToPath(bgPoints);
        } else {
            /**
             * 0/7------------------------------1
             * |                                            |
             * |                                            |
             * 6-----------------5   3----------2
             *                           \/
             *                           4
             */
            PointF[] borderPoints = new PointF[]{new PointF(0, 0),
                    new PointF(width, 0),
                    new PointF(width, height - mAnchorHeight),
                    new PointF(mTriangleX + mAnchorWidth / 2, height - mAnchorHeight),
                    new PointF(mTriangleX, height),
                    new PointF(mTriangleX - mAnchorWidth / 2, height - mAnchorHeight),
                    new PointF(0, height - mAnchorHeight),
                    new PointF(0, 0),
            };
            mBorderPath = createLIneToPath(borderPoints);

            PointF[] bgPoints = new PointF[]{new PointF(borderPoints[0].x + mBorderWidth, borderPoints[0].y + mBorderWidth),
                    new PointF(borderPoints[1].x - mBorderWidth, borderPoints[1].y + mBorderWidth),
                    new PointF(borderPoints[2].x - mBorderWidth, borderPoints[2].y - mBorderWidth),
                    new PointF(borderPoints[3].x - mBorderWidth, borderPoints[3].y - mBorderWidth),
                    new PointF(borderPoints[4].x, borderPoints[4].y - mBorderWidth),
                    new PointF(borderPoints[5].x + mBorderWidth, borderPoints[5].y - mBorderWidth),
                    new PointF(borderPoints[6].x + mBorderWidth, borderPoints[6].y - mBorderWidth),
                    new PointF(borderPoints[7].x + mBorderWidth, borderPoints[7].y + mBorderWidth),
            };
            mBgPath = createLIneToPath(bgPoints);
        }
    }

    private Path createLIneToPath(PointF[] points) {
        Path path = new Path();
        if (points != null && points.length > 1) {
            path.moveTo(points[0].x, points[0].y);
            for (int i = 1; i < points.length; i++) {
                path.lineTo(points[i].x, points[i].y);
            }
        }
        path.close();
        return path;
    }

    public void setAnchorYUp(int mAnchorYUp) {
        this.mAnchorYUp = mAnchorYUp;
    }

    public void setAnchorYDown(int mAnchorYDown) {
        this.mAnchorYDown = mAnchorYDown;
    }

    public void setAnchorX(int anchorX) {
        this.mAnchorX = anchorX;
    }

    public void setShowDown(boolean showDown) {
        mShowDown = showDown;
        if (mShowDown) {
            setPadding(getPaddingLeft(), (int) mAnchorHeight + mPadding, getPaddingRight(), mPadding);
        } else {
            setPadding(getPaddingLeft(), mPadding, getPaddingRight(), (int) mAnchorHeight + mPadding);
        }
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        Log.d(TAG, "w=" + w + " h=" + h + " oldw=" + oldw + " oldh=" + oldh);
        mWidth = w;
        mHeight = h;
        mIsWindowSizeChanged = true;
        show();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        initPath(mWidth, mHeight);
        mBorderDrawable = new ShapeDrawable(new PathShape(mBorderPath, mWidth, mHeight));
        mBorderDrawable.getPaint().setColor(mBorderColor);
        mBgDrawable = new ShapeDrawable(new PathShape(mBgPath, mWidth, mHeight));
        int bgColor = mBgColor;
        if (mIsNightMode) {
            bgColor = mBgColorDark;
        }
        mBgDrawable.getPaint().setColor(bgColor);

        int x = 0;
        int y = 0;
        mBorderDrawable.setBounds(x, y, x + mWidth, y + mHeight);
        mBorderDrawable.draw(canvas);
        mBgDrawable.setBounds(x, y, x + mWidth, y + mHeight);
        mBgDrawable.draw(canvas);
        super.onDraw(canvas);
    }
}


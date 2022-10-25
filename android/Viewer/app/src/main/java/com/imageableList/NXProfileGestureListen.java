package com.imageableList;

import android.util.Log;
import android.view.GestureDetector;
import android.view.MotionEvent;

/**
 * Created by snowman on 7/23/2015.
 */
public class NXProfileGestureListen extends GestureDetector.SimpleOnGestureListener {

    private static final String TAG = "MyGestureListener";
    private final int MIN_X_DISTANCE = 200;
    private final int MIN_Y_DISTANCE = 300;

    private MoveCallback mMoveCallback;

    public NXProfileGestureListen(MoveCallback callback) {
        mMoveCallback = callback;
    }

    /**
     * 双击的第二下Touch down时触发
     *
     * @param e
     * @return
     */
    @Override
    public boolean onDoubleTap(MotionEvent e) {
        return super.onDoubleTap(e);
    }

    /**
     * 双击的第二下 down和up都会触发，可用e.getAction()区分。
     *
     * @param e
     * @return
     */
    @Override
    public boolean onDoubleTapEvent(MotionEvent e) {
        return super.onDoubleTapEvent(e);
    }

    /**
     * down时触发
     *
     * @param e
     * @return
     */
    @Override
    public boolean onDown(MotionEvent e) {
        return super.onDown(e);
    }

    /**
     * Touch了滑动一点距离后，up时触发。
     *
     * @param e1
     * @param e2
     * @param velocityX
     * @param velocityY
     * @return
     */
    @Override
    public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX,
                           float velocityY) {
        Log.e(TAG, "onFling e1 : " + e1.getAction() + ", e2 : " + e2.getAction() + ", distanceX : " + velocityX + ", distanceY : " + velocityY);
        float minVelocity = 0; //最小滑动速度

        if (e1.getX() - e2.getX() > MIN_X_DISTANCE && Math.abs(e1.getY() - e2.getY()) < MIN_Y_DISTANCE && Math.abs(velocityX) > minVelocity) {
            mMoveCallback.JumpTo(true);
        } else if (e2.getX() - e1.getX() > MIN_X_DISTANCE && Math.abs(e1.getY() - e2.getY()) < MIN_Y_DISTANCE && Math.abs(velocityX) > minVelocity) {
            mMoveCallback.JumpTo(false);
        }

        return super.onFling(e1, e2, velocityX, velocityY);
    }

    /**
     * Touch了不移动一直 down时触发
     *
     * @param e
     */
    @Override
    public void onLongPress(MotionEvent e) {
        super.onLongPress(e);
    }

    /**
     * Touch了滑动时触发。
     *
     * @param e1
     * @param e2
     * @param distanceX
     * @param distanceY
     * @return
     */
    @Override
    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX,
                            float distanceY) {
        return super.onScroll(e1, e2, distanceX, distanceY);
    }

    /**
     * Touch了还没有滑动时触发
     *
     * @param e
     */
    @Override
    public void onShowPress(MotionEvent e) {
        super.onShowPress(e);
    }

    @Override
    public boolean onSingleTapConfirmed(MotionEvent e) {
        return super.onSingleTapConfirmed(e);
    }

    @Override
    public boolean onSingleTapUp(MotionEvent e) {
        return super.onSingleTapUp(e);
    }

    public interface MoveCallback {
        void JumpTo(boolean way);
    }

}

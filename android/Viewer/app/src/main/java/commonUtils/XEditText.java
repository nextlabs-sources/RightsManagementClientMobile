package commonUtils;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;

/**
 * extend the EditText which can response the event of DrawableLeft and DrawableRight.
 * should set setDrawableListener first if be able to response click event.
 */
public class XEditText extends EditText implements View.OnFocusChangeListener {

    final int DRAWABLE_LEFT = 0;
    final int DRAWABLE_TOP = 1;
    final int DRAWABLE_RIGHT = 2;
    final int DRAWABLE_BOTTOM = 3;
    /**
     * the reference of cancel button
     */
    public Drawable mClearDrawable;
    /**
     * judge if have focus
     */
    private boolean hasFoucs;
    private DrawableLeftListener mLeftListener;
    private DrawableRightListener mRightListener;

    public XEditText(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public XEditText(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public XEditText(Context context) {
        super(context);
    }

    public void init() {
        // get the drawRight of EditText.
        mClearDrawable = getCompoundDrawables()[2];
        //  can set the width and height of image. eg:  mClearDrawable.getIntrinsicWidth(), mClearDrawable.getIntrinsicHeight()
        mClearDrawable.setBounds(0, 0, 54, 54);
        // set image hidden default.
        setClearIconVisible(false);
        // set focus change listener
        setOnFocusChangeListener(this);

        // handler that click right drawable
        setDrawableRightListener(new DrawableRightListener() {
            @Override
            public void onDrawableRightClick(View view) {
                setText("");
                setError(null);
            }
        });

    }

    /**
     * set the image hidden and visible by judge the length of string when the focus of XEditText changed.
     */
    @Override
    public void onFocusChange(View v, boolean hasFocus) {
        this.hasFoucs = hasFocus;

        if (hasFocus) {
            setClearIconVisible(getText().length() > 0);
        } else {
            setClearIconVisible(false);
        }

    }

    /**
     * set the image hidden and visible，call setCompoundDrawables to draw for EditText.
     *
     * @param visible
     */
    protected void setClearIconVisible(boolean visible) {
        Drawable right = visible ? mClearDrawable : null;
        setCompoundDrawablesWithIntrinsicBounds(getCompoundDrawables()[0], getCompoundDrawables()[1], right, getCompoundDrawables()[3]);
    }

    /**
     * the method will recall when the editText text changed.
     */
    @Override
    public void onTextChanged(CharSequence s, int start, int count, int after) {
        if (hasFoucs) {
            setClearIconVisible(s.length() > 0);
        }
    }

    public void setDrawableLeftListener(DrawableLeftListener listener) {
        this.mLeftListener = listener;
    }

    public void setDrawableRightListener(DrawableRightListener listener) {
        this.mRightListener = listener;
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public boolean onTouchEvent(MotionEvent event) {
        switch (event.getAction()) {
            case MotionEvent.ACTION_UP:
                if (mRightListener != null) {
                    Drawable drawableRight = getCompoundDrawables()[DRAWABLE_RIGHT];
                    if (drawableRight != null && event.getRawX() >= (getRight() - drawableRight.getBounds().width())) {
                        mRightListener.onDrawableRightClick(this);
                        return true;
                    }
                }

                if (mLeftListener != null) {
                    Drawable drawableLeft = getCompoundDrawables()[DRAWABLE_LEFT];
                    if (drawableLeft != null && event.getRawX() <= (getLeft() + drawableLeft.getBounds().width())) {
                        mLeftListener.onDrawableLeftClick(this);
                        return true;
                    }
                }
                break;
        }

        return super.onTouchEvent(event);
    }

    public interface DrawableLeftListener {
        public void onDrawableLeftClick(View view);
    }

    public interface DrawableRightListener {
        public void onDrawableRightClick(View view);
    }
}


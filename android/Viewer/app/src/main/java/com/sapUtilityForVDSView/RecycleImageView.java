package com.sapUtilityForVDSView;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.widget.ImageView;

/**
 * recycleImageView
 */
public class RecycleImageView extends ImageView {

    private int co;
    private int borderwidth;

    public RecycleImageView(Context context) {
        super(context);
    }

    public RecycleImageView(Context context, AttributeSet attrs,
                            int defStyle) {
        super(context, attrs, defStyle);
    }

    public RecycleImageView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public void setColor(int color) {
        co = color;
    }

    public void setBorderWidth(int width) {

        borderwidth = width;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        Rect rec = canvas.getClipBounds();
        rec.bottom--;
        rec.right--;
        Paint paint = new Paint();
        paint.setColor(co);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeWidth(borderwidth);
        canvas.drawRect(rec, paint);
    }
}
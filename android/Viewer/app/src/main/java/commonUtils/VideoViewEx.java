package commonUtils;


import android.content.Context;
import android.util.AttributeSet;
import android.widget.VideoView;

public class VideoViewEx extends VideoView {

    public VideoViewEx(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    public VideoViewEx(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public VideoViewEx(Context context) {
        super(context);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {

        int width = getDefaultSize(0, widthMeasureSpec);
        int height = getDefaultSize(0, heightMeasureSpec);
        setMeasuredDimension(width, height);
    }

}
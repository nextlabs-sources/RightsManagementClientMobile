package commonUtils;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.MediaController;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.lang.reflect.Field;

// extends the MediaController that adds a button about controlling full screen display or not.
public class MediaControllerEx extends MediaController {
    private View mView;
    private Activity mActivity;

    public MediaControllerEx(Activity activity) {
        super(activity);
        mActivity = activity;
    }

    @Override
    public void setAnchorView(View view) {
        super.setAnchorView(view);

        mView = (View) LayoutInflater.from(mActivity).inflate(R.layout.video_fullscreen_button, null);
        try {
            Field mTextViewField = android.widget.MediaController.class.getDeclaredField("mEndTime");
            mTextViewField.setAccessible(true);
            TextView tv_time = (TextView) mTextViewField.get(this);
            ViewGroup parent = (ViewGroup) tv_time.getParent();
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
            parent.addView(mView, lp);

        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    public ImageView getImageView() {
        return (ImageView) mView.findViewById(R.id.imageView_fullscreen);
    }
}

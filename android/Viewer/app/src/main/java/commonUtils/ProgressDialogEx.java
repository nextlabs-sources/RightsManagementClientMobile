package commonUtils;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.lang.reflect.Field;

public class ProgressDialogEx extends ProgressDialog {
    public ProgressDialogEx(Context context) {
        super(context);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        init();
    }

    private void init() {
        try {
            Field mtv_ProgressNumberField = ProgressDialog.class.getDeclaredField("mProgressNumber");
            mtv_ProgressNumberField.setAccessible(true);
            TextView tv_ProgressNumber = (TextView) mtv_ProgressNumberField.get(this);
            tv_ProgressNumber.setVisibility(View.INVISIBLE);

            Field mtv_ProgressPercentField = ProgressDialog.class.getDeclaredField("mProgressPercent");
            mtv_ProgressPercentField.setAccessible(true);
            TextView tv_ProgressPercent = (TextView) mtv_ProgressPercentField.get(this);

            RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) tv_ProgressPercent.getLayoutParams();
            lp.removeRule(RelativeLayout.ALIGN_PARENT_START);
            lp.addRule(RelativeLayout.CENTER_HORIZONTAL, RelativeLayout.TRUE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

package commonUtils.dialog;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import com.nextlabs.viewer.R;

/**
 * a dialog class to hint user to verify whether clean cache or not.
 * it would show user the cache size.
 */
public class CleanCacheDialog extends Dialog {
    private Context context;
    private View mMainLayout;
    private View mChildLayout;
    private TextView mSureView;
    private TextView mCancelView;

    private IOnCertainToClean onCertainToClean;

    public CleanCacheDialog(Context context) {
        super(context, R.style.ShareDialog);
        this.context = context;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.dialog_clean_cache);
        initData();
        initEvent();
    }

    // test code for basic feature
    public void setSizeOfCachedFiles(long size) {
        TextView fileSize = (TextView) findViewById(R.id.tv_cache_content);
        double KB = size / 1000.0;
        fileSize.setText(fileSize.getText() + " " + KB + "KB");
    }

    private void initData() {
        mMainLayout = findViewById(R.id.ly_clean_cache);
        mChildLayout = findViewById(R.id.ly_clean_cache_child);
        mSureView = (TextView) findViewById(R.id.btn_sure);
        mCancelView = (TextView) findViewById(R.id.btn_cancel);
    }

    private void initEvent() {
        mMainLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
        mChildLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
        mSureView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (onCertainToClean != null) {
                    onCertainToClean.onFinish();
                    dismiss();
                }
            }
        });
        mCancelView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
    }

    /**
     * set the callback function which to clean cache
     *
     * @param callback callback function
     */
    public void setOnCertainToCleanCallback(IOnCertainToClean callback) {
        this.onCertainToClean = callback;
    }


    /**
     * callback function to clean cache
     */
    public interface IOnCertainToClean {
        void onFinish();
    }

    //it is best to obtain folder cache size from file-system interface.
    //for now there is no certain interface for this requirement.
//    private long getFolderSize(File file){
//        long size = 0;
//        try {
//            java.io.File[] fileList = file.listFiles();
//            for(File fileObject : fileList){
//                if (fileObject.isDirectory()){
//                    size = size + getFolderSize(fileObject);
//                }else{
//                    size = size + fileObject.length();
//                }
//            }
//        } catch (Exception e) {
//            // TODO Auto-generated catch block
//            e.printStackTrace();
//        }
//        return size;
//    }
}

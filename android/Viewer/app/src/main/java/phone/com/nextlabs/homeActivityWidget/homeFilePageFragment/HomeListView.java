package phone.com.nextlabs.homeActivityWidget.homeFilePageFragment;

import android.content.Context;
import android.os.Handler;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ImageButton;
import android.widget.RelativeLayout;

import com.imageableList.NXFileListView;
import com.nextlabs.viewer.R;

import java.util.List;

import appInstance.ViewerApp;
import appInstance.localRepo.sort.SortContext;
import nxl.types.INxFile;
import phone.com.nextlabs.homeActivityWidget.FileListView;
import phone.com.nextlabs.homeActivityWidget.SearchEditText;


public class HomeListView {
    private final static String TAG = "HomeFileFragment";

    //private HomeActivity mHomeActivity;
    private View view;

    private RelativeLayout mCategoryView;
    private FileListView mFileListViewObj;
    private ImageButton mSortBtn;
    private ImageButton mSearch;
    private ImageButton mSearchExit;
    private RelativeLayout mSearchTitleRelative;
    private RelativeLayout mNormalTitleRelative;
    private SearchEditText mSearchEditText;

    private SortContext mSortContext;

    private SortContext.SortType mSortType = SortContext.SortType.NAMEASCENDING;

    private ViewerApp app = ViewerApp.getInstance();
    private IGetLeftMenuStatus leftMenuStatusCallback;

    private int TIME = 20000;
    private Handler mHandlerBackgroundUpdater;
    private Runnable mRunnable = null;

    private HomeFileFragment mHomeFileFragment;


    public void setGetLeftMenuStatus(IGetLeftMenuStatus callback) {
        this.leftMenuStatusCallback = callback;
    }

    public interface IGetLeftMenuStatus {
        boolean onGetLeftMenuStatusFinished();
    }
}

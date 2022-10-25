package phone.com.nextlabs.homeActivityWidget.homeHelpFragment;

import android.app.Activity;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import phone.com.nextlabs.homeActivityWidget.layoutHelper.HomeLeftMenuView;

public class HomeHelpFragment extends Fragment {
    private final static String TAG = "HomeHelpFragment";

    private ViewerApp app = ViewerApp.getInstance();

    private Activity mHomeActivity;

    private TextView mTitleName;
    private ImageButton mBack2Home;
    private OnBack2MainView onBack2MainView;

    private View mMainView;
    private HomeLeftMenuView mLeftMenuView;

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        //communicate with activity
        mHomeActivity = getActivity();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.home_help_fragment, null);
        mMainView = view;
        initView(view);
        return view;
    }

    private void initView(View view) {
        mBack2Home = (ImageButton) view.findViewById(R.id.home_normal_title_back);
        mTitleName = (TextView) view.findViewById(R.id.home_normal_title_name);
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initData();
        initEvent();
    }

    private void initData() {
        mTitleName.setText(mHomeActivity.getString(R.string.help_title));
        mLeftMenuView = (HomeLeftMenuView) mHomeActivity.findViewById(R.id.home_leftmenu_view);
    }


    private void initEvent() {
        mBack2Home.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onBack2MainView.onBack2MainView();
                ;
            }
        });

        mMainView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mLeftMenuView.IsMenuShown()) {
                    mLeftMenuView.closeMenu();
                }
            }
        });
    }

    public void setOnBack2MainView(OnBack2MainView onBack2MainView) {
        this.onBack2MainView = onBack2MainView;
    }

    public interface OnBack2MainView {
        void onBack2MainView();
    }
}


package phone.com.nextlabs.homeActivityHelper.profile;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;


public class HomeProfileFragment extends Fragment {
    private final static String TAG = "HomeProfileFragment";
    private ViewerApp app = ViewerApp.getInstance();
    //private View mMainView;
    //private Activity mHomeActivity;
    private RelativeLayout mProfile_settings_layout;
    private RelativeLayout mProfile_account_layout;
    private RelativeLayout mProfile_help_layout;
    private RelativeLayout mProfile_signoff_layout;


    private ProFileEvents mDispatch;


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_home_profile, container, false);
        //mMainView = view;
        //mHomeActivity = getActivity();
        mDispatch = (ProFileEvents) getActivity();
        initView(view);
        return view;
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initEvent();
    }

    public interface ProFileEvents {
        void onClickSettings();

        void onClickAccounts();

        void onClickHelp();

        void onClickSignOff();
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    private void initView(View view) {
        mProfile_settings_layout = (RelativeLayout) view.findViewById(R.id.profile_settings_layout);
        mProfile_account_layout = (RelativeLayout) view.findViewById(R.id.profile_account_layout);
        mProfile_help_layout = (RelativeLayout) view.findViewById(R.id.profile_help_layout);
        mProfile_signoff_layout = (RelativeLayout) view.findViewById(R.id.profile_signoff_layout);
    }

    private void initEvent() {
        mProfile_settings_layout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mDispatch.onClickSettings();
            }
        });

        mProfile_account_layout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mDispatch.onClickAccounts();
            }
        });

        mProfile_help_layout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mDispatch.onClickHelp();
            }
        });

        mProfile_signoff_layout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mDispatch.onClickSignOff();
            }
        });
    }

}

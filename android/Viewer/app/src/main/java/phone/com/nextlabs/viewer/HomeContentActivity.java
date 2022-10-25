package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.NavigationView;
import android.support.design.widget.Snackbar;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.common.GooglePlayServicesUtil;
import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import errorHandler.ErrorCode;
import errorHandler.GenericError;
import phone.com.nextlabs.homeActivityHelper.favorite.HomeFavoriteFragment;
import phone.com.nextlabs.homeActivityHelper.home.HomeFilesFragment;
import phone.com.nextlabs.homeActivityHelper.offline.HomeOfflineFragment;
import phone.com.nextlabs.homeActivityHelper.profile.HomeProfileFragment;
import phone.com.nextlabs.homeActivityWidget.rightSlideMenu.HomeRightMenuContent;


public class HomeContentActivity
        extends AppCompatActivity
        implements GoogleDriveSdk.IShowErrorDialog,
        HomeProfileFragment.ProFileEvents {
    static private final int MSG_FAILED_SESSION_RECOVERY = 0x1001;
    static private final int MSG_USER_LOGINED = 0x1002;
    //private static String TAG = HomeContentActivity.class.getSimpleName();
    static public final int REQUSE_CODE_LOGIN = 0xF001;
    private DrawerLayout mDrawerLayout;
    private Toolbar mToolbar;
    private FloatingActionButton mFloatingActionButton;
    private NavigationView mNavigationView;

    private int mMenuId;
    private int mPreviousMenuId = -1;  // -1 for not selected

    private ViewerApp app = ViewerApp.getInstance();

    private final Handler mHandle = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_FAILED_SESSION_RECOVERY:
                    startActivityForResult(
                            new Intent(HomeContentActivity.this, NewLoginActivity.class),
                            REQUSE_CODE_LOGIN);
                    return true;
                case MSG_USER_LOGINED:
                    onUserLogin();
                default:
            }
            return false;
        }

    });


    private TextView userName;
    private TextView email;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home_content_main);
        HomeRightMenuContent.getInstance().initialize(HomeContentActivity.this);
        // Init Left-NavView, AppToolBar, FloatingActionBar
        mDrawerLayout = (DrawerLayout) findViewById(R.id.home_content_activity_layout);
        mDrawerLayout.setDrawerListener(new DrawerLayout.DrawerListener() {
            @Override
            public void onDrawerSlide(View view, float v) {
            }

            @Override
            public void onDrawerOpened(View view) {
                mMenuId = -1;
            }

            @Override
            public void onDrawerClosed(View view) {
                displayView(mMenuId);
            }

            @Override
            public void onDrawerStateChanged(int i) {

            }
        });
        // will be used for set title for different fragments
        mToolbar = (Toolbar) findViewById(R.id.home_toolbar);
        mFloatingActionButton = (FloatingActionButton) findViewById(R.id.home_floating_button);

        // Get refs to LeftNav's username and email
        userName = (TextView) findViewById(R.id.home_account_username);
        email = (TextView) findViewById(R.id.home_account_email);
        updateUserInfo("Welcome", "Nextlabs");

        //
        // config actionbar
        //
        View title_shadow = findViewById(R.id.home_title_shadow);
        if (android.os.Build.VERSION.SDK_INT >= 21) {
            title_shadow.setVisibility(View.GONE);
        } else {
            title_shadow.setVisibility(View.VISIBLE);
        }
        setSupportActionBar(mToolbar);
        getSupportActionBar().setElevation(0);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setHomeButtonEnabled(true);
        ActionBarDrawerToggle actionBarDrawerToggle = new ActionBarDrawerToggle(this, mDrawerLayout, mToolbar, R.string.home_left_nav_open, R.string.home_left_nav_close);
        actionBarDrawerToggle.syncState();

        //
        // config NavigationView
        //
        mNavigationView = (NavigationView) findViewById(R.id.home_left_navigationview);
        mNavigationView.setNavigationItemSelectedListener(new NavigationView.OnNavigationItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(final MenuItem menuItem) {
                String msgString = "";
                if (mPreviousMenuId != menuItem.getItemId()) {
                    switch (menuItem.getItemId()) {
                        case R.id.left_nav_main:
                            mPreviousMenuId = R.id.left_nav_main;
                            mMenuId = R.id.left_nav_main;
                            msgString = getString(R.string.title_nextlabs);
                            mToolbar.setSubtitle("");
                            mFloatingActionButton.setVisibility(View.VISIBLE);
                            break;
                        case R.id.left_nav_favorite:
                            mPreviousMenuId = R.id.left_nav_favorite;
                            mMenuId = R.id.left_nav_favorite;
                            msgString = (String) menuItem.getTitle();
                            mFloatingActionButton.setVisibility(View.GONE);
                            break;
                        case R.id.left_nav_offline:
                            mPreviousMenuId = R.id.left_nav_offline;
                            mMenuId = R.id.left_nav_offline;
                            msgString = (String) menuItem.getTitle();
                            mFloatingActionButton.setVisibility(View.GONE);
                            break;
                        case R.id.left_nav_profile:
                            mPreviousMenuId = R.id.left_nav_profile;
                            mMenuId = R.id.left_nav_profile;
                            msgString = (String) menuItem.getTitle();
                            mToolbar.setSubtitle("");
                            mFloatingActionButton.setVisibility(View.GONE);
                            break;
                    }
                    mToolbar.setTitle(msgString);
                    menuItem.setChecked(true);
                }

                mDrawerLayout.closeDrawers();
                return true;
            }
        });
    }

    public void updateUserInfo(String name, String email) {

        userName.setText(name);
        this.email.setText(email);
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Do if need splash
        if (ViewerApp.getInstance().isNeedToShowWelcome()) {
            startActivity(new Intent(this, WelcomeActivity.class));
            return;
        }
        if (!ViewerApp.getInstance().getSession().isSessionValid()) {
            onRecoverSession();
        } else {// valid session
            // here to new/restore Main-Activity's UI
            updateUserInfo(ViewerApp.getInstance().getSession().getUserInfo().getName(),
                    ViewerApp.getInstance().getSession().getUserInfo().getEmail());
            // direct to correct-page
            // 3 ways
            //      1  new to show Home
            //      2  back from other activity
            //      3  leave app first, then re-enter
//            if(mPreviousMenuId == -1 ){
//                // new to show Home
//                initRepoSystem();
//                mNavigationView.getMenu().getItem(0).setChecked(true);
//                mPreviousMenuId = R.id.left_nav_main;
//                displayView(mNavigationView.getMenu().getItem(0).getItemId());
//                mToolbar.setTitle(getString(R.string.title_nextlabs));
//            }
        }

    }


    private void onRecoverSession() {
        ViewerApp.getInstance().recoverySession(new ViewerApp.SessionRecoverListener() {
            @Override
            public void onSuccess() {
                // set UI for current session
                updateUserInfo(ViewerApp.getInstance().getSession().getUserInfo().getName(),
                        ViewerApp.getInstance().getSession().getUserInfo().getEmail());
                initRepoSystem();
            }

            @Override
            public void onAlreadyExist() {
                // set UI for current session
                updateUserInfo(ViewerApp.getInstance().getSession().getUserInfo().getName(),
                        ViewerApp.getInstance().getSession().getUserInfo().getEmail());
            }

            @Override
            public void onFailed(String reason) {
//                new AlertDialog.Builder(HomeContentActivity.this)
//                        .setTitle(R.string.title_popup_dialog)
//                        .setMessage(reason)
//                        .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
//                            @Override
//                            public void onClick(DialogInterface dialog, int id) {
//                                startActivity(new Intent(HomeContentActivity.this, NewLoginActivity.class));
//                                dialog.dismiss();
//                            }
//                        })
//                        .setCancelable(false)
//                        .show();
                //showMsgOnSnackBar(reason,false);
                Toast.makeText(HomeContentActivity.this, reason, Toast.LENGTH_SHORT).show();
                mHandle.sendEmptyMessageDelayed(MSG_FAILED_SESSION_RECOVERY, 2000);

            }

            @Override
            public void onProcess(String hint) {

            }
        });
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        int TASK = getResources().getInteger(R.integer.REQ_PICK_A_CLOUD_SERVICE);
        if (requestCode == TASK) {
            if (resultCode == Activity.RESULT_OK) {
                String name = data.getStringExtra(getString(R.string.PICKED_CLOUD_NAME));
            }
        } else if (requestCode == REQUSE_CODE_LOGIN && resultCode == Activity.RESULT_OK) {
            //For a new user login ok and session build ok
            mHandle.sendEmptyMessage(MSG_USER_LOGINED);
        } else {
            GoogleDriveSdk.ActivityResult(requestCode, resultCode, data);
            super.onActivityResult(requestCode, resultCode, data);
            return;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    private void onUserLogin() {
        initRepoSystem();

    }

    private void displayView(int position) {
        Fragment fragment = null;
        switch (position) {
            case R.id.left_nav_main:
                //change file system mode.
                app.onLeaveFavoriteOrOfflineMode();
                fragment = new HomeFilesFragment();
                break;
            case R.id.left_nav_favorite:
                fragment = new HomeFavoriteFragment();
                break;
            case R.id.left_nav_offline:
                fragment = new HomeOfflineFragment();
                break;
            case R.id.left_nav_profile:
                fragment = new HomeProfileFragment();
            default:
                break;
        }
        if (fragment != null) {
            FragmentManager fragmentManager = getSupportFragmentManager();
            FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
            fragmentTransaction.replace(R.id.home_container_body, fragment);
            fragmentTransaction.commit();
        }
    }

    @Override
    public void showGooglePlayServicesAvailabilityErrorDialog(final int connectionStatusCode) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Dialog dialog = GooglePlayServicesUtil.getErrorDialog(
                        connectionStatusCode,
                        HomeContentActivity.this,
                        GoogleDriveSdk.REQUEST_GOOGLE_PLAY_SERVICES);
                //                if (mFileListViewObj.getFileListViewProgressDialog() != null){
                //                    mFileListViewObj.getFileListViewProgressDialog().dismiss();
                //                }
                dialog.show();
            }
        });
    }

    @Override
    public void onClickSettings() {
        startActivity(new Intent(this, ProfileSettingActivity.class));
    }

    @Override
    public void onClickAccounts() {
        startActivity(new Intent(this, ProfileAccountActivity.class));
    }

    @Override
    public void onClickHelp() {
        startActivity(new Intent(this, HelpUIActivity.class));
    }

    @Override
    public void onClickSignOff() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle(R.string.title_popup_dialog)
                .setMessage(R.string.are_you_sure_exit_login)
                .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int id) {
                        // release res
                        app.deactivateRepoSystem();
                        app.closeSession();
                        // release this session's res
                        // redirect to Login
                        startActivityForResult(
                                new Intent(HomeContentActivity.this, NewLoginActivity.class),
                                REQUSE_CODE_LOGIN);

                    }
                })
                .setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int id) {

                    }
                });

        builder.setCancelable(false);
        builder.show();
    }

    long mIntervalBackPressedMills = 0;

    @Override
    public void onBackPressed() {
        if (!getSupportFragmentManager().popBackStackImmediate()) {
            // for no fragment can be pop-up
            if ((System.currentTimeMillis() - mIntervalBackPressedMills) > 2000) {
                Toast.makeText(getApplicationContext(), "Exit if press again", Toast.LENGTH_SHORT).show();
                mIntervalBackPressedMills = System.currentTimeMillis();
            } else {
                supportFinishAfterTransition();
            }
        }

    }

    private void initRepoSystem() {
        // init google first,  update Google Service
        GoogleDriveSdk.setIShowErrorDialog(HomeContentActivity.this);
        GoogleDriveSdk.setContext(HomeContentActivity.this);
        GoogleDriveSdk.updateGoogleServices(HomeContentActivity.this);

        // heavy time consuming initializing task
        //final ProgressDialog initializing = ProgressDialog.show(this, "", "Loading...");
        final Snackbar sb = showMsgOnSnackBar("Loading...", true);
        // app instance at this point will do some internal checks and initialize some internal components
        // to reduce the heavy burdens carried by UI
        app.onInitializeRepoSystem(this, new ViewerApp.RepoSysInitializeListener() {
            @Override
            public void success() {
                sb.dismiss();
                mNavigationView.getMenu().getItem(0).setChecked(true);
                mPreviousMenuId = R.id.left_nav_main;
                displayView(mNavigationView.getMenu().getItem(0).getItemId());
                mToolbar.setTitle(getString(R.string.title_nextlabs));
            }

            @Override
            public void progress(String msg) {
                sb.setText(msg);
            }

            @Override
            public void failed(int errorCode, String errorMsg) {
                sb.dismiss();
                if (errorCode == ErrorCode.REPO_ONE_DRIVE_INIT_FAILED) {
                    GenericError.showUI(HomeContentActivity.this, ErrorCode.REPO_UPDATE_FAILED, HomeContentActivity.this.getString(R.string.repo_update_failed),
                            true,
                            false,
                            false,
                            null);
                    //if one drive initialization failed. The whole app should still could work
                    mNavigationView.getMenu().getItem(0).setChecked(true);
                    mPreviousMenuId = R.id.left_nav_main;
                    displayView(mNavigationView.getMenu().getItem(0).getItemId());
                    mToolbar.setTitle(getString(R.string.title_nextlabs));
                }
            }
        });
    }

    private Snackbar showMsgOnSnackBar(CharSequence text, boolean indefinite) {
        Snackbar sb = Snackbar.make(mDrawerLayout, text, indefinite ? Snackbar.LENGTH_INDEFINITE : Snackbar.LENGTH_LONG);
        // customize it
        Snackbar.SnackbarLayout sl = (Snackbar.SnackbarLayout) sb.getView();
        sl.removeView(sl.findViewById(R.id.snackbar_action));
        ((TextView) sl.findViewById(R.id.snackbar_text)).setGravity(Gravity.CENTER);
        // show
        sb.show();
        return sb;

    }
}

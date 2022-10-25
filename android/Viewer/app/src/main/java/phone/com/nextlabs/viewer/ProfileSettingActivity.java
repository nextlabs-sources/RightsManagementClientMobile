package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.imageableList.ListServiceAdapter;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import appInstance.remoteRepo.onedrive.NXOneDrive;
import commonMethod.AccountService;
import commonUtils.FileHelper;
import commonUtils.dialog.ChangeTimeDialog;
import database.BoundService;
import errorHandler.ErrorCode;
import errorHandler.GenericError;

public class ProfileSettingActivity extends Activity {

    private Context mContext;
    private ViewerApp app = ViewerApp.getInstance();
    private RelativeLayout mSessionTimeLayout;
    private RelativeLayout mCleanCache;
    private TextView mTimeoutMinute;
    private ProgressDialog mProgressDialog;
    private Button mAddService;
    private AccountService mAccountService;

    private ListView mServiceListView;
    private ListServiceAdapter mListServiceAdapter;
    private List<BoundService> mServiceList;
    public static ListServiceAdapter.OnTrashItemClicked mOnTrashItemClicked;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mContext = this;
        setContentView(R.layout.activity_profile_setting);
        // for back
        findViewById(R.id.tv_setting_back).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ProfileSettingActivity.this.finish();
            }
        });
        LayoutInflater inflater = getLayoutInflater();
        // header view for listView
        ViewGroup header = (ViewGroup) inflater.inflate(R.layout.profile_setting_list_header, mServiceListView, false);
        mSessionTimeLayout = (RelativeLayout) header.findViewById(R.id.profile_setting_timeout_layout);
        mTimeoutMinute = (TextView) header.findViewById(R.id.tv_setting_timeout);
        // footer view for listView
        ViewGroup footer = (ViewGroup) inflater.inflate(R.layout.profile_setting_list_footer, mServiceListView, false);
        mCleanCache = (RelativeLayout) footer.findViewById(R.id.profile_clean_layout);
        mAddService = (Button) footer.findViewById(R.id.account_add_service);
        // list details
        mAccountService = new AccountService(ProfileSettingActivity.this);
        mServiceList = new ArrayList<>();
        mListServiceAdapter = new ListServiceAdapter(mContext, R.layout.home_account_item, mServiceList);
        mServiceListView = (ListView) findViewById(R.id.account_service_listview);

        mServiceListView.addHeaderView(header, null, false);
        mServiceListView.addFooterView(footer, null, false);
        mServiceListView.setDivider(null);
        mServiceListView.setAdapter(mListServiceAdapter);
        mListServiceAdapter.notifyDataSetChanged();

        mServiceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                TextView serviceName = (TextView) view.findViewById(R.id.home_service_name);
                TextView serviceAccount = (TextView) view.findViewById(R.id.home_service_account);
                Intent intent = new Intent(ProfileSettingActivity.this, RepositoryDetailActivity.class);
                intent.putExtra("position", position - 1);
                intent.putExtra("service_name", serviceName.getText().toString());
                intent.putExtra("service_account", serviceAccount.getText().toString());
                startActivity(intent);
            }
        });

        List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
        for (BoundService service : list) {
            if (service.type != BoundService.ServiceType.RECENT) {
                mServiceList.add(service);
            }
        }

        mAddService.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivityForResult(new Intent(ProfileSettingActivity.this, SupportedCloud.class),
                        getResources().getInteger(R.integer.REQ_PICK_A_CLOUD_SERVICE));
            }
        });

        // set session time out
        Date ttl = new Date(app.getSession().getUserInfo().getTtl());
        mTimeoutMinute.setText(ttl.toString());

        mOnTrashItemClicked = new ListServiceAdapter.OnTrashItemClicked() {
            @Override
            public void onTrashItemClicked(BoundService service, int position) {
                if (service.type == BoundService.ServiceType.ONEDRIVE) {
//                    OneDriveSdk.getInstance().LogOut();
                    NXOneDrive.signOut();
                }
                // del local files and records in cache_db
                try {
                    app.removeRepo(service);
                } catch (Exception e) {
                    Toast.makeText(mContext, "Exception: remove this service's local files", Toast.LENGTH_SHORT).show();
                    e.printStackTrace();
                }
                // del current service from database
                app.delService(mServiceList.get(position));
                // del this item
                mServiceList.remove(position);
                mListServiceAdapter.notifyDataSetChanged();
            }
        };
        mListServiceAdapter.setOnTrashItemClicked(mOnTrashItemClicked);

        mAccountService.setOnGetServiceFinish(new AccountService.OnGetServiceFinish() {
            @Override
            public void onGetServiceFinish(BoundService service) {
                mServiceList.add(service);
                mListServiceAdapter.notifyDataSetChanged();

            }
        });

        /**
         * show dialog to hint user whether to clean cache, if sure then clean, vice verse.
         */
        mCleanCache.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                AlertDialog.Builder builder = new AlertDialog.Builder(mContext);
                builder.setTitle(R.string.title_popup_dialog);
                long cacheSize = app.calReposCacheSize();
                builder.setMessage(getString(R.string.clean_cache_content) + " " + FileHelper.transferFileSize(cacheSize));
                builder.setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        //invoke clean function from file-system
                        app.clearReposCache(new ViewerApp.ClearCacheListener() {
                            @Override
                            public void finished() {
                                mProgressDialog.dismiss();
                            }
                        });

                        mProgressDialog = ProgressDialog.show(ProfileSettingActivity.this, "", getString(R.string.waiting));
                    }
                });
                builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.dismiss();
                    }
                });
                builder.setCancelable(false);
                builder.show();
            }
        });
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        int TASK = getResources().getInteger(R.integer.REQ_PICK_A_CLOUD_SERVICE);
        if (requestCode == TASK) {
            if (resultCode == Activity.RESULT_OK) {
                String name = data.getStringExtra(getString(R.string.PICKED_CLOUD_NAME));
                mAccountService.executeAccountAsyncTask(name);
            }
        } else {
            GoogleDriveSdk.ActivityResult(requestCode, resultCode, data);
            super.onActivityResult(requestCode, resultCode, data);
        }
    }
}

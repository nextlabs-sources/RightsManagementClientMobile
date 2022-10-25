package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;
import android.widget.TextView;

import com.imageableList.NXRepositoryDetailAdapter;
import com.imageableList.NXRepositoryDetailItem;
import com.nextlabs.viewer.R;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.localRepo.ILocalRepo;
import appInstance.localRepo.RepoInfo;
import commonUtils.FileHelper;
import database.BoundService;
import errorHandler.ErrorCode;
import errorHandler.GenericError;

public class RepositoryDetailActivity extends Activity {

    private TextView mBack;
    private TextView mCleanCache;
    private TextView mDeleteReposotory;
    private ListView mListView;
    private ArrayList<NXRepositoryDetailItem> mItemArray;
    private NXRepositoryDetailAdapter mRepositoryDetailAdapter;

    private int mPosition;
    private String mServiceName;
    private String mServiceAccount;
    private BoundService mClickBoundService;
    private RepoInfo mRepoInfo = new RepoInfo();
    private ProgressDialog mProgressDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_repository_detail);
        mPosition = getIntent().getIntExtra("position", -1);
        mServiceName = getIntent().getStringExtra("service_name");
        mServiceAccount = getIntent().getStringExtra("service_account");
        initContact();
        initData();
    }

    private void initContact() {
        mBack = (TextView) findViewById(R.id.tv_setting_back);
        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                RepositoryDetailActivity.this.finish();
            }
        });
        // footer view for listView
        LayoutInflater inflater = getLayoutInflater();
        mListView = (ListView) findViewById(R.id.repository_detail_listview);
        ViewGroup footer = (ViewGroup) inflater.inflate(R.layout.repository_detail_footer, mListView, false);
        mCleanCache = (TextView) footer.findViewById(R.id.repository_cleanCache);
        mDeleteReposotory = (TextView) footer.findViewById(R.id.repository_delete);

        mItemArray = new ArrayList<NXRepositoryDetailItem>();
        mRepositoryDetailAdapter = new NXRepositoryDetailAdapter(this, R.layout.repository_detail_item, mItemArray);
        mListView.addFooterView(footer, null, false);
        mListView.setAdapter(mRepositoryDetailAdapter);

        mCleanCache.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                AlertDialog.Builder builder = new AlertDialog.Builder(RepositoryDetailActivity.this);
                builder.setTitle(R.string.title_popup_dialog);
                builder.setMessage(getString(R.string.are_you_sure_clean_cache));
                builder.setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {

                        ViewerApp.getInstance().clearRepoCache(mClickBoundService, new ViewerApp.ClearCacheListener() {
                            @Override
                            public void finished() {
                                mProgressDialog.dismiss();
                                mRepoInfo.localCachedSize = 0;
                                paddingData(true);
                            }
                        });
                        mProgressDialog = ProgressDialog.show(RepositoryDetailActivity.this, "", getString(R.string.waiting));
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

        mDeleteReposotory.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                AlertDialog.Builder builder = new AlertDialog.Builder(RepositoryDetailActivity.this)
                        .setTitle(R.string.title_popup_dialog)
                        .setMessage(R.string.are_you_sure_delete_server)
                        .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int id) {
                                ProfileSettingActivity.mOnTrashItemClicked.onTrashItemClicked(mClickBoundService, mPosition);
                                finish();
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
        });

        mProgressDialog = ProgressDialog.show(RepositoryDetailActivity.this, "", getString(R.string.waiting));
    }

    private void initData() {

        paddingData(false);

        List<BoundService> list = ViewerApp.getInstance().getAllCloudServicesOfCurrentUser();
        for (BoundService service : list) {
            if (service.alias.equals(mServiceName) && service.account.equals(mServiceAccount)) {
                mClickBoundService = service;
                break;
            }
        }

        ViewerApp.getInstance().getRepoInformation(mClickBoundService, new ILocalRepo.IRepoInfoCallback() {
            @Override
            public void result(boolean status, RepoInfo info, String errorMsg) {
                mProgressDialog.dismiss();
                if (status) {
                    mRepoInfo = info;
                    paddingData(true);
                } else {
                    // todo, prompt error msg.
                    GenericError.showUI(RepositoryDetailActivity.this,
                            ErrorCode.GET_REPOSITORY_INFO_ERROR,
                            getString(R.string.name_get_repository_info),
                            true,
                            false,
                            false,
                            null);
                }
            }
        });
    }

    private void paddingData(boolean isRemoteData) {

        NXRepositoryDetailItem item_info = new NXRepositoryDetailItem(getString(R.string.name_repository_info), "");
        NXRepositoryDetailItem item_type = new NXRepositoryDetailItem(getString(R.string.name_repository_type), mServiceName);

        NXRepositoryDetailItem item_userName = null;
        NXRepositoryDetailItem item_email = null;
        NXRepositoryDetailItem item_totalSpace = null;
        NXRepositoryDetailItem item_usedSpace = null;
        if (isRemoteData) {
            item_userName = new NXRepositoryDetailItem(getString(R.string.name_repository_userName), mRepoInfo.displayName);
            item_email = new NXRepositoryDetailItem(getString(R.string.name_repository_email), mRepoInfo.email);
            item_totalSpace = new NXRepositoryDetailItem(getString(R.string.name_repository_totalSpace), FileHelper.transferFileSize(mRepoInfo.remoteTotalSpace));
            item_usedSpace = new NXRepositoryDetailItem(getString(R.string.name_repository_usedSpace), FileHelper.transferFileSize(mRepoInfo.remoteUsedSpace));
        } else {
            item_userName = new NXRepositoryDetailItem(getString(R.string.name_repository_userName), "");
            item_email = new NXRepositoryDetailItem(getString(R.string.name_repository_email), "");
            item_totalSpace = new NXRepositoryDetailItem(getString(R.string.name_repository_totalSpace), "");
            item_usedSpace = new NXRepositoryDetailItem(getString(R.string.name_repository_usedSpace), "");
        }

        // the item value need to be padded.
        NXRepositoryDetailItem item_localUsage = new NXRepositoryDetailItem(getString(R.string.name_repository_localUsage), "");
        NXRepositoryDetailItem item_offlineSize = new NXRepositoryDetailItem(getString(R.string.name_repository_offlineSize), FileHelper.transferFileSize(mRepoInfo.localOfflineSize));
        NXRepositoryDetailItem item_cacheSize = new NXRepositoryDetailItem(getString(R.string.name_repository_cacheSize), FileHelper.transferFileSize(mRepoInfo.localCachedSize));
        NXRepositoryDetailItem item_totalSize = new NXRepositoryDetailItem(getString(R.string.name_repository_totalSize), FileHelper.transferFileSize(mRepoInfo.localTotalSize));

        mItemArray.clear();
        mItemArray.add(item_info);
        mItemArray.add(item_type);
        mItemArray.add(item_userName);
        mItemArray.add(item_email);
        mItemArray.add(item_totalSpace);
        mItemArray.add(item_usedSpace);
        mItemArray.add(item_localUsage);
        mItemArray.add(item_offlineSize);
        mItemArray.add(item_cacheSize);
        mItemArray.add(item_totalSize);

        mRepositoryDetailAdapter.notifyDataSetChanged();
    }

}

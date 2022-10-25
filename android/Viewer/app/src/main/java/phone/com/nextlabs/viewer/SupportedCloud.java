package phone.com.nextlabs.viewer;

import android.app.ActionBar;
import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import com.nextlabs.viewer.R;
import com.onedrive.sdk.authentication.IAccountInfo;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.remoteRepo.dropbox.NXDropBox;
import appInstance.remoteRepo.msOneDrive.NXMsOneDrive;
import appInstance.remoteRepo.onedrive.NXOneDrive;
import appInstance.remoteRepo.sharepoint.SharePointSdk;
import appInstance.remoteRepo.sharepointonline.SharePointOnlineSdk;
import commonUtils.NetworkStatus;
import database.BoundService;
import errorHandler.ErrorCode;
import errorHandler.GenericError;

/**
 * Experimental Activity
 * Be used to show all supported remote repositories
 */
public class SupportedCloud extends Activity {
    static final String TAG = "NX_SupportedCloud";

    private boolean WaitDropBoxOAuth2 = false;
    private TextView mBack;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_supported_cloud);

        mBack = (TextView) findViewById(R.id.tv_back);
        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                SupportedCloud.this.finish();
            }
        });

        ActionBar bar = getActionBar();
        if (bar != null) {
            bar.hide();
        }

        //init list controls
        ListObj listService = new ListObj(this);
        listService.AttachListUIById(R.id.list_supported_cloud);

//remove this header according to IOS viewer app.
//        TextView header = new TextView(this);
//        header.setText(R.string.connect_cloud_service);
//        header.setTextAppearance(this, android.R.style.TextAppearance_Medium);
//        listService.addHeaderView(header);

        // item DropBox
        listService.add(new ListObj.Item(R.drawable.home_account_dropbox, getString(R.string.name_dropbox)));
        // item OneDrive
        listService.add(new ListObj.Item(R.drawable.home_account_onedrive, getString(R.string.name_onedrive)));
        // item MsOneDrive, wait until new SDK in stable
        //listService.add(new ListObj.Item(android.R.drawable.btn_plus, getString(R.string.name_msonedrive)));
        // item SharePoint
        //listService.add(new ListObj.Item(R.drawable.home_account_sharepoint, getString(R.string.name_sharepoint)));
        // item SharePointOnline
        //listService.add(new ListObj.Item(R.drawable.home_account_sharepoint_online, getString(R.string.name_sharepointonline)));
        // set callback
        listService.LinkItemsToUI(this, R.layout.support_service_item);

        listService.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                ListObj.Item item = (ListObj.Item) parent.getAdapter().getItem(position);
                if (item == null) { ///when user click list header that connect_cloud_service, don't deal with.
                    return;
                }
                if (item.getName().equalsIgnoreCase(getString(R.string.name_dropbox))) {
                    WaitDropBoxOAuth2 = true;
                    NXDropBox.startOAuth2Authentication(SupportedCloud.this);

                } else if (item.getName().equalsIgnoreCase(getString(R.string.name_msonedrive))) {
                    // msonedrive only support one user login
                    msOneDriveAuthentication();
                } else if (item.getName().equalsIgnoreCase(getString(R.string.name_onedrive))) {
                    NXOneDrive.fireOAuth2Authentication(SupportedCloud.this, new NXOneDrive.OAuth2Listener() {
                        @Override
                        public void success() {
                            setResult(RESULT_OK, getIntent().putExtra(getString(R.string.PICKED_CLOUD_NAME), getString(R.string.name_onedrive)));
                            SupportedCloud.this.finish();
                        }

                        @Override
                        public void failed() {
                            if (!ViewerApp.networkStatus.isNetworkAvailable()) {
                                hintBindFailed(getString(R.string.onedrive_repo_without_network));
                                return;
                            }
                            hintBindFailed(getString(R.string.onedrive_repo_bind_failed));
                        }
                    });
                } else if (item.getName().equalsIgnoreCase(getString(R.string.name_sharepoint))) {
                    SharePointSdk.StartAuth(SupportedCloud.this);
                } else if (item.getName().equalsIgnoreCase(getString(R.string.name_sharepointonline))) {
                    SharePointOnlineSdk.startAuth(SupportedCloud.this);
                }
            }
        });

    }

    void msOneDriveAuthentication() {

        NXMsOneDrive.startOAuth2Authentication(SupportedCloud.this, new NXMsOneDrive.IOAuth2Result() {
            @Override
            public void success(IAccountInfo accountInfo) {
                setResult(RESULT_OK, getIntent().putExtra(getString(R.string.PICKED_CLOUD_NAME), getString(R.string.name_msonedrive)));
                finish();
            }

            @Override
            public void failure(String errMsg) {
                setResult(RESULT_OK, getIntent().putExtra(getString(R.string.PICKED_CLOUD_NAME), getString(R.string.name_onedrive)));
            }
        });

    }


    @Override
    protected void onResume() {
        super.onResume();
        if (SharePointSdk.GetAuthStatus()) {
            SharePointSdk.ResetAuthStatus();
            setResult(RESULT_OK, getIntent().putExtra(getString(R.string.PICKED_CLOUD_NAME), getString(R.string.name_sharepoint)));
            finish();
        }
        if (SharePointOnlineSdk.GetAuthStatus()) {
            SharePointOnlineSdk.ResetAuthStatus();
            setResult(RESULT_OK, getIntent().putExtra(getString(R.string.PICKED_CLOUD_NAME), getString(R.string.name_sharepointonline)));
            finish();
        }
        if (WaitDropBoxOAuth2) {
            WaitDropBoxOAuth2 = false;

            if (NXDropBox.oAuth2AuthenticationSuccessful()) {
                setResult(RESULT_OK, getIntent().putExtra(getString(R.string.PICKED_CLOUD_NAME),
                        getString(R.string.name_dropbox)));
                Log.i(TAG, "successful Authentication of dropBox OAuth2");
                // add the OAuto token to database
                finish();
            } else {
                Log.e(TAG, "Authentication failed of dropBox OAuth2");
            }
        }
    }

    private void hintBindFailed(final String msg) {
        GenericError.showUI(this, ErrorCode.BOUND_SERVICE_BIND_FAILED, msg,
                true,
                false,
                false,
                null);
    }
}

class ListObj {
    private Activity mRoot;
    private ListView mListUi;
    private List<Item> mListItems = new ArrayList<>();
    private ItemAdapter mAdapter;


    public ListObj(Activity mRoot) {
        this.mRoot = mRoot;
    }

    public void LinkItemsToUI(Context context, int resource) {
        mAdapter = new ItemAdapter(context, resource, mListItems);
        mListUi.setAdapter(mAdapter);
    }

    public void AttachListUIById(int ListViewResId) {
        mListUi = (ListView) mRoot.findViewById(ListViewResId);
    }

    public void addHeaderView(View v) {
        mListUi.addHeaderView(v);
    }

    public boolean add(Item object) {
        return mListItems.add(object);
    }

    public void add(int location, Item object) {
        mListItems.add(location, object);
    }
    //    public void setAdapter(ListAdapter adapter) {
//        mListUi.setAdapter(adapter);
//    }

    public void setOnItemClickListener(AdapterView.OnItemClickListener listener) {
        mListUi.setOnItemClickListener(listener);
    }


    public void notifyDataSetChanged() {
        mAdapter.notifyDataSetChanged();
    }


    public static class Item {
        private int imgId;
        private String name;
        private BoundService service = null;


        public Item(int imgId, String name) {
            this.imgId = imgId;
            this.name = name;
        }

        public Item(int imgId, String name, BoundService service) {
            this.imgId = imgId;
            this.name = name;
            this.service = service;
        }

        public BoundService getService() {
            return service;
        }

        public int getImgId() {
            return imgId;
        }

        public void setImgId(int imgId) {
            this.imgId = imgId;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }

    public static class ItemAdapter extends ArrayAdapter<Item> {
        private int resItemLayoutId;

        public ItemAdapter(Context context, int resource, List<Item> objects) {
            super(context, resource, objects);
            resItemLayoutId = resource;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {

            Item item = getItem(position);

            View view = LayoutInflater.from(getContext()).inflate(resItemLayoutId, null);
            ImageView imageView = (ImageView) view.findViewById(R.id.service_image);
            TextView textView = (TextView) view.findViewById(R.id.service_name);

            imageView.setImageResource(item.getImgId());
            textView.setText(item.getName());
            return view;
        }
    }
}
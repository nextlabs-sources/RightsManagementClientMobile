package commonUtils.dialog;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.support.v4.app.Fragment;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import commonMethod.AccountService;
import commonUtils.dialog.dialogContentUtils.HomeBottomSheetAdapter;
import database.BoundService;
import phone.com.nextlabs.viewer.SupportedCloud;

/**
 * Bottom sheet for home activity
 */
public class HomeBottomSheet {
    private Activity mActivity;
    private ListView mServiceListView;
    private HomeBottomSheetAdapter mBottomSheetAdapter;
    private List<BoundService> mServiceList;
    private Dialog mBottomSheetDialog;

    private View mBottomView;
    private TextView mAddRepo;

    private AccountService mAccountService;

    private ViewerApp app = ViewerApp.getInstance();
    //used for activity result.
    private Fragment mFragment;
    private IShowRootFiles mShowFile;

    public HomeBottomSheet(Activity activity, Fragment fragment, AccountService accountService) {
        mActivity = activity;
        mFragment = fragment;
        mAccountService = accountService;
        initData();
        initEvent();

    }

    public void setOnShowRootFiles(IShowRootFiles listener) {
        mShowFile = listener;
    }

    private void initData() {
        mBottomView = mActivity.getLayoutInflater().inflate(R.layout.bottom_sheet_home, null);
        mServiceList = new ArrayList<>();
        mServiceList.addAll(ViewerApp.getInstance().getAllCloudServicesOfCurrentUser());
        mServiceListView = (ListView) mBottomView.findViewById(R.id.bottom_sheet_home_listview);
        mBottomSheetAdapter = new HomeBottomSheetAdapter(mActivity, R.layout.bottom_sheet_home_item, mServiceList);
        mServiceListView.setAdapter(mBottomSheetAdapter);

        // footer view for listView
        mBottomSheetAdapter.notifyDataSetChanged();
        //code to set adapter to populate list
        View footerView = ((LayoutInflater) mActivity.getSystemService(Context.LAYOUT_INFLATER_SERVICE)).inflate(R.layout.bottom_sheet_footer, mServiceListView, false);
        mServiceListView.addFooterView(footerView);
        mAddRepo = (TextView) footerView.findViewById(R.id.add_repo_bottom_sheet);
    }

    private void initEvent() {
        mServiceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                BoundService item = mServiceList.get(position);
                try {
                    if (item.selected == 0) {
                        item.selected = 1;
                        app.activateRepo(item);
                    } else {
                        item.selected = 0;
                        app.deactivateRepo(item);
                    }
                    app.updateService(item);
                    mBottomSheetAdapter.notifyDataSetChanged();
                    if (mShowFile != null) {
                        mShowFile.onShow();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        mAddRepo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mFragment.startActivityForResult(new Intent(mActivity, SupportedCloud.class),
                        mActivity.getResources().getInteger(R.integer.REQ_PICK_A_CLOUD_SERVICE));
            }
        });
        if (mAccountService != null) {
            mAccountService.setOnGetServiceFinish(new AccountService.OnGetServiceFinish() {
                @Override
                public void onGetServiceFinish(BoundService service) {
                    mServiceList.add(service);
                    mBottomSheetAdapter.notifyDataSetChanged();
                    if (mShowFile != null) {
                        mShowFile.onShow();
                    }
                }
            });
        }
    }

    public void showBottomSheet() {
        mBottomSheetDialog = new Dialog(mActivity, R.style.BottomSheetHome);
        mBottomSheetDialog.setContentView(mBottomView);
        mBottomSheetDialog.setCancelable(true);
        mBottomSheetDialog.getWindow().setLayout(ListView.LayoutParams.MATCH_PARENT, ListView.LayoutParams.WRAP_CONTENT);
        mBottomSheetDialog.getWindow().setGravity(Gravity.BOTTOM);
        mBottomSheetDialog.show();
    }

    public interface IShowRootFiles {
        void onShow();
    }
}

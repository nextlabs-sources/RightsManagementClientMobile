package phone.com.nextlabs.homeActivityWidget.leftSlideMenu;

import android.app.Activity;
import android.view.View;
import android.widget.ListView;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import commonMethod.AccountService;
import database.BoundService;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.LeftMenuList;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.LeftMenuListAdapter;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.LeftMenuItem;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.Node;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.TreeListViewAdapter;

@SuppressWarnings("unchecked")
public class HomeLeftMenuContent {
    private List<LeftMenuList> mMenuList = new ArrayList<LeftMenuList>();
    private List<LeftMenuList> mStableList = new ArrayList<LeftMenuList>();
    private List<LeftMenuList> mDynamicList = new ArrayList<LeftMenuList>();
    private ListView mMenuListView;
    private TreeListViewAdapter mMenuAdapter;
    private AccountService mLeftMenuService;
    private Activity mHomeActivity;
    private View mInflateView;
    private ViewerApp app;

    private OnLeftMenuItemClickListener onLeftMenuItemClickListener;

    public HomeLeftMenuContent(Activity activity, View view) {
        mHomeActivity = activity;
        mInflateView = view;
        initData();
        initEvent();
    }

    public void setOnLeftMenuItemClickListener(OnLeftMenuItemClickListener onItemClickListener) {
        this.onLeftMenuItemClickListener = onItemClickListener;
    }

    private void initData() {
        mLeftMenuService = new AccountService(mHomeActivity);
        app = ViewerApp.getInstance();
        String[] slideMenu = mHomeActivity.getResources().getStringArray(R.array.left_menu_name);
        int size = slideMenu.length;
        for (int i = 0; i < size; ++i) {
            LeftMenuItem menuItem = new LeftMenuItem(slideMenu[i], null);
            mStableList.add(new LeftMenuList(i + 1, 0, menuItem));
        }
        mMenuList.addAll(mStableList);
        updateMenuList();
    }

    private void initEvent() {
        mMenuListView = (ListView) mInflateView.findViewById(R.id.home_leftmenu_list);
        try {
            mMenuAdapter = new LeftMenuListAdapter<>(mMenuListView, mHomeActivity, mMenuList, 0);
            mMenuAdapter.setOnTreeNodeClickListener(new TreeListViewAdapter.OnTreeNodeClickListener() {
                @Override
                public void onClick(Node node, int position) {
                    if (node.isLeaf()) {
                        if (onLeftMenuItemClickListener != null) {
                            onLeftMenuItemClickListener.onItemClick(node, position);
                        }
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
        mMenuListView.setAdapter(mMenuAdapter);

        mLeftMenuService.setOnGetServiceFinish(new AccountService.OnGetServiceFinish() {
            @Override
            public void onGetServiceFinish(BoundService service) {
                notifyDataSetChanged();
            }
        });
    }

    // let the menu know outside has been updated
    // about bound service refresh
    public void notifyDataSetChanged() {
        updateMenuList();
        mMenuAdapter.notifyDataSetChanged(mMenuList);
    }

    private void updateMenuList() {
        GoogleDriveSdk.updateGoogleServices(mHomeActivity);
        int listSize = mMenuList.size();
        mMenuList.removeAll(mDynamicList);
        mDynamicList.clear();
        List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
        if (list == null || list.size() == 0) {
            mDynamicList.add(new LeftMenuList(++listSize, 1, new LeftMenuItem(mHomeActivity.getString(R.string.left_menu_adddrive), null)));
            mMenuList.addAll(mDynamicList);
            return;
        }
        for (BoundService service : list) {
            if (service.type != BoundService.ServiceType.RECENT) {
                mDynamicList.add(new LeftMenuList(++listSize, 1, new LeftMenuItem(service.alias, service)));
            }
        }
        mDynamicList.add(new LeftMenuList(++listSize, 1, new LeftMenuItem(mHomeActivity.getString(R.string.left_menu_adddrive), null)));
        mMenuList.addAll(mDynamicList);
    }

    public void executeAccountAsyncTask(String name) {
        mLeftMenuService.executeAccountAsyncTask(name);
    }

    public interface OnLeftMenuItemClickListener {
        void onItemClick(Node node, int position);
    }
}

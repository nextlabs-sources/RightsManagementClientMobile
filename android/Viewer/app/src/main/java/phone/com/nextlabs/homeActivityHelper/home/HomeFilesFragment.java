package phone.com.nextlabs.homeActivityHelper.home;

import android.app.Activity;
import android.app.SearchManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.widget.SearchView;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import appInstance.remoteRepo.googledrive.SdkWrapper.GoogleDriveSdk;
import commonMethod.AccountService;
import commonMethod.sort.SortContext;
import commonUtils.dialog.HomeBottomSheet;
import commonUtils.fileListUtils.nxfileListHelper.MainNXFileList;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.IHandleNXFileList;
import commonUtils.fileListUtils.nxfileListHelper.widget.SearchFile;

/**
 * fragment for home files.
 */
public class HomeFilesFragment extends Fragment {
    private View mMainView;
    private ViewerApp app = ViewerApp.getInstance();
    private IHandleNXFileList mMainNXFileListObj;
    private FloatingActionButton mFloatingActionButton;

    private SearchFile mSearchFileObj;
    private SearchView mSearchView;
    private MenuItem mSearchItem;

    private AccountService mAccountService;


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

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mMainView = inflater.inflate(R.layout.fragment_home_files, container, false);
        setHasOptionsMenu(true);
        return mMainView;
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initData();
        initEvent();
    }

    @Override
    public void onResume() {
        super.onResume();
        if (ViewerApp.isFromViewPage) {
            mMainNXFileListObj.closeRightMenu();
        }
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_home_file, menu);
        //initialize the default sortType in UI.
        menu.findItem(R.id.sort_by_name).setChecked(true);

        mSearchItem = menu.findItem(R.id.action_search);
        mSearchView = (SearchView) MenuItemCompat.getActionView(mSearchItem);
        mSearchView.setMaxWidth(10000);
        SearchManager searchManager = (SearchManager) getActivity().getSystemService(Context.SEARCH_SERVICE);
        mSearchView.setSearchableInfo(searchManager.getSearchableInfo(getActivity().getComponentName()));
        //initialize search event handler
        mSearchFileObj = new SearchFile(getActivity(), mSearchView);
        mSearchFileObj.setOnFilterData(new SearchFile.OnFilterData() {
            @Override
            public void onFilterData(String filterStr, boolean isEmpty) {
                ((MainNXFileList) mMainNXFileListObj).handleSearchEvent(filterStr, isEmpty);
            }
        });
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        switch (id) {
            case R.id.action_sort:
                //initialize sort list.
                MenuItem sortByDrive = item.getSubMenu().getItem(2);
                if (app.isInSyntheticRoot()) {
                    sortByDrive.setVisible(true);
                } else {
                    sortByDrive.setVisible(false);
                }
                break;
            case R.id.sort_by_name:
                mMainNXFileListObj.setSortType(SortContext.SortType.NAMEASCENDING);
                item.setChecked(true);
                break;
            case R.id.sort_by_time:
                mMainNXFileListObj.setSortType(SortContext.SortType.NEWEST);
                item.setChecked(true);
                break;
            case R.id.sort_by_driver:
                mMainNXFileListObj.setSortType(SortContext.SortType.DRIVERTYPE);
                item.setChecked(true);
                break;
        }
        return super.onOptionsItemSelected(item);
    }

    private void initData() {
        mAccountService = new AccountService(getActivity());

        mFloatingActionButton = (FloatingActionButton) getActivity().findViewById(R.id.home_floating_button);
        mMainNXFileListObj = new MainNXFileList(getActivity(), mMainView);
        //register search collapse event.
        ((MainNXFileList) mMainNXFileListObj).setCollapseSearchViewCallback(new MainNXFileList.ICollapseSearchView() {
            @Override
            public void onCollapseSearchView() {
                MenuItemCompat.collapseActionView(mSearchItem);
            }
        });

        //if there is no repo added in local, show empty view, if has show file list
        if (app.getAllCloudServicesOfCurrentUser().size() == 0) {
            mMainNXFileListObj.notifyDataChanged();
        } else {
            try {
                if (app.findWorkingFolder().getLocalPath().equals("/")) {
                    mMainNXFileListObj.showAllRootFiles();
                } else {
                    mMainNXFileListObj.showCurrentNodeFiles();
                }
            } catch (Exception e) {
                mMainNXFileListObj.showAllRootFiles();
                e.printStackTrace();
            }
        }
    }

    private void initEvent() {
        mFloatingActionButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                HomeBottomSheet homeBottomSheet = new HomeBottomSheet(getActivity(), HomeFilesFragment.this, mAccountService);
                homeBottomSheet.showBottomSheet();
                homeBottomSheet.setOnShowRootFiles(new HomeBottomSheet.IShowRootFiles() {
                    @Override
                    public void onShow() {
                        //if there is no repo added in local, show empty view, if has show file list
                        if (app.getAllCloudServicesOfCurrentUser().size() == 0) {
                            mMainNXFileListObj.notifyDataChanged();
                        } else {
                            try {
                                mMainNXFileListObj.showAllRootFiles();
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    }
                });
            }
        });
        ((MainNXFileList) mMainNXFileListObj).setHideKeyboard(new MainNXFileList.IHideKeyboard() {
            @Override
            public void onHideKeyboard() {
                if (mSearchView != null) {
                    mSearchView.clearFocus();

                }
            }
        });
    }
}

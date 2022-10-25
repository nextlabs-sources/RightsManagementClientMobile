package phone.com.nextlabs.homeActivityHelper.offline;

import android.app.SearchManager;
import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.widget.SearchView;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import com.nextlabs.viewer.R;

import appInstance.ViewerApp;
import commonMethod.sort.SortContext;
import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.nxfileListHelper.OfflineNXFileList;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.IHandleNXFileList;
import commonUtils.fileListUtils.nxfileListHelper.widget.SearchFile;
import nxl.types.INxFile;

/**
 * fragment for offline files.
 */
public class HomeOfflineFragment extends Fragment {
    private final static String TAG = "HomeFavoriteFragment";
    private IHandleNXFileList mOfflineNXFileListObj;
    private View mOfflineView;
    private ViewerApp app = ViewerApp.getInstance();

    private Toolbar mToolbar;
    private SortContext mSortContext;

    private SearchFile mSearchFileObj;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mOfflineView = inflater.inflate(R.layout.fragment_home_offline, null);
        setHasOptionsMenu(true);
        return mOfflineView;
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
            mOfflineNXFileListObj.closeRightMenu();
        }
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_home_offline, menu);

        final MenuItem searchItem = menu.findItem(R.id.action_search);
        final SearchView searchView = (SearchView) MenuItemCompat.getActionView(searchItem);
        searchView.setMaxWidth(10000);
        SearchManager searchManager = (SearchManager) getActivity().getSystemService(Context.SEARCH_SERVICE);
        searchView.setSearchableInfo(searchManager.getSearchableInfo(getActivity().getComponentName()));
        //initialize search event handler
        mSearchFileObj = new SearchFile(getActivity(), searchView);
        mSearchFileObj.setOnFilterData(new SearchFile.OnFilterData() {
            @Override
            public void onFilterData(String filterStr, boolean isEmpty) {
                ((OfflineNXFileList) mOfflineNXFileListObj).handleSearchEvent(filterStr, isEmpty);
            }
        });

        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return super.onOptionsItemSelected(item);
    }

    private void initData() {
        mOfflineNXFileListObj = new OfflineNXFileList(getActivity(), mOfflineView);
        mOfflineNXFileListObj.showAllRootFiles();
        mToolbar = (Toolbar) getActivity().findViewById(R.id.home_toolbar);
        mSortContext = new SortContext();
        try {
            mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getOfflineFiles()), getActivity());
            mToolbar.setSubtitle(mSortContext.onGetServiceCount() + " Drivers " + app.getOfflineFiles().size() + " Files");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initEvent() {
        mOfflineNXFileListObj.setOnOfflineStatusChanged(new IHandleNXFileList.OnFileOfflineStatusChanged() {
            @Override
            public void onOfflineStatusChanged(INxFile node, boolean isChanged) {
                try {
                    mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(app.getOfflineFiles()), getActivity());
                    mToolbar.setSubtitle(mSortContext.onGetServiceCount() + " Drivers " + app.getOfflineFiles().size() + " Files");
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }
}

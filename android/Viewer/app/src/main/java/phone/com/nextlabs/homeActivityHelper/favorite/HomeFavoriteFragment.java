package phone.com.nextlabs.homeActivityHelper.favorite;

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

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;
import commonMethod.sort.SortContext;
import commonUtils.fileListUtils.FileUtils;
import commonUtils.fileListUtils.nxfileListHelper.FavoriteNXFileList;
import commonUtils.fileListUtils.nxfileListHelper.baseMethod.IHandleNXFileList;
import commonUtils.fileListUtils.nxfileListHelper.widget.SearchFile;
import nxl.types.INxFile;

/**
 * fragment for favorite files.
 */
public class HomeFavoriteFragment extends Fragment {
    private final static String TAG = "HomeFavoriteFragment";

    private View mFavoriteView;
    private Toolbar mToolbar;

    private IHandleNXFileList mFavoriteNXFileListObj;
    private ViewerApp app = ViewerApp.getInstance();

    private List<INxFile> mFavoriteDocs = new ArrayList<>();

    private SortContext mSortContext;
    private SearchFile mSearchFileObj;
    private SearchView mSearchView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mFavoriteView = inflater.inflate(R.layout.fragment_home_favorite, null);
        setHasOptionsMenu(true);
        return mFavoriteView;
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
            mFavoriteNXFileListObj.closeRightMenu();
        }
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_home_favorite, menu);


        final MenuItem searchItem = menu.findItem(R.id.action_search);
        mSearchView = (SearchView) MenuItemCompat.getActionView(searchItem);
        mSearchView.setMaxWidth(10000);
        SearchManager searchManager = (SearchManager) getActivity().getSystemService(Context.SEARCH_SERVICE);
        mSearchView.setSearchableInfo(searchManager.getSearchableInfo(getActivity().getComponentName()));
        //initialize search event handler
        mSearchFileObj = new SearchFile(getActivity(), mSearchView);
        mSearchFileObj.setOnFilterData(new SearchFile.OnFilterData() {
            @Override
            public void onFilterData(String filterStr, boolean isEmpty) {
                ((FavoriteNXFileList) mFavoriteNXFileListObj).handleSearchEvent(filterStr, isEmpty);
            }
        });

        ((FavoriteNXFileList) mFavoriteNXFileListObj).setCollapseSearchViewCallback(new FavoriteNXFileList.ICollapseSearchView() {
            @Override
            public void onCollapseSearchView() {
                MenuItemCompat.collapseActionView(searchItem);
            }
        });
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return super.onOptionsItemSelected(item);
    }

    private void initData() {
        //change file system model from others to favorite
        //Favorite fragment hold the favorite root data.
        mFavoriteDocs.addAll(app.getFavoriteFiles());

        mFavoriteNXFileListObj = new FavoriteNXFileList(getActivity(), mFavoriteView);
        //restore older status of favorite list.
        try {
            mFavoriteNXFileListObj.showCurrentNodeFiles();
        } catch (Exception e) {
            e.printStackTrace();
        }

        mToolbar = (Toolbar) getActivity().findViewById(R.id.home_toolbar);

        mSortContext = new SortContext();
        try {
            mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(mFavoriteDocs), getActivity());
            mToolbar.setSubtitle(mSortContext.onGetServiceCount() + " Drivers " + mFavoriteDocs.size() + " Files");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initEvent() {
        mFavoriteNXFileListObj.setOnFavoriteStatusChanged(new IHandleNXFileList.OnFileFavoriteStatusChanged() {
            @Override
            public void onFavoriteStatusChanged(INxFile node, boolean isChanged) {
                if (isChanged) {
                    mFavoriteDocs.add(node);
                } else {
                    mFavoriteDocs.remove(node);
                }
                try {
                    mSortContext.DispatchSortAlgorithm(SortContext.SortType.DRIVERTYPE, FileUtils.translateINxList(mFavoriteDocs), getActivity());
                    mToolbar.setSubtitle(mSortContext.onGetServiceCount() + " Drivers " + mFavoriteDocs.size() + " Files");
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        ((FavoriteNXFileList) mFavoriteNXFileListObj).setHideKeyboard(new FavoriteNXFileList.IHideKeyboard() {
            @Override
            public void onHideKeyboard() {
                mSearchView.clearFocus();
            }
        });
    }
}
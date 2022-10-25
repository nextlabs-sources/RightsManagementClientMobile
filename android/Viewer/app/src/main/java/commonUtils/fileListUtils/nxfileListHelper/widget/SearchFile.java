package commonUtils.fileListUtils.nxfileListHelper.widget;

import android.content.Context;
import android.support.v7.widget.SearchView;
import android.text.TextUtils;

/**
 * search file helper class
 */
public class SearchFile {
    private Context mContext;
    private SearchView mSearchView;
    private OnFilterData onFilterData;

    public SearchFile(Context context, SearchView searchView) {
        mContext = context;
        mSearchView = searchView;
        initEvent();
    }

    private void initEvent() {
        mSearchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override
            public boolean onQueryTextSubmit(String query) {
//                return false;
                if (!"".equals(query)) {
                    mSearchView.post(new Runnable() {
                        @Override
                        public void run() {
                            mSearchView.clearFocus();
                        }
                    });
                }
                return true;
            }

            @Override
            public boolean onQueryTextChange(String newText) {
                // newText is text entered by user to SearchView
                filterData(newText);
                return false;
            }
        });

    }

    /**
     * method to judge whether the query text in search view is empty
     *
     * @return true means empty, vice verse
     */
    public boolean isTextEmpty() {
        return (mSearchView == null) || TextUtils.isEmpty(mSearchView.getQuery());
    }


    /**
     * used to filter data
     *
     * @param filterStr the query string
     */
    private void filterData(String filterStr) {
        boolean isEmpty = TextUtils.isEmpty(mSearchView.getQuery());
        if (onFilterData != null) {
            onFilterData.onFilterData(filterStr, isEmpty);
        }
    }

    /**
     * set the interface to filer the target query data
     *
     * @param onFilterData callback
     */
    public void setOnFilterData(OnFilterData onFilterData) {
        this.onFilterData = onFilterData;
    }

    /**
     * interface for search algorithm
     */
    public interface OnFilterData {
        void onFilterData(String filerStr, boolean isEmpty);
    }
}

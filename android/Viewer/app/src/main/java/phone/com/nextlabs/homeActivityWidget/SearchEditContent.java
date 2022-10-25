package phone.com.nextlabs.homeActivityWidget;

import android.app.Activity;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;

/**
 * search function object
 * used to handle search event.
 */
public class SearchEditContent {
    private Activity mActivity;
    private int mResourceID;
    private SearchEditText mSearchEditText;
    private OnFilterData onFilterData;

    public SearchEditContent(Activity activity, int resourceID) {
        mActivity = activity;
        mResourceID = resourceID;
        initData();
        initEvent();
    }

    private void initData() {
        mSearchEditText = (SearchEditText) mActivity.findViewById(mResourceID);
    }

    private void initEvent() {
        //if the search control cannot find then return.
        if (mSearchEditText == null) {
            return;
        }
        mSearchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterData(s.toString());
            }

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
    }

    public boolean isTextEmpty() {
        if (mSearchEditText != null) {
            return TextUtils.isEmpty(mSearchEditText.getText());
        }
        return true;
    }

    public void setOnFilterData(OnFilterData onFilterData) {
        this.onFilterData = onFilterData;
    }

    private void filterData(String filterStr) {
        boolean isEmpty = TextUtils.isEmpty(mSearchEditText.getText());

        onFilterData.onFilterData(filterStr, isEmpty);
    }

    public interface OnFilterData {
        void onFilterData(String filerStr, boolean isEmpty);
    }
}

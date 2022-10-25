package com.widgets;

import android.app.Activity;
import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;
import android.widget.PopupWindow;

import com.imageableList.NXSort;
import com.imageableList.NXSortPopAdapter;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by eric on 7/9/2015.
 */
public class SortPopWindow extends PopupWindow {
    private Activity mContext;
    private View conentView;
    private ListView mListView;
    private List<NXSort> mSortList = new ArrayList<NXSort>();
    private NXSortPopAdapter mAdapter;

    public SortPopWindow(final Activity context) {
        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        conentView = inflater.inflate(R.layout.sort_popup, null);
        mContext = context;
        initSortList();
        this.mAdapter = new NXSortPopAdapter(mContext, R.layout.sort_popup_item, mSortList);

        DisplayMetrics dm = mContext.getResources().getDisplayMetrics();
        int w = dm.widthPixels;
        int h = dm.heightPixels;

        this.setContentView(conentView);
        mListView = (ListView) conentView.findViewById(R.id.sortList);
        mListView.setAdapter(mAdapter);
        this.setWidth(w / 3);
        this.setHeight(ViewGroup.LayoutParams.WRAP_CONTENT);
        this.setFocusable(true);
        this.setOutsideTouchable(true);
        this.update();
        ColorDrawable dw = new ColorDrawable(0000000000);
        this.setBackgroundDrawable(dw);
    }

    public void showPopupWindow(View parent) {
        if (!this.isShowing()) {
            //this.showAsDropDown(parent, parent.getLayoutParams().width / 2, 10);
            this.showAsDropDown(parent, -10, 10);
        } else {
            this.dismiss();
        }
    }

    public ListView getSortListView() {
        return mListView;
    }

    private void initSortList() {
        String[] popStr = mContext.getResources().getStringArray(R.array.sort_display);
        this.mSortList.add(new NXSort(popStr[0], R.drawable.snamea));
        this.mSortList.add(new NXSort(popStr[1], R.drawable.snamed));
        this.mSortList.add(new NXSort(popStr[2], R.drawable.stimea));
        this.mSortList.add(new NXSort(popStr[3], R.drawable.stimed));
        this.mSortList.add(new NXSort(popStr[4], R.drawable.slargest));
        this.mSortList.add(new NXSort(popStr[5], R.drawable.ssmallest));
    }
}

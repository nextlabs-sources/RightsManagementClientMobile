package com.widgets;

import android.app.Activity;
import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;
import android.widget.PopupWindow;

import com.imageableList.NXSelect;
import com.imageableList.NXSelectPopAdapter;
import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

import commonUtils.DensityUtil;

public class ViewFilePopupWindow extends PopupWindow {
    private static final float WINDOW_Width = 180.0f;
    private Activity mContext;
    private View conentView;
    private ListView mListView;
    private List<NXSelect> mSelectList = new ArrayList<NXSelect>();
    private NXSelectPopAdapter mAdapter;

    public ViewFilePopupWindow(final Activity context) {
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        conentView = inflater.inflate(R.layout.popuplistview_layout, null);
        mContext = context;
        initSelectList();
        mAdapter = new NXSelectPopAdapter(mContext, R.layout.select_popup_item, getSelectList());

        this.setContentView(conentView);
        mListView = (ListView) conentView.findViewById(R.id.selectList);
        mListView.setAdapter(mAdapter);
        this.setWidth(DensityUtil.dip2px(mContext, WINDOW_Width));
        this.setHeight(ViewGroup.LayoutParams.WRAP_CONTENT);
        this.setFocusable(true);
        this.setOutsideTouchable(true);

        this.update();
        ColorDrawable dw = new ColorDrawable(R.color.white);
        this.setBackgroundDrawable(dw);

    }

    public void showPopupWindow(View parent, int StatusBarHeight, int titleHeight) {
        if (!this.isShowing()) {
            this.showAtLocation(parent, Gravity.RIGHT | Gravity.TOP, 30, StatusBarHeight + titleHeight);
        } else {
            this.dismiss();
        }
    }

    public List<NXSelect> getSelectList() {
        return mSelectList;
    }

    public ListView getListView() {
        return mListView;
    }

    private void initSelectList() {
        mSelectList.clear();
        String[] popupString = mContext.getResources().getStringArray(R.array.select_display);
        mSelectList.add(new NXSelect(R.drawable.protect_icon, popupString[0]));
        mSelectList.add(new NXSelect(R.drawable.share_icon, popupString[1]));
        mSelectList.add(new NXSelect(R.drawable.print_icon, popupString[2]));
        mSelectList.add(new NXSelect(R.drawable.property_icon, popupString[3]));
    }

}

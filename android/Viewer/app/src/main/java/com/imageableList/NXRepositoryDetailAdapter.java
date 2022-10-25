package com.imageableList;

import android.app.Activity;
import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

import phone.com.nextlabs.viewer.RepositoryDetailActivity;

public class NXRepositoryDetailAdapter extends ArrayAdapter<NXRepositoryDetailItem> {
    private int resourceId;
    private Context mContext;

    public NXRepositoryDetailAdapter(Context context, int textViewResourceId, List<NXRepositoryDetailItem> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
        mContext = context;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        NXRepositoryDetailItem item = getItem(position);
        View view;
        ItemInfo itemInfo;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            itemInfo = new ItemInfo();
            itemInfo.mName = (TextView) view.findViewById(R.id.repository_item_name);
            itemInfo.mValue = (TextView) view.findViewById(R.id.repository_item_value);
            view.setTag(itemInfo);
        } else {
            view = convertView;
            itemInfo = (ItemInfo) view.getTag();
            // recover original parameter
            itemInfo.mName.setTextColor(mContext.getResources().getColor(R.color.Black));
            Drawable dw = new ColorDrawable(mContext.getResources().getColor(R.color.white));
            view.setBackground(dw);

            RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) itemInfo.mName.getLayoutParams();
            lp.removeRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
            lp.addRule(RelativeLayout.CENTER_VERTICAL, RelativeLayout.TRUE);
        }

        DisplayMetrics dm = new DisplayMetrics();
        ((Activity) mContext).getWindowManager().getDefaultDisplay().getMetrics(dm);
        int mScreenWidth = dm.widthPixels;

        if (item.getItmeName().equals(mContext.getString(R.string.name_repository_email))) {
            itemInfo.mValue.setMaxWidth(mScreenWidth * 3 / 4);

        }

        itemInfo.mName.setText(item.getItmeName());
        itemInfo.mValue.setText(item.getItemValue());

        if (item.getItmeName().equals(mContext.getString(R.string.name_repository_info)) ||
                item.getItmeName().equals(mContext.getString(R.string.name_repository_localUsage))) {

            itemInfo.mName.setTextColor(mContext.getResources().getColor(R.color.Gray));
            Drawable dw = new ColorDrawable(mContext.getResources().getColor(R.color.transparent));
            view.setBackground(dw);

            RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) itemInfo.mName.getLayoutParams();
            lp.removeRule(RelativeLayout.CENTER_VERTICAL);
            lp.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM, RelativeLayout.TRUE);
        }

        return view;
    }

    class ItemInfo {
        TextView mName;
        TextView mValue;
    }
}

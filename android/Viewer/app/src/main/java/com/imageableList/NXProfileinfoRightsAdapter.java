package com.imageableList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

/**
 * Created by snowman on 7/23/2015.
 */
public class NXProfileinfoRightsAdapter extends ArrayAdapter<NXProfileRightsItem> {
    private int resourceId;

    public NXProfileinfoRightsAdapter(Context context, int textViewResourceId, List<NXProfileRightsItem> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        NXProfileRightsItem item = getItem(position);
        View view;
        ItemInfo itemInfo;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            itemInfo = new ItemInfo();
            itemInfo.mName = (TextView) view.findViewById(R.id.infoitemrightsname);
            itemInfo.mValue = (ImageView) view.findViewById(R.id.infoitemrightsvalue);
            view.setTag(itemInfo);
        } else {
            view = convertView;
            itemInfo = (ItemInfo) view.getTag();
        }

        itemInfo.mName.setText(item.getmRightName());
        if (item.getmIFChecked()) {
            itemInfo.mValue.setVisibility(View.VISIBLE);
        }

        return view;
    }

    class ItemInfo {
        TextView mName;
        ImageView mValue;
    }
}

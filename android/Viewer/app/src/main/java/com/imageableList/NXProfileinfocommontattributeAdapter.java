package com.imageableList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

/**
 * Created by snowman on 7/23/2015.
 */
public class NXProfileinfocommontattributeAdapter extends ArrayAdapter<NXProfileCommonattributeItem> {
    private int resourceId;

    public NXProfileinfocommontattributeAdapter(Context context, int textViewResourceId, List<NXProfileCommonattributeItem> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        NXProfileCommonattributeItem item = getItem(position);
        View view;
        ItemInfo itemInfo;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            itemInfo = new ItemInfo();
            itemInfo.mName = (TextView) view.findViewById(R.id.infoitemcommonattributename);
            itemInfo.mValue = (TextView) view.findViewById(R.id.infoitemcommonattributevalue);
            view.setTag(itemInfo);
        } else {
            view = convertView;
            itemInfo = (ItemInfo) view.getTag();
        }

        itemInfo.mName.setText(item.getmAttributeName());
        itemInfo.mValue.setText(item.getmAttributeValue());

        return view;
    }

    class ItemInfo {
        TextView mName;
        TextView mValue;
    }
}

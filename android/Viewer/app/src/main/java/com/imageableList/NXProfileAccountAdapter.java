package com.imageableList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

public class NXProfileAccountAdapter extends ArrayAdapter<NXProfileAccountItem> {
    private int resourceId;

    public NXProfileAccountAdapter(Context context, int textViewResourceId, List<NXProfileAccountItem> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        NXProfileAccountItem item = getItem(position);
        View view;
        ItemInfo itemInfo;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            itemInfo = new ItemInfo();
            itemInfo.mName = (TextView) view.findViewById(R.id.account_name);
            itemInfo.mValue = (TextView) view.findViewById(R.id.account_value);
            view.setTag(itemInfo);
        } else {
            view = convertView;
            itemInfo = (ItemInfo) view.getTag();
        }

        itemInfo.mName.setText(item.getName());
        itemInfo.mValue.setText(item.getValue());

        return view;
    }

    class ItemInfo {
        TextView mName;
        TextView mValue;
    }
}

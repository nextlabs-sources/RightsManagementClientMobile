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
 * Created by snowman on 7/29/2015.
 */
public class NXModifyAdapter extends ArrayAdapter<NXModifyItem> {
    private int resourceId;

    public NXModifyAdapter(Context context, int textViewResourceId, List<NXModifyItem> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        NXModifyItem item = getItem(position);
        View view;
        ItemInfo itemInfo;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            itemInfo = new ItemInfo();
            itemInfo.mName = (TextView) view.findViewById(R.id.modifyname);
            itemInfo.mValue = (TextView) view.findViewById(R.id.modifyvalue);
            itemInfo.mImge = (ImageView) view.findViewById(R.id.modifyimageView);
            view.setTag(itemInfo);
        } else {
            view = convertView;
            itemInfo = (ItemInfo) view.getTag();
        }

        itemInfo.mName.setText(item.getModifyName());
        itemInfo.mValue.setText(item.getmModifyValue());
        itemInfo.mImge.setImageResource(item.getmImag());

        return view;
    }

    class ItemInfo {
        TextView mName;
        TextView mValue;
        ImageView mImge;
    }
}


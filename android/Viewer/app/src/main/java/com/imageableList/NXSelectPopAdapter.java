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

public class NXSelectPopAdapter extends ArrayAdapter<NXSelect> {
    private int resourceId;

    public NXSelectPopAdapter(Context context, int textViewResourceId, List<NXSelect> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {

        NXSelect select = getItem(position);
        View view;
        ViewHolder viewHolder;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            viewHolder = new ViewHolder();
            viewHolder.itemImage = (ImageView) view.findViewById(R.id.imSelect);
            viewHolder.itemName = (TextView) view.findViewById(R.id.txSelect);
            view.setTag(viewHolder);
        } else {
            view = convertView;
            viewHolder = (ViewHolder) view.getTag();
        }
        viewHolder.itemImage.setImageResource(select.getImageId());
        viewHolder.itemName.setText(select.getItemName());

        return view;
    }

    class ViewHolder {
        ImageView itemImage;
        TextView itemName;
    }
}

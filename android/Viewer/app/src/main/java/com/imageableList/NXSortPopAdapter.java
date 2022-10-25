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
 * Created by eric on 7/9/2015.
 */
public class NXSortPopAdapter extends ArrayAdapter<NXSort> {
    private int resourceId;

    public NXSortPopAdapter(Context context, int textViewResourceId, List<NXSort> objects) {
        super(context, textViewResourceId, objects);
        resourceId = textViewResourceId;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {

        NXSort sort = getItem(position);
        View view;
        ViewHolder viewHolder;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(resourceId, null);
            viewHolder = new ViewHolder();
            viewHolder.itemImage = (ImageView) view.findViewById(R.id.imSort);
            viewHolder.itemName = (TextView) view.findViewById(R.id.txSort);
            view.setTag(viewHolder);
        } else {
            view = convertView;
            viewHolder = (ViewHolder) view.getTag();
        }
        viewHolder.itemImage.setImageResource(sort.getImageId());
        viewHolder.itemName.setText(sort.getName());

        return view;
    }

    class ViewHolder {
        ImageView itemImage;
        TextView itemName;
    }
}
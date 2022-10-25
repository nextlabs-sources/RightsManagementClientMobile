package com.imageableList;

import android.app.Activity;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class NXDriverAdapter extends BaseAdapter {

    private List<Map<String, Object>> mList;
    private ArrayList<Integer> mPositionList;
    private Activity mActivity = null;

    public NXDriverAdapter(Activity activity, List<Map<String, Object>> list, ArrayList<Integer> positionList) {
        this.mActivity = activity;
        this.mList = list;
        this.mPositionList = positionList;
    }

    @Override
    public int getCount() {
        return mList.size();
    }

    @Override
    public Object getItem(int position) {
        return mList.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {
        ViewHolder holder = null;
        if (convertView == null) {
            holder = new ViewHolder();
            convertView = LayoutInflater.from(mActivity).inflate(R.layout.fragment_driver_item, null);
            holder.textViewDriverName = (TextView) convertView.findViewById(R.id.item_drivername);
            holder.textViewUserAccount = (TextView) convertView.findViewById(R.id.item_userAccount);
            holder.checkImage = (ImageView) convertView.findViewById(R.id.checkImage);
            convertView.setTag(holder);
        } else {
            holder = (ViewHolder) convertView.getTag();
        }

        convertView.setBackgroundColor(Color.WHITE);

        holder.textViewDriverName.setText(mList.get(position).get("service_alias").toString());
        holder.textViewUserAccount.setText(mList.get(position).get("service_account").toString());

        if (mPositionList.get(position) == -1) {
            holder.checkImage.setVisibility(View.INVISIBLE);
        } else {
            holder.checkImage.setVisibility(View.VISIBLE);
        }

        return convertView;
    }

    class ViewHolder {
        TextView textViewDriverName;
        TextView textViewUserAccount;
        ImageView checkImage;
    }

}

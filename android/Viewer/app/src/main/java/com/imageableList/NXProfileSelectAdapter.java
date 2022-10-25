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

import java.util.List;
import java.util.Map;


/**
 * Created by aning on 11/2/2015.
 */
public class NXProfileSelectAdapter extends BaseAdapter {
    private List<Map<String, Object>> mList;
    private Activity mActivity = null;

    public NXProfileSelectAdapter(Activity activity, List<Map<String, Object>> list) {
        this.mActivity = activity;
        this.mList = list;
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
            convertView = LayoutInflater.from(mActivity).inflate(R.layout.profile_select_item, null);
            holder.textViewUser = (TextView) convertView.findViewById(R.id.item_username);
            holder.textViewServer = (TextView) convertView.findViewById(R.id.item_server);
            holder.checkImage = (ImageView) convertView.findViewById(R.id.checkImage);
            convertView.setTag(holder);
        } else {
            holder = (ViewHolder) convertView.getTag();
        }

        convertView.setBackgroundColor(Color.WHITE);

        // parse userName and server.
        String userProfile = mList.get(position).get("profile").toString();
        holder.textViewUser.setText(userProfile.substring(0, userProfile.indexOf(" ")));
        holder.textViewServer.setText(userProfile.substring(userProfile.indexOf(" ") + 1));
        holder.textViewServer.setTextColor(Color.GRAY);

//        if (position == LoadProfileActivity.mLastSelectedPosition) {
//            holder.checkImage.setVisibility(View.VISIBLE);
//        } else {
//            holder.checkImage.setVisibility(View.INVISIBLE);
//        }

        return convertView;
    }

    class ViewHolder {
        TextView textViewUser;
        TextView textViewServer;
        ImageView checkImage;
    }
}


package com.imageableList;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageButton;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

import database.BoundService;

/**
 * adapter for linked Bound Service
 */
public class ListServiceAdapter extends ArrayAdapter<BoundService> {
    private int mResourceId;
    private List<BoundService> mBoundServiceItem;
    private Context mContext;

    private OnTrashItemClicked onTrashItemClicked;

    public ListServiceAdapter(Context context, int textViewResourceId, List<BoundService> objects) {
        super(context, textViewResourceId, objects);
        mResourceId = textViewResourceId;
        mBoundServiceItem = objects;
        mContext = context;
    }

    public void setOnTrashItemClicked(OnTrashItemClicked onInfoItemClicked) {
        this.onTrashItemClicked = onInfoItemClicked;
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {
        final BoundService boundService = getItem(position);
        View view;
        ViewHolder viewHolder;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(mResourceId, null);
            viewHolder = new ViewHolder();
            viewHolder.serviceName = (TextView) view.findViewById(R.id.home_service_name);
            viewHolder.serviceAccount = (TextView) view.findViewById(R.id.home_service_account);
            viewHolder.serviceAccountID = (TextView) view.findViewById(R.id.home_service_account_id);
            viewHolder.serviceImage = (ImageButton) view.findViewById(R.id.home_service_image);
            viewHolder.trashButton = (ImageButton) view.findViewById(R.id.home_service_trash);
            view.setTag(viewHolder);
        } else {
            view = convertView;
            viewHolder = (ViewHolder) view.getTag();
        }
        viewHolder.trashButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                AlertDialog.Builder builder = new AlertDialog.Builder(mContext)
                        .setTitle(R.string.title_popup_dialog)
                        .setMessage(R.string.are_you_sure_delete_server)
                        .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int id) {
                                onTrashItemClicked.onTrashItemClicked(boundService, position);
                            }
                        })
                        .setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int id) {
                                return;
                            }
                        });

                builder.setCancelable(false);
                builder.show();
                return;
            }
        });

        viewHolder.serviceName.setText(boundService.alias);
        viewHolder.serviceAccount.setText(boundService.account);

        if (boundService.type.equals(BoundService.ServiceType.DROPBOX)) {
            viewHolder.trashButton.setVisibility(View.VISIBLE);
            viewHolder.serviceImage.setImageResource(R.drawable.home_account_dropbox);
            viewHolder.serviceAccountID.setVisibility(View.GONE);
        } else if (boundService.type.equals(BoundService.ServiceType.ONEDRIVE)) {
            viewHolder.trashButton.setVisibility(View.VISIBLE);
            viewHolder.serviceImage.setImageResource(R.drawable.home_account_onedrive);
            viewHolder.serviceAccountID.setVisibility(View.GONE);
        } else if (boundService.type.equals(BoundService.ServiceType.SHAREPOINT)) {
            viewHolder.trashButton.setVisibility(View.VISIBLE);
            viewHolder.serviceImage.setImageResource(R.drawable.home_account_sharepoint);
            viewHolder.serviceAccountID.setVisibility(View.VISIBLE);
        } else if (boundService.type.equals(BoundService.ServiceType.SHAREPOINT_ONLINE)) {
            viewHolder.trashButton.setVisibility(View.VISIBLE);
            viewHolder.serviceImage.setImageResource(R.drawable.home_account_sharepoint_online);
            viewHolder.serviceAccountID.setVisibility(View.VISIBLE);
            viewHolder.serviceAccountID.setText(boundService.accountID);
        } else if (boundService.type.equals(BoundService.ServiceType.GOOGLEDRIVE)) {
            viewHolder.serviceImage.setImageResource(R.drawable.home_account_google);
            viewHolder.trashButton.setVisibility(View.GONE);
            viewHolder.serviceAccountID.setVisibility(View.GONE);
        }
        viewHolder.serviceAccountID.setText(boundService.accountID);
        return view;
    }


    public interface OnTrashItemClicked {
        void onTrashItemClicked(BoundService service, int position);
    }

    class ViewHolder {
        TextView serviceName;
        TextView serviceAccountID;
        TextView serviceAccount;
        ImageButton serviceImage;
        ImageButton trashButton;
    }
}

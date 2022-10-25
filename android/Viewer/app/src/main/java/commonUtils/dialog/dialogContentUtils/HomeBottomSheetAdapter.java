package commonUtils.dialog.dialogContentUtils;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

import database.BoundService;

/**
 * adapter for bottom sheet adapter
 */
public class HomeBottomSheetAdapter extends ArrayAdapter<BoundService> {
    private int mResourceId;
    private List<BoundService> mBoundServiceItem;
    private Context mContext;

    public HomeBottomSheetAdapter(Context context, int textViewResourceId, List<BoundService> objects) {
        super(context, textViewResourceId, objects);
        mResourceId = textViewResourceId;
        mBoundServiceItem = objects;
        mContext = context;
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {
        final BoundService boundService = getItem(position);
        View view;
        ViewHolder viewHolder;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(mResourceId, null);
            viewHolder = new ViewHolder();
            viewHolder.repoThumbnail = (ImageView) view.findViewById(R.id.bottom_sheet_home_repo_thumbnail);
            viewHolder.repoName = (TextView) view.findViewById(R.id.bottom_sheet_home_repo_name);
            viewHolder.repoAccountID = (TextView) view.findViewById(R.id.bottom_sheet_home_repo_account_id);
            viewHolder.repoAccount = (TextView) view.findViewById(R.id.bottom_sheet_home_repo_account);
            viewHolder.repoChecked = (ImageView) view.findViewById(R.id.bottom_sheet_home_repo_checked);
            view.setTag(viewHolder);
        } else {
            view = convertView;
            viewHolder = (ViewHolder) view.getTag();
        }

        viewHolder.repoName.setText(boundService.alias);
        viewHolder.repoAccount.setText(boundService.account);

        if (boundService.type.equals(BoundService.ServiceType.DROPBOX)) {
            viewHolder.repoThumbnail.setImageResource(R.drawable.bottom_sheet_dropbox);
            viewHolder.repoAccountID.setVisibility(View.GONE);
        } else if (boundService.type.equals(BoundService.ServiceType.ONEDRIVE)) {
            viewHolder.repoThumbnail.setImageResource(R.drawable.bottom_sheet_onedrive);
            viewHolder.repoAccountID.setVisibility(View.GONE);
        } else if (boundService.type.equals(BoundService.ServiceType.SHAREPOINT)) {
            viewHolder.repoThumbnail.setImageResource(R.drawable.bottom_sheet_sharepoint);
            viewHolder.repoAccountID.setVisibility(View.VISIBLE);
        } else if (boundService.type.equals(BoundService.ServiceType.SHAREPOINT_ONLINE)) {
            viewHolder.repoThumbnail.setImageResource(R.drawable.bottom_sheet_sharepoint_online);
            viewHolder.repoAccountID.setVisibility(View.VISIBLE);
        } else if (boundService.type.equals(BoundService.ServiceType.GOOGLEDRIVE)) {
            viewHolder.repoThumbnail.setImageResource(R.drawable.bottom_sheet_googledrive);
            viewHolder.repoAccountID.setVisibility(View.GONE);
        }
        viewHolder.repoAccountID.setText(boundService.accountID);

        if (boundService.selected == 1) {
            viewHolder.repoChecked.setVisibility(View.VISIBLE);
        } else {
            viewHolder.repoChecked.setVisibility(View.GONE);
        }
        return view;
    }

    class ViewHolder {
        ImageView repoThumbnail;
        TextView repoName;
        TextView repoAccountID;
        TextView repoAccount;
        ImageView repoChecked;
    }
}

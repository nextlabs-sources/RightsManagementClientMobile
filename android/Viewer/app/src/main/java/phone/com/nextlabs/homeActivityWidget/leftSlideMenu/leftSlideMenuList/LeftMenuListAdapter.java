package phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.List;

import database.BoundService;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.Node;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.TreeListViewAdapter;

/**
 * Created by eric on 10/22/2015.
 */
public class LeftMenuListAdapter<T> extends TreeListViewAdapter<T> {

    public LeftMenuListAdapter(ListView mTree, Context context, List<T> datas,
                               int defaultExpandLevel) throws IllegalArgumentException, IllegalAccessException {
        super(mTree, context, datas, defaultExpandLevel);
    }

    @Override
    public View getConvertView(Node node, int position, View convertView, ViewGroup parent) {
        ViewHolder viewHolder;
        if (convertView == null) {
            convertView = mInflater.inflate(R.layout.home_leftslide_item, parent, false);
            viewHolder = new ViewHolder();
            viewHolder.icon = (ImageView) convertView.findViewById(R.id.home_leftslide_icon);
            viewHolder.label = (TextView) convertView.findViewById(R.id.home_leftslide_label);
            viewHolder.thumb = (ImageView) convertView.findViewById(R.id.home_leftslide_thumbImage);
            viewHolder.bottom = (TextView) convertView.findViewById(R.id.home_leftslide_service_label);
            viewHolder.check = (ImageView) convertView.findViewById(R.id.home_leftslide_service_clicked);
            convertView.setTag(viewHolder);
        } else {
            viewHolder = (ViewHolder) convertView.getTag();
        }

        if (node.getIcon() == -1) {
            viewHolder.icon.setVisibility(View.INVISIBLE);
        } else {
            viewHolder.icon.setVisibility(View.VISIBLE);
            viewHolder.icon.setImageResource(node.getIcon());
        }

        if (node.getBoundService() != null) {
            if (node.getBoundService().selected == 0) {
                node.setChecked(false);
                node.setCheckImage(-1);
                viewHolder.check.setVisibility(View.GONE);
            } else {
                node.setChecked(true);
                node.setCheckImage(1);
                viewHolder.check.setVisibility(View.VISIBLE);
            }
        }

        if (node.getCheckImage() == -1) {
            viewHolder.check.setVisibility(View.GONE);
        } else {
            viewHolder.check.setVisibility(View.VISIBLE);
        }

        viewHolder.thumb.setImageResource(node.getThumbImage());
        viewHolder.label.setText(node.getName());
        if (node.getpId() == 1) {
            viewHolder.bottom.setVisibility(View.VISIBLE);
            BoundService boundService = node.getBoundService();
            String nodeName = node.getName();
            switch (nodeName) {
                case "Add Drive":
                    viewHolder.bottom.setVisibility(View.GONE);
                    break;
                case "DropBox":
                case "OneDrive":
                case "SharePoint":
                case "SharePointOnline":
                case "GoogleDrive":
                    viewHolder.bottom.setText(boundService.account);
                    break;
            }
        } else {
            viewHolder.bottom.setVisibility(View.GONE);
        }
        return convertView;
    }

    private final class ViewHolder {
        TextView label;
        TextView bottom;
        ImageView thumb;
        ImageView icon;
        ImageView check;
    }

}
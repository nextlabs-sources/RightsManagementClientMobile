package phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode;

import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.ListView;

import java.util.List;

/**
 * Created by eric on 10/22/2015.
 */
public abstract class TreeListViewAdapter<T> extends BaseAdapter {
    protected Context mContext;
    // record all visibility nodes
    protected List<Node> mNodes;
    protected LayoutInflater mInflater;
    // record all nodes
    protected List<Node> mAllNodes;

    private OnTreeNodeClickListener onTreeNodeClickListener;

    private int mDefaultExpandLevel;

    public TreeListViewAdapter(ListView mTree, Context context, List<T> datas,
                               int defaultExpandLevel) throws IllegalArgumentException,
            IllegalAccessException {
        mContext = context;
        //sort all nodes
        mDefaultExpandLevel = defaultExpandLevel;
        mAllNodes = TreeHelper.getSortedNodes(datas, defaultExpandLevel);
        mNodes = TreeHelper.filterVisibleNode(mAllNodes);

        mInflater = LayoutInflater.from(context);

        mTree.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view,
                                    int position, long id) {
                expandOrCollapse(position);

                notifyDataSetChanged();
                if (onTreeNodeClickListener != null) {
                    onTreeNodeClickListener.onClick(mNodes.get(position),
                            position);
                }
            }
        });

    }

    public void setOnTreeNodeClickListener(OnTreeNodeClickListener onTreeNodeClickListener) {
        this.onTreeNodeClickListener = onTreeNodeClickListener;
    }

    public void notifyDataSetChanged(List<T> datas) {
        try {
            mAllNodes = TreeHelper.getSortedNodes(datas, 10);
            mNodes = TreeHelper.filterVisibleNode(mAllNodes);
            notifyDataSetChanged();
        } catch (Exception e) {
            Log.e("TreeListViewAdapter", e.toString());
        }
    }

    private void expandOrCollapse(int position) {
        Node n = mNodes.get(position);
        if (n != null) {
            if (!n.isLeaf()) {
                n.setExpand(!n.isExpand());
                mNodes = TreeHelper.filterVisibleNode(mAllNodes);
            }
        }
    }

    @Override
    public int getCount() {
        return mNodes.size();
    }

    @Override
    public Object getItem(int position) {
        return mNodes.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        Node node = mNodes.get(position);
        convertView = getConvertView(node, position, convertView, parent);
        // set inside padding
        convertView.setPadding(node.getLevel() * 40, 3, 3, 3);
//        if (node.getLevel() != 0){
//            convertView.setBackgroundColor(0xeeff0000);
//            convertView.getBackground().setAlpha(100);
//        }else{
//            convertView.setBackgroundColor(0);
//        }
        convertView.setBackgroundColor(0);
        return convertView;
    }

    public abstract View getConvertView(Node node, int position, View convertView, ViewGroup parent);

    public interface OnTreeNodeClickListener {
        void onClick(Node node, int position);
    }

}

package com.TagList;

import android.content.Context;
import android.graphics.Color;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import appInstance.ViewerApp;
import restAPIWithRMS.dataTypes.NXLabel;

public abstract class TreeListViewAdapter<T> extends BaseAdapter {

    private static final String CREATE_TIME_DEFAULT_VALUE = "$(current_time)";
    private static final String OWNER_NAME = "owner_name";
    private static final String OWNER_HOST = "owner_host";
    private static final String CREATE_TIME = "create_time";
    // all visible nodes
    public static List<Node> mNodes;
    public static ArrayList<Pair<String, String>> mreclassifyTagsOut;
    public static List<Node> mOriginalCurrentUserNodes;
    public static ListView mListView;
    private static TreeListViewAdapter instance;
    protected Context mContext;
    protected LayoutInflater mInflater;
    // all nodes
    private List<Node> mAllNodes;
    protected List<Node> mCurrentUserNodes;
    protected boolean mreclassify;
    protected boolean mIsAttributeTag;
    protected TextView mProtectOrReclassify;
    private List<Node> mAttributeAllNodes;
    private List<T> mAllData;
    private List<T> mCurrentUserData;
    // now the feature of save tag in attribute page have cancelled, so the parameter IsCanSave can be optimized.
    private boolean IsCanSave = false;
    private boolean IsAddNewTag = false;

    // click callback interface
    private OnTreeNodeClickListener onTreeNodeClickListener;

    public TreeListViewAdapter(ListView mTree, TextView mProtectSave, Context context, List<T> allData, List<T> currentUserData, ArrayList<Pair<String, String>> reclassifyTagsOut, final boolean reclassify, boolean mIsAttrTag)
            throws IllegalArgumentException, IllegalAccessException {
        mContext = context;
        mreclassify = reclassify;
        mIsAttributeTag = mIsAttrTag;
        mProtectOrReclassify = mProtectSave;
        mreclassifyTagsOut = reclassifyTagsOut;
        mListView = mTree;
        mAllData = allData;
        mCurrentUserData = currentUserData;
        // package source data into nodes (include tag node and value node) and organized  them into multiple tree. tag node -- label node, value node -- leaf node.
        mAllNodes = TreeHelper.getSortedNodes(allData);
        mOriginalCurrentUserNodes = TreeHelper.getSortedNodes(currentUserData);
        mCurrentUserNodes = TreeHelper.getSortedNodes(currentUserData);
        instance = this;

        // handle a original file
        if (reclassifyTagsOut == null) {
            // get the will display nodes ( root nodes and sub nodes of the default value) from all nodes.
            mNodes = TreeHelper.getDisplayNodes(mCurrentUserNodes, true, mIsAttributeTag, TreeHelper.getSortedNodes(currentUserData), IsCanSave);
        } else {
            // handle a nxl file
            if (!mIsAttrTag && mreclassify) {
                IsAddNewTag = true;
            }
            handleNxlFileTag(mCurrentUserNodes, mIsAttrTag);
        }

        mInflater = LayoutInflater.from(context);
        // set click event handler of listView item
        mTree.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                expandOrCollapse(position);
            }

        });

    }

    static public TreeListViewAdapter getInstance() {
        return instance;
    }

    public void setOnTreeNodeClickListener(OnTreeNodeClickListener onTreeNodeClickListener) {
        this.onTreeNodeClickListener = onTreeNodeClickListener;
    }

    // fix bug 33446.
    private void processTags(List<Node> listNodes, Pair<String, String> pair) {
        String tagName = pair.first;
        String tagValue = pair.second;
        for (Node node : mAllNodes) {
            if (node.getTagName() != null && node.getTagName().equals(tagName)) {
                node.setDefaultValue(tagValue);
                listNodes.add(node);
                // handle the value node
                node.getChildren().clear();
                if (tagValue.contains(",")) {
                    List<Node> childrenList = new ArrayList<>();
                    String[] values = tagValue.split(",");
                    for (String value : values) {
                        Node valueNode = new Node();
                        valueNode.setParent(node);
                        valueNode.setMultipleSelect(node.getMultipleSelect());
                        valueNode.setTagName("");
                        valueNode.setDisplayName("");
                        valueNode.setDefaultValue(value);
                        listNodes.add(valueNode);

                        childrenList.add(valueNode);
                    }
                    node.setChildren(childrenList);
                } else {
                    Node valueNode = new Node();
                    valueNode.setParent(node);
                    valueNode.setMultipleSelect(node.getMultipleSelect());
                    valueNode.setTagName("");
                    valueNode.setDisplayName("");
                    valueNode.setDefaultValue(tagValue);
                    listNodes.add(valueNode);

                    List<Node> childrenList = new ArrayList<>();
                    childrenList.add(valueNode);
                    node.setChildren(childrenList);
                }

                break;
            }
        }
    }

    // fix bug 33246 about tags order issue when view the tags protected on IOS device in android device.
    private ArrayList<Pair<String, String>> sortTags() {
        ArrayList<Pair<String, String>> tagList = new ArrayList<>();
        int countOwner = 0;
        int countHost = 0;
        for (Node node : mAllNodes) {
            for (Pair<String, String> onePair : mreclassifyTagsOut) {
                if (node.getTagName() != null && node.getTagName().equals(onePair.first)) {
                    Pair<String, String> pair = new Pair<String, String>(onePair.first, onePair.second);
                    if (OWNER_HOST.equals(onePair.first) && countHost >= 1) {
                        continue;
                    } else if (OWNER_NAME.equals(onePair.first) && countOwner >= 1) {
                        continue;
                    }

                    if (OWNER_HOST.equals(onePair.first)) {
                        countHost++;
                    } else if (OWNER_NAME.equals(onePair.first)) {
                        countOwner++;
                    }

                    tagList.add(pair);
                    break;
                }
            }
        }

        return tagList;
    }

    public void handleNxlFileTag(List<Node> currentUserNodes, boolean isAttributeTag) throws IllegalArgumentException, IllegalAccessException {
        // handle a nxl file
        List<Node> listNodes = new ArrayList<>();
        if (isAttributeTag || !mreclassify) {
            ArrayList<Pair<String, String>> sortTagsList = sortTags();
            for (Pair<String, String> pair : sortTagsList) {
                processTags(listNodes, pair);
            }
        } else {  // can reclassify in protect page.
            for (Node node : currentUserNodes) {
                for (Pair<String, String> pair : mreclassifyTagsOut) {
                    if (node.getTagName() != null && node.getTagName().equals(pair.first)) {
                        node.setDefaultValue(pair.second);
                        listNodes.add(node);
                        break;
                    }
                }
            }

            // padding current when reclassify.
            for (Node oneNode : listNodes) {
                if (oneNode.getDisplayName().equals("Create Time")) {
                    for (Node valueNode : TreeHelper.getValueNodeChildren(oneNode)) {
                        if (valueNode.getDefaultValue().equals(CREATE_TIME_DEFAULT_VALUE)) {
                            if (mreclassify) {
                                Calendar calendar = Calendar.getInstance();
                                String date = calendar.get(Calendar.YEAR) + "-" + (calendar.get(Calendar.MONTH) + 1) + "-" + calendar.get(Calendar.DAY_OF_MONTH)
                                        + " " + calendar.get(Calendar.HOUR_OF_DAY) + ":" + calendar.get(Calendar.MINUTE) + ":" + calendar.get(Calendar.SECOND);
                                valueNode.setDefaultValue(date);
                                oneNode.setDefaultValue(date);
                            } else {
                                valueNode.setDefaultValue(oneNode.getDefaultValue());
                            }
                        }
                    }
                }
            }

        }


        if (mIsAttributeTag) {
            mAttributeAllNodes = currentUserNodes;
        }

        // for this case that only have view tags right, we collapse the values firstly, only when user click,then the values that last selected will expand.
        if (isAttributeTag || !mreclassify) {
            List<Node> tagNodes = new ArrayList<>();
            for (Node node : listNodes) {
                if (!node.isLeaf() || !node.getDisplayName().isEmpty()) {
                    node.setExpand(false);
                    tagNodes.add(node);
                }
            }
            mNodes = tagNodes;
        } else {
            mNodes = TreeHelper.getDisplayNodes(listNodes, mreclassify, false, TreeHelper.getSortedNodes(mCurrentUserData), IsAddNewTag);
        }

    }

    // item click event handler
    public void expandOrCollapse(int position) {
        Node n = mNodes.get(position);

        // disabled listView item click if have no classify rights.  
        if (mreclassifyTagsOut != null) {

            if (mIsAttributeTag) {
                // return and can't continue to run the below handler,means disabled the item click.
                if (n.isLeaf() && !IsCanSave) {
                    return;
                }
            } else {
                if (!mreclassify && n.isLeaf()) {
                    // return and can't continue to run the below handler,means disabled the item click.
                    return;
                }
            }
        }

        if (n != null) {
            if (!n.isLeaf()) {  // click tag node.

                n.setExpand(!n.isExpand());
                mNodes = TreeHelper.filterVisibleNode(mNodes, n);
                notifyDataSetChanged();
            } else {  // click value Node
                if (n.getMultipleSelect()) {
                    multipleSelectHandler(n, position);
                } else {
                    singleSelectHandler(n, position);
                }
            }

        }
    }

    private void singleSelectHandler(Node n, int position) {
        if (mreclassifyTagsOut == null)
            TreeHelper.recoverBlackForMandatory(n, position);

        Node node = n.getParent();
        if (node.getFlagRed())
            node.setFlagRed(false);

        // if not exist red tags, enable protect button
        int i = 0;
        for (i = 0; i < mNodes.size(); i++) {
            if (!mNodes.get(i).isLeaf() && !mNodes.get(i).getFlagRed()) {
                continue;
            } else if (!mNodes.get(i).isLeaf() && mNodes.get(i).getFlagRed()) {
                break;
            }
        }

        if (i == mNodes.size()) {
            mProtectOrReclassify.setTextColor(Color.rgb(18, 26, 255));
            mProtectOrReclassify.setEnabled(true);
        }

        if (mIsAttributeTag) {
            mNodes = TreeHelper.filterVisibleNode2(mNodes, mAttributeAllNodes, n);
        } else {
            mNodes = TreeHelper.filterVisibleNode2(mNodes, mCurrentUserNodes, n);
        }

        notifyDataSetChanged();
    }

    private void multipleSelectHandler(Node n, int position) {

        Node parentNode = n.getParent();
        if (n.getChecked()) {
            n.setChecked(false);
            unCheckEvent(n);
        } else {
            n.setChecked(true);
            checkEvent(n, position);
        }

        String strDisplayValue = "";
        List<Node> checkedLists = new ArrayList<>();
        for (Node oneNode : TreeHelper.getValueNodeChildren(parentNode)) {
            if (oneNode.getChecked()) {
                checkedLists.add(oneNode);
            }
        }

        if (checkedLists.size() > 0) {
            for (int i = 0; i < checkedLists.size(); i++) {
                strDisplayValue += checkedLists.get(i).getDefaultValue();
                if (i < checkedLists.size() - 1) {
                    strDisplayValue += ",";
                }
            }
            parentNode.setDefaultValue(strDisplayValue);

        } else {
            parentNode.setDefaultValue("");
        }

        notifyDataSetChanged();
    }

    private void checkEvent(Node node, int position) {
        Node parentNode = node.getParent();

        if (mreclassifyTagsOut == null)
            TreeHelper.recoverBlackForMandatory(node, position);

        if (parentNode.getFlagRed())
            parentNode.setFlagRed(false);

        // if not exist red tags, enable protect button
        int j = 0;
        for (j = 0; j < mNodes.size(); j++) {
            if (!mNodes.get(j).isLeaf() && !mNodes.get(j).getFlagRed()) {
                continue;
            } else if (!mNodes.get(j).isLeaf() && mNodes.get(j).getFlagRed())
                break;
        }
        if (j == mNodes.size()) {
            mProtectOrReclassify.setTextColor(Color.rgb(18, 26, 255));
            mProtectOrReclassify.setEnabled(true);
        }

        // handle the subTag if have
        if (node.getSubValueId() != -1) { // have subTag.
            // search the location of insert
            int index = -1;
            for (int i = 0; i < mNodes.size(); i++) {
                if (mNodes.get(i) == parentNode) {
                    index = i; // parent location
                    break;
                }
            }

            // get the value node of click tagNode.
            List<Node> childLists = TreeHelper.getValueNodeChildren(parentNode);

            index += childLists.size();
            index += 1; // ---- need multiple test!!!

            // recursive add sub tag.
            TreeHelper.addSearchSubLabel(node, mNodes, mCurrentUserNodes, index);

        }
        notifyDataSetChanged();
    }

    private void unCheckEvent(Node node) {

        // handle the subTag if have
        if (node.getSubValueId() != -1) {
            TreeHelper.removeSearchSubLabel(node, mNodes);
        }

        notifyDataSetChanged();
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
        return convertView;
    }

    public abstract View getConvertView(Node node, int position, View convertView, ViewGroup parent);

    public interface OnTreeNodeClickListener {
        void onClick(Node node, int position);
    }

}


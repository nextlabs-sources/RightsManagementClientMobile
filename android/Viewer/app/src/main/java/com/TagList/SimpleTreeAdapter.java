package com.TagList;

import android.content.Context;
import android.graphics.Color;
import android.util.Pair;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.util.ArrayList;
import java.util.List;

public class SimpleTreeAdapter<T> extends TreeListViewAdapter<T> {
    private static final String TAG = "SimpleTreeAdapter";
    private static final int TYPE_COUNT = 2;
    private static final int TYPE_SingleSelect = 0;
    private static final int TYPE_MultipleSelect = 1;
    private int currentType;
    private ArrayList<Pair<String, String>> mreclassifyTags;

    public SimpleTreeAdapter(ListView mTree, TextView mProtectOrSave, Context context, List<T> allData, List<T> currentUserData, ArrayList<Pair<String, String>> reclassifyTags, boolean reclassify, boolean mIsAttrTag)
            throws IllegalArgumentException, IllegalAccessException {
        super(mTree, mProtectOrSave, context, allData, currentUserData, reclassifyTags, reclassify, mIsAttrTag);
        mreclassifyTags = reclassifyTags;
    }

    @Override
    public View getConvertView(final Node node, final int position, View convertView, ViewGroup parent) {
        ViewSingleHolder viewSingleHolder = null;
        ViewMultipleHolder viewMultipleHolder = null;

        currentType = getItemViewType(position);
        if (currentType == TYPE_SingleSelect) {
            if (convertView == null) {
                convertView = mInflater.inflate(R.layout.list_item, parent, false);

                viewSingleHolder = new ViewSingleHolder();
                viewSingleHolder.icon = (ImageView) convertView
                        .findViewById(R.id.id_treenode_icon);
                viewSingleHolder.displayName_tv = (TextView) convertView
                        .findViewById(R.id.id_treenode_tagName);
                viewSingleHolder.defaultValue_tv = (TextView) convertView
                        .findViewById(R.id.id_treenode_defaultValue);

                convertView.setTag(viewSingleHolder);
            } else {
                viewSingleHolder = (ViewSingleHolder) convertView.getTag();
            }

            //  set data
            if (node.getDefaultValue() != null) {

                if (!node.isLeaf()) { // label node
                    if (node.isExpand()) {
                        viewSingleHolder.defaultValue_tv.setText("");
                    } else {
                        viewSingleHolder.defaultValue_tv.setText(node.getDefaultValue());
                        viewSingleHolder.defaultValue_tv.setTextColor(Color.GRAY);

                        RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) viewSingleHolder.defaultValue_tv.getLayoutParams();
                        lp.removeRule(RelativeLayout.CENTER_VERTICAL);
                    }
                } else {  // leaf node
                    viewSingleHolder.defaultValue_tv.setText(node.getDefaultValue());
                    viewSingleHolder.defaultValue_tv.setTextColor(Color.BLACK);
                    // set textView vertical center.
                    RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) viewSingleHolder.defaultValue_tv.getLayoutParams();
                    lp.addRule(RelativeLayout.CENTER_VERTICAL);
                }
            }

            if (!node.isLeaf()) { // label node
                viewSingleHolder.displayName_tv.setText(node.getDisplayName());
                // set or remove textView vertical center.
                if (node.isExpand()) {
                    RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) viewSingleHolder.displayName_tv.getLayoutParams();
                    lp.addRule(RelativeLayout.CENTER_VERTICAL);
                } else {
                    RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) viewSingleHolder.displayName_tv.getLayoutParams();
                    lp.removeRule(RelativeLayout.CENTER_VERTICAL);
                }

                // set display name color (set red color for mandatory if not select)
                viewSingleHolder.displayName_tv.setTextColor(Color.BLACK);
                String strDefaultValue = node.getDefaultValue();

                if (node.getMandatory() && (strDefaultValue.equals("Select...") || strDefaultValue.isEmpty()) && viewSingleHolder.displayName_tv.getTextColors().getDefaultColor() != Color.RED) {
                    viewSingleHolder.displayName_tv.setTextColor(Color.RED);
                    node.setFlagRed(true);
                }

                // set expand or collapse icon
                TreeHelper.setNodeIcon(node);
                viewSingleHolder.icon.setVisibility(View.VISIBLE);
                viewSingleHolder.icon.setImageResource(node.getIcon());

                // hidden  button
                if (node.getFlagRed()) {
                    mProtectOrReclassify.setTextColor(Color.GRAY);
                    mProtectOrReclassify.setEnabled(false);
                }

            } else {  // leaf node
                viewSingleHolder.displayName_tv.setText("");
                TreeHelper.setCheckIcon(node);
                Node parentNode = node.getParent();

                // check for the default value
                String defaultValues = "";
                if (parentNode != null) {
                    defaultValues = parentNode.getDefaultValue();
                }

                if (!defaultValues.isEmpty() && !defaultValues.equals("Select...")) {
                    if (defaultValues.equals(node.getDefaultValue())) {
                        viewSingleHolder.icon.setVisibility(View.VISIBLE);
                        viewSingleHolder.icon.setImageResource(node.getIcon());
                        node.setChecked(true);
                    } else {
                        viewSingleHolder.icon.setVisibility(View.INVISIBLE);
                        viewSingleHolder.icon.setImageResource(node.getIcon());
                        node.setChecked(false);
                    }
                } else {
                    viewSingleHolder.icon.setVisibility(View.INVISIBLE);
                    viewSingleHolder.icon.setImageResource(node.getIcon());
                    node.setChecked(false);
                }

            }

        } else if (currentType == TYPE_MultipleSelect) {
            if (convertView == null) {
                convertView = mInflater.inflate(R.layout.list_multiple_item, parent, false);
                viewMultipleHolder = new ViewMultipleHolder();
                viewMultipleHolder.defaultValue_tv = (TextView) convertView
                        .findViewById(R.id.id_treenode_mul_defaultValue);

                viewMultipleHolder.icon = (ImageView) convertView
                        .findViewById(R.id.id_treenode_mul_icon);

                convertView.setTag(viewMultipleHolder);

            } else {
                viewMultipleHolder = (ViewMultipleHolder) convertView.getTag();
            }

            // set data
            String value = node.getDefaultValue();
            viewMultipleHolder.defaultValue_tv.setText(value);
            TreeHelper.setCheckIcon(node);

            // check for default value
            String defaultValues = node.getParent().getDefaultValue();
            if (!defaultValues.isEmpty() && !defaultValues.equals("Select...")) {
                if (!defaultValues.contains(",")) {
                    if (node.getDefaultValue().equals(defaultValues)) {
                        viewMultipleHolder.icon.setVisibility(View.VISIBLE);
                        viewMultipleHolder.icon.setImageResource(node.getIcon());
                        node.setChecked(true);
                    } else {
                        viewMultipleHolder.icon.setVisibility(View.INVISIBLE);
                        viewMultipleHolder.icon.setImageResource(node.getIcon());
                        node.setChecked(false);
                    }
                } else {
                    String[] theValues = defaultValues.split(",");
                    int i = 0;
                    for (i = 0; i < theValues.length; i++) {
                        if (node.getDefaultValue().equals(theValues[i])) {
                            viewMultipleHolder.icon.setVisibility(View.VISIBLE);
                            viewMultipleHolder.icon.setImageResource(node.getIcon());
                            node.setChecked(true);
                            break;
                        }
                    }
                    if (i == theValues.length) {
                        viewMultipleHolder.icon.setVisibility(View.INVISIBLE);
                        viewMultipleHolder.icon.setImageResource(node.getIcon());
                        node.setChecked(false);
                    }
                }
            } else {
                viewMultipleHolder.icon.setVisibility(View.INVISIBLE);
                viewMultipleHolder.icon.setImageResource(node.getIcon());
                node.setChecked(false);
            }

        }

        // set the background of value nodes is white.
        if (!node.isLeaf()) {
            convertView.setBackgroundColor(Color.rgb(240, 240, 240));
        } else {
            convertView.setBackgroundColor(Color.WHITE);
        }

        // disabled the button protect or save if have no classify rights.
        if (mreclassifyTagsOut != null && !mreclassify) {
            mProtectOrReclassify.setTextColor(Color.GRAY);
            mProtectOrReclassify.setEnabled(false);
        }

        return convertView;
    }

    @Override
    public int getItemViewType(int position) {

        Node node = mNodes.get(position);
        if (node.getMultipleSelect() && node.getDisplayName() != null && (node.getDisplayName().equals("") || node.getDisplayName().isEmpty())) {  // only is valueNode
            return TYPE_MultipleSelect;
        } else {
            return TYPE_SingleSelect;
        }
    }

    @Override
    public int getViewTypeCount() {
        return TYPE_COUNT;
    }

    private final class ViewSingleHolder {
        ImageView icon;
        TextView displayName_tv;
        TextView defaultValue_tv;
    }

    private final class ViewMultipleHolder {
        ImageView icon;
        TextView defaultValue_tv;
    }
}


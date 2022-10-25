package com.TagList;

import android.graphics.Color;
import android.text.TextUtils;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

public class TreeHelper {
    public static <T> List<Node> getSortedNodes(List<T> datas) throws IllegalArgumentException, IllegalAccessException {
        List<Node> result = new ArrayList<Node>();
        // convert data into List<Node>
        List<Node> nodes = convetData2Node(datas);
        // get root nodes
        List<Node> rootNodes = getRootNodes(nodes);
        // sort and set nodes parent-child relation
        for (Node node : rootNodes) {
            addNode(result, node, 1);
        }
        return result;
    }

    public static List<Node> getDisplayNodes(List<Node> nodes, boolean reclassify, boolean isAttributeTag, List<Node> allOriginalNodes, boolean isAddNewTag) {
        List<Node> result = new ArrayList<Node>();
        List<Node> rootNodes = getRootNodes(nodes);
        for (Node node : rootNodes) {
            result.add(node);

            // add the value nodes of this node.
            addValueNodes(result, node, reclassify, isAttributeTag);
            // add sub node.
            addTagNode(result, nodes, node, reclassify, isAttributeTag);
        }

        // the new root labels and its default sub-labels should be added if these labels from RMS changed may because of new policy.
        if (isAddNewTag) {
            List<Node> rootAllNodes = getRootNodes(allOriginalNodes);
            for (Node oneRootNode : rootAllNodes) {
                int i = 0;
                for (i = 0; i < rootNodes.size(); i++) {
                    if (oneRootNode.getId() == rootNodes.get(i).getId()) {
                        break;
                    }
                }
                // can not find oneRootNode in rootNodes. means oneRootNode is a new root node.
                if (i == rootNodes.size()) {
                    // when the newly added tag containing "Create Time", need get the current time.
                    if (oneRootNode.getDisplayName().equals("Create Time")) {
                        for (Node valueNode : TreeHelper.getValueNodeChildren(oneRootNode)) {
                            if (valueNode.getDefaultValue().equals("$(current_time)")) {
                                Calendar calendar = Calendar.getInstance();
                                String date = calendar.get(Calendar.YEAR) + "-" + (calendar.get(Calendar.MONTH) + 1) + "-" + calendar.get(Calendar.DAY_OF_MONTH)
                                        + " " + calendar.get(Calendar.HOUR_OF_DAY) + ":" + calendar.get(Calendar.MINUTE) + ":" + calendar.get(Calendar.SECOND);
                                valueNode.setDefaultValue(date);
                                oneRootNode.setDefaultValue(date);
                            }
                        }
                    }
                    result.add(oneRootNode);
                    // add the value nodes of this node.
                    addValueNodes(result, oneRootNode, reclassify, isAttributeTag);
                    // add sub node.
                    addTagNode(result, allOriginalNodes, oneRootNode, reclassify, isAttributeTag);
                }
            }
        }

        return result;
    }

    public static void removeSearchSubLabel(Node valueNode, List<Node> visibleNodes) {
        Node subNode = getNodeBySubValueId(visibleNodes, valueNode.getSubValueId());

        String defaultValue = subNode.getDefaultValue();
        if (!defaultValue.isEmpty() && defaultValue != "Select...") { // have default value
            if (defaultValue.contains(",")) {
                List<Node> tmpNodes = getValueNodeByLabelDefaultValueEx(subNode);
                for (Node node : tmpNodes) { // 每一个分别递归
                    if (node.getSubValueId() != -1) {
                        removeSearchSubLabel(node, visibleNodes);
                    }
                }
            } else {
                Node node = getValueNodeByLabelDefaultValue(subNode);
                if (node != null && node.getSubValueId() != -1) { // original defaultValue have subLabel
                    removeSearchSubLabel(node, visibleNodes);
                }
            }

        }

        visibleNodes.remove(subNode);

        // set original default value back before remove
        for (Node node : TreeListViewAdapter.mOriginalCurrentUserNodes) {
            if (node.getId() == subNode.getId()) {
                subNode.setDefaultValue(node.getDefaultValue());
            }
        }

        if (subNode.isExpand()) {

            List<Node> childLists = subNode.getChildren();
            for (Node node : childLists) {
                if (node.isLeaf()) {
                    visibleNodes.remove(node);
                    node.setChecked(false);
                }
            }
        }

    }

    public static List<Node> filterVisibleNode2(List<Node> visibleNodes, List<Node> allNodes, Node clickNode) {

        // remove original subTag (and the valueNodes of the subTag if have) if have
        Node parentNode = clickNode.getParent();
        String defaultValue = parentNode.getDefaultValue();
        if (!defaultValue.isEmpty() && defaultValue != "Select...") { // have default value
            Node valueNode = getValueNodeByLabelDefaultValue(parentNode);
            if (valueNode != null && valueNode.getSubValueId() != -1) { // original defaultValue have subLabel
                removeSearchSubLabel(valueNode, visibleNodes);
            }
        }

        //  set default value.
        if (clickNode.getChecked()) {
            parentNode.setDefaultValue("");
            clickNode.setChecked(false);
        } else {
            parentNode.setDefaultValue(clickNode.getDefaultValue());
            clickNode.setChecked(true);
        }

        // judge new value if have subTag,if have then add these subTag and their value nodes.
        Node valueNode = getValueNodeByLabelDefaultValue(parentNode);
        int index = -1; // the location of parent node.
        for (int i = 0; i < visibleNodes.size(); i++) {
            if (visibleNodes.get(i) == parentNode) {
                index = i;
                break;
            }
        }

        if (valueNode != null && valueNode.getSubValueId() != -1) { // original defaultValue have subLabel
            int insertIndex = index + getValueNodeFromChildren(parentNode).size() + 1;
            addSearchSubLabel(valueNode, visibleNodes, allNodes, insertIndex);
        }

        return visibleNodes;
    }

    public static void addSearchSubLabel(Node valueNode, List<Node> visibleNodes, List<Node> allNodes, int index) {
        Node subNode = getNodeBySubValueId(allNodes, valueNode.getSubValueId());

        String defaultValue = subNode.getDefaultValue();
        if (!defaultValue.isEmpty() && !defaultValue.equals("Select...")) { // have default value
            if (defaultValue.contains(",")) {
                List<Node> tmpNodes = getValueNodeByLabelDefaultValueEx(subNode);
                for (Node node : tmpNodes) {
                    if (node.getSubValueId() != -1) {
                        addSearchSubLabel(node, visibleNodes, allNodes, index);
                    }
                }
            } else {
                Node node = getValueNodeByLabelDefaultValue(subNode);
                if (node != null && node.getSubValueId() != -1) { // original defaultValue have subLabel
                    addSearchSubLabel(node, visibleNodes, allNodes, index);
                }
            }

        }

        visibleNodes.add(index, subNode);  // note: recursive add is beginning with the last one.
        subNode.setExpand(true); // here is critical

        // also add the value nodes of this node.
        visibleNodes.addAll(index + 1, getValueNodeFromChildren(subNode));
    }

    // recover black for mandatory when user select.
    public static void recoverBlackForMandatory(Node n, int position) {
        Node node = n.getParent();
        List<Node> childLists = node.getChildren();
        int parentPosition = -1;
        for (int i = 0; i < childLists.size(); i++) {
            if (childLists.get(i).isLeaf() && childLists.get(i).getDefaultValue().equals(n.getDefaultValue())) {
                parentPosition = position - (i + 1);
                break;
            }
        }
        RelativeLayout relativeLayout = (RelativeLayout) TreeListViewAdapter.mListView.getAdapter().getView(parentPosition, null, null);
        TextView textView_displayName = (TextView) relativeLayout.getChildAt(0);
        if (node.getMandatory() && node.getDefaultValue().equals("Select...") && textView_displayName.getTextColors().getDefaultColor() == Color.RED) {
            textView_displayName.setTextColor(Color.BLACK);
        }
    }

    public static List<Node> filterValuesByPriority(String defaultValue, List<Node> leafNodes) {
        List<Node> result = new ArrayList<>();
        int defaultId = -1;
        if (!defaultValue.contains(",")) {
            for (int i = 0; i < leafNodes.size(); i++) {
                if (leafNodes.get(i).getDefaultValue().equals(defaultValue)) {
                    defaultId = i;
                    break;
                }
            }
        } else {
            String[] defaultValues = defaultValue.split(",");
            int maxIndex = -1;
            for (String defaultvalue : defaultValues) {
                int tmpIndex = -1;
                for (int i = 0; i < leafNodes.size(); i++) {
                    if (leafNodes.get(i).getDefaultValue().equals(defaultvalue)) {
                        tmpIndex = i;
                        break;
                    }
                }
                if (tmpIndex > maxIndex)
                    maxIndex = tmpIndex;
            }

            defaultId = maxIndex;
        }

        if (defaultId != -1 && leafNodes.get(defaultId).getPriority() != -1) {
            for (int j = 0; j < leafNodes.size(); j++) {
                if (leafNodes.get(j).getPriority() >= leafNodes.get(defaultId).getPriority()) {
                    result.add(leafNodes.get(j));
                }
            }

            return result;
        } else {
            return leafNodes;
        }

    }

    public static List<Node> filterVisibleNode(List<Node> visibleNodes, Node clickNode) {

        // get the value node of click tagNode.
        List<Node> childLists = getValueNodeChildren(clickNode);

        // expand or collapse the value nodes of the clickNode.
        int index = -1;
        if (clickNode.isExpand()) { // add valueNodes (LeafNode) of clickNode

            for (int i = 0; i < visibleNodes.size(); i++) {
                if (visibleNodes.get(i) == clickNode) {
                    index = i;
                    break;
                }
            }

            // for value priority
//            if (TreeListViewAdapter.mreclassifyTagsOut != null && !clickNode.getDefaultValue().equals("") && !clickNode.getDefaultValue().equals("Select...")) {
//                childLists = filterValuesByPriority(clickNode.getDefaultValue(), childLists);
//                clickNode.setChildren(childLists);
//            }

            visibleNodes.addAll(index + 1, childLists);
        } else { // remove valueNodes (LeafNode) of clickNode

            for (int i = 0; i < visibleNodes.size(); i++) {
                if (visibleNodes.get(i) == clickNode) {
                    index = i;
                    break;
                }
            }

            for (int i = 0; i < childLists.size(); i++) {
                visibleNodes.remove(index + 1);
            }

        }

        // tagNode.isExpand 取反，将图标设反
        setNodeIcon(clickNode);

        return visibleNodes;
    }

    public static List<Node> getValueNodeChildren(Node node) {
        List<Node> valueNodeChildren = new ArrayList<>();
        for (Node oneNode : node.getChildren()) {
            if (oneNode.isLeaf()) {
                valueNodeChildren.add(oneNode);
            }
        }
        return valueNodeChildren;
    }

    public static Node getNodeBySubValueId(List<Node> nodes, int subValueId) {
        for (Node node : nodes) {
            if (node.getId() == subValueId)
                return node;
        }
        return null;
    }

    public static String getTagNameByDisplayName(String displayName) {
        for (Node node : SimpleTreeAdapter.mNodes) {
            if (node.getDisplayName().equals(displayName)) {
                return node.getTagName();
            }
        }
        return null;
    }

    public static Node getNodeByTagName(String tagName) {
        for (Node node : SimpleTreeAdapter.mNodes) {
            if (node.getTagName().equals(tagName)) {
                return node;
            }
        }
        return null;
    }

    public static Node getValueNodeByLabelDefaultValue(Node LabelNode) {  // defaultValue not contains ","
        List<Node> nodeList = LabelNode.getChildren(); // include value node and the subNode of each value node.
        for (Node one : nodeList) {
            if (one.isLeaf() && LabelNode.getDefaultValue().equals(one.getDefaultValue()))
                return one;
        }
        return null;
    }

    public static List<Node> getValueNodeByLabelDefaultValueEx(Node LabelNode) {  // defaultValue contains ","
        List<Node> result = new ArrayList<>();
        List<Node> nodeList = LabelNode.getChildren();
        String[] values = LabelNode.getDefaultValue().split(",");
        for (String value : values) {
            for (Node one : nodeList) {
                if (one.isLeaf() && value.equals(one.getDefaultValue()))
                    result.add(one);
            }
        }

        return result;
    }

    // convert data source into tree nodes
    private static <T> List<Node> convetData2Node(List<T> datas) throws IllegalArgumentException, IllegalAccessException {
        List<Node> nodes = new ArrayList<Node>();
        Node node = null;

        for (T t : datas) {
            int id = -1;
            int pId = -2;
            int SubValueId = -1;
            int priority = -1;
            String tagName = null;
            String displayName = null;
            String defaultValue = null;
            boolean multipleSelect = false;
            boolean mandatory = false;

            Class<? extends Object> clazz = t.getClass();
            Field[] declaredFields = clazz.getDeclaredFields();
            for (Field f : declaredFields) {
                if (f.getAnnotation(TreeNodeId.class) != null) {
                    f.setAccessible(true);
                    id = f.getInt(t);
                }
                if (f.getAnnotation(TreeNodePid.class) != null) {
                    f.setAccessible(true);
                    pId = f.getInt(t);
                }
                if (f.getAnnotation(TreeNodeSubValueId.class) != null) {
                    f.setAccessible(true);
                    SubValueId = f.getInt(t);
                }

                if (f.getAnnotation(TreeNodeTagName.class) != null) {
                    f.setAccessible(true);
                    tagName = (String) f.get(t);
                }
                if (f.getAnnotation(TreeNodeDisplayName.class) != null) {
                    f.setAccessible(true);
                    displayName = (String) f.get(t);
                }
                if (f.getAnnotation(TreeNodeDefaultValue.class) != null) {
                    f.setAccessible(true);
                    defaultValue = (String) f.get(t);
                }
                if (f.getAnnotation(TreeNodeMultipleSelect.class) != null) {
                    f.setAccessible(true);
                    multipleSelect = (boolean) f.get(t);
                }
                if (f.getAnnotation(TreeNodeMandatory.class) != null) {
                    f.setAccessible(true);
                    mandatory = (boolean) f.get(t);
                }
                if (f.getAnnotation(TreeNodePriority.class) != null) {
                    f.setAccessible(true);
                    priority = f.getInt(t);
                }

                if (id != -1 && pId != -2 && SubValueId != -1 && tagName != null && displayName != null && defaultValue != null && multipleSelect != false && mandatory != false && priority != -1) {
                    break;
                }

            }

            node = new Node(id, pId, SubValueId, tagName, displayName, defaultValue, multipleSelect, mandatory, priority);
            nodes.add(node);
        }

        // set parent and children relationship. getChildren() contains its real tag nodes and its value nodes.
        for (int i = 0; i < nodes.size(); i++) {   // --- nodes contains tag node and value  node.
            Node n = nodes.get(i);
            for (int j = i + 1; j < nodes.size(); j++) {
                Node m = nodes.get(j);
                if (m.getpId() == n.getId()) { // m is n children
                    n.getChildren().add(m);
                    m.setParent(n);
                } else if (m.getId() == n.getpId()) { // n is m children
                    m.getChildren().add(n);
                    n.setParent(m);
                }
            }
        }

        // set icon
        for (Node n : nodes) {
            if (!n.getDisplayName().isEmpty())
                setNodeIcon(n);
        }

        return nodes;
    }

    private static List<Node> getRootNodes(List<Node> nodes) {
        List<Node> root = new ArrayList<Node>();
        for (Node node : nodes) {
            if (node.isRoot())
                root.add(node);
        }
        return root;
    }

    // organize a tree for nodes
    private static void addNode(List<Node> nodes, Node node, int currentLevel) {

        nodes.add(node);
        if (node.isLeaf()) {
            return;
        }

        // getChildren ---  value node  and tag node.
        for (int i = 0; i < node.getChildren().size(); i++) {
            addNode(nodes, node.getChildren().get(i), currentLevel + 1);
        }
    }

    private static void addTagNode(List<Node> resultNodes, List<Node> allNodes, Node node, boolean reclassify, boolean isAttributeTag) {
        if (node.getDefaultValue().isEmpty() || node.getDefaultValue().equals("Select...")) {  // have no defaultValue
            return;
        }

        if (node.getDefaultValue().contains(",")) {
            List<Node> tmpNodes = getValueNodeByLabelDefaultValueEx(node);
            for (Node oneNode : tmpNodes) {
                if (oneNode.getSubValueId() != -1) {
                    // defaultValue have subTag
                    Node subTagNode = getNodeBySubValueId(allNodes, oneNode.getSubValueId());
                    if (null == subTagNode) {
                        return;
                    }
                    resultNodes.add(subTagNode);

                    // add the value nodes of this subTagNode.
                    addValueNodes(resultNodes, subTagNode, reclassify, isAttributeTag);

                    addTagNode(resultNodes, allNodes, subTagNode, reclassify, isAttributeTag);
                }
            }
        } else {
            Node valueNode = getValueNodeByLabelDefaultValue(node);

            if (null == valueNode) {
                return;
            }
            if (valueNode.getSubValueId() == -1) {  // defaultValue  have no subTag.
                return;
            }

            // defaultValue have subTag
            Node subTagNode = getNodeBySubValueId(allNodes, valueNode.getSubValueId());
            resultNodes.add(subTagNode);

            // add the value nodes of this subTagNode.
            addValueNodes(resultNodes, subTagNode, reclassify, isAttributeTag);

            addTagNode(resultNodes, allNodes, subTagNode, reclassify, isAttributeTag);
        }
    }

    private static void addValueNodes(List<Node> resultNodes, Node node, boolean reclassify, boolean isAttributeTag) {

        if (isAttributeTag) {
            displayLastSelectedTag(resultNodes, node);
        } else {
            if (reclassify) {
                // reclassify , need handle for priority of values -- fix bug 22604  
                if (TreeListViewAdapter.mreclassifyTagsOut != null) {
                    List<Node> childLists = getValueNodeChildren(node);
                    if (!TextUtils.isEmpty(node.getDefaultValue()) && !"Select...".equals(node.getDefaultValue())) {
                        childLists = filterValuesByPriority(node.getDefaultValue(), childLists);
                    }
                    node.setChildren(childLists);
                    resultNodes.addAll(childLists);
                } else {  // protect
                    for (Node one : node.getChildren()) {
                        if (one.isLeaf()) {
                            resultNodes.add(one);
                        }
                    }
                }
            } else {  // only read, display the tag values that last selected, so need filter.
                displayLastSelectedTag(resultNodes, node);
            }
        }
    }

    private static void displayLastSelectedTag(List<Node> resultNodes, Node node) {
        List<Node> valueNodesList = getValueNodeFromChildren(node);
        if (!node.getDefaultValue().contains(",")) { // single select
            for (Node oneValue : valueNodesList) {
                if (!oneValue.getDefaultValue().equals(node.getDefaultValue())) {
                    node.getChildren().remove(oneValue);
                } else {
                    resultNodes.add(oneValue);
                }
            }
        } else { // default value contains ","
            String defaultValueNodes[] = node.getDefaultValue().split(",");
            for (Node oneValue : valueNodesList) {
                int i = 0;
                for (i = 0; i < defaultValueNodes.length; i++) {
                    if (defaultValueNodes[i].equals(oneValue.getDefaultValue())) {
                        resultNodes.add(oneValue);
                        break;
                    }
                }
                // oneValue is not the default value node
                if (i == defaultValueNodes.length) {
                    node.getChildren().remove(oneValue);
                }
            }
        }
    }

    public static List<Node> getValueNodeFromChildren(Node node) {
        List<Node> resultNodes = new ArrayList<>();
        for (Node one : node.getChildren()) {
            if (one.isLeaf()) {
                resultNodes.add(one);
            }
        }

        return resultNodes;
    }

    // set nodes icon
    public static void setNodeIcon(Node node) {
        if (!node.isExpand()) {
            node.setIcon(R.drawable.expand_arrow); // isExpand = false
        } else if (node.isExpand()) {
            node.setIcon(R.drawable.forward); // isExpand = true
        } else
            node.setIcon(-1);
    }

    public static void setCheckIcon(Node node) {
        node.setIcon(R.drawable.protect_checkmark);
    }

}


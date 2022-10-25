package phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode;

import com.nextlabs.viewer.R;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

public class TreeHelper {
    public static <T> List<Node> getSortedNodes(List<T> datas,
                                                int defaultExpandLevel) throws IllegalArgumentException,
            IllegalAccessException {
        List<Node> result = new ArrayList<Node>();
        List<Node> nodes = convertData2Node(datas);
        List<Node> rootNodes = getRootNodes(nodes);
        for (Node node : rootNodes) {
            addNode(result, node, defaultExpandLevel, 1);
        }
        return result;
    }

    public static List<Node> filterVisibleNode(List<Node> nodes) {
        List<Node> result = new ArrayList<Node>();
        for (Node node : nodes) {
            if (node.isRoot() || node.isParentExpand()) {
                setNodeIcon(node);
                setNodeThumb(node);
                setNodeCheck(node);
                result.add(node);
            }
        }
        return result;
    }

    private static <T> List<Node> convertData2Node(List<T> datas)
            throws IllegalArgumentException, IllegalAccessException {
        List<Node> nodes = new ArrayList<Node>();
        Node node = null;

        for (T t : datas) {
            int id = -1;
            int pId = -1;
            LeftMenuItem label = null;
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
                if (f.getAnnotation(TreeNodeLabel.class) != null) {
                    f.setAccessible(true);
                    label = (LeftMenuItem) f.get(t);
                }
                if (id != -1 && pId != -1 && label != null) {
                    break;
                }
            }
            node = new Node(id, pId, label);
            nodes.add(node);
        }

        for (int i = 0; i < nodes.size(); i++) {
            Node n = nodes.get(i);
            for (int j = i + 1; j < nodes.size(); j++) {
                Node m = nodes.get(j);
                if (m.getpId() == n.getId()) {
                    n.getChildren().add(m);
                    m.setParent(n);
                } else if (m.getId() == n.getpId()) {
                    m.getChildren().add(n);
                    n.setParent(m);
                }
            }
        }

        for (Node n : nodes) {
            setNodeIcon(n);
            setNodeThumb(n);
            setNodeCheck(n);
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

    private static void addNode(List<Node> nodes, Node node,
                                int defaultExpandLevel, int currentLevel) {

        nodes.add(node);
        if (defaultExpandLevel >= currentLevel) {
            node.setExpand(true);
        }

        if (node.isLeaf())
            return;
        for (int i = 0; i < node.getChildren().size(); i++) {
            addNode(nodes, node.getChildren().get(i), defaultExpandLevel,
                    currentLevel + 1);
        }
    }

    private static void setNodeIcon(Node node) {
        if (node.getChildren().size() > 0 && node.isExpand()) {
            node.setIcon(R.drawable.home_leftmenu_ex);
        } else if (node.getChildren().size() > 0 && !node.isExpand()) {
            node.setIcon(R.drawable.home_leftmenu_ec);
        } else
            node.setIcon(-1);
    }

    private static void setNodeThumb(Node node) {
        String nodeName = node.getName();
        int nodeParentId = node.getpId();
        if (nodeParentId == 0) {
            if (nodeName.equals("My Drive")) {
                node.setThumbImage(R.drawable.home_leftmenu_cloud);
            } else if (nodeName.equals("Favorite")) {
                node.setThumbImage(R.drawable.home_leftmenu_favorite);
            } else if (nodeName.equals("Offline")) {
                node.setThumbImage(R.drawable.home_leftmenu_offline);
            } else if (nodeName.equals("Account")) {
                node.setThumbImage(R.drawable.home_leftmenu_account);
            } else if (nodeName.equals("Help")) {
                node.setThumbImage(R.drawable.home_leftmenu_help);
            }

        } else if (nodeParentId == 1) {
            if (nodeName.equals("DropBox")) {
                node.setThumbImage(R.drawable.home_leftmenu_dropbox);
            } else if (nodeName.equals("OneDrive")) {
                node.setThumbImage(R.drawable.home_leftmenu_onedrive);
            } else if (nodeName.equals("SharePoint")) {
                node.setThumbImage(R.drawable.home_leftmenu_sharepoint);
            } else if (nodeName.equals("SharePointOnline")) {
                node.setThumbImage(R.drawable.home_leftmenu_sharepoint);
            } else if (nodeName.equals("GoogleDrive")) {
                node.setThumbImage(R.drawable.home_leftmenu_google);
            } else if (nodeName.equals("Add Drive")) {
                node.setThumbImage(R.drawable.home_leftmenu_add);
            }
        }
    }

    private static void setNodeCheck(Node node) {
        String nodeName = node.getName();
        int nodeParentId = node.getpId();
        if (nodeParentId == 1) {
            switch (nodeName) {
                case "DropBox":
                case "OneDrive":
                case "SharePoint":
                case "SharePointOnline":
                case "GoogleDrive":
                    if (node.isChecked()) {
                        node.setCheckImage(1);
                    } else {
                        node.setCheckImage(-1);
                    }
                    break;
                default:
                    node.setCheckImage(-1);
                    break;
            }
        } else {
            node.setCheckImage(-1);
        }
    }
}

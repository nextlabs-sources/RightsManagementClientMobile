package phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode;

import java.util.ArrayList;
import java.util.List;

import database.BoundService;

public class Node {
    // list id
    private int id;
    // parent id, root id equals 0
    private int pId = 0;
    // list name
    private LeftMenuItem menuItem;
    // current level
    private int level;
    private boolean isExpand = false;
    // slide icon
    private int icon;
    private int thumbImage;

    private boolean isChecked = false;
    private int checkImage;


    private List<Node> children = new ArrayList<Node>();
    private Node parent;

    public Node() {
    }

    public Node(int id, int pId, LeftMenuItem menuItem) {
        super();
        this.id = id;
        this.pId = pId;
        this.menuItem = menuItem;
    }

    public int getIcon() {
        return icon;
    }

    public void setIcon(int icon) {
        this.icon = icon;
    }

    public int getThumbImage() {
        return thumbImage;
    }

    public void setThumbImage(int thumb) {
        this.thumbImage = thumb;
    }

    public int getCheckImage() {
        return checkImage;
    }

    public void setCheckImage(int check) {
        checkImage = check;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getpId() {
        return pId;
    }

    public void setpId(int pId) {
        this.pId = pId;
    }

    public String getName() {
        return menuItem.getName();
    }

    public void setName(String name) {
        this.menuItem.setName(name);
    }

    public BoundService getBoundService() {
        return menuItem.getBoundService();
    }

    public void setBoundService(BoundService bs) {
        this.menuItem.setBoundService(bs);
    }

    public LeftMenuItem getMenuItem() {
        return menuItem;
    }

    public void setMenuItem(LeftMenuItem menuItem) {
        this.menuItem = menuItem;
    }

    public boolean isExpand() {
        return isExpand;
    }

    public void setExpand(boolean isExpand) {
        this.isExpand = isExpand;
        if (!isExpand) {
            for (Node node : children) {
                node.setExpand(isExpand);
            }
        }
    }

    public boolean isChecked() {
        return isChecked;
    }

    public void setChecked(boolean isChecked) {
        this.isChecked = isChecked;
    }

    public List<Node> getChildren() {
        return children;
    }

    public void setChildren(List<Node> children) {
        this.children = children;
    }

    public Node getParent() {
        return parent;
    }

    public void setParent(Node parent) {
        this.parent = parent;
    }

    public boolean isRoot() {
        return parent == null;
    }

    public boolean isParentExpand() {
        if (parent == null)
            return false;
        return parent.isExpand();
    }

    public boolean isLeaf() {
        return children.size() == 0;
    }

    public int getLevel() {
        return parent == null ? 0 : parent.getLevel() + 1;
    }

    public void setLevel(int level) {
        this.level = level;
    }
}
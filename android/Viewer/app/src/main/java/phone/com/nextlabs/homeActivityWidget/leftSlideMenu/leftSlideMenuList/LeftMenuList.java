package phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList;

import database.BoundService;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.LeftMenuItem;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.TreeNodeId;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.TreeNodeLabel;
import phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode.TreeNodePid;

/**
 * Created by eric on 10/22/2015.
 */
public class LeftMenuList {
    @TreeNodeId
    private int id;
    @TreeNodePid
    private int parentId;
    @TreeNodeLabel
    private LeftMenuItem menuItem;

    public LeftMenuList(int id, int parentId, LeftMenuItem menuItem) {
        super();
        this.id = id;
        this.parentId = parentId;
        this.menuItem = menuItem;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getpId() {
        return parentId;
    }

    public void setpId(int pId) {
        this.parentId = pId;
    }

    public String getName() {
        return this.menuItem.getName();
    }

    public void setName(String label) {
        this.menuItem.setName(label);
    }

    public LeftMenuItem getMenuItem() {
        return this.menuItem;
    }

    public void setMenuItem(LeftMenuItem menuItem) {
        this.menuItem = menuItem;
    }

    public BoundService getBoundService() {
        return this.menuItem.getBoundService();
    }

    public void setBoundService(BoundService boundService) {
        menuItem.setBoundService(boundService);
    }
}

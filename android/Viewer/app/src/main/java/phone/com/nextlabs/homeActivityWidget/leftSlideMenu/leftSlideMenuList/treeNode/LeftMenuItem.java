package phone.com.nextlabs.homeActivityWidget.leftSlideMenu.leftSlideMenuList.treeNode;

import database.BoundService;

/**
 * Created by eric on 10/25/2015.
 */
public class LeftMenuItem {
    private String name;
    private BoundService boundService;

    public LeftMenuItem(String name, BoundService boundService) {
        this.name = name;
        this.boundService = boundService;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BoundService getBoundService() {
        return boundService;
    }

    public void setBoundService(BoundService boundService) {
        this.boundService = boundService;
    }
}

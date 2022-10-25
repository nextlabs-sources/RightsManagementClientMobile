package database;

import java.io.Serializable;


public class BoundService implements Serializable {
    public int id;
    public int userID;  // used as primary key to represent a user
    public ServiceType type;
    public String alias;
    public String account;
    public String accountID;
    public String accountToken;
    public int selected;

    public BoundService(int id, int userID, ServiceType type, String alias, String account, String accountID, String accountToken, int selected) {
        this.id = id;
        this.userID = userID;
        this.type = type;
        this.alias = alias;
        this.account = account;
        this.accountID = accountID;
        this.accountToken = accountToken;
        this.selected = selected;
    }

    public enum ServiceType {
        DROPBOX(0),
        SHAREPOINT_ONLINE(1),
        SHAREPOINT(2),
        ONEDRIVE(3),
        RECENT(4),
        GOOGLEDRIVE(5);

        private int value = 0;

        ServiceType(int type) {
            value = type;
        }

        public static ServiceType valueOf(int value) {
            switch (value) {
                case 0:
                    return DROPBOX;
                case 1:
                    return SHAREPOINT_ONLINE;
                case 2:
                    return SHAREPOINT;
                case 3:
                    return ONEDRIVE;
                case 4:
                    return RECENT;
                case 5:
                    return GOOGLEDRIVE;
                default:
                    throw new IllegalArgumentException("value" + value + " is not a legal value to convert to ServiceType");
            }
        }

        public int value() {
            return this.value;
        }

    }


}

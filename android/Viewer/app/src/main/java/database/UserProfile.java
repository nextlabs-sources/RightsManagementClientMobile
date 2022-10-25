package database;


public class UserProfile {
    public int id;      // this is autoincremental value
    public String name;
    public String token;
    public int type;    // 0: for ldap,   or others ,  NOT USED FOR NOW
    public long timeout;
    public String server;
    public long login_time;
    public long last_access_time;
    public long logout_time;
    public String login_server;


    public UserProfile(int id, String name, String token, int type, long timeout, String server,
                       long login_time, long last_access_time, long logout_time, String login_server) {
        this.id = id;
        this.name = name;
        this.token = token;
        this.type = type;
        this.timeout = timeout;
        this.server = server;
        this.login_time = login_time;
        this.last_access_time = last_access_time;
        this.logout_time = logout_time;
        this.login_server = login_server;
    }
}



package appInstance.remoteRepo.sharepointonline;

/**
 * Created by aning on 6/2/2015.
 */

public class Account {

    private String mUsername;
    private String mUrl;
    private String mCookie;

    public Account() {
        mUsername = "";
        mUrl = "";
        mCookie = "";
    }

    public String getUsername() {
        return this.mUsername;
    }

    public void setUsername(String Username) {
        this.mUsername = Username;
    }

    public String getUrl() {
        return this.mUrl;
    }

    public void setUrl(String Url) {
        this.mUrl = Url;
    }

    public String getCookie() {
        return this.mCookie;
    }

    public void setCookie(String Cookie) {
        this.mCookie = Cookie;
    }
}

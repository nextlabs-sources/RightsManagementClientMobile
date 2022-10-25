package rms.common;

public class NXClientInfo {
    public String serialNumber;
    // content
    public int platformId;
    public long heartbeatInterval;
    public long logInterval;
    public String bypassFilter;
    public boolean bProtectionEnabled;

    public NXClientInfo() {
        serialNumber = null;
        platformId = -1;
        heartbeatInterval = -1;
        logInterval = -1;
        bypassFilter = null;
        bProtectionEnabled = false;
    }
}

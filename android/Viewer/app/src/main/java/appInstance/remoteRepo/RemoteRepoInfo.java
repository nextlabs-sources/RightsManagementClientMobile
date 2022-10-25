package appInstance.remoteRepo;

/**
 * As required, remote repo should provide some information about repo's user and repos itself.
 */
public class RemoteRepoInfo {
    public String displayName = "unknown";
    public String email = "unknown";
    public long remoteTotalSpace = 0; // in bytes
    public long remoteUsedSpace = 0; // in bytes

}

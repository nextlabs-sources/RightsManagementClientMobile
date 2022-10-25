package appInstance.localRepo;

import appInstance.remoteRepo.RemoteRepoInfo;

/**
 * Created by oye on 3/7/2016.
 */
public class RepoInfo extends RemoteRepoInfo {
    public long localOfflineSize = 0;
    public long localCachedSize = 0;
    public long localTotalSize = 0;
}

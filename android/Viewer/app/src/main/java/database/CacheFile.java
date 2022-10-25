package database;


public class CacheFile {
    public int id;
    public int userID;
    public int serviceID;
    public String sourcePath;
    public String cachePath;
    public long cacheSize;
    public String checksum;
    public String cachedTime;
    public String accessTime;
    public int offlineFlag;
    public int favoriteFlag;
    public String safePath;

    public CacheFile(int id, int userID, int serviceID, String sourcePath, String cachePath, long cacheSize,
                     String checksum, String cachedTime, String accessTime, int offlineFlag, int favoriteFlag, String safePath) {
        this.id = id;
        this.userID = userID;
        this.serviceID = serviceID;
        this.sourcePath = sourcePath;
        this.cachePath = cachePath;
        this.cacheSize = cacheSize;
        this.checksum = checksum;
        this.cachedTime = cachedTime;
        this.accessTime = accessTime;
        this.offlineFlag = offlineFlag;
        this.favoriteFlag = favoriteFlag;
        this.safePath = safePath;
    }
}

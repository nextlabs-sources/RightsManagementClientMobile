package appInstance;

import android.app.Activity;
import android.app.Application;
import android.content.SharedPreferences;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import commonUtils.AppVersionHelper;
import database.ViewerDB;
import restAPIWithRMS.DecryptionToken;
import restAPIWithRMS.EncryptionTokens;
import restAPIWithRMS.HeartBeat2;
import restAPIWithRMS.Membership;
import rms.common.NXUserInfo;

import java.io.File;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import javax.annotation.Nonnull;

import appInstance.localRepo.ILocalRepo;
import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.onedrive.NXOneDrive;
import commonUtils.NetworkStatus;
import database.BoundService;
import database.CacheFile;
import database.UserProfile;
import errorHandler.ErrorCode;
import nxl.types.INxFile;
import restAPIWithRMS.Listener;
import restAPIWithRMS.RouterLoginURL;
import restAPIWithRMS.dataTypes.NXKeyRing;
import restAPIWithRMS.dataTypes.NXLabel;

/**
 * This class is designed to manage all lifecycle of app and hold Global instances
 * -            holds repository system
 * -            holds database
 * -            holds session for current login user
 * -               - use SharedPreference to store and recover significant fields of current login user
 * -            make communication with RMS
 * -            get rights and labels for current login user
 */
public class ViewerApp extends Application {

    /*
     * this filed is used to let all app components to display debug info
     * for release version , keep it as  DEBUG = false;
     */
    static public final boolean DEBUG = true;
    static private final String TAG = "NX_APP";
    static private final String FIRST_SIGN_FLAG = "firstSignFlagCache";
    //static private final String USER_LOGIN_PASSWORD = "userLoginPassword";
    static public NetworkStatus networkStatus;
    private static ViewerApp singleton;
    private File repoMountPoint;
    private RepoSystem repoSystem = new RepoSystem();
    private ViewerDB dataBase2;
    private final Session session = new Session();
    private RunningMode previousMode = RunningMode.SYNTHETIC;  //by default

    private Session2 session2 = new Session2();

    //used to check whether the page from view page.
    public static boolean isFromViewPage = false;

    static public ViewerApp getInstance() {
        return singleton;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        singleton = this;
        initGlobalInstance();

    }

    private void initGlobalInstance() {
        //dataBase.initDataBase();
        dataBase2 = new ViewerDB(this);
        networkStatus = new NetworkStatus(this);
        initMountPoint();

    }

    public boolean isNeedToShowWelcome() {
        SharedPreferences sp = ViewerApp.getInstance().getSPreferences();
        boolean firstSignIn = sp.getBoolean("firstSignIn", true);
        if (firstSignIn) {
            SharedPreferences.Editor editor = sp.edit();
            int versionCode = AppVersionHelper.getVersionCode(getApplicationContext());
            editor.putInt("VersionCode", versionCode);
            editor.apply();
        }
        return firstSignIn || isVersionChange();
    }

    public void setWelcomeHadShowed() {
        SharedPreferences sp = ViewerApp.getInstance().getSPreferences();
        SharedPreferences.Editor editor = sp.edit();
        editor.putBoolean("firstSignIn", false);
        editor.apply();
    }

    private boolean isVersionChange() {
        int currentVersionCode = AppVersionHelper.getVersionCode(getApplicationContext());
        SharedPreferences sp = ViewerApp.getInstance().getSPreferences();
        int oldVersionCode = sp.getInt("VersionCode", 0);
        return currentVersionCode != oldVersionCode;
    }

    public Session2 getSession() {
        return session2;
    }


    /**
     * todo: check every state ,if any error occurs , whole app corrupted
     *
     * @return
     */
    private boolean initMountPoint() {
        repoMountPoint = getExternalFilesDir(null);
        repoMountPoint = new File(repoMountPoint, "cache");
        if (!repoMountPoint.exists()) {
            repoMountPoint.mkdirs();
        }
        return true;
    }

    //get file system mount point
    public File getMountPoint() {
        return repoMountPoint;
    }

    //
    // internal Event response
    //

    public void onInitializeRepoSystem(@Nonnull Activity homeActivity, @Nonnull final RepoSysInitializeListener listener) {
        //
        List<BoundService> services = getAllCloudServicesOfCurrentUser();

        boolean isNeedInitOneDrive = false;
        for (BoundService s : services) {
            if (s.type == BoundService.ServiceType.ONEDRIVE) {
                isNeedInitOneDrive = true;
                break;
            }
        }
        if (!isNeedInitOneDrive) {
            listener.progress("Initializing repository system");
            initRepoSystem();
            listener.progress("Activating repository system");
            activateRepoSystem();
            listener.success();
            return;
        }

        listener.progress("Initializing OneDrive session");
        NXOneDrive.init(homeActivity, new NXOneDrive.InitListener() {
            @Override
            public void result(boolean status) {
                if (status) {
                    listener.progress("Initializing repository system");
                    initRepoSystem();
                    listener.progress("Activating repository system");
                    activateRepoSystem();
                    listener.success();
                } else {
                    listener.failed(ErrorCode.REPO_ONE_DRIVE_INIT_FAILED, "ops, failed when initializing OneDrive SDK");
                }
            }
        });
    }


    /**
     * Will be called just after a new session build completely
     * - repo system depends this point to perform initialization task
     */
    private void onNewSessionBuildingComplete() {
        // close exist
        repoSystem.create(repoMountPoint, getSession().getUserInfo().getEmail()); //require session has initialized
    }

    /**
     * Be called when user log out
     */
    private void onCloseSessionComplete() {
        repoSystem.close();

    }

    //
    // Repo operations
    //

    /**
     * restore current login user's attached repos from database,
     * usually it was called just before client wants to use it
     */
    public void initRepoSystem() {
        repoSystem.attach(getAllCloudServicesOfCurrentUser());
    }

    public void activateRepoSystem() {
        repoSystem.activate();
    }

    /**
     * this will shutdown repo system and save all internal data into disk
     * Knowledge:
     * - for current log-in user performing logout , call it
     * - for system shutdown this process, call it
     */
    public void deactivateRepoSystem() {
        repoSystem.deactivate();
    }

    /**
     * delete a repository
     * - for current login user ,to unlink a repo
     */
    public void removeRepo(BoundService service) throws Exception {
        try {
            // remove items from cache_db related with this service
            List<CacheFile> files = getCacheFiles();
            for (CacheFile f : files) {
                if (f.serviceID == service.id) {
                    delCacheFile(f);
                }
            }
            repoSystem.detach(service);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    /**
     * Used to judge repoSystem is Running at Synthetic mode and Synthetic root
     */
    public boolean isInSyntheticRoot() {
        return repoSystem.isInSyntheticRoot();
    }
//    /**
//     * @param service repo you want as the focused ,
//     *                null:  use all livingRepo  , not use a single
//     * @throws Exception
//     */
//    public void changeFocusedRepo(BoundService service) throws Exception {
//        repoSystem.setFocusedRepo(service);
//    }

    /**
     * used to switch the state of an attached repo to active
     * <ol>
     * <li>activate state means contents of this repo can be accessed</li>
     * <li>deactivate state means contents of this repo can NOT be accessed</li>
     * </ol>
     * <p/>
     * Remarks:
     * <p>the ability of a activated repo includes :
     * <ol>
     * <li>listing offline files , favorite files</li>
     * <li>adding its root contents into the ShadowRoot</li>
     * </ol>
     * </p>
     */
    public void activateRepo(BoundService service) throws Exception {
        try {
            if (service == null) {
                throw new RuntimeException(ErrorCode.E_RT_PARAM_SERVICE_INVALID);
            }
            repoSystem.activateRepo(service);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }

    }

    /**
     * user want to deactivate a repo
     * affect state of repoSystem
     *
     * @param service
     * @throws Exception
     */
    public void deactivateRepo(BoundService service) throws Exception {
        try {
            if (service == null) {
                throw new RuntimeException(ErrorCode.E_RT_PARAM_SERVICE_INVALID + "at APP:deactivateRepo");
            }
            repoSystem.deactivateRepo(service);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    public void markAsFavorite(INxFile file) {
        try {
            BoundService service = file.getService();
            if (service == null) {
                return;
            }
            ILocalRepo repo = repoSystem.findInLivingRepo(service);
            if (repo == null) {
                return;
            }
            repo.markAsFavorite(file);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }

    }

    public void unmarkAsFavorite(INxFile file) {
        try {
            BoundService service = file.getService();
            if (service == null) {
                return;
            }
            ILocalRepo repo = repoSystem.findInLivingRepo(service);
            if (repo == null) {
                return;
            }
            repo.unmarkAsFavorite(file);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    public void markAsOffline(INxFile file) {
        try {
            BoundService service = file.getService();
            if (service == null) {
                return;
            }
            ILocalRepo repo = repoSystem.findInLivingRepo(service);
            if (repo == null) {
                return;
            }
            repo.markAsOffline(file);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    public void unmarkAsOffline(INxFile file) {
        try {
            BoundService service = file.getService();
            if (service == null) {
                return;
            }
            ILocalRepo repo = repoSystem.findInLivingRepo(service);
            if (repo == null) {
                return;
            }
            repo.unmarkAsOffline(file);

        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    public List<INxFile> getFavoriteFiles() {
        try {
            onEnterFavoriteOrOfflineMode();
            return repoSystem.getFavoriteFiles();
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    public List<INxFile> getOfflineFiles() {
        try {
            onEnterFavoriteOrOfflineMode();
            return repoSystem.getOfflineFiles();
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    private void onEnterFavoriteOrOfflineMode() {
        RunningMode curMode = repoSystem.getState();
        if (curMode != RunningMode.FAVORITE && curMode != RunningMode.OFFLINE) {
            previousMode = curMode;
        }
    }

    /**
     * Important ,
     * be used to notify app to restore previous mode
     */
    public void onLeaveFavoriteOrOfflineMode() {
        repoSystem.changeState(previousMode);
    }

    /**
     * known used:
     * - home activity , enter a folder
     */
    public List<INxFile> listFolder(INxFile folder, IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        return repoSystem.enterFolder(folder, callback);
    }

    /**
     * Get local working folder directly, for typical usage scenario ,
     * get the current repo's local caches ,NO USE SOCKET
     * Known used:
     * - home activity, timer task of  refresh, i.e.  UI calls this method periodically
     * - home activity, sort the contents of this folder
     */
    public List<INxFile> listWorkingFolder() throws Exception {
        return repoSystem.listFolder();
    }

    /**
     * Get the current working folder
     */
    public INxFile findWorkingFolder() throws Exception {
        return repoSystem.findWorkingFolder();
    }

    /**
     * Mandatorily use network to sync current working folder
     * Known used:
     * - home activity, pull down to refresh
     */
    public void syncWorkingFolder(@Nonnull IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        if (DEBUG) Log.d(TAG, "TBD:syncWorkingFolder");
        try {
            if (callback == null) {
                throw new RuntimeException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);
            }
            // for no network
            if (!ViewerApp.networkStatus.isNetworkAvailable()) {
                throw new RuntimeException(ErrorCode.E_IO_NO_NETWORK);
                //callback.getFileMetaInfoFinished(false,null,ErrorCode.E_IO_NO_NETWORK);
            }
            repoSystem.syncWorkingFolder(callback);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    public int getSizeOfLivingRepo() {
        return repoSystem.getSizeOfLivingRepo();
    }

    /**
     * Get all Living repos's root files(files and folders)
     * <p/>
     * NOTICE:
     * call this method will affect each local repos's focused folder to ROOT
     */
    public Map<ILocalRepo, List<INxFile>> getLivingReposRoot() {
        return repoSystem.getRootByLivingRepos();
    }

    public void refreshRepos(List<ILocalRepo> repos,
                             IRemoteRepo.IGetFileMetaInfoCallback callback) throws Exception {
        if (callback == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_CALLBACK_INVALID);
        }
        if (repos == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "repos");
        }
        repoSystem.refreshSpecificRoot(repos, callback);
    }

    /**
     * get a document content, the document must linked with a BoundService
     * <p/>
     * remarks:
     * - this method will change focused repo
     * - repoSystem can find the @{document} is belong to which living repo
     * - if not find the host of the @{document}, throw Exception
     */
    public
    @Nullable
    File getFile(INxFile document, IRemoteRepo.IDownLoadCallback callback) throws Exception {
        try {
            BoundService service = document.getService();
            if (service == null) {
                throw new RuntimeException(ErrorCode.E_REPO_NULL_LINKED_SERVICE + document.getLocalPath());
            }
            ILocalRepo repo = repoSystem.findInLivingRepo(service);
            if (repo == null) {
                throw new RuntimeException(ErrorCode.E_REPO_NO_REPOS + "living repos");
            }
            repoSystem.setFocusedRepo(repo);
            return repo.getDocument(document, callback);
        } catch (Exception e) {
            if (DEBUG) {
                Log.d(TAG, e.toString());
                e.printStackTrace();
            }
            throw e;
        }
    }

    /**
     * this method must be called when repoSystem has focused repo
     */
    public void uploadFile(INxFile parentFolder, String fileName, File localFile, IRemoteRepo.IUploadFileCallback callback) throws Exception {
        if (DEBUG) Log.d(TAG, "TBD:uploadFile");
        ILocalRepo repo = repoSystem.getFocusedRepo();
        if (repo == null) {
            return;
        }

        repo.uploadFile(parentFolder, fileName, localFile, callback);
    }

    /**
     * this method must be called when repoSystem has focused repo
     */
    public void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IRemoteRepo.IUploadFileCallback callback) throws Exception {
        if (DEBUG) Log.d(TAG, "TBD:updateFile");
        ILocalRepo repo = repoSystem.getFocusedRepo();
        if (repo == null) {
            return;
        }
        repo.updateFile(parentFolder, updateFile, localFile, callback);
    }

    /**
     * this method will change current working folder
     */
    public INxFile uptoParent() {
        return repoSystem.getParent();
    }

    /**
     * this method will not affect current working folder
     */
    public INxFile findParent(INxFile child) {
        return repoSystem.getParent(child, false);
    }

    /**
     * this method will not affect current working folder
     */
    public INxFile findParentThroughBoundService(INxFile child) {
        return repoSystem.getParent(child, true);
    }


    // clean the repos' cache file that is not marked as offline
    public void clearReposCache(final ClearCacheListener listener) {
        if (listener == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "-listener");
        }
        repoSystem.clearCache(listener);
    }

    public void clearRepoCache(final BoundService boundService, final ClearCacheListener listener) {
        if (boundService == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "boundService");
        }
        if (listener == null) {
            throw new RuntimeException(ErrorCode.E_RT_PARAM_INVALID + "-listener");
        }
        repoSystem.clearRepoCache(boundService, listener);

    }

    public long calReposCacheSize() {
        return repoSystem.calReposCacheSize();
    }


    public boolean addService(BoundService.ServiceType type, String alias, String account, String accountId, String accountToken, int selected) {
        //return dataBase.addService(session.getCurrentUser(), type, alias, account, accountId, accountToken, selected);
        return dataBase2.addService(session2.userInfo.getUserId(), session2.tenantId, type, alias, account, accountId, accountToken, selected);
    }

    public void delService(BoundService boundService) {
        // dataBase.delService(boundService);
        dataBase2.delService(session2.userInfo.getUserId(), session2.tenantId, boundService);
    }

    public void updateService(BoundService boundService) {
        //dataBase.updateService(boundService);
        dataBase2.updateService(session2.userInfo.getUserId(), session2.tenantId, boundService);
    }

    public UserProfile getCurrentUser() {
        return session.getCurrentUser();
    }

//    public void removeUser(UserProfile user) {
//        dataBase.removeUser(user);
//    }

    public List<CacheFile> getCacheFiles() {
        return new ArrayList<>(); //wait for new interface
        // return dataBase.getCachedFilesByUser(session.getCurrentUser());
    }

    public boolean addCacheFile(int serviceId, String sourcePath, String cachePath, long cacheSize, String checksum, String cachedTime, String accessTime, int offlineFlag, int favoriteFlag, String safePath) {
        return true; // wait for new interface
        //return dataBase.addCacheFiles(session.getCurrentUser(), serviceId, sourcePath, cachePath, cacheSize, checksum, cachedTime, accessTime, offlineFlag, favoriteFlag, safePath);
    }

    public void delCacheFile(CacheFile cacheFile) {
        return; //wait for new interface
        //dataBase.delCacheFile(cacheFile);
    }

    public void getRepoInformation(BoundService boundService, ILocalRepo.IRepoInfoCallback callback) {
        repoSystem.getRepoInformation(boundService, callback);
    }

    public List<BoundService> getAllCloudServicesOfCurrentUser() {
        return dataBase2.queryService(session2.userInfo.getUserId(), session2.tenantId);
    }

    public void closeSession() {
        session2.closeSession();
        // new interface
        onCloseSessionComplete();
    }

    public boolean getUserLoginUrl_2(String rmServer, String tenant, Listener listener) {
        RouterLoginURL loginURL = new RouterLoginURL();
        try {
            RouterLoginURL.Response Response = loginURL.invokeToRMS(rmServer, tenant, listener);
            session2.loginErrorCode = Response.getErrorCode();
            //session2.loginErrorMessage = Response.getErrorMsg();
            if (session2.loginErrorCode == 200) {
                session2.rmServer = Response.getLoginPageUrl(); // rms server url.
                return true;
            } else {
                return false;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public String sessionGetUserLoginUrl_2() {
        return session2.rmServer;
    }

    public int sessionGetAgentId() {
        return session.agentId;
    }

    public String sessionGetAgentCertification() {
        return session.getAgentCertification();
    }

    public String sessionGetHeartBeatRawXml() {
        return session.heartBeatResponseXml;
    }

    public List<NXKeyRing> sessionGetKeyRings() {
        return session.nxKeyRingList;
    }

    public List<String> sessionGetSupportedCadFormats() {
        return session.nxSupportedCadFormats;
    }

    public List<NXLabel> sessionGetLabelsByCurrentUser() {
        return session.nxLabelListByCurrentUser;
    }

    public List<NXLabel> sessionGetLabelsByAll() {
        return session.nxLabelListByAll;
    }


    /**
     * save the flag value that if the user first sign in
     */
    public SharedPreferences getSPreferences() {
        return getSharedPreferences(FIRST_SIGN_FLAG, MODE_PRIVATE);
    }

    public interface SessionRecoverListener {
        void onSuccess();

        void onAlreadyExist();

        void onFailed(String reason);

        void onProcess(String hint);
    }

    public void recoverySession(@NonNull SessionRecoverListener listener) {
        /*
        On failed ,clear seeson
         */
        listener.onProcess("check session validation");
        if (session2.isSessionValid()) {
            listener.onProcess("session has existed");
            listener.onAlreadyExist();
            return;
        }

        listener.onProcess("session recovering...");
        if (!session2.recoverSession(listener)) {
            session2.clearSession();
            return;
        }

        // session recovery OK!
        onNewSessionBuildingComplete();

        listener.onProcess("session check ttl");
        // session ttl test
        boolean sessionExpired = session2.sessionExpired();

        if (!sessionExpired) {
            session2.startHeartBeatTask();
            listener.onProcess("session recovered");
            listener.onSuccess();
        } else {
            // session exists,but expired
            session2.clearSession();
            listener.onFailed("session has recovered, but expired");
        }

    }


    public String getSessionSid() {
        return session.sid;
    }

    public int getSessionUserID() {
        return session.getCurrentUserID();
    }

    public String getSessionServer() {
        return session.getCurrentServer();
    }


    public interface RepoSysInitializeListener {
        void success();

        void failed(int errorCode, String errorMsg);

        void progress(String msg);
    }

    public interface ClearCacheListener {
        void finished();
    }

    /**
     * Hold all important fields that can represent current login user
     */
    @Deprecated
    class Session {
        static private final String SESSION_CACHE = "sessionCache";
        private UserProfile currentUser;
        // common
        private String sid;
        private String certification;
        private int agentId;
        private String agentProfileName;
        private String agentProfileModifiedDate;
        private String commProfileName;
        private String commProfileModifiedDate;
        private int heartBeatFrequencyWithSecond;

        // rms related
        private List<NXKeyRing> nxKeyRingList;
        private List<NXLabel> nxLabelListByCurrentUser;
        private List<NXLabel> nxLabelListByAll;
        private List<String> nxSupportedCadFormats;
        private String heartBeatResponseXml;

        // this background thread is used to periodically communicate with RMS to get heartbeat response.
        private Thread heartbeatTask;


        public String getAgentCertification() {
            return certification;
        }

        public void updateCurrentUser(UserProfile user) {
            currentUser = user;
        }

        public UserProfile getCurrentUser() {
            return currentUser;
        }

        public int getCurrentUserID() {
            return currentUser.id;
        }

        public String getCurrentServer() {
            return currentUser.server;
        }


        public String getToken() {
            return currentUser.token;
        }

    }


    // new session.
    public class Session2 {
        static private final String SESSION_CACHE = "sessionCache";

        private String heartBeatResponseJson;
        private int loginErrorCode;
        private NXUserInfo userInfo;
        private String rmServer;  // rms server
        private String tenantId;

        // for DH
        private String certificates;
        private String privateKey;
        private List<String> agreements;

        // encryption tokens
        private Map<String, String> mapTokens = new HashMap<>();
        // used to cache decryption toke
        private Map<String, String> mapDecryptTokens = new HashMap<>();
        // maintenance level
        private int ml;
        // decryption token
        private String decryptToken;

        // this background thread is used to periodically communicate with RMS to get heartbeat response.
        private Thread heartbeatTask;

        // for test rest api
        private Membership membership = new Membership();
        private EncryptionTokens encryptionTokens = new EncryptionTokens();
        private DecryptionToken decryptionToken = new DecryptionToken();

        /**
         * whether user has loged on and lasted a valid communicating with RMS
         */
        public boolean isSessionValid() {
            return userInfo != null && !sessionExpired();
        }

        /**
         * Any exceptions occured will be resulted to return true
         */
        private boolean sessionExpired() {
            if (userInfo == null) {
                return true;
            }
            long ttl = userInfo.getTtl();
            long now = System.currentTimeMillis();
            if (DEBUG) {
                Log.d(TAG, "Check if session expired:\n" +
                        "Now:\t" + new Date(now).toString()
                        + "\nExpired:\t" + new Date(ttl).toString()
                        + "\nResult:\t" + (ttl < now));
            }
            return ttl < now;

        }

        public void newSession(NXUserInfo userInfo, String tenantId) {
            this.userInfo = userInfo;
            this.tenantId = tenantId;

            saveSession();
            startHeartBeatTask();
        }

        public void closeSession() {
            stopHeartBeatTask();
            clearSession();
            userInfo = null;
        }

        public void startGetToken() {
            try {
                membership.invokeToRMS(getCurrentServer(), userInfo);
                certificates = membership.getCertificates();
                privateKey = membership.getPrivateKey();
                encryptionTokens.invokeToRMS(getCurrentServer(), userInfo);
                agreements = encryptionTokens.getAgreements();

                mapTokens = encryptionTokens.getMapTokens();
                ml = encryptionTokens.getMl();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        public String getCertificates() {
            return certificates;
        }

        public String getPrivateKey() {
            return privateKey;
        }

        public List<String> getAgreements() {
            return agreements;
        }

        public Map<String, String> getMapDecryptTokens() {
            return mapDecryptTokens;
        }

        public Map<String, String> getMapTokens() {
            return mapTokens;
        }

        public int getMl() {
            return ml;
        }

        public String getTenantId() {
            return tenantId;
        }

        public long getCurrentTimeout() {
            return userInfo.getTtl();
        }

        public NXUserInfo getUserInfo() {
            return this.userInfo;
        }

        public String getCurrentServer() {
            return rmServer;
        }


        private void startHeartBeatTask() {
            heartbeatTask = new Thread(new BackGroundHearBeat());
            heartbeatTask.start();
        }

        private void stopHeartBeatTask() {
            heartbeatTask.interrupt();
        }

        /**
         * save some shared preference
         */
        private synchronized void saveSession() {
            SharedPreferences sp = getSharedPreferences(SESSION_CACHE, MODE_PRIVATE);
            SharedPreferences.Editor editor = sp.edit();
            {
                editor.putString("raw_rm_user_json", userInfo.getRawJSON());
                editor.putString("rm_server", rmServer);
                editor.putString("tenantId", tenantId);
            }
            editor.apply();

        }


        private synchronized boolean recoverSession() {
            // recover common login profile
            String userJson;
            String serverURL;
            String tenantID;
            // retrieve session values
            try {
                SharedPreferences sp = getSharedPreferences(SESSION_CACHE, MODE_PRIVATE);
                userJson = sp.getString("raw_rm_user_json", "NULL");
                if (userJson.equals("NULL")) {
                    return false;
                }
                serverURL = sp.getString("rm_server", "NULL");
                if (serverURL.equals("NULL")) {
                    return false;
                }
                tenantID = sp.getString("tenantId", "NULL");
                if ("NULL".equals(tenantID)) {
                    return false;
                }
            } catch (Exception e) {
                return false;
            }

            userInfo = NXUserInfo.parseUserInfo(userJson);
            rmServer = serverURL;
            tenantId = tenantID;
            // recover login msg
            loginErrorCode = 0;
            return true;

        }

        private synchronized boolean recoverSession(SessionRecoverListener listener) {
            // recover common login profile
            String userJson;
            String serverURL;
            String tenantID;

            // retrieve session values
            try {
                SharedPreferences sp = getSharedPreferences(SESSION_CACHE, MODE_PRIVATE);
                userJson = sp.getString("raw_rm_user_json", "NULL");
                if (userJson.equals("NULL")) {
                    listener.onFailed("failed recovering session");
                    return false;
                }
                serverURL = sp.getString("rm_server", "NULL");
                if (serverURL.equals("NULL")) {
                    listener.onFailed("failed recovering session");
                    return false;
                }
                tenantID = sp.getString("tenantId", "NULL");
                if ("NULL".equals(tenantID)) {
                    listener.onFailed("failed recovering session");
                    return false;
                }
            } catch (Exception e) {
                listener.onFailed("failed recovering session,exception:" + e.toString());
                return false;
            }

            userInfo = NXUserInfo.parseUserInfo(userJson);
            rmServer = serverURL;
            tenantId = tenantID;
            // recover login msg
            loginErrorCode = 0;
            listener.onProcess("success recovering session!");
            return true;
        }


        private synchronized void clearSession() {
            SharedPreferences sp = getSharedPreferences(SESSION_CACHE, MODE_PRIVATE);
            SharedPreferences.Editor editor = sp.edit();
            editor.clear();
            editor.apply();

            userInfo = null;
            rmServer = null;
            tenantId = null;


        }

        class BackGroundHearBeat implements Runnable {
            private HeartBeat2 heartBeat = new HeartBeat2();

            @Override
            public void run() {
                boolean isUnknownHost = false;
                while (!Thread.interrupted()) {
                    try {
                        if (isUnknownHost) {
                            isUnknownHost = false;
                            TimeUnit.SECONDS.sleep(30);
                        }
                        if (ViewerApp.networkStatus.isNetworkAvailable()) {
                            //todo: what about WiFi is on, but can not make a good communication?
                            TaskWithNetworkOn();
                            TimeUnit.SECONDS.sleep(1800);
                        } else { // no network
                            TaskWithNetworkOff();
                        }
                        // sleep
                        //   TimeUnit.SECONDS.sleep(heartBeatFrequencyWithSecond);

                    } catch (UnknownHostException e) {
                        isUnknownHost = true;
                        // may be calsed by bad network ,try to recover from disk
                        try {
                            TaskWithNetworkOff();
                        } catch (Exception ee) {
                        }
                        Log.e(TAG, "network error,wait for 30 seconds,and try again!");
                        //try TaskWithNetworkOff
                    } catch (InterruptedException e) {
                        Log.e(TAG, "task thread is been interrupted!");
                        break;
                    } catch (Exception e) {
                        e.printStackTrace();
                        Log.e(TAG, e.toString());
                    }
                }// end while
            }

            private void TaskWithNetworkOn() throws Exception {
                heartBeat.invokeToRMS(getCurrentServer(), getUserInfo().getTicket(), String.valueOf(getUserInfo().getUserId()));
                // write cache to disk each time when get new heart beat response
                heartBeatResponseJson = heartBeat.getRawNetStreamContent();

                //serializeToDisk();
            }

            private void TaskWithNetworkOff() throws Exception {
                //heartBeatResponseJson = unserializeFromDisk();
                // heartBeat.setRawNetStreamContent(heartBeatResponseJson);
                //heartBeat.parseResponseManually(heartBeatResponseJson);

            }

            /**
             * As requirements, task must store heartbeat response to local in case of no network
             * - every time when getting response, encrypt raw json data and write into disk
             * - use aes128 with key = md5(SID);
             */

        }
    }
}

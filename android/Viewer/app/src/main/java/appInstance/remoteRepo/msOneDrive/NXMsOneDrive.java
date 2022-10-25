package appInstance.remoteRepo.msOneDrive;

import android.app.Activity;

import com.onedrive.sdk.authentication.IAccountInfo;
import com.onedrive.sdk.authentication.MSAAuthenticator;
import com.onedrive.sdk.core.ClientException;
import com.onedrive.sdk.core.DefaultClientConfig;
import com.onedrive.sdk.core.IClientConfig;
import com.onedrive.sdk.extensions.IOneDriveClient;
import com.onedrive.sdk.extensions.OneDriveClient;
import com.onedrive.sdk.logger.LoggerLevel;

import java.io.File;

import appInstance.remoteRepo.IRemoteRepo;
import appInstance.remoteRepo.RemoteRepoInfo;
import nxl.types.INxFile;

/**
 * this will use the new version of OneDrive Open SDK
 * But for currently ,It's not stable ,
 */
public class NXMsOneDrive implements IRemoteRepo {
    static final private String ONEDRIVE_CLIENT_ID = "00000000481767DB";
    static final private String[] ONEDRIVE_SCOPES = {
            "wl.signin", //Allows your application to take advantage of single sign-on capabilities.
            "onedrive.readwrite",   //Grants read and write permission to all of a user's OneDrive files
            "onedrive.appfolder",   //Grants read and write permissions to a specific folder for your application
            "wl.offline_access" //Allows your application to receive a refresh token so it can work offline even when the user isn't active
    };

    // OneDrive Client
    private static IOneDriveClient mOneDriveClient;

    static public void startOAuth2Authentication(Activity activity, final IOAuth2Result resultCallback) {
        final DefaultCallback<IOneDriveClient> callback = new DefaultCallback<IOneDriveClient>(activity) {
            @Override
            public void success(IOneDriveClient iOneDriveClient) {
                mOneDriveClient = iOneDriveClient;
                resultCallback.success(mOneDriveClient.getAuthenticator().getAccountInfo());
            }

            @Override
            public void failure(ClientException error) {
                super.failure(error);
                resultCallback.failure(error.getMessage());
            }
        };
        new OneDriveClient.Builder()
                .fromConfig(createOneDriveConfig())
                .loginAndBuildClient(activity, callback);
    }

    static public IAccountInfo getAccountInfo() {
        return mOneDriveClient.getAuthenticator().getAccountInfo();
    }

    static private IClientConfig createOneDriveConfig() {
        final MSAAuthenticator msaAuthenticator = new MSAAuthenticator() {
            @Override
            public String getClientId() {
                return ONEDRIVE_CLIENT_ID;
            }

            @Override
            public String[] getScopes() {
                return ONEDRIVE_SCOPES;
            }
        };

        final IClientConfig clientConfig = DefaultClientConfig.createWithAuthenticator(msaAuthenticator);
        clientConfig.getLogger().setLoggingLevel(LoggerLevel.Debug);

        return clientConfig;


    }

    @Override
    public INxFile getFileMetaInfo(INxFile file) {
        return null;
    }

    @Override
    public void getFileMetaInfo(INxFile file, IGetFileMetaInfoCallback callback) {

    }

    @Override
    public void downloadFile(INxFile document, String localPath, IDownLoadCallback callback) {

    }

    @Override
    public void uploadFile(INxFile parentFolder, String fileName, File localFile, IUploadFileCallback callback) {

    }

    @Override
    public void updateFile(INxFile parentFolder, INxFile updateFile, File localFile, IUploadFileCallback callback) {

    }

    @Override
    public boolean getInfo(RemoteRepoInfo info) {
        // todo:implement your code here
        return false;
    }

    @Override
    public boolean isProgressSupported() {
        return false;
    }

    public interface IOAuth2Result {
        void success(IAccountInfo accountInfo);

        void failure(String errMsg);
    }
}

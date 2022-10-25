package appInstance.remoteRepo;

import javax.annotation.Nonnull;

import appInstance.remoteRepo.dropbox.NXDropBox;
import appInstance.remoteRepo.googledrive.NXGoogleDrive;
import appInstance.remoteRepo.onedrive.NXOneDrive;
import appInstance.remoteRepo.sharepointonline.NXSharePointOnline;
import database.BoundService;

/**
 * This class is designed as a factory to create supported remote repo sites,including:
 * -dropbox
 * -sharepoint online
 * -sharepoint
 * -onedrive
 * -google drive
 * Notice: user must not depend on the concrete class ,used IServiceOperation instead
 */
public class RemoteRepoFactory {
    public static
    @Nonnull
    IRemoteRepo create(BoundService service) throws Exception {
        IRemoteRepo rt;
        switch (service.type) {
            case DROPBOX:
                NXDropBox dropBox = new NXDropBox();
                dropBox.SetOAuth2AccessToken(service.accountToken);
                rt = dropBox;
                break;
            case SHAREPOINT_ONLINE:
                rt = new NXSharePointOnline(service.accountID, service.account, service.accountToken);
                break;
            case SHAREPOINT:
                rt = new appInstance.remoteRepo.sharepoint.NXSharePoint(service.accountID, service.account, service.accountToken);
                break;
            case ONEDRIVE:
                rt = new NXOneDrive();
                break;
            case GOOGLEDRIVE:
                rt = new NXGoogleDrive(service.account);
                break;
            default:
                throw new RuntimeException("error:this service type dost not supported");
        }
        return rt;
    }
}

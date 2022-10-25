package appInstance.localRepo;

import database.BoundService;


public class LocalRepoFactory {
    static public ILocalRepo create(BoundService.ServiceType type) throws Exception {
        switch (type) {
            case DROPBOX:
                return new LocalRepoBase();
            case SHAREPOINT_ONLINE:
                return new LocalRepoBase();
            case SHAREPOINT:
                return new LocalRepoBase();
            case ONEDRIVE:
                return new LocalRepoBase();
            case GOOGLEDRIVE:
                return new FileSysGoogle();
            default:
                throw new RuntimeException("error:this service type dost not supported");
        }
    }
}

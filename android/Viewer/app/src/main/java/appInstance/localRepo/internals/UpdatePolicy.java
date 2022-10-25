package appInstance.localRepo.internals;

import appInstance.remoteRepo.IRemoteRepo;
import nxl.types.INxFile;

/**
 * Designed for Cache class use to update a folder's information
 */
class UpdatePolicy {
    public void updateFolder(IUpdatable target, IRemoteRepo operation, INxFile folder) {
        target.updateFolder(operation.getFileMetaInfo(folder));
    }
}

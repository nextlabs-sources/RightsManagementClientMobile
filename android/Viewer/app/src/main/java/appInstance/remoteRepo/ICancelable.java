package appInstance.remoteRepo;

/**
 * this interface is used by user who want to start an async task to RemoteRepo, like:
 * - download
 * - upload
 * - get meta information of a folder or file
 * <p/>
 * the current design is before the async task starting , the callback will give user this interface
 * and through it user can cancel the stared task
 */
public interface ICancelable {
    void cancel();
}

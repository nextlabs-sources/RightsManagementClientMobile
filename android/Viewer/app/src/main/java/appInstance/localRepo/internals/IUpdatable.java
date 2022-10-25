package appInstance.localRepo.internals;

import nxl.types.INxFile;

/**
 * Created by oye on 10/20/2015.
 */
public interface IUpdatable {
    void updateFolder(INxFile folder);

    void updateDocument(INxFile document);

}

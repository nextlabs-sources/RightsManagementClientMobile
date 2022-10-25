package nxl;

import java.util.List;
import java.util.Stack;

import database.BoundService;
import nxl.types.INxFile;
import nxl.types.NxFileBase;


public class Utils {
    /**
     * be used to enumerate all files in {@param parent}
     *
     * @param parent        target folder,
     * @param enumerateFile callback interface
     */
    static public void EnumerateAllFiles(final INxFile parent, OnEnumerate enumerateFile) {
        if (parent == null) {
            return;
        }
        // handle parent itself
        enumerateFile.onFileFound(parent);
        if (!parent.isFolder()) {
            return;
        }
        // works
        Stack<INxFile> workingStack = new Stack<>();
        workingStack.push(parent);
        while (!workingStack.isEmpty()) {
            INxFile folder = workingStack.pop();
            List<INxFile> children = folder.getChildren();
            //handle children of the folder
            for (INxFile child : children) {
                enumerateFile.onFileFound(child);
                if (child.isFolder()) {
                    workingStack.push(child);
                }
            }
        }
    }

    public interface OnEnumerate {
        void onFileFound(INxFile file);
    }


    static public void attachService(final INxFile folder, final BoundService service, boolean isMarkSubFolder) {
        if (folder == null) {
            return;
        }
        if (service == null) {
            return;
        }

        ((NxFileBase) folder).setBoundService(service);

        if (!folder.isFolder()) {
            return;
        }
        if (!isMarkSubFolder) {
            for (INxFile f : folder.getChildren()) {
                ((NxFileBase) f).setBoundService(service);
            }
        } else {
            EnumerateAllFiles(folder, new OnEnumerate() {
                @Override
                public void onFileFound(INxFile file) {
                    ((NxFileBase) file).setBoundService(service);
                }
            });
        }
    }

}

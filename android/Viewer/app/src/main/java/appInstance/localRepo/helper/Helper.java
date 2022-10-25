package appInstance.localRepo.helper;

import android.util.Log;

import java.io.File;

import nxl.types.INxFile;


public class Helper {
    static public final String TAG = "NX_Helper";

    static public String getParent(INxFile file) {
        if (file == null)
            throw new NullPointerException("file is null");

        if (file.getLocalPath().equals("/")) {
            return "/";
        } else {
            int index = file.getLocalPath().lastIndexOf('/');
            if (index == -1)
                throw new RuntimeException("file not a standard path");
            return file.getLocalPath().substring(0, index + 1);
        }
    }

    static public String nxPath2AbsPath(File root, String origPath) {
        File f = new File(root, origPath);
        return f.getAbsolutePath();
    }

    static public String absPath2NxPath(File root, String absPath) {
        return absPath.substring(root.getAbsolutePath().length());
    }


    static public void makeSureDocExist(File file) {
        try {
            assert !file.isDirectory();
            if (!file.exists()) {
                //Bug: make sure the parent folder exist
                makeSureDirExist(file.getParentFile());

                file.createNewFile();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    static public boolean makeSureDirExist(File file) {
        try {
            if (file.isDirectory()) {
                return true;
            }
            if (!file.exists()) {
                file.mkdirs();
            } else if (!file.isDirectory() && file.canWrite()) {
                file.delete();
                file.mkdirs();
            } else {
                Log.e(TAG, "error");
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    static public void RecursionDeleteFile(File file) {

        // recursive outlet
        if (file.isFile()) {
            file.delete();
            return;
        }

        if (file.isDirectory()) {
            File[] childFile = file.listFiles();
            if (childFile == null || childFile.length == 0) {
                file.delete();
                return;
            }
            for (File f : childFile) {
                RecursionDeleteFile(f);
            }
            file.delete();
        }
    }

    static public void deleteFile(File file) {
        file.delete();
    }

    static public long folderSize(File directory) {
        long length = 0;
        for (File file : directory.listFiles()) {
            if (file.isFile())
                length += file.length();
            else
                length += folderSize(file);
        }
        return length;
    }
}

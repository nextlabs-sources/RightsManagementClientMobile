package commonUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.text.DecimalFormat;

/**
 * designed to provide as many as possible handy-utils for files,dirs,etc.
 */
public class FileHelper {

    public static byte[] readToByteArray(File file) throws Exception {

        if (file == null) {
            throw new RuntimeException("file is null");
        }
        if (!file.isFile()) {
            throw new RuntimeException("file is not a file");

        }
        if (!file.exists()) {
            throw new RuntimeException("file is not exist");
        }

        if (file.length() == 0) {
            return new byte[0];
        }
        byte[] b = new byte[(int) file.length()];
        InputStream in = new FileInputStream(file);
        try {
            if (in.read(b) != file.length()) {
                throw new RuntimeException("error");
            }
            return b;
        } finally {
            in.close();
        }
    }

    static public boolean makeSureFileExist(File file) throws Exception {
        if (file == null) {
            throw new RuntimeException("file is null");
        }
        if (file.isDirectory()) {
            throw new RuntimeException("file is is directory");
        }
        if (!file.exists()) {
            //Bug: make sure the parent folder exist
            makeSureDirExist(file.getParentFile());

            file.createNewFile();
        }
        return true;
    }

    static public boolean makeSureDirExist(File file) throws Exception {

        if (file == null) {
            throw new RuntimeException("file is null");
        }
        if (!file.isDirectory()) {
            throw new RuntimeException("file is not a dir");
        }

        if (!file.exists()) {
            return file.mkdirs();
        }
        return true;
    }

    static public boolean delFile(String fileName) {

        File file = new File(fileName);

        if (!file.exists() || file.isDirectory()) {
            return false;
        }

        return file.delete();

    }

    static public String transferFileSize(long fileSize) {
        long sizeInteger = fileSize / 1024;
        DecimalFormat decimalFormat = new DecimalFormat("0.0");
        if (1024 > sizeInteger && 0 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / 1024)) + " KB";
        } else if (1024 * 1024 > sizeInteger && 1024 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / (1024 * 1024))) + " MB";
        } else if (1024 * 1024 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / (1024 * 1024 * 1024))) + " GB";
        }
        return fileSize + " bytes";
    }

}

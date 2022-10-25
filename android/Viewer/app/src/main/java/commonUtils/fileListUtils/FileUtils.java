package commonUtils.fileListUtils;

import android.text.TextUtils;
import android.util.Log;

import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.TimeZone;

import nxl.types.INxFile;

/**
 * handle file property
 * such file size, modify time etc.
 */
public class FileUtils {
    public static String getLetter(String name) {
        String nameLetter = name.trim().substring(0, 1).toUpperCase();
        if (nameLetter.matches("[A-Z]")) {
            return nameLetter;
        } else {
            return "#";
        }
    }

    public static boolean isSpecificLetter(String name) {
        String nameLetter = name.trim().substring(0, 1).toUpperCase();
        return !nameLetter.matches("[A-Z]");
    }

    public static String transparentFileSize(long fileSize) {
        long sizeInteger = fileSize / 1024;
        DecimalFormat decimalFormat = new DecimalFormat("0.0");
        if (1024 > sizeInteger && 0 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / 1024)) + " KB";
        } else if (1024 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / (1024 * 1024))) + " MB";
        }
        return fileSize + " B";
    }

    public static String ConvertTime(INxFile file, boolean isBottomItem) {
        if (TextUtils.isEmpty(file.getLastModifiedTime())) {
            return "";
        }
        try {
            if (isBottomItem) {
                DateFormat sdBottom = new SimpleDateFormat("yyyy/MM/dd HH:mm");
                sdBottom.setTimeZone(TimeZone.getDefault());
                return sdBottom.format(new Date(file.getLastModifiedTimeLong()));
            } else {
                DateFormat sdTitle = new SimpleDateFormat("MMMM yyyy");
                sdTitle.setTimeZone(TimeZone.getDefault());
                return sdTitle.format(new Date(file.getLastModifiedTimeLong()));
            }
        } catch (Exception e) {
            Log.e("NXFileAdapter", e.toString());
        }
        return "";
    }

    /**
     * translate INxFile format data to NXFileItem format
     * NXFileItem title is the first letter of name by default
     *
     * @param nxFiles the meta data
     * @return NXFileItem format List
     */
    public static List<NXFileItem> translateINxList(List<INxFile> nxFiles) {
        List<NXFileItem> nxFileItems = new ArrayList<>();
        if (nxFiles == null) {
            return nxFileItems;
        }
        for (INxFile item : nxFiles) {
            nxFileItems.add(new NXFileItem(item, getLetter(item.getName())));
        }
        return nxFileItems;
    }
}

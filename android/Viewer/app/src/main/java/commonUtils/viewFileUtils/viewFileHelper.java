package commonUtils.viewFileUtils;

import android.app.Activity;
import android.content.Context;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;
import android.view.WindowManager;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Field;

public class viewFileHelper {
    private static final int BUFFER_SIZE = 4096;

    public static int getStatusBarHeight(Context context) {
        Class<?> dimenClass = null;
        Object obj = null;
        Field field = null;
        int integer = 0, statusBarHeight = 0;
        try {
            dimenClass = Class.forName("com.android.internal.R$dimen");
            obj = dimenClass.newInstance();
            field = dimenClass.getField("status_bar_height");
            integer = Integer.parseInt(field.get(obj).toString());
            statusBarHeight = context.getResources().getDimensionPixelSize(integer);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return statusBarHeight;
    }

    public static void backgroundAlpha(Activity activity, float bg_alpha) {
        WindowManager.LayoutParams lp = activity.getWindow().getAttributes();
        lp.alpha = bg_alpha;
        activity.getWindow().setAttributes(lp);
    }

    public static void fillFileParameters(nxl.types.NxFileBase Base, String LocalPath,
                                          long Size, String Name, String Time) {
        Base.setLocalPath(LocalPath);
        Base.setSize(Size);
        Base.setName(Name);
        Base.setLastModifiedTime(Time);
    }

    public static String readTextFile(Uri uri) {
        String ret = "";

        try {
            File file = new File(uri.getPath());
            FileInputStream inputStream = new FileInputStream(file);

            try {
                InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
                BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
                String receiveString;
                StringBuilder stringBuilder = new StringBuilder();

                while ((receiveString = bufferedReader.readLine()) != null) {
                    stringBuilder.append(receiveString);
                }
                ret = stringBuilder.toString();
            } catch (IOException e) {
                throw e;
            } finally {
                try {
                    inputStream.close();
                } catch (IOException e) {
                }
            }
        } catch (FileNotFoundException e) {
            Log.e("ViewFile activity", "File not found: " + e.toString());
        } catch (IOException e) {
            Log.e("ViewFile activity", "Can not read file: " + e.toString());
        }

        return ret;
    }

    public static File copyData(Context context, Uri uri, String fileName, String tmpPath) {
        InputStream is = null;
        FileOutputStream os = null;
        File tmpFile = null;
        String tmpFilePath = null;

        try {
            File base = null;
            if (Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)) {
                base = context.getExternalFilesDir(null);
                base = new File(base, tmpPath);
                if (!base.exists()) {
                    base.mkdirs();
                }
            }

            if (base == null) {
                return null;
            }

            tmpFilePath = base.toString() + "/" + fileName;
            try {
                tmpFile = new File(tmpFilePath);
                if (!tmpFile.exists())
                    tmpFile.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
            }

            is = context.getContentResolver().openInputStream(uri);
            os = new FileOutputStream(tmpFile);
            byte[] buffer = new byte[BUFFER_SIZE];
            int count = 0;
            while ((count = is.read(buffer)) > 0) {
                os.write(buffer, 0, count);
            }
            os.close();
            is.close();

        } catch (Exception e) {
            if (is != null) {
                try {
                    is.close();
                } catch (Exception e1) {
                    e.printStackTrace();
                }
            }
            if (os != null) {
                try {
                    os.close();
                } catch (Exception e2) {
                    e.printStackTrace();
                }
            }
        }

        return tmpFile;
    }
}

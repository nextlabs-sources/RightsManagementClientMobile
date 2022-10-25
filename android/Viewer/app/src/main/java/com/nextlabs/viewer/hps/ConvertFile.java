package com.nextlabs.viewer.hps;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;

import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import appInstance.ViewerApp;
import restAPIWithRMS.Listener;

public class ConvertFile {
    private static final String TAG = "ConvertFile";
    private final String TMP_PATH = "tmp/convertFile";

    private Context mContext;
    private int agentId;
    private String filePath;
    private String toFormat;
    private boolean isNxl;
    private String ConvertPath = null;
    private String fileName;

    public ConvertFile(Context context, int agentId, String fileName, String filePath, String toFormat, boolean isNxl) {
        this.mContext = context;
        this.agentId = agentId;
        this.fileName = fileName;
        this.filePath = filePath;
        this.toFormat = toFormat;
        this.isNxl = isNxl;
    }

    public void Do(IConvertAsyncTask mCallback) {
        ConvertTask converttask = new ConvertTask(mCallback);
        converttask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void) null);
        // converttask.execute((Void)null);
    }

    public interface IConvertAsyncTask {
        void onConvertFinish(String ConvertPath);
    }

    public class ConvertTask extends AsyncTask<Void, String, Boolean> {
        private ProgressDialog mProgressDialog;
        private IConvertAsyncTask mCallback;

        ConvertTask(IConvertAsyncTask mCallback) {
            this.mCallback = mCallback;
        }

        @Override
        protected Boolean doInBackground(Void... params) {
            try {
                Listener listener = new Listener() {
                    @Override
                    public void progress(int current, int total) {
                        publishProgress("" + current + "/" + total);
                    }

                    @Override
                    public void currentState(String state) {
                        publishProgress(state);
                    }
                };

                listener.currentState("prepare buffer");

                FileInputStream fin = new FileInputStream(filePath);
                int length = fin.available();
                byte[] buffer = new byte[length];
                fin.read(buffer);
                fin.close();

                listener.currentState("call to RMS");

                restAPIWithRMS.ConvertFile convertRequest = new restAPIWithRMS.ConvertFile();
                if (!convertRequest.invokeToRMS(
                        ViewerApp.getInstance().getSessionServer(),
                        ViewerApp.getInstance().sessionGetAgentCertification(),
                        agentId,
                        fileName,
                        buffer,
                        toFormat,
                        isNxl,
                        listener)) {
                    Log.d(TAG, "Convert file fail");
                    return false;
                }

                listener.currentState("save the converted file");

                if (!saveFile(convertRequest.getConvertedFileName(), convertRequest.getConvertedFile())) {
                    Log.d(TAG, "Save file failed!");
                    return false;
                }

                listener.currentState("prepare to render the 3D component");

                return true;
            } catch (Exception e) {
                Log.e(TAG, "1" + e.toString());
                e.printStackTrace();
            }
            return false;
        }


        private boolean saveFile(String fileName, byte[] contentData) {

            // create a temporary directory "/tmp/convertFile"
            boolean bRet = true;
            File base = null;
            if (Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)) {
                base = mContext.getExternalFilesDir(null);
                base = new File(base, TMP_PATH);   //   /storage/emulated/0/Android/data/com.nextlabs.viewer/files/tmp/convertFile
                if (!base.exists()) {
                    base.mkdirs();
                }
            }

            // create file, like "/tmp/convertFile/xxx.hsf" and so on.
            String tmpFilePath = base.toString() + "/" + fileName;
            File tmpLocal = null;
            try {
                tmpLocal = new File(tmpFilePath);
                if (!tmpLocal.exists())
                    tmpLocal.createNewFile();
            } catch (IOException e) {
                bRet = false;
                Log.d(TAG, "create temporary file failed!");
                e.printStackTrace();
            }

            // write content data into file
            try {
                DataOutputStream d = new DataOutputStream(new FileOutputStream(tmpLocal));
                d.write(contentData);
                d.flush();
            } catch (Exception e) {
                bRet = false;
                Log.d(TAG, "write data file failed!");
                e.printStackTrace();
            }
            ConvertPath = tmpFilePath;

            return bRet;
        }

        @Override
        protected void onPreExecute() {
            mProgressDialog = ProgressDialog.show(mContext, "", "Loading. Please wait...", true);
        }

        @Override
        protected void onProgressUpdate(String... values) {
            mProgressDialog.setMessage(values[0]);
        }

        @Override
        protected void onPostExecute(final Boolean success) {
            if (!success) {
                //Toast.makeText(mContext, "Convert failed", Toast.LENGTH_SHORT).show();
                Log.e(TAG, "Convert failed");
            }
            mProgressDialog.dismiss();
            mCallback.onConvertFinish(ConvertPath);
        }
    }

}

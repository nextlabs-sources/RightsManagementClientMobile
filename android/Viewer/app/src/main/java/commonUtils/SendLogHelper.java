package commonUtils;

import android.os.AsyncTask;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import appInstance.ViewerApp;
import restAPIWithRMS.SendLog;
import restAPIWithRMS.dataTypes.NXLogRequestValue;

public class SendLogHelper {
    static private final String TAG = "SendLogHelper";
    static private final String LOG_RECORD = "/failedLog.log";
    private NXLogRequestValue mLogRequestValue;
    private NXLogRequestValue.LogType mLogType;
    private logFileHelper mLogFileHelper;
    private List<SendLog.Request> mRequestList;

    public SendLogHelper(NXLogRequestValue requestValue, NXLogRequestValue.LogType logType) {
        mLogRequestValue = requestValue;
        mLogType = logType;
        mLogFileHelper = new logFileHelper();
        mRequestList = mLogFileHelper.unSerializeFromDisk();
        //bug fix, for unSerialize failed, new one
        if (mRequestList == null) {
            mRequestList = new ArrayList<>();
        }
    }

    public SendLogHelper() {
        mLogFileHelper = new logFileHelper();
        mRequestList = mLogFileHelper.unSerializeFromDisk();
        //bug fix, for unSerialize failed, new one
        if (mRequestList == null) {
            mRequestList = new ArrayList<>();
        }
    }

    public void reportToRMS() {
        SendLogAsyncTask sendLog = new SendLogAsyncTask();
        sendLog.execute();
    }

    public void resubmitToRMS() {
        resubmitLogAsyncTask resubmitLogAsyncTask = new resubmitLogAsyncTask();
        resubmitLogAsyncTask.execute();
    }

    public static class parseContent {
        //parse log's, parse hashMap format tags to list.
        public static List<SendLog.Request.Tag> transferTagToLog(Map mp) {
            List<SendLog.Request.Tag> tagList = new ArrayList<>();
            Iterator it = mp.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry pair = (Map.Entry) it.next();
                String name = (String) pair.getKey();
                @SuppressWarnings("unchecked")
                Vector<String> value = (Vector<String>) pair.getValue();
                for (String v : value) {
                    SendLog.Request.Tag tags = new SendLog.Request().new Tag();
                    tags.Name = name;
                    tags.Value = v;
                    tagList.add(tags);
                }
                //it.remove(); // avoids a ConcurrentModificationException
            }
            return tagList;
        }

        //parse hashMap format hit policy to list.
        public static List<SendLog.Request.Policy> transferPolicyToLog(Vector<Map.Entry<String, String>> mp) {
            List<SendLog.Request.Policy> policyList = new ArrayList<>();
            if (mp != null) {
                for (Map.Entry<String, String> me : mp) {
                    SendLog.Request.Policy policy = new SendLog.Request().new Policy();
                    policy.Id = Integer.parseInt(me.getKey());
                    policy.Name = me.getValue();
                    policyList.add(policy);
                }
            }
            return policyList;
        }
    }

    public class SendLogAsyncTask extends AsyncTask<Void, Void, Boolean> {
        private SendLog.Request request;

        @Override
        protected Boolean doInBackground(Void... params) {
            try {
                ViewerApp app = ViewerApp.getInstance();
                SendLog log = new SendLog();
                request = new SendLog.Request();
                if (mLogRequestValue != null) {
                    switch (mLogType) {
                        case Evaluation:
                            request.setEvaluationLog(mLogRequestValue.agentId,
                                    mLogRequestValue.rights,
                                    mLogRequestValue.userName,
                                    mLogRequestValue.sid,
                                    mLogRequestValue.hostNme,
                                    mLogRequestValue.nxDocPath,
                                    mLogRequestValue.nxDocPathTags,
                                    mLogRequestValue.hitPolicies);
                            break;
                        case Operation:
                            request.setOperationLog(mLogRequestValue.agentId,
                                    mLogRequestValue.operation,
                                    mLogRequestValue.userName,
                                    mLogRequestValue.sid,
                                    mLogRequestValue.hostNme,
                                    mLogRequestValue.nxDocPath,
                                    mLogRequestValue.nxDocPathTags,
                                    mLogRequestValue.hitPolicies);
                            break;
                        default:
                            break;
                    }
                    SendLog.Response response = log.invokeToRMS(app.getSessionServer(), app.sessionGetAgentCertification(), request);
                    if (response.isSuccess()) {
                        return true;
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, e.getMessage());
            }
            return false;
        }

        @Override
        protected void onPostExecute(final Boolean success) {
            if (!success) {
                mRequestList.add(request);
                try {
                    mLogFileHelper.serializeToDisk(mRequestList);
                } catch (Exception e) {
                    Log.e(TAG, e.getMessage());
                }
            } else {
                resubmitToRMS();
            }
        }
    }

    public class resubmitLogAsyncTask extends AsyncTask<Void, Void, Boolean> {
        @Override
        protected Boolean doInBackground(Void... params) {
            ViewerApp app = ViewerApp.getInstance();
            SendLog log = new SendLog();
            if (mRequestList != null) {
                Iterator<SendLog.Request> it = mRequestList.iterator();
                while (it.hasNext()) {
                    try {
                        SendLog.Response response = log.invokeToRMS(app.getSessionServer(), app.sessionGetAgentCertification(), it.next());
                        if (response.isSuccess()) {
                            it.remove();
                        }
                    } catch (Exception e) {
                        Log.e(TAG, e.toString());
                    }
                }
            }
            return true;
        }

        @Override
        protected void onPostExecute(Boolean unused) {
            try {
                mLogFileHelper.serializeToDisk(mRequestList);
            } catch (Exception e) {
                Log.e(TAG, e.getMessage());
            }
        }
    }

    public class logFileHelper {
        public boolean serializeToDisk(List<SendLog.Request> contentList) {
            try {
                File file = getSendLogLocalCache();
                if (!file.exists() && !file.createNewFile()) {
                    return false;
                }
                FileOutputStream fos = new FileOutputStream(file);
                ObjectOutputStream oos = new ObjectOutputStream(fos);
                oos.writeObject(contentList);
                fos.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            return true;
        }

        public List<SendLog.Request> unSerializeFromDisk() {
            try {
                File file = getSendLogLocalCache();
                if (!file.exists()) {
                    return null;
                }
                FileInputStream fis = new FileInputStream(file);
                ObjectInputStream ois = new ObjectInputStream(fis);
                @SuppressWarnings("unchecked")
                ArrayList<SendLog.Request> returnList = (ArrayList<SendLog.Request>) ois.readObject();
                ois.close();
                return returnList;
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
            return null;
        }

        private File getSendLogLocalCache() {
            return new File(ViewerApp.getInstance().getMountPoint(), ViewerApp.getInstance().getSessionSid() + LOG_RECORD);
        }
    }
}

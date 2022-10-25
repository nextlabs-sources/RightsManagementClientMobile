package appInstance.remoteRepo.sharepoint.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.sharepoint.Account;
import appInstance.remoteRepo.sharepoint.SharePointSdk;

/**
 * Created by wwu on 6/3/2015.
 */
public class GetAccountAsyncTask extends AsyncTask<Void, Void, Account> {
    private IGetAccountAsyncTask mCallBack = null;

    public void setCallBack(IGetAccountAsyncTask mCallBack) {
        this.mCallBack = mCallBack;
    }

    @Override
    protected Account doInBackground(Void... params) {
        return SharePointSdk.GetAuthAccount();
    }

    @Override
    protected void onPostExecute(Account account) {
        if (mCallBack != null) {
            mCallBack.onFinishGet(account);
        }
    }

    public interface IGetAccountAsyncTask {
        void onFinishGet(Account account);
    }
}


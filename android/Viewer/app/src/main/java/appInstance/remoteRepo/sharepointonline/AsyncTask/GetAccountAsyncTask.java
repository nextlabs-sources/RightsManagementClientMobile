package appInstance.remoteRepo.sharepointonline.AsyncTask;

import android.os.AsyncTask;

import appInstance.remoteRepo.sharepointonline.Account;
import appInstance.remoteRepo.sharepointonline.SharePointOnlineSdk;

/**
 * Created by aning on 6/2/2015.
 */

public class GetAccountAsyncTask extends AsyncTask<Void, Void, Account> {

    private IGetAccountAsyncTask mCallBack = null;

    public void setCallBack(IGetAccountAsyncTask mCallBack) {
        this.mCallBack = mCallBack;
    }

    @Override
    protected Account doInBackground(Void... params) {
        Account account = null;
        try {
            account = SharePointOnlineSdk.GetAuthAccount();
        } catch (Exception e) {

        }
        return account;
    }

    @Override
    protected void onPostExecute(Account account) {
        if (mCallBack != null) {
            mCallBack.onFinishGet(account);
        }
    }

    public interface IGetAccountAsyncTask {
        void onFinishGet(appInstance.remoteRepo.sharepointonline.Account account);
    }
}

package commonMethod;

import android.app.Activity;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.dropbox.client2.DropboxAPI;
import com.nextlabs.viewer.R;

import java.util.List;

import appInstance.ViewerApp;
import appInstance.remoteRepo.dropbox.NXDropBox;
import appInstance.remoteRepo.onedrive.NXOneDrive;
import appInstance.remoteRepo.onedrive.util.Account;
import database.BoundService;
import errorHandler.ErrorCode;
import errorHandler.GenericError;


public class AccountService
        implements NXDropBox.GetAccountAsyncTask.IGetAccountAsyncTask,
        NXOneDrive.GetAccountAsyncTask.IGetAccountAsyncTask,
        appInstance.remoteRepo.sharepoint.AsyncTask.GetAccountAsyncTask.IGetAccountAsyncTask,
        appInstance.remoteRepo.sharepointonline.AsyncTask.GetAccountAsyncTask.IGetAccountAsyncTask {

    private Activity mHomeActivity;
    private ViewerApp app;
    private OnGetServiceFinish onGetServiceFinish;


    public AccountService(Activity activity) {
        mHomeActivity = activity;
        app = ViewerApp.getInstance();
    }

    public void setOnGetServiceFinish(OnGetServiceFinish onItemClickListener) {
        this.onGetServiceFinish = onItemClickListener;
    }

    public void executeAccountAsyncTask(String name) {
        if (name.equals(mHomeActivity.getString(R.string.name_dropbox))) {
            NXDropBox.GetAccountAsyncTask task = new NXDropBox.GetAccountAsyncTask();
            task.setCallBack(this);
            task.execute();
        }
        if (name.equals(mHomeActivity.getString(R.string.name_onedrive))) {
            NXOneDrive.GetAccountAsyncTask task = new NXOneDrive.GetAccountAsyncTask();
            task.setCallback(this);
            task.execute();
        }

        if (name.equals(mHomeActivity.getString(R.string.name_msonedrive))) {
            //support only one account at MsOneDrive
            final String tbdEmail = "tbd@sdk.not.impl";
            final String tbdId = "tbd.ID";
            List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
            if (list != null) {
                for (BoundService service : list) {
                    if (service.type == BoundService.ServiceType.ONEDRIVE &&
                            service.account.equalsIgnoreCase(tbdEmail)) {
                        // Toast.makeText(mHomeActivity, "Service exists.", Toast.LENGTH_SHORT).show();
                        hintBoundServiceHadBind(mHomeActivity.getString(R.string.one_drive_bind_multiple));
                        return;
                    }
                }
            }

        }

        if (name.equals(mHomeActivity.getString(R.string.name_sharepoint))) {
            appInstance.remoteRepo.sharepoint.AsyncTask.GetAccountAsyncTask task = new appInstance.remoteRepo.sharepoint.AsyncTask.GetAccountAsyncTask();
            task.setCallBack(this);
            task.execute();
        }
        if (name.equals(mHomeActivity.getString(R.string.name_sharepointonline))) {
            appInstance.remoteRepo.sharepointonline.AsyncTask.GetAccountAsyncTask task = new appInstance.remoteRepo.sharepointonline.AsyncTask.GetAccountAsyncTask();
            task.setCallBack(this);
            task.execute();
        }
    }

    // CallBack Dorpbox
    @Override
    public void onFinishGet(DropboxAPI.Account account) {
        //bugs account may be null
        if (account == null) {
            //Toast.makeText(mHomeActivity, "Failed:Get DropBox API", Toast.LENGTH_LONG).show();
            hintBoundServiceHadBind(mHomeActivity.getString(R.string.repo_bind_failed));
            return;
        }
        //add this new account to Database
        List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
        if (list != null) {
            for (BoundService service : list) {
                if (service.type == BoundService.ServiceType.DROPBOX &&
                        service.account.equalsIgnoreCase(account.email)) {
                    hintBoundServiceHadBind(mHomeActivity.getString(R.string.normal_drive_bind_multiple));
                    return;
                }
            }
        }

        BoundService service = new BoundService(-1, app.getSession().getUserInfo().getUserId(),
                BoundService.ServiceType.DROPBOX, mHomeActivity.getString(R.string.name_dropbox), account.email,
                "" + account.uid, NXDropBox.getOAuth2Token(),
                1);

        if (configByService(service)) {
            onGetServiceFinish.onGetServiceFinish(service);
        } else {
            Toast.makeText(mHomeActivity, "Failed when adding a service.", Toast.LENGTH_SHORT).show();
        }
    }

    // CallBack OneDrive
    @Override
    public void onFinishGet(Account account) {
        List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
        if (list != null) {
            for (BoundService service : list) {
                if (service.type == BoundService.ServiceType.ONEDRIVE &&
                        service.account.equalsIgnoreCase(account.getMail())) {
                    hintBoundServiceHadBind(mHomeActivity.getString(R.string.one_drive_bind_multiple));
                    return;
                }
            }
        }


        BoundService service = new BoundService(-1, app.getSession().getUserInfo().getUserId(),
                BoundService.ServiceType.ONEDRIVE, mHomeActivity.getString(R.string.name_onedrive), account.getMail(),
                "" + account.getId(), NXOneDrive.getAccessToken(), 1);

        if (configByService(service)) {
            onGetServiceFinish.onGetServiceFinish(service);
        } else {
            Toast.makeText(mHomeActivity, "Failed when adding a service.", Toast.LENGTH_SHORT).show();
        }
    }

    // Callback sharepoint
    @Override
    public void onFinishGet(appInstance.remoteRepo.sharepoint.Account account) {
        List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
        if (list != null) {
            for (BoundService service : list) {
                if (service.type == BoundService.ServiceType.SHAREPOINT &&
                        service.account.equalsIgnoreCase(account.Username) && service.accountID.equalsIgnoreCase(account.Url)) {
                    hintBoundServiceHadBind(mHomeActivity.getString(R.string.normal_drive_bind_multiple));
                    return;
                }
            }
        }

        BoundService service = new BoundService(-1, app.getSession().getUserInfo().getUserId(),
                BoundService.ServiceType.SHAREPOINT, mHomeActivity.getString(R.string.name_sharepoint), account.Username,
                account.Url, account.Password, 1);

        if (configByService(service)) {
            onGetServiceFinish.onGetServiceFinish(service);
        } else {
            Toast.makeText(mHomeActivity, "Failed when adding a service.", Toast.LENGTH_SHORT).show();
        }
    }

    // Callback sharepoint_online
    @Override
    public void onFinishGet(appInstance.remoteRepo.sharepointonline.Account account) {
        List<BoundService> list = app.getAllCloudServicesOfCurrentUser();
        if (list != null) {
            for (BoundService service : list) {
                if (service.type == BoundService.ServiceType.SHAREPOINT_ONLINE &&
                        service.account.equalsIgnoreCase(account.getUsername()) && service.accountID.equalsIgnoreCase(account.getUrl())) {
                    hintBoundServiceHadBind(mHomeActivity.getString(R.string.normal_drive_bind_multiple));
                    return;
                }
            }
        }

        // add new repository to db and do update
        BoundService service = new BoundService(-1, app.getSession().getUserInfo().getUserId(),
                BoundService.ServiceType.SHAREPOINT_ONLINE, mHomeActivity.getString(R.string.name_sharepointonline), account.getUsername(),
                account.getUrl(), account.getCookie(), 1);

        if (configByService(service)) {
            onGetServiceFinish.onGetServiceFinish(service);
        } else {
            Toast.makeText(mHomeActivity, "Failed when adding a service.", Toast.LENGTH_SHORT).show();
        }
    }

    private boolean configByService(BoundService service) {
        // add into db first ,then amend service.id
        boolean rt = app.addService(service.type, service.alias, service.account, service.accountID, service.accountToken, service.selected);
        if (!rt) {
            Log.e("Failed", "can not insert service into db");
            return false;
        }
        // list service and find the revised service.id
        List<BoundService> services = app.getAllCloudServicesOfCurrentUser();
        BoundService revisedService = null;
        for (BoundService s : services) {
            if (service.type == s.type &&
                    TextUtils.equals(service.alias, s.alias) &&
                    TextUtils.equals(service.account, s.account) &&
                    TextUtils.equals(service.accountID, s.accountID) &&
                    TextUtils.equals(service.accountToken, s.accountToken)
                    ) {
                revisedService = s;
                //update param of service
                service.id = s.id;
                break;
            }
        }
        if (revisedService != null) {
            // activateRepo by revised Boundservice
            try {
                app.activateRepo(revisedService);
                rt = true;
            } catch (Exception e) {
                rt = false;
                e.printStackTrace();
            }
        } else {
            rt = false;
            // todo: must be occuring a error when insert service item into DB
        }
        return rt;
    }

    private void hintBoundServiceHadBind(final String msg) {
        GenericError.showUI(mHomeActivity, ErrorCode.BOUND_SERVICE_HAD_BIND, msg,
                true,
                false,
                false,
                null);
    }

    public interface OnGetServiceFinish {
        void onGetServiceFinish(BoundService service);
    }
}

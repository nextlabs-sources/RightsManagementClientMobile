package errorHandler;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;

import com.nextlabs.viewer.R;

public class GenericError {
    static public void showUI(final Activity activity, int errorCode, String msg, boolean isOK, boolean isCancel, final boolean isActivityFinish, final IErrorResult callback) {
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle(R.string.title_popup_dialog)
                .setMessage(msg);
        if (isOK) {
            builder.setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int id) {
                    if (callback != null) {
                        callback.okHandler();
                    }
                    if (isActivityFinish) {
                        activity.finish();
                    }
                }
            });
        }

        if (isCancel) {
            builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int id) {
                    if (callback != null) {
                        callback.cancelHandler();
                    }
                }
            });
        }

        builder.setCancelable(false);
        builder.show();
    }

    static public void showSimpleUI(Context context, String msg) {
        new AlertDialog.Builder(context)
                .setTitle(R.string.title_popup_dialog)
                .setMessage(msg)
                .setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.dismiss();
                    }
                })
                .setCancelable(true)
                .show();
    }
}

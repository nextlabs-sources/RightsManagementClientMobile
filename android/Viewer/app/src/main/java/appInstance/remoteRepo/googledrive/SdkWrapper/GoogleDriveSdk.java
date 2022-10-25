package appInstance.remoteRepo.googledrive.SdkWrapper;


import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.api.client.extensions.android.http.AndroidHttp;
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential;
import com.google.api.client.googleapis.extensions.android.gms.auth.UserRecoverableAuthIOException;
import com.google.api.client.googleapis.media.MediaHttpUploader;
import com.google.api.client.googleapis.media.MediaHttpUploaderProgressListener;
import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestInitializer;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.InputStreamContent;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.client.util.ExponentialBackOff;
import com.google.api.services.drive.Drive;
import com.google.api.services.drive.DriveScopes;
import com.google.api.services.drive.model.About;
import com.google.api.services.drive.model.File;
import com.google.api.services.drive.model.FileList;
import com.google.api.services.drive.model.ParentReference;
import com.google.api.services.drive.model.User;
import com.nextlabs.viewer.R;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.SyncFailedException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import appInstance.ViewerApp;
import appInstance.localRepo.helper.Helper;
import appInstance.remoteRepo.RemoteRepoInfo;
import database.BoundService;

public class GoogleDriveSdk {
    public static final int REQUEST_AUTHORIZATION = 1001;
    public static final int REQUEST_GOOGLE_PLAY_SERVICES = 1002;

    private static final String[] SCOPES = {DriveScopes.DRIVE};
    private static final String TAG = "GoogleDriveSdk";
    private static IShowErrorDialog s_CallBack;
    private static Activity s_activity;
    private static Boolean bActivated = false;
    private final HttpTransport transport = AndroidHttp.newCompatibleTransport();
    private final JsonFactory jsonFactory = GsonFactory.getDefaultInstance();
    private GoogleAccountCredential credential;
    private com.google.api.services.drive.Drive mService;
    private Boolean bDownloadCancelled = false;
    private Boolean bUploadCancelled = false;
    private Boolean bUpdateCancelled = false;
    private String LastUserName = "";

    public GoogleDriveSdk(String UserName) {
        if (!LastUserName.equals(UserName)) {
            LastUserName = UserName;

            if (isGooglePlayServicesAvailable()) {
                bActivated = true;

                credential = GoogleAccountCredential.usingOAuth2(
                        s_activity, Arrays.asList(SCOPES))
                        .setBackOff(new ExponentialBackOff())
                        .setSelectedAccountName(UserName);

                mService = new com.google.api.services.drive.Drive.Builder(
                        transport, jsonFactory, setHttpTimeout(credential))
                        .setApplicationName("Viewer")
                        .build();
            } else {
                bActivated = false;
            }
        }
    }

    public static void updateGoogleServices(Context context) {
        // check system accounts and find it's type = com.google
        AccountManager manager = (AccountManager) context.getSystemService(Context.ACCOUNT_SERVICE);
        Account[] list = manager.getAccounts();
        List<String> GoogleList = new ArrayList<>();
        for (Account account : list) {
            if (account.type.equalsIgnoreCase("com.google")) {
                GoogleList.add(account.name);
            }
        }

        //
        List<BoundService> Existedlist = ViewerApp.getInstance().getAllCloudServicesOfCurrentUser();
        List<String> ExistedGoogleList = new ArrayList<>();
        for (BoundService service : Existedlist) {
            if (service.type.equals(BoundService.ServiceType.GOOGLEDRIVE)) {
                ExistedGoogleList.add(service.account);

                if (!GoogleList.contains(service.account)) {
                    // del local files and records in cache_db
                    try {
                        ViewerApp.getInstance().removeRepo(service);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    // del current service from database
                    ViewerApp.getInstance().delService(service);
                }
            }
        }

        GoogleList.removeAll(ExistedGoogleList);
        for (String Item : GoogleList) {
            ViewerApp.getInstance().addService(BoundService.ServiceType.GOOGLEDRIVE, context.getString(R.string.name_googledrive), Item, Item, "", 1);
        }
    }

    public static void setIShowErrorDialog(IShowErrorDialog CallBack) {
        s_CallBack = CallBack;
    }

    public static void setContext(Activity activity) {
        s_activity = activity;
    }

    public static void ActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_AUTHORIZATION && resultCode == Activity.RESULT_OK) {
            bActivated = true;
        }
    }

    private HttpRequestInitializer setHttpTimeout(final HttpRequestInitializer requestInitializer) {
        return new HttpRequestInitializer() {
            @Override
            public void initialize(HttpRequest httpRequest) throws IOException {
                requestInitializer.initialize(httpRequest);
                httpRequest.setConnectTimeout(10000);  // 10 seconds connect timeout
                httpRequest.setReadTimeout(10000);     // 10 seconds read timeout
            }
        };
    }

    public nxl.types.NxFileBase GetMetaInfo(nxl.types.INxFile File) {
        if (!bActivated) {
            return null;
        }

        String path = File.getCloudPath();
        if (path.equals("/")) {
            return GetRoot();
        } else {
            return GetFoldersAndFiles(File);
        }
    }

    private nxl.types.NxFileBase GetRoot() {
        try {
            nxl.types.NxFileBase rt = GetRootBase();
            Drive.Files.List request = mService.files().list().setMaxResults(1000).setQ("'root' in parents and trashed != true");
            do {
                try {
                    FileList result = request.execute();
                    List<File> files = result.getItems();
                    if (files != null) {
                        for (File file : files) {
                            nxl.types.NxFileBase filebase = null;
                            if (file.getMimeType().equals("application/vnd.google-apps.folder")) {
                                filebase = new nxl.types.NXFolder();
                                fillFileParmas(filebase, "/" + file.getTitle(), file.getId(), 0, file.getTitle(), file.getModifiedDate().toString(), file.getModifiedDate().getValue());
                            } else {
                                filebase = new nxl.types.NXDocument();
                                Long filesize = file.getFileSize();
                                fillFileParmas(filebase, "/" + file.getTitle(), file.getId(), filesize == null ? -1 : filesize, file.getTitle(), file.getModifiedDate().toString(), file.getModifiedDate().getValue());
                            }
                            rt.addChild(filebase);
                        }
                    }
                    request.setPageToken(result.getNextPageToken());
                } catch (UserRecoverableAuthIOException userRecoverableException) {
                    if (bActivated) {
                        bActivated = false;
                        s_activity.startActivityForResult(
                                userRecoverableException.getIntent(),
                                REQUEST_AUTHORIZATION);
                    }
                    return null;
                } catch (IOException e) {
                    request.setPageToken(null);
                    return null;
                } catch (Exception e) {
                }
            } while (request.getPageToken() != null &&
                    request.getPageToken().length() > 0);
            return rt;
        } catch (Exception e) {
            return null;
        }
    }

    private nxl.types.NxFileBase GetFoldersAndFiles(nxl.types.INxFile File) {
        try {
            nxl.types.NxFileBase rt = GetBase(File);
            Drive.Files.List request = mService.files().list().setMaxResults(1000).setQ("'" + File.getCloudPath() + "'" + " in parents and trashed != true");
            do {
                try {
                    FileList result = request.execute();
                    List<File> files = result.getItems();
                    if (files != null) {
                        for (File file : files) {
                            nxl.types.NxFileBase filebase = null;
                            if (file.getMimeType().equals("application/vnd.google-apps.folder")) {
                                filebase = new nxl.types.NXFolder();
                                fillFileParmas(filebase, File.getLocalPath() + "/" + file.getTitle(), file.getId(), 0, file.getTitle(), file.getModifiedDate().toString(), file.getModifiedDate().getValue());
                            } else {
                                filebase = new nxl.types.NXDocument();
                                Long filesize = file.getFileSize();
                                fillFileParmas(filebase, File.getLocalPath() + "/" + file.getTitle(), file.getId(), filesize == null ? -1 : filesize, file.getTitle(), file.getModifiedDate().toString(), file.getModifiedDate().getValue());
                            }
                            rt.addChild(filebase);
                        }
                    }
                    request.setPageToken(result.getNextPageToken());
                } catch (IOException e) {
                    request.setPageToken(null);
                    return null;
                }
            } while (request.getPageToken() != null &&
                    request.getPageToken().length() > 0);
            return rt;
        } catch (Exception e) {
        }
        return null;
    }

    public void StartDownloadFile(String CloudPath) {
        bDownloadCancelled = false;
    }

    public boolean DownloadFile(String CloudPath, String LocalPath, long fileSize, IUpdateDownLoadFile update) {
        if (!bActivated) {
            return false;
        }

        try {
            InputStream downloadStream = null;
            if (fileSize != -1) {
                downloadStream = mService.files().get(CloudPath).executeMediaAsInputStream();
            } else {
                String downloadUrl = mService.files().get(CloudPath).execute().getExportLinks().get("application/pdf");
                if (downloadUrl != null && downloadUrl.length() > 0) {
                    com.google.api.client.http.HttpResponse resp = mService.getRequestFactory().buildGetRequest(new GenericUrl(downloadUrl)).execute();
                    downloadStream = resp.getContent();
                } else {
                    return false;
                }
            }

            if (downloadStream != null) {
                java.io.File local = new java.io.File(LocalPath);
                appInstance.localRepo.helper.Helper.makeSureDocExist(local);
                //File output stream
                OutputStream outputStream = new FileOutputStream(local);
                return copyStreamToOutput(downloadStream, outputStream, fileSize, update, LocalPath);
            }
        } catch (Exception e) {
        }

        return false;
    }

    public void AbortTask() {
        bDownloadCancelled = true;
    }

    public void StartUploadFile() {
        bUploadCancelled = false;
    }

    public void StartUpdatedFile() {
        bUpdateCancelled = false;
    }

    public boolean UploadFile(nxl.types.INxFile parentFolde, String fileName, java.io.File localFile, final IUpdateDownLoadFile update) {
        if (!bActivated) {
            return false;
        }
        try {
            final long fileSize = localFile.length();
            final FileInputStream fileStream = new FileInputStream(localFile);
            InputStreamContent mediaContent = new InputStreamContent("application/octet-stream", new BufferedInputStream(fileStream));
            mediaContent.setLength(fileSize);

            // File's metadata.
            File body = new File();
            body.setTitle(fileName);
            body.setMimeType("application/octet-stream");

            String path = parentFolde.getCloudPath();
            if (path.equals("/")) {
                body.setParents(Arrays.asList(new ParentReference().setId("root")));
            } else {
                body.setParents(Arrays.asList(new ParentReference().setId(path)));
            }

            Drive.Files.Insert request = mService.files().insert(body, mediaContent);
            MediaHttpUploader uploader = request.getMediaHttpUploader();
            uploader.setDirectUploadEnabled(false);
            uploader.setChunkSize(MediaHttpUploader.MINIMUM_CHUNK_SIZE);

            uploader.setProgressListener(new MediaHttpUploaderProgressListener() {
                public void progressChanged(MediaHttpUploader uploader) {
                    try {
                        if (bUploadCancelled) {
                            fileStream.close();
                        } else {
                            long newValue = (long) (uploader.getNumBytesUploaded() / (double) fileSize * 100);
                            if (newValue > 100) {
                                newValue = 100;
                            }
                            update.onUpdate(newValue);
                            ;
                        }
                    } catch (IOException e) {
                    }
                }
            });

            File file = request.execute();
            if (file != null) {
                return true;
            }
        } catch (IOException e) {

        }

        return false;
    }

    public boolean UpdateFile(nxl.types.INxFile parentFolde, String CloudPath, java.io.File localFile, final IUpdateDownLoadFile update) {
        if (!bActivated) {
            return false;
        }
        try {
            File file = mService.files().get(CloudPath).execute();

            final long fileSize = localFile.length();
            final FileInputStream fileStream = new FileInputStream(localFile);
            InputStreamContent mediaContent = new InputStreamContent(file.getMimeType(), new BufferedInputStream(fileStream));
            mediaContent.setLength(fileSize);

            Drive.Files.Update request = mService.files().update(CloudPath, file, mediaContent);
            MediaHttpUploader uploader = request.getMediaHttpUploader();
            uploader.setDirectUploadEnabled(false);
            uploader.setChunkSize(MediaHttpUploader.MINIMUM_CHUNK_SIZE);

            uploader.setProgressListener(new MediaHttpUploaderProgressListener() {
                public void progressChanged(MediaHttpUploader uploader) {
                    try {
                        if (bUpdateCancelled) {
                            fileStream.close();
                        } else {
                            long newValue = (long) (uploader.getNumBytesUploaded() / (double) fileSize * 100);
                            if (newValue > 100) {
                                newValue = 100;
                            }
                            update.onUpdate(newValue);
                            ;
                        }
                    } catch (IOException e) {
                    }
                }
            });

            file = request.execute();
            if (file != null) {
                return true;
            }
        } catch (IOException e) {

        }

        return false;
    }

    public void AbortUploadTask() {
        bUploadCancelled = true;
    }

    public void AbortUpdateTask() {
        bUpdateCancelled = true;
    }

    private boolean copyStreamToOutput(InputStream input, OutputStream output, long fileSize, IUpdateDownLoadFile updatet, String LocalPath) {
        BufferedOutputStream bos = null;
        long totalRead = 0;
        long lastListened = 0;

        boolean b = true;

        try {
            bos = new BufferedOutputStream(output);

            byte[] buffer = new byte[4096];
            int read;
            while (true) {
                read = input.read(buffer);
                if (read < 0) {
                    break;
                }

                bos.write(buffer, 0, read);

                totalRead += read;

                if (fileSize != -1) {
                    long newValue = (long) (totalRead / (double) fileSize * 100);
                    if (newValue > 100) {
                        newValue = 100;
                    }

                    updatet.onUpdate(newValue);
                    ;
                }

                if (bDownloadCancelled) {
                    return false;
                }
            }

            bos.flush();
            output.flush();
            // Make sure it's flushed out to disk
            try {
                if (output instanceof FileOutputStream) {
                    ((FileOutputStream) output).getFD().sync();
                }
            } catch (SyncFailedException e) {
                b = false;
            }

        } catch (IOException e) {
            b = false;
        } finally {
            if (bos != null) {
                try {
                    bos.close();
                } catch (IOException e) {
                }
            }
            try {
                output.close();
            } catch (IOException e) {
            }
            try {
                input.close();
            } catch (IOException e) {
            }

            if (bDownloadCancelled) {
                Helper.deleteFile(new java.io.File(LocalPath));
            }
        }

        return b;
    }

    public boolean getRepositoryInfo(RemoteRepoInfo info) {
        try {
            About about = mService.about().get().execute();
            if (about != null) {
                info.remoteTotalSpace = about.getQuotaBytesTotal();
                info.remoteUsedSpace = about.getQuotaBytesUsed();

                User user = about.getUser();
                if (user != null) {
                    info.displayName = user.getDisplayName();
                    info.email = user.getEmailAddress();
                }
            }

            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private nxl.types.NxFileBase GetRootBase() {
        nxl.types.NxFileBase rt = new nxl.types.NXFolder();
        fillFileParmas(rt, "/", "/", 0, "root", "", 0);
        return rt;
    }

    private nxl.types.NxFileBase GetBase(nxl.types.INxFile File) {
        nxl.types.NxFileBase rt = new nxl.types.NXFolder();
        fillFileParmas(rt, File.getLocalPath(), File.getCloudPath(), File.getSize(), File.getName(), "", 0);
        return rt;
    }

    private void fillFileParmas(nxl.types.NxFileBase Base, String LocalPath, String CloudPath, long Size, String Name, String Time, long TimeValue) {
        Base.setLocalPath(LocalPath);
        Base.setCloudPath(CloudPath);
        Base.setSize(Size);
        Base.setName(Name);
        Base.setLastModifiedTime(Time);
        Base.setLastModifiedTimeLong(TimeValue);
    }

    private boolean isGooglePlayServicesAvailable() {
        final int connectionStatusCode =
                GooglePlayServicesUtil.isGooglePlayServicesAvailable(s_activity);
        if (GooglePlayServicesUtil.isUserRecoverableError(connectionStatusCode)) {
            s_CallBack.showGooglePlayServicesAvailabilityErrorDialog(connectionStatusCode);
            return false;
        } else if (connectionStatusCode != ConnectionResult.SUCCESS) {
            return false;
        }
        return true;
    }

    public interface IShowErrorDialog {
        void showGooglePlayServicesAvailabilityErrorDialog(final int connectionStatusCode);
    }

    public interface IUpdateDownLoadFile {
        void onUpdate(long newValue);
    }
}

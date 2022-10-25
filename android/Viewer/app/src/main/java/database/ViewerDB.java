package database;


import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.DatabaseErrorHandler;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.util.ArrayList;
import java.util.List;

import appInstance.ViewerApp;


public class ViewerDB extends SQLiteOpenHelper {

    private static final String DATABASE_DBNAME = "viewer_database.db";
    private static final String DATABASE_TABLE_SERVICE = "bound_service";
    private static final String DATABASE_TABLE_CACHEFILE = "cache_file";
    private static final int DATABASE_VERSION = 1;
    private static final String SQL_SET_ON_FOREIGN_KEY = "PRAGMA foreign_keys=ON;";
    private static final String SQL_CREATE_TABLE_SERVICE =
            "CREATE TABLE " + DATABASE_TABLE_SERVICE +
                    " (" +
                    "service_id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "user_id INTEGER, " +
                    "tenant_name TEXT, " +
                    "service_type INTEGER, " +
                    "service_alias TEXT, " +
                    "service_account TEXT, " +
                    "service_account_id TEXT, " +
                    "service_account_token TEXT, " +
                    "selected INTEGER" +
                    ");";
    private static final String SQL_CREATE_CACHE_FILE =
            "CREATE TABLE " + DATABASE_TABLE_CACHEFILE +
                    " (" +
                    "cache_id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "user_id INTEGER, " +
                    "service_id INTEGER, " +
                    "source_path TEXT, " +
                    "cache_path TEXT, " +
                    "cache_size INTEGER64, " +
                    "checksum TEXT, " +
                    "cached_time TEXT, " +
                    "access_time TEXT, " +
                    "offline_flag INTEGER, " +
                    "favorite_flag INTEGER, " +
                    "safe_path TEXT" +
                    ");";


    public ViewerDB(Context context) {
        super(context, DATABASE_DBNAME, null, DATABASE_VERSION);
    }


    /*
       Callback when first create db, good place to create tables
     */
    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(SQL_SET_ON_FOREIGN_KEY);
        // create table
        db.execSQL(SQL_CREATE_TABLE_SERVICE);
        db.execSQL(SQL_CREATE_CACHE_FILE);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        switch (oldVersion) {
            case DATABASE_VERSION:
                // for next
                break;
            default:
        }

    }

    public List<BoundService> queryService(int userId, String tenantName) {
        List<BoundService> items = new ArrayList<BoundService>();

        Cursor c = getReadableDatabase().query(
                DATABASE_TABLE_SERVICE,
                new String[]{"*"},
                "user_id=? and tenant_name=?",
                new String[]{Integer.toString(userId), tenantName},
                null, null, null);

        while (c.moveToNext()) {
            BoundService i = new BoundService(
                    c.getInt(c.getColumnIndex("service_id")),
                    c.getInt(c.getColumnIndex("user_id")),
                    BoundService.ServiceType.valueOf(c.getInt(c.getColumnIndex("service_type"))),
                    c.getString(c.getColumnIndex("service_alias")),
                    c.getString(c.getColumnIndex("service_account")),
                    c.getString(c.getColumnIndex("service_account_id")),
                    c.getString(c.getColumnIndex("service_account_token")),
                    c.getInt(c.getColumnIndex("selected"))
            );

            items.add(i);
        }
        return items;

    }

    public boolean addService(int userId, String tenantName, BoundService.ServiceType type,
                              String alias, String account, String accountId,
                              String accountToken, int selected) {
        ContentValues values = new ContentValues();
//        values.put("service_id","null");
        values.put("user_id", userId);
        values.put("tenant_name", tenantName);
        values.put("service_type", type.value());
        values.put("service_alias", alias);
        values.put("service_account", account);
        values.put("service_account_id", accountId);
        values.put("service_account_token", accountToken);
        values.put("selected", selected);
        return -1 != getWritableDatabase().insert(DATABASE_TABLE_SERVICE, null, values);

    }

    public boolean updateService(int userId, String tenantName, BoundService service) {
        ContentValues values = new ContentValues();
        values.put("selected", service.selected);
        return -1 != getWritableDatabase().update(DATABASE_TABLE_SERVICE, values,
                "user_id=? and " +
                        "tenant_name =? and " +
                        "service_type = ? and " +
                        "service_account_token =?",
                new String[]{
                        Integer.toString(userId),
                        tenantName,
                        Integer.toString(service.type.value()),
                        service.accountToken});
    }

    public boolean delService(int userId, String tenantName, BoundService service) {
        return -1 != getWritableDatabase().delete(DATABASE_TABLE_SERVICE,
                "user_id=? and " +
                        "tenant_name =? and " +
                        "service_type = ? and " +
                        "service_account_token =?",
                new String[]{
                        Integer.toString(userId),
                        tenantName,
                        Integer.toString(service.type.value()),
                        service.accountToken});
    }

}

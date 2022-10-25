package database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.util.ArrayList;
import java.util.List;

/**
 * Tables of Two
 * -bound_service:
 * <p/>
 * -cached_file:
 */
public class DBManager {
    private SQLiteDatabase db;

    public DBManager(Context context) {
        db = context.openOrCreateDatabase("Database.db", Context.MODE_PRIVATE, null);

        db.execSQL("CREATE TABLE IF NOT EXISTS bound_service" +
                "(service_id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "user_id INTEGER, " +
                "service_type INTEGER, " +
                "service_alias TEXT, " +
                "service_account TEXT, " +
                "service_account_id TEXT, " +
                "service_account_token TEXT, " +
                "selected INTEGER)");

        db.execSQL("CREATE TABLE IF NOT EXISTS cache_file" +
                "(cache_id INTEGER PRIMARY KEY AUTOINCREMENT, " +
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
                "safe_path TEXT)");
    }

    public void close() {
        db.close();
    }


    public void add(String table, List<Object> Items) {
        if (table == "BoundService") {
            addBoundService(Items);
        } else if (table == "CacheFile") {
            addCacheFiles(Items);
        }
    }


    private void addBoundService(List<Object> Items) {
        db.beginTransaction();
        try {
            for (Object Obj : Items) {
                BoundService Item = (BoundService) Obj;
                db.execSQL("INSERT INTO bound_service VALUES(null, ?, ?, ?, ?, ?, ?, ?)", new Object[]{Item.userID, Item.type.value(), Item.alias, Item.account, Item.accountID, Item.accountToken, Item.selected});
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
        }
    }

    private void addCacheFiles(List<Object> Items) {
        db.beginTransaction();
        try {
            for (Object Obj : Items) {
                CacheFile Item = (CacheFile) Obj;
                db.execSQL("INSERT INTO cache_file VALUES(null, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", new Object[]{Item.userID, Item.serviceID, Item.sourcePath, Item.cachePath, Item.cacheSize, Item.checksum, Item.cachedTime, Item.accessTime, Item.offlineFlag, Item.favoriteFlag, Item.safePath});
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
        }
    }

    public void update(String table, Object Obj) {
        if (table == "BoundService") {
            updateBoundService(Obj);
        } else if (table == "CacheFile") {
            updateCacheFiles(Obj);
        }
    }


    private void updateBoundService(Object Obj) {
        BoundService Item = (BoundService) Obj;

        ContentValues cv = new ContentValues();
        cv.put("user_id", Item.userID);
        cv.put("service_type", Item.type.value());
        cv.put("service_alias", Item.alias);
        cv.put("service_account", Item.account);
        cv.put("service_account_id", Item.accountID);
        cv.put("service_account_token", Item.accountToken);
        cv.put("selected", Item.selected);

        db.update("bound_service", cv, "service_id = ?", new String[]{Integer.toString(Item.id)});
    }

    private void updateCacheFiles(Object Obj) {
        CacheFile Item = (CacheFile) Obj;

        ContentValues cv = new ContentValues();
        cv.put("service_id", Item.serviceID);
        cv.put("source_path", Item.sourcePath);
        cv.put("cache_path", Item.cachePath);
        cv.put("cache_size", Item.cacheSize);
        cv.put("checksum", Item.checksum);
        cv.put("cached_time", Item.cachedTime);
        cv.put("access_time", Item.accessTime);
        cv.put("offline_flag", Item.offlineFlag);
        cv.put("favorite_flag", Item.favoriteFlag);
        cv.put("safe_path", Item.safePath);

        db.update("cache_file", cv, "user_id = ?", new String[]{Integer.toString(Item.id)});
    }

    public void delete(String table, Object Obj) {
        if (table == "BoundService") {
            deleteBoundService(Obj);
        } else if (table == "CacheFile") {
            deleteCacheFiles(Obj);
        }
    }


    private void deleteBoundService(Object Obj) {
        BoundService Item = (BoundService) Obj;
        if (Item.type == BoundService.ServiceType.SHAREPOINT) {
            db.delete("bound_service", "service_account = ? and service_account_id = ?", new String[]{Item.account, Item.accountID});
        } else {
            db.delete("bound_service", "service_account = ?", new String[]{Item.account});
        }
    }

    private void deleteCacheFiles(Object Obj) {
        CacheFile Item = (CacheFile) Obj;
        db.delete("cache_file", "cache_path = ?", new String[]{((CacheFile) Obj).cachePath});
    }

    public List<Object> query(String table) {
        if (table == "BoundService") {
            return queryBoundService();
        } else if (table == "CacheFile") {
            return queryCacheFiles();
        }
        return null;
    }

    private List<Object> queryBoundService() {
        ArrayList<Object> Items = new ArrayList<Object>();
        Cursor c = db.rawQuery("SELECT * FROM bound_service", null);
        while (c.moveToNext()) {
            BoundService Item = new BoundService(c.getInt(c.getColumnIndex("service_id")), c.getInt(c.getColumnIndex("user_id")), BoundService.ServiceType.valueOf(c.getInt(c.getColumnIndex("service_type"))),
                    c.getString(c.getColumnIndex("service_alias")), c.getString(c.getColumnIndex("service_account")), c.getString(c.getColumnIndex("service_account_id")), c.getString(c.getColumnIndex("service_account_token")),
                    c.getInt(c.getColumnIndex("selected")));

            Items.add(Item);
        }
        c.close();
        return Items;
    }

    private List<Object> queryCacheFiles() {
        ArrayList<Object> Items = new ArrayList<Object>();
        Cursor c = db.rawQuery("SELECT * FROM cache_file", null);
        while (c.moveToNext()) {
            CacheFile Item = new CacheFile(c.getInt(c.getColumnIndex("cache_id")), c.getInt(c.getColumnIndex("user_id")), c.getInt(c.getColumnIndex("service_id")), c.getString(c.getColumnIndex("source_path")),
                    c.getString(c.getColumnIndex("cache_path")), c.getLong(c.getColumnIndex("cache_size")), c.getString(c.getColumnIndex("checksum")), c.getString(c.getColumnIndex("cached_time")), c.getString(c.getColumnIndex("access_time")),
                    c.getInt(c.getColumnIndex("offline_flag")), c.getInt(c.getColumnIndex("favorite_flag")), c.getString(c.getColumnIndex("safe_path")));

            Items.add(Item);
        }
        c.close();
        return Items;
    }


}

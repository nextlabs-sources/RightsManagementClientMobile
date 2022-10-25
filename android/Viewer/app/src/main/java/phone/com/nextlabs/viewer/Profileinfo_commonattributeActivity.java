package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.MimeTypeMap;
import android.widget.ListView;
import android.widget.TextView;

import com.imageableList.NXProfileCommonattributeItem;
import com.imageableList.NXProfileGestureListen;
import com.imageableList.NXProfileinfocommontattributeAdapter;
import com.nextlabs.viewer.R;

import java.io.File;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.TimeZone;

import commonUtils.fileListUtils.FileUtils;
import nxl.types.INxFile;


public class Profileinfo_commonattributeActivity extends Activity implements View.OnTouchListener, NXProfileGestureListen.MoveCallback {

    private TextView mDone;
    private ListView mListViewItems;
    private ArrayList<NXProfileCommonattributeItem> mItemArray;
    private NXProfileinfocommontattributeAdapter mProfileAdapter;
    private INxFile mClickFile;
    private File mCurrentFile;
    private boolean mIsNXFile = false;
    private boolean bAsThirdPartyOpen = false;

    private View mDot0;
    private View mDot1;
    private View mDot2;

    private GestureDetector mDetector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profileinfo_commonattribute);

        mDetector = new GestureDetector(this, new NXProfileGestureListen(this));

        Intent intent = getIntent();
        if (intent.getAction().equals("INFOFORWARD") || intent.getAction().equals("INFOBACK")) {
            mCurrentFile = (File) getIntent().getSerializableExtra("current_file");
            mClickFile = (INxFile) getIntent().getSerializableExtra("click_file");
            bAsThirdPartyOpen = getIntent().getBooleanExtra("as_third_party", false);
        }

        mIsNXFile = isNXFile();
        initContact();
        initData();

        mDone = (TextView) findViewById(R.id.profileinfodone);
        mDone.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Profileinfo_commonattributeActivity.this.finish();
            }
        });

    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return mDetector.onTouchEvent(event);
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        mDetector.onTouchEvent(event);
        return false;   //onTouch -> OnTouchEvent   if onTouch return true, OnTouchEvent won't be excuted.
    }

    @Override
    public void JumpTo(boolean way) {
        if (way && mIsNXFile) {
            Intent intent = new Intent();
            intent.setAction("INFOFORWARD");
            intent.putExtra("click_file", (nxl.types.NxFileBase) mClickFile);
            intent.putExtra("current_file", mCurrentFile);
            intent.putExtra("as_third_party", bAsThirdPartyOpen);
            intent.setClass(Profileinfo_commonattributeActivity.this, ClassifyActivity.class);
            Profileinfo_commonattributeActivity.this.startActivity(intent);
            Profileinfo_commonattributeActivity.this.finish();
            overridePendingTransition(R.anim.in_from_right, R.anim.out_to_left);
        }
    }

    private boolean isNXFile() {
        return (nxl.fileFormat.Utils.check(mCurrentFile.getPath(), false));
    }

    private void initContact() {
        mListViewItems = (ListView) findViewById(R.id.profileinfocommonattributelistView);
        mListViewItems.setOnTouchListener(this);
        mItemArray = new ArrayList<NXProfileCommonattributeItem>();
        mProfileAdapter = new NXProfileinfocommontattributeAdapter(this, R.layout.profile_info_commontattribute_item, mItemArray);
        mListViewItems.setAdapter(mProfileAdapter);

        if (mIsNXFile) {
            mDot0 = findViewById(R.id.profileInfo_dot_0);
            mDot1 = findViewById(R.id.profileInfo_dot_1);
            mDot2 = findViewById(R.id.profileInfo_dot_2);
        }

    }

    private void initData() {

        String fileName = mClickFile.getName();
        DateFormat modifyTime = new SimpleDateFormat("yyyy/MM/dd HH:mm");
        modifyTime.setTimeZone(TimeZone.getDefault());
        String result = modifyTime.format(new Date(mClickFile.getLastModifiedTimeLong()));
        NXProfileCommonattributeItem itemName = new NXProfileCommonattributeItem(getString(R.string.attribute_file_name), fileName);
        NXProfileCommonattributeItem itemLocation = new NXProfileCommonattributeItem(getString(R.string.attribute_location), mClickFile.getLocalPath());
        NXProfileCommonattributeItem itemSize = new NXProfileCommonattributeItem(getString(R.string.attribute_file_size), FileUtils.transparentFileSize(mClickFile.getSize()));
        NXProfileCommonattributeItem itemLastModifyTime = new NXProfileCommonattributeItem(getString(R.string.attribute_modify_time), result);
        NXProfileCommonattributeItem itemType = null;
        if (fileName.endsWith(".nxl")) {
            String formalName = fileName.substring(0, fileName.lastIndexOf("."));
            itemType = new NXProfileCommonattributeItem(getString(R.string.attribute_file_type), formalName.substring(formalName.lastIndexOf(".")).toLowerCase());
        } else {
            itemType = new NXProfileCommonattributeItem(getString(R.string.attribute_file_type), fileName.substring(fileName.lastIndexOf(".")).toLowerCase());
        }

        mItemArray.clear();
        mItemArray.add(itemName);
        mItemArray.add(itemLocation);
        mItemArray.add(itemType);
        mItemArray.add(itemSize);
        mItemArray.add(itemLastModifyTime);

        if (mIsNXFile) {
            mDot0.setVisibility(View.VISIBLE);
            mDot1.setVisibility(View.VISIBLE);
            mDot2.setVisibility(View.VISIBLE);
        }
        mProfileAdapter.notifyDataSetChanged();
    }

    private String getMiniType(String filepath) {
        String type = "";
        if (mIsNXFile) {
            filepath = filepath.substring(0, filepath.length() - 4);
        }
        String extension = MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(new File(filepath)).toString());
        if (extension != null && !extension.isEmpty()) {
            type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
        }
        if (null == type) {
            type = extension;
        }
        return type;
    }
}

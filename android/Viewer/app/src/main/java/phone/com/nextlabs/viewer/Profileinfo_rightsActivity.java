package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ListView;
import android.widget.TextView;

import com.imageableList.NXProfileGestureListen;
import com.imageableList.NXProfileRightsItem;
import com.imageableList.NXProfileinfoRightsAdapter;
import com.nextlabs.viewer.R;

import java.io.File;
import java.util.ArrayList;

import PolicyEngineWrapper.NXPolicyEngineWrapper;
import PolicyEngineWrapper.NXRights;
import PolicyEngineWrapper.NXRightsList;
import appInstance.ViewerApp;
import commonUtils.SendLogHelper;
import nxl.types.INxFile;
import restAPIWithRMS.dataTypes.NXLogRequestValue;


public class Profileinfo_rightsActivity
        extends Activity
        implements View.OnTouchListener, NXProfileGestureListen.MoveCallback {
    private TextView mBack;
    private ListView mListViewItems;
    private ArrayList<NXProfileRightsItem> mItemArray;
    private NXProfileinfoRightsAdapter mProfileAdapter;
    private INxFile mClickFile;
    private File mCurrentFile;
    private boolean bAsThirdPartyOpen = false;

    private GestureDetector mDetector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profileinfo_rights);

        mDetector = new GestureDetector(this, new NXProfileGestureListen(this));

        Intent intent = getIntent();
        if (intent.getAction().equals("INFOFORWARD")) {
            mCurrentFile = (File) getIntent().getSerializableExtra("current_file");
            mClickFile = (INxFile) getIntent().getSerializableExtra("click_file");
            bAsThirdPartyOpen = getIntent().getBooleanExtra("as_third_party", false);
        }

        initContact();
        initData();

        mBack = (TextView) findViewById(R.id.profileinforightsback);
        mBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Profileinfo_rightsActivity.this.finish();
                overridePendingTransition(R.anim.in_from_left, R.anim.out_to_right);
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
        if (way) {
            return;
        } else {
            Intent intent = new Intent();
            intent.setAction("INFOBACK");
            intent.putExtra("click_file", (nxl.types.NxFileBase) mClickFile);
            intent.putExtra("current_file", mCurrentFile);
            intent.putExtra("as_third_party", bAsThirdPartyOpen);
            intent.setClass(Profileinfo_rightsActivity.this, ClassifyActivity.class);
            Profileinfo_rightsActivity.this.startActivity(intent);
            Profileinfo_rightsActivity.this.finish();
            overridePendingTransition(R.anim.in_from_left, R.anim.out_to_right);
        }
    }

    private void initContact() {
        mListViewItems = (ListView) findViewById(R.id.profileinforightslistView);
        mListViewItems.setOnTouchListener(this);
        mItemArray = new ArrayList<NXProfileRightsItem>();
        mProfileAdapter = new NXProfileinfoRightsAdapter(this, R.layout.profile_info_rights_item, mItemArray);
        mListViewItems.setAdapter(mProfileAdapter);
    }

    private NXRights getRights(String filePath) {
        NXRights retRights = new NXRights();
        nxl.fileFormat.Tags tags = new nxl.fileFormat.Tags();

        if (nxl.fileFormat.Utils.getTags(filePath, false, null, tags)) {
            String content = ViewerApp.getInstance().sessionGetHeartBeatRawXml();
            retRights = NXPolicyEngineWrapper.GetRights(ViewerApp.getInstance().getSessionSid(), tags.toHashMap(), content);
            //report log to rms server
            {
                ViewerApp app = ViewerApp.getInstance();
                NXLogRequestValue requestValue = new NXLogRequestValue();
                requestValue.agentId = app.sessionGetAgentId();
                requestValue.rights = NXRightsList.getRightsList(retRights);
                requestValue.userName = app.getCurrentUser().name;
                requestValue.sid = app.getSessionSid();
                requestValue.hostNme = android.os.Build.MANUFACTURER;
                requestValue.nxDocPath = filePath;
                requestValue.nxDocPathTags = SendLogHelper.parseContent.transferTagToLog(tags.toHashMap());
                requestValue.hitPolicies = SendLogHelper.parseContent.transferPolicyToLog(NXPolicyEngineWrapper.getHitPolicy());
                SendLogHelper logHelper = new SendLogHelper(requestValue, NXLogRequestValue.LogType.Evaluation);
                logHelper.reportToRMS();
            }
        }
        return retRights;
    }

    private void initData() {

        NXRights rights = getRights(mCurrentFile.getPath());

        NXProfileRightsItem itemView = new NXProfileRightsItem(getString(R.string.right_view), rights.hasView());
        NXProfileRightsItem itemClassify = new NXProfileRightsItem(getString(R.string.right_classify), rights.hasClassify());

        mItemArray.clear();
        mItemArray.add(itemView);
        mItemArray.add(itemClassify);

        mProfileAdapter.notifyDataSetChanged();
    }
}

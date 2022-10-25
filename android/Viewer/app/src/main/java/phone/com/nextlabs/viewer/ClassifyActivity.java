package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.TagList.Node;
import com.TagList.SimpleTreeAdapter;
import com.TagList.TreeHelper;
import com.TagList.TreeListViewAdapter;
import com.TagList.TreeNodeDefaultValue;
import com.TagList.TreeNodeDisplayName;
import com.TagList.TreeNodeId;
import com.TagList.TreeNodeMandatory;
import com.TagList.TreeNodeMultipleSelect;
import com.TagList.TreeNodePid;
import com.TagList.TreeNodePriority;
import com.TagList.TreeNodeSubValueId;
import com.TagList.TreeNodeTagName;
import com.imageableList.NXProfileGestureListen;
import com.nextlabs.viewer.R;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

import PolicyEngineWrapper.NXPolicyEngineWrapper;
import PolicyEngineWrapper.NXRights;
import PolicyEngineWrapper.NXRightsList;
import appInstance.ViewerApp;
import appInstance.remoteRepo.ICancelable;
import appInstance.remoteRepo.IRemoteRepo;
import commonUtils.ProgressDialogEx;
import commonUtils.SendLogHelper;
import commonUtils.viewFileUtils.viewFileHelper;
import database.UserProfile;
import errorHandler.ErrorCode;
import errorHandler.GenericError;
import nxl.types.INxFile;
import restAPIWithRMS.dataTypes.NXLabel;
import restAPIWithRMS.dataTypes.NXLogRequestValue;
import restAPIWithRMS.dataTypes.NXValue;


public class ClassifyActivity
        extends Activity
        implements IRemoteRepo.IUploadFileCallback,
        View.OnTouchListener, NXProfileGestureListen.MoveCallback {

    private static final String OWNER = "$(user.name)";
    private static final String HOST = "$(host.name)";
    private static final String CREATE_TIME = "$(current_time)";
    private static final String FILE_SUFFIX_NXL = ".nxl";
    private static final String ERROR_CODE = "400";
    private static final String MSG_ALREADY_EXISTS = "resource_already_exists";

    private static String TAG = "ClassifyActivity";
    private TextView mCancel;
    private TextView mBack;
    private TextView mFileName;
    private TextView mClassification;
    private TextView protectOrReclassify;
    private String mfilename;
    private String mfilePath;
    private boolean misNxlFile = false;
    private boolean reclassify;
    private nxl.fileFormat.Tags mreclassifyTagsOut; // use new TagsInterface
    private ProgressDialogEx mProgressDialog;
    private File mSourceFile;
    // used for nxl file attribute page flip icon.
    private View mDot0;
    private View mDot1;
    private View mDot2;
    private List<NodeData> mCurrentUserDatas = new ArrayList<NodeData>(); // here NodeData contains value node and tag node
    private List<NodeData> mAllDatas = new ArrayList<NodeData>(); // here NodeData contains value node and tag node
    private TreeListViewAdapter mAdapter;
    private ListView mListView;
    private boolean mIsAttributeTag = false;
    private boolean mIsProtect = false;
    private boolean mIsCancelUpload = false;
    private INxFile mClickFile;
    private File mCurrentFile;
    private boolean bAsThirdPartyOpen = false;
    private INxFile mParentFolder;
    private GestureDetector mDetector;
    private ICancelable uploadFileCancelHandler;
    private final View.OnClickListener mCommonListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            int id = v.getId();
            switch (id) {
                case R.id.classifycancelOrBack:
                    ClassifyActivity.this.finish();
                    break;
                case R.id.protectOrReclassify:
                    protectFile();
                    break;
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_classify);
        init();
        try {
            if (mreclassifyTagsOut != null) {
                mAdapter = new SimpleTreeAdapter<>(mListView, protectOrReclassify, this, mAllDatas, mCurrentUserDatas, mreclassifyTagsOut.getTags(), reclassify, mIsAttributeTag);
            } else {
                mAdapter = new SimpleTreeAdapter<>(mListView, protectOrReclassify, this, mAllDatas, mCurrentUserDatas, null, reclassify, mIsAttributeTag);
            }

            mAdapter.setOnTreeNodeClickListener(new TreeListViewAdapter.OnTreeNodeClickListener() {
                @Override
                public void onClick(Node node, int position) {
                    if (node.isLeaf()) {
                    }
                }

            });

        } catch (Exception e) {
            e.printStackTrace();
        }
        mListView.setAdapter(mAdapter);
    }

    private void init() {

        // the tag of file attribute.
        Intent intent = getIntent();
        if (intent.getAction() != null && (intent.getAction().equals("INFOFORWARD") || intent.getAction().equals("INFOBACK"))) {
            mIsAttributeTag = true;
            mBack = (TextView) findViewById(R.id.classifycancelOrBack);
            mBack.setText(getString(R.string.back));
            mBack.setTextColor(getResources().getColor(R.color.normal_text_color));
            Drawable drawable = getResources().getDrawable(R.drawable.file_category_back);
            drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
            mBack.setCompoundDrawables(drawable, null, null, null);

            protectOrReclassify = (TextView) findViewById(R.id.protectOrReclassify);
            protectOrReclassify.setVisibility(View.INVISIBLE);
            mListView = (ListView) findViewById(R.id.id_tree);
            mListView.setOnTouchListener(this);
            mFileName = (TextView) findViewById(R.id.filenameOrClassification);

            mDetector = new GestureDetector(this, new NXProfileGestureListen(this));

            mClickFile = (INxFile) getIntent().getSerializableExtra("click_file");
            mParentFolder = ViewerApp.getInstance().findParentThroughBoundService(mClickFile);
            mCurrentFile = (File) getIntent().getSerializableExtra("current_file");
            bAsThirdPartyOpen = getIntent().getBooleanExtra("as_third_party", false);

            mfilePath = mCurrentFile.getPath();
            mClassification = (TextView) findViewById(R.id.filenameOrClassification);
            mClassification.setText(getString(R.string.classification));

            mBack.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    ClassifyActivity.this.finish();
                    overridePendingTransition(R.anim.in_from_left, R.anim.out_to_right);
                }
            });

//            protectOrReclassify.setOnClickListener(new View.OnClickListener() {
//                @Override
//                public void onClick(View v) {
//                    if (!mIsProtect) {
//                        try {
//                            TreeListViewAdapter.getInstance().handleNxlFileTag(TreeHelper.getSortedNodes(mDatas), false);
//                        } catch (Exception e) {
//                            Log.d(TAG, e.toString());
//                        }
//
//                        TreeListViewAdapter.getInstance().notifyDataSetChanged();
//                        mIsProtect = true;
//                    } else {
//                        protectFile();
//                        showProgressBar();
//                    }
//                }
//            });

            mDot0 = findViewById(R.id.tag_dot_0);
            mDot1 = findViewById(R.id.tag_dot_1);
            mDot2 = findViewById(R.id.tag_dot_2);
            mDot0.setVisibility(View.VISIBLE);
            mDot1.setVisibility(View.VISIBLE);
            mDot2.setVisibility(View.VISIBLE);
        } else if (intent.getAction() != null && intent.getAction().equals("NXProtectToView")) {
            mCancel = (TextView) findViewById(R.id.classifycancelOrBack);
            protectOrReclassify = (TextView) findViewById(R.id.protectOrReclassify);
            protectOrReclassify.setVisibility(View.VISIBLE);
            mFileName = (TextView) findViewById(R.id.filenameOrClassification);
            mListView = (ListView) findViewById(R.id.id_tree);

            mClickFile = (INxFile) getIntent().getSerializableExtra("click_protect");
            mParentFolder = ViewerApp.getInstance().findParentThroughBoundService(mClickFile);
            mCurrentFile = (File) getIntent().getSerializableExtra("current_file");
            bAsThirdPartyOpen = getIntent().getBooleanExtra("as_third_party", false);

            protectOrReclassify.setOnClickListener(mCommonListener);
            mCancel.setOnClickListener(mCommonListener);
            mfilePath = mCurrentFile.getPath();
            mfilename = mfilePath.substring(mfilePath.lastIndexOf('/') + 1);
            mFileName.setText(mfilename);
        }

        if (nxl.fileFormat.Utils.check(mfilePath, false)) {
            misNxlFile = true;
            mreclassifyTagsOut = new nxl.fileFormat.Tags();
            boolean result = nxl.fileFormat.Utils.getTags(mfilePath, false, null, mreclassifyTagsOut);

            if (result) {
                String content = ViewerApp.getInstance().sessionGetHeartBeatRawXml();
                NXRights rights = NXPolicyEngineWrapper.GetRights(ViewerApp.getInstance().getSessionSid(), mreclassifyTagsOut.toHashMap(), content);

                if (mIsAttributeTag) {
                    reclassify = false;
                } else {
                    if (rights.hasClassify()) {
                        // re-classify
                        reclassify = true;
                        protectOrReclassify.setText(getString(R.string.Reclassify));
                    } else {
                        // only view
                        reclassify = false;
                        protectOrReclassify.setVisibility(View.INVISIBLE);
                    }
                }

                //report log to rms server.
                {
                    ViewerApp app = ViewerApp.getInstance();
                    NXLogRequestValue requestValue = new NXLogRequestValue();
                    requestValue.agentId = app.sessionGetAgentId();
                    requestValue.rights = NXRightsList.getRightsList(rights);
                    requestValue.userName = app.getCurrentUser().name;
                    requestValue.sid = app.getSessionSid();
                    requestValue.hostNme = android.os.Build.MANUFACTURER;
                    requestValue.nxDocPath = mfilePath;
                    requestValue.nxDocPathTags = SendLogHelper.parseContent.transferTagToLog(mreclassifyTagsOut.toHashMap());
                    requestValue.hitPolicies = SendLogHelper.parseContent.transferPolicyToLog(NXPolicyEngineWrapper.getHitPolicy());
                    SendLogHelper logHelper = new SendLogHelper(requestValue, NXLogRequestValue.LogType.Evaluation);
                    logHelper.reportToRMS();
                }
            }
        }

        initDatas();
    }

    private void protectFile() {

        mIsCancelUpload = false;
        // get tags from UI
        nxl.fileFormat.Tags tags = new nxl.fileFormat.Tags();
        tags.fromString(getTagsStringFromUI());
        // get latest key
        byte[] keyBlob = nxl.fileFormat.Utils.getKeyBlobLatest(ViewerApp.getInstance().sessionGetKeyRings());

        if (!misNxlFile && !mIsAttributeTag) {

            String cipherPath = mfilePath + FILE_SUFFIX_NXL;
            // convert to nxl file , is cipherPath file had existed , overwrite it
            if (!nxl.fileFormat.Utils.convert(mfilePath, cipherPath, keyBlob, true))
                Log.d(TAG, "create nxl file failed!");
            // attach tags to cipherPath
            if (!nxl.fileFormat.Utils.setTags(cipherPath, keyBlob, tags)) {
                Log.d(TAG, "Set tags failed!");
            }
            // upload this new created cipher file to cloud
            upLoadFile(new File(cipherPath));
            showProgressBar();
        } else {
            if (!nxl.fileFormat.Utils.setTags(mfilePath, keyBlob, tags)) {
                // fix bug 33348
                GenericError.showUI(ClassifyActivity.this, ErrorCode.RECLASSIFY_FAILED, getString(R.string.reclassify_file_failed), true, false, true, null);
                return;
            }

            updateFile(mClickFile, mCurrentFile);
            showProgressBar();
        }

        if (bAsThirdPartyOpen) {
            doSetting();
        }
    }

    private String getTagsStringFromUI() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < mListView.getCount(); i++) {
            RelativeLayout relativeLayout = (RelativeLayout) mListView.getAdapter().getView(i, null, null);
            TextView textView_displayName = (TextView) relativeLayout.getChildAt(0);
            String displayName = textView_displayName.getText().toString();
            String tagName = TreeHelper.getTagNameByDisplayName(displayName);

            String tagValue = "";
            if (tagName != null && !tagName.isEmpty() && !tagName.equals("")) {
                Node node = TreeHelper.getNodeByTagName(tagName);
                tagValue = node.getDefaultValue();
                if (!tagValue.equals("Select...") && !tagValue.isEmpty()) {
                    sb.append(tagName);
                    sb.append("=");
                    sb.append(tagValue);
                    sb.append("\0");
                }
            }

        }
        sb.append("\0");
        return sb.toString();
    }


    private void initDatas() {
        // get labels.
        List<NXLabel> AllLabels = ViewerApp.getInstance().sessionGetLabelsByAll();
        List<NXLabel> currentUserlabels = ViewerApp.getInstance().sessionGetLabelsByCurrentUser();
        processLabels(AllLabels, mAllDatas);
        processLabels(currentUserlabels, mCurrentUserDatas);
    }

    private void processLabels(List<NXLabel> Labels, List<NodeData> Data) {
        if (null == Labels) {
            protectOrReclassify.setTextColor(Color.GRAY);
            protectOrReclassify.setEnabled(false);
            return;
        }

        List<NXLabelEx> sourceData = new ArrayList<NXLabelEx>();
        for (NXLabel label : Labels) {
            List<NXValue> valueList = label.values;
            // padding data for owner, host and create time.
            if (label.displayName.equals("Owner")) {
                for (NXValue value : valueList) {
                    if (value.labelValue.equals(OWNER)) {
                        UserProfile currentUser = ViewerApp.getInstance().getCurrentUser();
                        value.labelValue = currentUser.name;
                    }
                }
            } else if (label.displayName.equals("Host")) {
                for (NXValue value : valueList) {
                    if (value.labelValue.equals(HOST)) {
                        value.labelValue = android.os.Build.MANUFACTURER;
                    }
                }
            } else if (label.displayName.equals("Create Time")) {
                for (NXValue value : valueList) {
                    if (value.labelValue.equals(CREATE_TIME) && mreclassifyTagsOut == null) {
                        Calendar calendar = Calendar.getInstance();
                        value.labelValue = calendar.get(Calendar.YEAR) + "-" + (calendar.get(Calendar.MONTH) + 1) + "-" + calendar.get(Calendar.DAY_OF_MONTH)
                                + " " + calendar.get(Calendar.HOUR_OF_DAY) + ":" + calendar.get(Calendar.MINUTE) + ":" + calendar.get(Calendar.SECOND);
                    }
                }
            }

            NXLabelEx labelEx = new NXLabelEx(label.name, label.displayName, label.mandatory, label.multipleSelection, label.defaultValueId, label.id, valueList);
            sourceData.add(labelEx);
        }

        mapSubLabelPid(sourceData);

        int tmpId = sourceData.size();
        for (NXLabelEx nxLabel : sourceData) {
            Data.add(new NodeData(nxLabel._id, nxLabel.parentId, -1, nxLabel.tagName, nxLabel.displayName, nxLabel.defaultValue, nxLabel.multipleSelect, nxLabel.mandatory, -1)); // tag node.

            List<NXValue> vl = new ArrayList<>();
            vl = nxLabel.label.values;
            for (NXValue value : vl) {
                int pId = nxLabel._id;
                int subValueId = value.subValueId;
                // set value node pid as to its tag node id.
                Data.add(new NodeData(++tmpId, pId, subValueId, "", "", value.labelValue, nxLabel.multipleSelect, false, value.priority)); // value node -- tagName and displayName is null.  labelValue is defaultValue.
            }

        }

    }

    // map the parent id for the subLabel
    private void mapSubLabelPid(List<NXLabelEx> sourceData) {   // sourceData  -- tag node.
        for (int i = 0; i < sourceData.size(); i++) {
            for (int j = i + 1; j < sourceData.size(); j++) {
                List<NXValue> list1 = new ArrayList<>();
                list1 = sourceData.get(i).label.values;
                for (NXValue value : list1) {
                    if (value.subValueId != -1) // have subTag
                    {
                        if (value.subValueId == sourceData.get(j)._id)
                            sourceData.get(j).parentId = sourceData.get(i)._id;
                    }
                }

                List<NXValue> list2 = new ArrayList<>();
                list2 = sourceData.get(j).label.values;
                for (NXValue value : list2) {
                    if (value.subValueId != -1) // have subTag
                    {
                        if (value.subValueId == sourceData.get(i)._id)
                            sourceData.get(i).parentId = sourceData.get(j)._id;
                    }
                }
            }
        }
    }

    private void upLoadFile(File sourceFile) {
        mSourceFile = sourceFile;
        try {
            if (mParentFolder != null && !bAsThirdPartyOpen) {
                ViewerApp.getInstance().uploadFile(mParentFolder, sourceFile.getName(), sourceFile, this);
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }

    }

    private void updateFile(INxFile updateFile, File sourceFile) {
        mSourceFile = sourceFile;
        try {
            if (mParentFolder != null && !bAsThirdPartyOpen) {
                ViewerApp.getInstance().updateFile(mParentFolder, updateFile, sourceFile, this);
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
            e.printStackTrace();
        }

    }

    @Override
    public void cancelHandler(ICancelable handler) {
        uploadFileCancelHandler = handler;
    }

    @Override
    public void uploadFileProgress(long newValue) {
        mProgressDialog.setProgress((int) newValue);
    }

    @Override
    public void uploadFileFinished(boolean taskStatus, String cloudPath, String errorMsg) {
        mProgressDialog.dismiss();

        if (mIsCancelUpload) {
            mIsCancelUpload = false;
            return;
        }

        if (taskStatus) {
            doSetting();
        } else {
            if (errorMsg.equals(ERROR_CODE) || errorMsg.equals(MSG_ALREADY_EXISTS)) {
                renameUpload();
            } else {
                GenericError.showUI(ClassifyActivity.this, ErrorCode.UPLOAD_FILE_FAILED_ERROR, getString(R.string.upload_file_failed), true, false, true, null);
            }
        }

    }

    private void doSetting() {
        // close original file and display the encrypted file.
        Intent intent = new Intent();
        String localPath = "";
        if (misNxlFile) {
            intent.putExtra("NXVIEW", mfilePath);
            localPath = mClickFile.getLocalPath().substring(0, mClickFile.getLocalPath().lastIndexOf("/") + 1) + mfilename;
            mFileName.setText(mfilename);
        } else {
            intent.putExtra("NXVIEW", mfilePath + FILE_SUFFIX_NXL);
            localPath = mClickFile.getLocalPath() + FILE_SUFFIX_NXL;
            mFileName.setText(mfilename + FILE_SUFFIX_NXL);
        }

        // for display file attribute after protect
        nxl.types.NxFileBase file = new nxl.types.NXDocument();
        SimpleDateFormat modifyTime = new SimpleDateFormat("yyyy/MM/dd HH:mm");
        String result = modifyTime.format(new Date(mSourceFile.lastModified()));
        viewFileHelper.fillFileParameters(file, localPath, mSourceFile.length(), mSourceFile.getName(), result);

        // switch viewFileActivity then display the protected file or reclassify file.
        intent.setAction("NXViewEncryptFile");
        intent.putExtra("click_file", file);
        intent.putExtra("as_third_party", bAsThirdPartyOpen);
        intent.setClass(ClassifyActivity.this, ViewFileActivity.class);
        startActivity(intent);
        finish();

        // close original file view.
        if (ViewFileActivity.ViewFileActivityInstance != null) {
            ViewFileActivity.ViewFileActivityInstance.finish();
        }
    }

    private void renameUpload() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View renameView = LayoutInflater.from(this).inflate(R.layout.upload_rename_dialog, null);
        final EditText et_rename = (EditText) renameView.findViewById(R.id.ev_file_rename);

        if (mfilename.endsWith(FILE_SUFFIX_NXL)) {
            // remove extension ".xnl"
            mfilename = mfilename.substring(0, mfilename.lastIndexOf("."));
        }

        if (mfilename.contains(".")) {
            et_rename.setText(mfilename.substring(0, mfilename.lastIndexOf(".")));
        } else {
            et_rename.setText(mfilename);
        }

        final String originalContent = et_rename.getText().toString();

        final String normalFileExtension = mfilename.contains(".") ? mfilename.substring(mfilename.lastIndexOf(".")) : mfilename;

        builder.setTitle(R.string.title_popup_dialog);
        builder.setMessage(getString(R.string.dialog_rename_msg));
        builder.setView(renameView);
        builder.setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int id) {
                String inputName = et_rename.getText().toString();
                if (!inputName.isEmpty()) {
                    mfilename = inputName + normalFileExtension + FILE_SUFFIX_NXL;
                }

                File renameFile = new File(mSourceFile.getParent() + "/" + inputName + normalFileExtension + FILE_SUFFIX_NXL);
                if (mSourceFile.renameTo(renameFile)) {
                    upLoadFile(renameFile);
                    showProgressBar();
                    mfilePath = mSourceFile.getParent() + "/" + inputName + normalFileExtension + FILE_SUFFIX_NXL;
                    misNxlFile = true;
                }


            }
        });
        builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int id) {
                finish();
            }
        });
        builder.setCancelable(false);
        final AlertDialog dialog = builder.create();
        dialog.show();

        final Button positiveButton = ((AlertDialog) dialog).getButton(AlertDialog.BUTTON_POSITIVE);
        positiveButton.setEnabled(false);

        et_rename.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s.toString().isEmpty() || s.toString().equals(originalContent)) {
                    positiveButton.setEnabled(false);
                } else {
                    positiveButton.setEnabled(true);
                }
            }
        });

    }

    private void showProgressBar() {
        if (bAsThirdPartyOpen) {
            return;
        }

        mProgressDialog = new ProgressDialogEx(ClassifyActivity.this);
        mProgressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        mProgressDialog.setMessage(getString(R.string.uploading));
        mProgressDialog.setCancelable(false);
        mProgressDialog.setButton(DialogInterface.BUTTON_NEGATIVE, getString(R.string.cancel), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                // ViewerApp.getInstance().getInterfaceOfRemoteRepo().cancelUpload();
                if (uploadFileCancelHandler != null) {
                    uploadFileCancelHandler.cancel();
                    mIsCancelUpload = true;
                } else {
                    Log.e(TAG, "fatal error, uploadFileCancelHandler should not null");
                }
                dialog.dismiss();
            }
        });
        mProgressDialog.show();
    }

    // Used for fingers slide the screen in File attribute tag.
    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (mDetector != null)
            return mDetector.onTouchEvent(event);
        else
            return false;
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        mDetector.onTouchEvent(event);
        return false;   //onTouch -> OnTouchEvent   if onTouch return true, OnTouchEvent won't be excuted.
    }

    @Override
    public void JumpTo(boolean way) {
        if (way) {
            Intent intent = new Intent();
            intent.setAction("INFOFORWARD");
            intent.putExtra("click_file", (nxl.types.NxFileBase) mClickFile);
            intent.putExtra("current_file", mCurrentFile);
            intent.putExtra("as_third_party", bAsThirdPartyOpen);
            intent.setClass(ClassifyActivity.this, Profileinfo_rightsActivity.class);
            ClassifyActivity.this.startActivity(intent);
            ClassifyActivity.this.finish();
            overridePendingTransition(R.anim.in_from_right, R.anim.out_to_left);
        } else {
            Intent intent = new Intent();
            intent.setAction("INFOBACK");
            intent.putExtra("click_file", (nxl.types.NxFileBase) mClickFile);
            intent.putExtra("current_file", mCurrentFile);
            intent.putExtra("as_third_party", bAsThirdPartyOpen);
            intent.setClass(ClassifyActivity.this, Profileinfo_commonattributeActivity.class);
            ClassifyActivity.this.startActivity(intent);
            ClassifyActivity.this.finish();
            overridePendingTransition(R.anim.in_from_left, R.anim.out_to_right);
        }
    }

    // control the MotionEvent should not be null when slide page that the listView is non-clickable.
    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        super.dispatchTouchEvent(ev);
        if (mDetector != null)
            return mDetector.onTouchEvent(ev);
        else
            return false;
    }

    public class NodeData {
        @TreeNodeId
        private int _id;
        @TreeNodePid
        private int parentId;
        @TreeNodeSubValueId
        private int subValueId;
        @TreeNodeTagName
        private String tagName;
        @TreeNodeDisplayName
        private String displayName;
        @TreeNodeDefaultValue
        private String defaultValue;
        @TreeNodeMultipleSelect
        private boolean multipleSelect;
        @TreeNodeMandatory
        private boolean mandatory;
        @TreeNodePriority
        private int priority;

        public NodeData(int _id, int parentId, int subValueId, String tagName, String displayName, String defaultValue, boolean multipleSelect, boolean mandatory, int priority) {
            super();
            this._id = _id;
            this.parentId = parentId;
            this.tagName = tagName;
            this.displayName = displayName;
            this.defaultValue = defaultValue;
            this.subValueId = subValueId;
            this.multipleSelect = multipleSelect;
            this.mandatory = mandatory;
            this.priority = priority;
        }

    }

    public class NXLabelEx {
        @TreeNodeId
        private int _id;
        @TreeNodePid
        private int parentId;
        @TreeNodeTagName
        private String tagName;
        @TreeNodeDisplayName
        private String displayName;
        @TreeNodeDefaultValue
        private String defaultValue;
        @TreeNodeMultipleSelect
        private boolean multipleSelect;
        @TreeNodeMandatory
        private boolean mandatory;

        private NXLabel label;

        public NXLabelEx(String name, String displayName, boolean mandatory, boolean multipleSelection, int defaultValueId, int id, List<NXValue> values) {
            label = new NXLabel();
            label.name = name;
            label.displayName = displayName;
            label.mandatory = mandatory;
            label.multipleSelection = multipleSelection;
            label.defaultValueId = defaultValueId;
            label.id = id;
            label.values = values;

            this._id = id;
            this.tagName = name;
            this.displayName = displayName;
            this.parentId = -1; // -1 means root node
            this.multipleSelect = multipleSelection;
            this.mandatory = mandatory;

            for (int i = 0; i < values.size(); i++) {
                if (i == label.defaultValueId) {
                    defaultValue = values.get(i).labelValue;
                } else if (label.defaultValueId == -1) {
                    defaultValue = "Select...";
                }
            }
        }

    }

}


package phone.com.nextlabs.viewer;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.ListView;
import android.widget.TextView;

import com.imageableList.NXProfileAccountAdapter;
import com.imageableList.NXProfileAccountItem;
import com.nextlabs.viewer.R;

import java.util.ArrayList;

import appInstance.ViewerApp;
import database.UserProfile;
import rms.common.NXUserInfo;

public class ProfileAccountActivity extends Activity {

    //private TextView mBack;
    private ListView mListViewItems;
    private ArrayList<NXProfileAccountItem> mItemArray;
    private NXProfileAccountAdapter mProfileAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile_account);

        findViewById(R.id.tv_account_back).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ProfileAccountActivity.this.finish();
            }
        });
        initContact();
        initData();

    }

    private void initContact() {
        mListViewItems = (ListView) findViewById(R.id.profile_account_list); /*mListViewItems.setOnTouchListener(this);*/
        mItemArray = new ArrayList<>();
        mProfileAdapter = new NXProfileAccountAdapter(this, R.layout.profile_account_item, mItemArray);
        mListViewItems.setAdapter(mProfileAdapter);
    }

    private void initData() {

        NXUserInfo user = ViewerApp.getInstance().getSession().getUserInfo();

        NXProfileAccountItem item_username = new NXProfileAccountItem("User Name", user.getName());
        NXProfileAccountItem item_mail = new NXProfileAccountItem("E-mail", user.getEmail());
        NXProfileAccountItem item_rmserver = new NXProfileAccountItem("RM Server", ViewerApp.getInstance().getSession().getCurrentServer());

        mItemArray.clear();
        mItemArray.add(item_username);
        mItemArray.add(item_mail);
        mItemArray.add(item_rmserver);

        mProfileAdapter.notifyDataSetChanged();
    }

}

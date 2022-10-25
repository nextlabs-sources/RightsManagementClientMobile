package commonUtils.dialog;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.nextlabs.viewer.R;
import com.widgets.timeoutDialogWidget.adapter.AbstractWheelTextAdapter;
import com.widgets.timeoutDialogWidget.views.OnWheelChangedListener;
import com.widgets.timeoutDialogWidget.views.OnWheelScrollListener;
import com.widgets.timeoutDialogWidget.views.WheelView;

import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ChangeTimeDialog extends Dialog {
    private Context context;
    private WheelView mDayWheelView;
    private WheelView mHourWheelView;

    private View mMainLayout;
    private View mChildLayout;
    private TextView mSureView;
    private TextView mCancelView;

    private ArrayList<String> mDayList = new ArrayList<String>();
    private ArrayList<String> mHourList = new ArrayList<String>();
    private TimeTextAdapter mDayAdapter;
    private TimeTextAdapter mHourAdapter;

    private int mCurrentDay = 0;
    private int mCurrentHour = 0;

    private int maxTextSize = 25;
    private int minTextSize = 18;

    private boolean mIsSetData = false;

    private String mSelectDay;
    private String mSelectHour;

    private IOnGetTimeFinished onGetTimeFinished;

    public ChangeTimeDialog(Context context) {
        super(context, R.style.ShareDialog);
        this.context = context;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.dialog_setting_timeout);
        mDayWheelView = (WheelView) findViewById(R.id.wv_day);
        mHourWheelView = (WheelView) findViewById(R.id.wv_hour);

        mMainLayout = findViewById(R.id.ly_setting_time);
        mChildLayout = findViewById(R.id.ly_setting_time_child);
        mSureView = (TextView) findViewById(R.id.btn_sure);
        mCancelView = (TextView) findViewById(R.id.btn_cancel);

        mMainLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
        mChildLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
        mSureView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (onGetTimeFinished != null) {
                    onGetTimeFinished.onFinish(mCurrentDay, mCurrentHour);
                    dismiss();
                }
            }
        });
        mCancelView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });

        if (!mIsSetData) {
            initData();
        }
        initDays();
        mDayAdapter = new TimeTextAdapter(context, mDayList, mCurrentDay, maxTextSize, minTextSize);
        mDayWheelView.setVisibleItems(5);
        mDayWheelView.setViewAdapter(mDayAdapter);
        mDayWheelView.setCurrentItem(mCurrentDay);

        initHours();
        mHourAdapter = new TimeTextAdapter(context, mHourList, mCurrentHour, maxTextSize, minTextSize);
        mHourWheelView.setVisibleItems(5);
        mHourWheelView.setViewAdapter(mHourAdapter);
        mHourWheelView.setCurrentItem(mCurrentHour);

        mDayWheelView.addChangingListener(new OnWheelChangedListener() {
            @Override
            public void onChanged(WheelView wheel, int oldValue, int newValue) {
                // TODO Auto-generated method stub
                String currentText = (String) mDayAdapter.getItemText(wheel.getCurrentItem());
                mSelectDay = currentText;
                setTextviewSize(currentText, mDayAdapter);
                mCurrentDay = Integer.parseInt(parseDate(mSelectDay));
            }
        });

        mDayWheelView.addScrollingListener(new OnWheelScrollListener() {

            @Override
            public void onScrollingStarted(WheelView wheel) {
                // TODO Auto-generated method stub
            }

            @Override
            public void onScrollingFinished(WheelView wheel) {
                // TODO Auto-generated method stub
                String currentText = (String) mDayAdapter.getItemText(wheel.getCurrentItem());
                setTextviewSize(currentText, mDayAdapter);
            }
        });

        mHourWheelView.addChangingListener(new OnWheelChangedListener() {
            @Override
            public void onChanged(WheelView wheel, int oldValue, int newValue) {
                // TODO Auto-generated method stub
                String currentText = (String) mHourAdapter.getItemText(wheel.getCurrentItem());
                mSelectHour = currentText;
                setTextviewSize(currentText, mHourAdapter);
                mCurrentHour = Integer.parseInt(parseDate(mSelectHour));
            }
        });

        mHourWheelView.addScrollingListener(new OnWheelScrollListener() {
            @Override
            public void onScrollingStarted(WheelView wheel) {
                // TODO Auto-generated method stub

            }

            @Override
            public void onScrollingFinished(WheelView wheel) {
                // TODO Auto-generated method stub
                String currentText = (String) mHourAdapter.getItemText(wheel.getCurrentItem());
                setTextviewSize(currentText, mHourAdapter);
            }
        });
    }

    public void initDays() {
        mDayList.clear();
        for (int i = 0; i <= 100; ++i) {
            if (i == 0 || i == 1) {
                mDayList.add(i + " day");
            } else {
                mDayList.add(i + " days");
            }
        }
    }

    public void initHours() {
        mHourList.clear();
        for (int i = 0; i <= 23; ++i) {
            if (i == 0 || i == 1) {
                mHourList.add(i + " hour");
            } else {
                mHourList.add(i + " hours");
            }
        }
    }

    /**
     * set the callback function which to retrieve value from dialog
     *
     * @param callback callback function
     */
    public void setOnGetTimeFinished(IOnGetTimeFinished callback) {
        this.onGetTimeFinished = callback;
    }

    /**
     * set text view size.
     *
     * @param currentItemText the target view need to be set
     * @param adapter         wheel view adapter
     */
    public void setTextviewSize(String currentItemText, TimeTextAdapter adapter) {
        ArrayList<View> arrayList = adapter.getTextViews();
        int size = arrayList.size();
        String currentText;
        for (int i = 0; i < size; i++) {
            TextView textView = (TextView) arrayList.get(i);
            currentText = textView.getText().toString();
            if (currentItemText.equals(currentText)) {
                textView.setTextSize(maxTextSize);
            } else {
                textView.setTextSize(minTextSize);
            }
        }
    }

    /**
     * initialize data
     */
    public void initData() {
        setDate(0, 1);
    }

    /**
     * initialize time out value
     */
    public void setDate(int day, int hour) {
        mSelectDay = day + "";
        mSelectHour = hour + "";
        mIsSetData = true;
        mCurrentDay = day;
        mCurrentHour = hour;
    }

    /**
     * parse number from string value
     *
     * @param temp source string
     * @return number string in temp
     */
    private String parseDate(String temp) {
        String regEx = "[^0-9]";
        Pattern p = Pattern.compile(regEx);
        Matcher m = p.matcher(temp);
        return m.replaceAll("").trim();
    }

    /**
     * callback function to retrieve value from dialog
     */
    public interface IOnGetTimeFinished {
        void onFinish(int day, int hour);
    }

    /**
     * adapter for wheel view
     */
    private class TimeTextAdapter extends AbstractWheelTextAdapter {
        ArrayList<String> list;

        protected TimeTextAdapter(Context context, ArrayList<String> list, int currentItem, int maxsize, int minsize) {
            super(context, R.layout.item_time, NO_RESOURCE, currentItem, maxsize, minsize);
            this.list = list;
            setItemTextResource(R.id.timeItem);
        }

        @Override
        public View getItem(int index, View cachedView, ViewGroup parent) {
            View view = super.getItem(index, cachedView, parent);
            return view;
        }

        @Override
        public int getItemsCount() {
            return list.size();
        }

        @Override
        protected CharSequence getItemText(int index) {
            return list.get(index) + "";
        }
    }
}
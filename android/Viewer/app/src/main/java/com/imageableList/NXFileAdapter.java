package com.imageableList;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import appInstance.localRepo.sort.SortContext;
import nxl.types.INxFile;

public class NXFileAdapter extends ArrayAdapter<INxFile> {
    private int mResourceId;
    private List<INxFile> mFileList;
    private String mLastGrayStr;
    private SortContext.SortType mSortType;
    private Context mContext;

    private OnInfoItemClicked onInfoItemClicked;

    public NXFileAdapter(Context context, int textViewResourceId, List<INxFile> objects) {
        super(context, textViewResourceId, objects);
        mResourceId = textViewResourceId;
        mFileList = objects;

        mContext = context;
    }

    public void setOnInfoItemClicked(OnInfoItemClicked onInfoItemClicked) {
        this.onInfoItemClicked = onInfoItemClicked;
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {
        final INxFile file = getItem(position);
        View view;
        ViewHolder viewHolder;
        //  infoButtonListener infoListener;
        if (convertView == null) {
            view = LayoutInflater.from(getContext()).inflate(mResourceId, null);
            viewHolder = new ViewHolder();
            viewHolder.fileName = (TextView) view.findViewById(R.id.file_item_name);
            viewHolder.fileProperty = (TextView) view.findViewById(R.id.file_item_info);
            viewHolder.imageView = (ImageView) view.findViewById(R.id.file_item_image);
            viewHolder.indexName = (TextView) view.findViewById(R.id.fileItemIndex);
            viewHolder.linearLayout = (LinearLayout) view.findViewById(R.id.fileItemIndexLayout);
            viewHolder.fileInfo = (ImageButton) view.findViewById(R.id.file_item_property);
            view.setTag(viewHolder);
        } else {
            view = convertView;
            viewHolder = (ViewHolder) view.getTag();
        }
        //infoListener = new infoButtonListener(file);
        //viewHolder.fileInfo.setOnClickListener(infoListener);
        viewHolder.fileInfo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onInfoItemClicked.onInfoItemClicked(file, position);
            }
        });
        switch (mSortType) {
            case NAMEASCENDING: {
                int section = getSectionForPosition(position);
                if (position == getPositionForSection(section)) {
                    viewHolder.linearLayout.setVisibility(View.VISIBLE);
                    String letter;
                    if (isSpecificalLetter(file.getName().toUpperCase())) {
                        letter = "#";
                    } else {
                        letter = file.getName().toUpperCase().substring(0, 1);
                    }
                    viewHolder.indexName.setText(letter);
                } else {
                    viewHolder.linearLayout.setVisibility(View.GONE);
                }
            }
            break;
            case DRIVERTYPE: {
                if (position == 0) {
                    viewHolder.linearLayout.setVisibility(View.VISIBLE);
                    String titleService = file.getService().alias;
                    mLastGrayStr = titleService;
                    viewHolder.indexName.setText(titleService);
                } else {
                    String titleService = file.getService().alias;
                    if (!titleService.equals(mLastGrayStr)) {
                        viewHolder.linearLayout.setVisibility(View.VISIBLE);
                        mLastGrayStr = titleService;
                        viewHolder.indexName.setText(titleService);
                    } else {
                        viewHolder.linearLayout.setVisibility(View.GONE);
                    }
                }
            }
            break;
            case NEWEST: {
                String firstTime = getSectionForTime(position);
                if (position == getPositionForTime(firstTime)) {
                    viewHolder.linearLayout.setVisibility(View.VISIBLE);
                    String titleTime = ConvertTime(file, false);
                    viewHolder.indexName.setText(titleTime);
                } else {
                    viewHolder.linearLayout.setVisibility(View.GONE);
                }
            }
            break;
        }

        String temp = file.getName();
        long fileSize = 0;
        if (file.isSite()) {
            if (file.isMarkedAsFavorite()) {
                viewHolder.imageView.setImageResource(R.drawable.home_site_favorite_icon);
            } else {
                viewHolder.imageView.setImageResource(R.drawable.home_site_icon);
            }
            temp = file.getName().substring(1);
        } else if (file.isFolder()) {
            if (file.isMarkedAsFavorite()) {
                viewHolder.imageView.setImageResource(R.drawable.home_folder_favorite_icon);
            } else {
                viewHolder.imageView.setImageResource(R.drawable.home_folder_icon);
            }
        } else {
            if (file.isMarkedAsFavorite() && file.isMarkedAsOffline()) {
                viewHolder.imageView.setImageResource(R.drawable.home_file_both_icon);
            } else if (file.isMarkedAsOffline()) {
                viewHolder.imageView.setImageResource(R.drawable.home_file_offline_icon);
            } else if (file.isMarkedAsFavorite()) {
                viewHolder.imageView.setImageResource(R.drawable.home_file_favorite_icon);
            } else {
                viewHolder.imageView.setImageResource(R.drawable.home_file_icon);
            }
            fileSize = file.getSize();
        }
        viewHolder.fileName.setText(temp);
        //the string value is the temp value, because there is method in INxfile class.
        if (file.getSize() != 0) {
            viewHolder.fileProperty.setText(file.getService().alias + ", " + transparentFileSize(fileSize) + ", " + ConvertTime(file, true));
        } else {
            viewHolder.fileProperty.setText(file.getService().alias);
        }

        return view;
    }

    public void setSortType(SortContext.SortType type) {
        mSortType = type;
    }

    /**
     * get current file's first letter using the list view position value
     */
    private int getSectionForPosition(int position) {
        String name = mFileList.get(position).getName().toUpperCase();
        //set the first character using regular expression
        return getLetter(name);
    }

    /**
     * get the first position when the same first letter appears
     */
    private int getPositionForSection(int section) {
        for (int i = 0; i < getCount(); i++) {
            String name = mFileList.get(i).getName();
            //char firstChar = sortStr.toUpperCase().charAt(0);
            int firstChar = getLetter(name);
            if (firstChar == section) {
                return i;
            }
        }
        return -1;
    }

    private int getLetter(String name) {
        String nameLetter = name.trim().substring(0, 1).toUpperCase();
        if (nameLetter.matches("[A-Z]")) {
            return nameLetter.charAt(0);
        } else {
            return "#".charAt(0);
        }
    }

    private boolean isSpecificalLetter(String name) {
        String nameLetter = name.trim().substring(0, 1).toUpperCase();
        return !nameLetter.matches("[A-Z]");
    }

    private String transparentFileSize(long fileSize) {
        long sizeInteger = fileSize / 1024;
        DecimalFormat decimalFormat = new DecimalFormat("0.0");
        if (1024 > sizeInteger && 0 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / 1024)) + " KB";
        } else if (1024 < sizeInteger) {
            return Double.parseDouble(decimalFormat.format((double) fileSize / (1024 * 1024))) + " MB";
        }
        return fileSize + " B";
    }

    private String getSectionForTime(int position) {
        //set the first time
        return ConvertTime(mFileList.get(position), false);
    }

    private int getPositionForTime(String firstTime) {
        for (int i = 0; i < getCount(); i++) {
            String time = ConvertTime(mFileList.get(i), false);
            if (time.equals(firstTime)) {
                return i;
            }
        }
        return -1;
    }

    private String ConvertTime(INxFile file, boolean isBottomItem) {
        if (TextUtils.isEmpty(file.getLastModifiedTime())) {
            return "";
        }
        try {
            if (isBottomItem) {
                SimpleDateFormat sdBottom = new SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.US);
                return sdBottom.format(new Date(file.getLastModifiedTimeLong()));
            } else {
                SimpleDateFormat sdTitle = new SimpleDateFormat("MMMM yyyy", Locale.US);
                return sdTitle.format(new Date(file.getLastModifiedTimeLong()));
            }
        } catch (Exception e) {
            Log.e("NXFileAdapter", e.toString());
        }
        return "";
    }

    public interface OnInfoItemClicked {
        void onInfoItemClicked(INxFile nxfile, int position);
    }

    class ViewHolder {
        ImageView imageView;
        TextView fileName;
        TextView fileProperty;
        TextView indexName;
        LinearLayout linearLayout;
        ImageButton fileInfo;
    }

//    private class infoButtonListener implements View.OnClickListener {
//        private INxFile mFile;
//        public infoButtonListener(INxFile file){
//            mFile = file;
//        }
//        @Override
//        public void onClick(View v) {
//            // TODO Auto-generated method stub
//            Toast.makeText(mContext, mFile.getName(), Toast.LENGTH_SHORT).show();
//        }
//    }
}

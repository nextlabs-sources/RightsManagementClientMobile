package commonUtils.fileListUtils;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.io.File;
import java.util.List;

import appInstance.ViewerApp;
import nxl.types.INxFile;

/**
 * adapter for file list(recycler view)
 */
public class NXFileRecyclerViewAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private static final int NORMAL_ITEM = 0;
    private static final int GROUP_ITEM = 1;
    private static final int FOOTER_ITEM = 2;
    private OnItemClickListener mOnItemClickListener;
    private OnInfoItemClicked onInfoItemClicked;
    private Context mContext;
    private List<NXFileItem> mFileList;
    private LayoutInflater mLayoutInflater;

    private ViewerApp app;

    private String[] docFormat = {".docx", ".docm", ".doc", ".dotx", ".dotm", ".dot"};
    private String[] excelFormat = {".xlsx", ".xls", ".xlsb", ".xlsxltx", ".xltm", ".xlt", ".xlam"};
    private String[] pptFormat = {".pptx", ".pptm", ".ppt", ".potx", ".potm", ".pot", ".ppsm", ".pps", ".ppam", ".ppa"};

    public NXFileRecyclerViewAdapter(Context context, List<NXFileItem> objects) {
        mContext = context;
        mLayoutInflater = LayoutInflater.from(mContext);
        mFileList = objects;
        app = ViewerApp.getInstance();
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.mOnItemClickListener = listener;
    }

    public void setOnInfoItemClicked(OnInfoItemClicked listener) {
        this.onInfoItemClicked = listener;
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        if (viewType == NORMAL_ITEM) {
            return new NXFileRecyclerViewHolder(mLayoutInflater.inflate(R.layout.nxfile_recyclerview_normal_item, parent, false));
        } else if (viewType == GROUP_ITEM) {
            return new NXFileTitleViewHolder(mLayoutInflater.inflate(R.layout.nxfile_recyclerview_group_item, parent, false));
        } else if (viewType == FOOTER_ITEM) {
            return new NXFileFooterViewHolder(mLayoutInflater.inflate(R.layout.nxfile_recyclerview_footer, parent, false));
        }
        return null;
    }

    @Override
    public void onBindViewHolder(final RecyclerView.ViewHolder holder, final int position) {
        if (holder instanceof NXFileTitleViewHolder) {
            NXFileItem fileSrcItem = mFileList.get(position);
            bindGroupItem(fileSrcItem, (NXFileTitleViewHolder) holder, position);
        } else if (holder instanceof NXFileRecyclerViewHolder) {
            NXFileItem fileSrcItem = mFileList.get(position);
            bindNormalItem(fileSrcItem, (NXFileRecyclerViewHolder) holder, position);
        } else if (holder instanceof NXFileFooterViewHolder) {
            bindFooterItem(null, (NXFileFooterViewHolder) holder, position);
        }
    }

    @Override
    public int getItemCount() {
        return mFileList.size() + 1;
    }

    @Override
    public int getItemViewType(int position) {
        if (position == 0) {
            return GROUP_ITEM;
        } else if (isPositionFooter(position)) {
            return FOOTER_ITEM;
        } else {
            NXFileItem entity = mFileList.get(position);
            String currentTitle = entity.getTitle();
            int prevIndex = position - 1;
            boolean isDifferent = !mFileList.get(prevIndex).getTitle().equals(currentTitle);
            return isDifferent ? GROUP_ITEM : NORMAL_ITEM;
        }
    }

    private boolean isPositionFooter(int position) {
        return position == mFileList.size();
    }

    void bindNormalItem(NXFileItem entity, final NXFileRecyclerViewHolder holder, final int position) {
        INxFile fileItem = entity.getNXFile();
        long fileSize = fileItem.getSize();
        String tempFileName = fileItem.getName();
        holder.favoriteFlag.setVisibility(View.GONE);
        holder.offlineRefreshingFlag.setVisibility(View.GONE);
        holder.offlineLocalFlag.setVisibility(View.GONE);
        if (fileItem.isSite()) {
            holder.fileThumbnail.setImageResource(R.drawable.home_site_icon);
            tempFileName = fileItem.getName().substring(1);
        } else if (fileItem.isFolder()) {
            holder.fileThumbnail.setImageResource(R.drawable.home_folder_icon);
        } else {
            if (isNxFile(fileItem)) {
                holder.fileThumbnail.setImageResource(R.drawable.home_file_nx_icon);
            } else {
                String fileType = fileItem.getName().toLowerCase();
                if (fileType.endsWith("pdf")) {
                    holder.fileThumbnail.setImageResource(R.drawable.home_file_pdf_icon);
                } else if (isExists(fileType, OFFICETYPE.WORDDOC)) {
                    holder.fileThumbnail.setImageResource(R.drawable.home_file_word_icon);
                } else if (isExists(fileType, OFFICETYPE.EXCELDOC)) {
                    holder.fileThumbnail.setImageResource(R.drawable.home_file_excel_icon);
                } else if (isExists(fileType, OFFICETYPE.PPTDOC)) {
                    holder.fileThumbnail.setImageResource(R.drawable.home_file_ppt_icon);
                } else if (fileType.endsWith(".txt")) {
                    holder.fileThumbnail.setImageResource(R.drawable.home_file_txt_icon);
                } else {
                    holder.fileThumbnail.setImageResource(R.drawable.home_file_icon);
                }
            }
        }
        if (fileItem.isMarkedAsFavorite() && fileItem.isMarkedAsOffline()) {
            holder.favoriteFlag.setVisibility(View.VISIBLE);
            holder.offlineLocalFlag.setVisibility(View.VISIBLE);
        } else if (fileItem.isMarkedAsOffline()) {
            if (fileItem.isCached()) {
                holder.offlineLocalFlag.setVisibility(View.VISIBLE);
            } else {
                holder.offlineRefreshingFlag.setVisibility(View.VISIBLE);
            }
        } else if (fileItem.isMarkedAsFavorite()) {
            holder.favoriteFlag.setVisibility(View.VISIBLE);
        }
        fileSize = fileItem.getSize();

        //the string value is the temp value, because there is method in INxfile class.
        String time = FileUtils.ConvertTime(fileItem, true);
        if (fileItem.getService() != null) {
            if (fileItem.getSize() != 0) {
                //consider google driver specific file. The file has no file size.
                if (fileSize == -1) {
                    holder.subDetail.setText(fileItem.getService().alias + (time.isEmpty() ? "" : (", " + time)));
                } else {
                    holder.subDetail.setText(fileItem.getService().alias + ", " + FileUtils.transparentFileSize(fileSize) + (time.isEmpty() ? "" : (", " + time)));
                }

            } else {
                holder.subDetail.setText(fileItem.getService().alias + (time.isEmpty() ? "" : (", " + time)));
            }
        } else {

            holder.subDetail.setText("unknown service " + (time.isEmpty() ? "" : (", " + time)));
        }

        holder.mFileName.setText(tempFileName);

        if (mOnItemClickListener != null) {
            holder.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (mOnItemClickListener != null) {
                        mOnItemClickListener.onItemClick(holder.itemView, position);
                    }
                }
            });
        }

        holder.fileInfo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (onInfoItemClicked != null) {
                    onInfoItemClicked.onInfoItemClicked(position);
                }
            }
        });
    }

    void bindGroupItem(NXFileItem entity, NXFileTitleViewHolder holder, int position) {
        bindNormalItem(entity, holder, position);
        holder.mTitleName.setText(entity.getTitle());
        holder.mTitleName.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //nothing happen
            }
        });
    }

    void bindFooterItem(NXFileItem entity, RecyclerView.ViewHolder holder, int position) {

    }

    private boolean isNxFile(INxFile nxFile) {
        try {
            if (nxFile.isCached()) {
                File file = app.getFile(nxFile, null);
                return file != null && nxl.fileFormat.Utils.check(file.getPath(), true);
            } else {
                return nxFile.getName().toLowerCase().endsWith(".nxl");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public interface OnItemClickListener {
        void onItemClick(View view, int position);
    }

    public interface OnInfoItemClicked {
        void onInfoItemClicked(int position);
    }

    public class NXFileRecyclerViewHolder extends RecyclerView.ViewHolder {
        public TextView mFileName;
        public TextView subDetail;
        public ImageButton fileInfo;
        public ImageView fileThumbnail;
        public ImageView favoriteFlag;
        public ImageView offlineLocalFlag;
        public ImageView offlineRefreshingFlag;

        public NXFileRecyclerViewHolder(View itemView) {
            super(itemView);
            fileThumbnail = (ImageView) itemView.findViewById(R.id.nxfile_thumbnail);
            mFileName = (TextView) itemView.findViewById(R.id.nxfile_name);
            subDetail = (TextView) itemView.findViewById(R.id.nxfile_sub_detail);
            fileInfo = (ImageButton) itemView.findViewById(R.id.nxfile_detail);
            favoriteFlag = (ImageView) itemView.findViewById(R.id.nxfile_favorite_icon);
            offlineLocalFlag = (ImageView) itemView.findViewById(R.id.nxfile_offline_local_icon);
            offlineRefreshingFlag = (ImageView) itemView.findViewById(R.id.nxfile_offline_downloading_icon);
        }
    }

    public class NXFileTitleViewHolder extends NXFileRecyclerViewHolder {
        public TextView mTitleName;

        public NXFileTitleViewHolder(View itemView) {
            super(itemView);
            mTitleName = (TextView) itemView.findViewById(R.id.nxfile_title);
        }
    }

    public class NXFileFooterViewHolder extends RecyclerView.ViewHolder {
        public TextView mFooterView;

        public NXFileFooterViewHolder(View itemView) {
            super(itemView);
            mFooterView = (TextView) itemView.findViewById(R.id.nxfile_rv_footer);
        }
    }

    private boolean isExists(String dest, OFFICETYPE type) {
        String[] temp = null;
        switch (type) {
            case WORDDOC:
                temp = docFormat;
                break;
            case EXCELDOC:
                temp = excelFormat;
                break;
            case PPTDOC:
                temp = pptFormat;
                break;
        }
        if (temp != null) {
            for (String suffix : temp) {
                if (dest.endsWith(suffix)) {
                    return true;
                }
            }
        }
        return false;
    }

    public enum OFFICETYPE {
        WORDDOC(0),
        EXCELDOC(1),
        PPTDOC(2);

        private int value = 0;

        OFFICETYPE(int type) {
            value = type;
        }

        public static OFFICETYPE valueOf(int value) {
            switch (value) {
                case 0:
                    return WORDDOC;
                case 1:
                    return EXCELDOC;
                case 2:
                    return PPTDOC;
                default:
                    throw new IllegalArgumentException("value" + value + " is not a legal value to convert to OFFICETYPE");
            }
        }

        public int value() {
            return this.value;
        }
    }

}

package com.sapUtilityForVDSView;

import android.content.Context;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.nextlabs.viewer.R;
import com.sap.ve.SDVLImage;

import java.util.ArrayList;
import java.util.List;

/**
 * adapter for VDS thumbnail image.
 */
public class GalleryAdapter extends
        RecyclerView.Adapter<GalleryAdapter.ViewHolder> {

    private final ArrayList<Integer> selected = new ArrayList<>();
    private LayoutInflater m_inflater;
    private List<SDVLImage> m_datas;
    private OnItemClickListener mOnItemClickListener;

    public GalleryAdapter(Context context, List<SDVLImage> datats) {
        m_inflater = LayoutInflater.from(context);
        m_datas = datats;
    }

    public void setOnItemClickListener(OnItemClickListener mOnItemClickListener) {
        this.mOnItemClickListener = mOnItemClickListener;
    }

    @Override
    public int getItemCount() {
        return m_datas.size();
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup viewGroup, int i) {
        View view = m_inflater.inflate(R.layout.activity_index_gallery_item,
                viewGroup, false);
        ViewHolder viewHolder = new ViewHolder(view);

        viewHolder.mImg = (RecycleImageView) view
                .findViewById(R.id.id_index_gallery_item_image);
        return viewHolder;
    }

    @Override
    public void onBindViewHolder(final ViewHolder viewHolder, final int i) {
        final byte[] data = m_datas.get(i).data;
        viewHolder.mImg.setImageBitmap(BitmapFactory.decodeByteArray(data, 0, data.length));
        if (selected.contains(i)) {
            // view not selected
            viewHolder.mImg.setColor(Color.RED);
            viewHolder.mImg.setBorderWidth(10);
        } else {
            // view is selected
            viewHolder.mImg.setColor(Color.WHITE);
            viewHolder.mImg.setBorderWidth(0);
        }

        if (mOnItemClickListener != null) {
            viewHolder.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mOnItemClickListener.onItemClick(viewHolder.itemView, i);
                    viewHolder.mImg.setColor(Color.RED);
                    viewHolder.mImg.setBorderWidth(10);

                    if (selected.isEmpty()) {
                        selected.add(i);
                    } else {
                        int oldSelected = selected.get(0);
                        selected.clear();
                        selected.add(i);
                        // we do not notify that an item has been selected
                        // because that work is done here.  we instead send
                        // notifications for items to be deselected

                        notifyItemChanged(oldSelected);
                    }
                    notifyItemChanged(i);
                }
            });
        }
    }

    public interface OnItemClickListener {
        void onItemClick(View view, int position);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        RecycleImageView mImg;

        public ViewHolder(View arg0) {
            super(arg0);
        }
    }
}

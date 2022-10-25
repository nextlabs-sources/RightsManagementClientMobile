package com.imageableList;

import android.content.Context;
import android.support.v4.widget.SwipeRefreshLayout;
import android.util.AttributeSet;
import android.view.View;

/**
 * to fix android swipe refresh layout issue about multiple refresh
 */
public class NXSwipeRefreshLayout extends SwipeRefreshLayout {
    public NXSwipeRefreshLayout(Context context) {
        super(context);
    }

    public NXSwipeRefreshLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    public boolean onStartNestedScroll(View child, View target, int nestedScrollAxes) {
        return !isRefreshing() && super.onStartNestedScroll(child, target, nestedScrollAxes);
    }
}

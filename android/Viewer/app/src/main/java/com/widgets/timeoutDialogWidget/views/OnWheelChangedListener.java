package com.widgets.timeoutDialogWidget.views;

/**
 * Wheel changed listener interface
 * The onChanged() method is called wheneveer current wheel positions is changed:
 * New Wheel position is set
 * Wheel view is scrolled
 */
public interface OnWheelChangedListener {

    void onChanged(WheelView wheel, int oldValue, int newValue);
}

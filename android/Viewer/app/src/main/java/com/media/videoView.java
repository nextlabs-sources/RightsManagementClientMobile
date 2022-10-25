package com.media;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.media.MediaPlayer;
import android.net.Uri;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.OrientationEventListener;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.Toast;

import com.nextlabs.viewer.R;

import java.io.File;

import commonUtils.MediaControllerEx;
import commonUtils.VideoViewEx;

public class videoView {

    private static final String TAG = "videoView";
    private VideoViewEx mVideoView;
    private MediaControllerEx mMediaController;
    private View mView;
    private ImageView mSwitchScreenButton;
    private int mScreenWidth;
    private int mScreenHeight;

    private Activity mActivity;
    private OrientationEventListener mOrientationListener;
    // whether is landscape or not
    private boolean mIsLand = false;
    // whether is click switch screen button
    private boolean mClickSwitch = false;
    // whether click and switch into landscape
    private boolean mClickLand = true;
    // whether click and switch into portrait
    private boolean mClickPort = true;

    public videoView(Activity activity) {
        mActivity = activity;
    }

    public void init() {

        DisplayMetrics dm = new DisplayMetrics();
        mActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
        mScreenWidth = dm.widthPixels;
        mScreenHeight = dm.heightPixels;

        mView = mActivity.getLayoutInflater().inflate(R.layout.activity_video, null);
        mVideoView = (VideoViewEx) mView.findViewById(R.id.video);
        mMediaController = new MediaControllerEx(mActivity);
        startListener();

        mVideoView.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mp) {

                mSwitchScreenButton = mMediaController.getImageView();

                if (mScreenHeight > mScreenWidth) {
                    mSwitchScreenButton.setImageResource(R.drawable.spread_32);
                    mIsLand = false;
                    portraitDisplay();
                } else {
                    mSwitchScreenButton.setImageResource(R.drawable.shrink_32);
                    mIsLand = true;
                    landscapeDisplay();
                }


                mSwitchScreenButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        mClickSwitch = true;
                        if (!mIsLand) { // switch to landscape
                            mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
                            mSwitchScreenButton.setImageResource(R.drawable.shrink_32);
                            landscapeDisplay();
                            mIsLand = true;
                            mClickLand = false;
                        } else {  // switch to portrait
                            mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
                            mSwitchScreenButton.setImageResource(R.drawable.spread_32);
                            portraitDisplay();
                            mIsLand = false;
                            mClickPort = false;
                        }
                    }
                });

            }
        });

        mVideoView.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
                Toast.makeText(mActivity, "player completion", Toast.LENGTH_SHORT).show();
            }
        });

        mVideoView.setOnErrorListener(new MediaPlayer.OnErrorListener() {
            @Override
            public boolean onError(MediaPlayer mp, int what, int extra) {
                Log.i(TAG, "error for playing video !");
                return false;
            }
        });

    }

    /**
     * start listen automatic screen rotate
     */
    private final void startListener() {
        mOrientationListener = new OrientationEventListener(mActivity) {
            @Override
            public void onOrientationChanged(int rotation) {
                // set portrait
                if (((rotation >= 0) && (rotation <= 30)) || (rotation >= 330)) {
                    if (mClickSwitch) {
                        if (mIsLand && !mClickLand) {
                            return;
                        } else {
                            mClickPort = true;
                            mClickSwitch = false;
                            mIsLand = false;
                        }
                    } else {
                        if (mIsLand) {
                            mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
                            mIsLand = false;
                            mClickSwitch = false;
                        }
                    }
                } else if (((rotation >= 230) && (rotation <= 310))) {   // set landscape
                    if (mClickSwitch) {
                        if (!mIsLand && !mClickPort) {
                            return;
                        } else {
                            mClickLand = true;
                            mClickSwitch = false;
                            mIsLand = true;
                        }
                    } else {
                        if (!mIsLand) {
                            mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
                            mIsLand = true;
                            mClickSwitch = false;
                        }
                    }
                }
            }
        };
        mOrientationListener.enable();
    }

    // full screen mode (landscape view)
    public void landscapeDisplay() {
        DisplayMetrics dm = new DisplayMetrics();
        mActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
        mScreenWidth = dm.widthPixels;
        mScreenHeight = dm.heightPixels;

        FrameLayout.LayoutParams lp_mc = new FrameLayout.LayoutParams(mScreenWidth, RelativeLayout.LayoutParams.WRAP_CONTENT);
        lp_mc.setMargins(0, 0, 0, 0);
        mMediaController.setLayoutParams(lp_mc);

        RelativeLayout.LayoutParams layoutParams =
                new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        mVideoView.setLayoutParams(layoutParams);
    }

    // window mode (portrait window view)
    public void portraitDisplay() {
        DisplayMetrics dm = new DisplayMetrics();
        mActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
        mScreenWidth = dm.widthPixels;
        mScreenHeight = dm.heightPixels;

        RelativeLayout.LayoutParams lp = new RelativeLayout.LayoutParams(mScreenWidth, mScreenHeight / 2);
        lp.setMargins(0, mScreenHeight / 4, 0, mScreenHeight / 4);
        mVideoView.setLayoutParams(lp);

        FrameLayout.LayoutParams lp_mc = new FrameLayout.LayoutParams(mScreenWidth, RelativeLayout.LayoutParams.WRAP_CONTENT);
        lp_mc.setMargins(0, 0, 0, mScreenHeight / 4);
        mMediaController.setLayoutParams(lp_mc);
    }

    public View getVideoView() {
        return mView;
    }

    public ImageView getSwitchScreenButton() {
        return mSwitchScreenButton;
    }

    public void StartPlayVideo(String path) {
        if (!path.isEmpty()) {
            mVideoView.setVideoPath(path);
            mVideoView.setMediaController(mMediaController);
            mVideoView.requestFocus();
            mVideoView.start();
        }
    }

    public void StartPlayVideo(File document) {
        if (document != null) {
            mVideoView.setVideoURI(Uri.fromFile(document));
            mVideoView.setMediaController(mMediaController);
            mVideoView.requestFocus();
            mVideoView.start();
        }
    }

    public void pausePlayVideo() {
        if (mVideoView != null && mVideoView.isPlaying()) {
            mVideoView.pause();
        }
    }

    private void resetVideo() {
        if (mVideoView != null) {
            mVideoView.seekTo(0);
        }
    }

}

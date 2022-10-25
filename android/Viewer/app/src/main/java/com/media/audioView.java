package com.media;

import android.app.Activity;
import android.media.MediaPlayer;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.widget.Chronometer;
import android.widget.ImageView;
import android.widget.SeekBar;
import android.widget.TextView;

import com.nextlabs.viewer.R;

import java.io.IOException;

public class audioView implements Chronometer.OnChronometerTickListener {

    private static final String TAG = "audioView";
    private static final int UPDATE_FREQUENCY = 500;
    private static final int STEP_VALUE = 4000;
    private final Handler handler = new Handler();
    private TextView selelctedFile = null;
    private SeekBar seekbar = null;
    private MediaPlayer player = null;
    private final Runnable updatePositionRunnable = new Runnable() {
        public void run() {
            updatePosition();
        }
    };
    private ImageView playButton = null;
    private ImageView prevButton = null;
    private ImageView nextButton = null;
    private boolean isStarted = true;
    private String currentFile = "";
    private boolean isMoveingSeekBar = false;
    private View mView;
    private Activity mActivity;
    private View.OnClickListener onButtonClick = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.play: {
                    if (player.isPlaying()) {
                        // pause
                        handler.removeCallbacks(updatePositionRunnable);
                        player.pause();
                        playButton.setImageResource(R.drawable.play_32);

                    } else {
                        // start play.
                        if (isStarted) {
                            player.start();
                            playButton.setImageResource(R.drawable.pause_32);

                            updatePosition();
                        } else {
                            startPlay(currentFile);
                        }

                    }

                    break;
                }
                case R.id.next: {
                    int seekto = player.getCurrentPosition() + STEP_VALUE;

                    if (seekto > player.getDuration())
                        seekto = player.getDuration();

                    player.pause();
                    player.seekTo(seekto);
                    player.start();

                    break;
                }
                case R.id.prev: {
                    int seekto = player.getCurrentPosition() - STEP_VALUE;

                    if (seekto < 0)
                        seekto = 0;

                    player.pause();
                    player.seekTo(seekto);
                    player.start();

                    break;
                }
            }
        }
    };
    private MediaPlayer.OnCompletionListener onCompletion = new MediaPlayer.OnCompletionListener() {

        @Override
        public void onCompletion(MediaPlayer mp) {
            stopPlay();
        }
    };
    private MediaPlayer.OnErrorListener onError = new MediaPlayer.OnErrorListener() {

        @Override
        public boolean onError(MediaPlayer mp, int what, int extra) {
            Log.i(TAG, "error for playing audio!");
            return false;
        }
    };
    private SeekBar.OnSeekBarChangeListener seekBarChanged = new SeekBar.OnSeekBarChangeListener() {
        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
            isMoveingSeekBar = false;
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
            isMoveingSeekBar = true;
        }

        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if (isMoveingSeekBar) {
                player.seekTo(progress);
                Log.i("OnSeekBarChangeListener", "onProgressChanged");
            }
        }
    };

    public audioView(Activity activity) {
        mActivity = activity;
    }

    public void init() {

        mView = mActivity.getLayoutInflater().inflate(R.layout.activity_audio, null);
        selelctedFile = (TextView) mView.findViewById(R.id.selectedfile);
        seekbar = (SeekBar) mView.findViewById(R.id.seekbar);
        playButton = (ImageView) mView.findViewById(R.id.play);
        prevButton = (ImageView) mView.findViewById(R.id.prev);
        nextButton = (ImageView) mView.findViewById(R.id.next);

        player = new MediaPlayer();

        player.setOnCompletionListener(onCompletion);
        player.setOnErrorListener(onError);
        seekbar.setOnSeekBarChangeListener(seekBarChanged);

        playButton.setOnClickListener(onButtonClick);
        nextButton.setOnClickListener(onButtonClick);
        prevButton.setOnClickListener(onButtonClick);

    }

    @Override
    public void onChronometerTick(Chronometer chronometer) {

    }

    public View getVideoView() {
        return mView;
    }

    public MediaPlayer getAudioPlayer() {
        return player;
    }

    public void startPlay(String file) {

        selelctedFile.setText(file.substring(file.lastIndexOf("/") + 1));
        seekbar.setProgress(0);

        player.stop();
        player.reset();

        try {
            player.setDataSource(file);
            player.prepare();
            player.start();
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
        } catch (IllegalStateException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

        seekbar.setMax(player.getDuration());
        playButton.setImageResource(R.drawable.pause_32);

        updatePosition();

        isStarted = true;
    }

    public void stopPlay() {
        player.stop();
        player.reset();
        playButton.setImageResource(R.drawable.play_32);
        handler.removeCallbacks(updatePositionRunnable);
        seekbar.setProgress(0);

        isStarted = false;
    }

    public void pause() {
        if (player != null && player.isPlaying()) {
            player.pause();
            playButton.setImageResource(R.drawable.play_32);
        }
    }

    private void updatePosition() {
        handler.removeCallbacks(updatePositionRunnable);

        seekbar.setProgress(player.getCurrentPosition());

        handler.postDelayed(updatePositionRunnable, UPDATE_FREQUENCY);
    }

}

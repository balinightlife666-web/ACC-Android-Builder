package com.arda.musicplayer;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Binder;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.PowerManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.Set;

public class PlaybackService extends Service {
    public static final String ACTION_PLAY_PAUSE = "com.arda.musicplayer.PLAY_PAUSE";
    public static final String ACTION_NEXT = "com.arda.musicplayer.NEXT";
    public static final String ACTION_PREVIOUS = "com.arda.musicplayer.PREVIOUS";

    private static final String CHANNEL_ID = "arda_music_playback";
    private static final int NOTIFICATION_ID = 4107;
    private static final String PREFS = "arda_music_player";
    private static final String PREF_PLAYLIST = "playlist";
    private static final String PREF_AUTOMIX = "automix";
    private static final String PREF_MIX_SECONDS = "mix_seconds";

    public final class LocalBinder extends Binder {
        public PlaybackService getService() {
            return PlaybackService.this;
        }
    }

    private final IBinder binder = new LocalBinder();
    private final ArrayList<Track> playlist = new ArrayList<>();
    private final Handler handler = new Handler(Looper.getMainLooper());

    private MediaPlayer activePlayer;
    private MediaPlayer nextPlayer;
    private boolean activePrepared;
    private boolean nextPrepared;
    private boolean playing;
    private boolean crossing;
    private boolean autoMix = true;
    private boolean foreground;
    private int currentIndex = -1;
    private int mixSeconds = 8;
    private int generation;
    private int crossfadeWindowMs;
    private float crossfadeProgress;
    private float outputGain = 1f;
    private AudioManager audioManager;
    private AudioFocusRequest audioFocusRequest;

    private final BroadcastReceiver noisyReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction())) pause();
        }
    };

    private final Runnable ticker = new Runnable() {
        @Override
        public void run() {
            tickMixEngine();
            handler.postDelayed(this, 50L);
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
        createNotificationChannel();
        loadState();
        IntentFilter filter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(noisyReceiver, filter, RECEIVER_NOT_EXPORTED);
        else registerReceiver(noisyReceiver, filter);
        handler.post(ticker);
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && intent.getAction() != null) {
            switch (intent.getAction()) {
                case ACTION_PLAY_PAUSE:
                    playPause();
                    break;
                case ACTION_NEXT:
                    next();
                    break;
                case ACTION_PREVIOUS:
                    previous();
                    break;
                default:
                    break;
            }
        }
        return START_STICKY;
    }

    public synchronized ArrayList<Track> getPlaylist() {
        return new ArrayList<>(playlist);
    }

    public synchronized void addTracks(ArrayList<Track> tracks) {
        Set<String> known = new LinkedHashSet<>();
        for (Track track : playlist) known.add(track.uri);
        for (Track track : tracks) {
            if (track != null && track.uri != null && known.add(track.uri)) playlist.add(track);
        }
        persistState();
    }

    public synchronized void clearPlaylist() {
        stopPlayback(true);
        playlist.clear();
        currentIndex = -1;
        persistState();
    }

    public synchronized void setAutoMix(boolean enabled) {
        autoMix = enabled;
        if (!enabled && crossing) abortCrossfade();
        persistState();
        updateNotification();
    }

    public synchronized void setMixSeconds(int seconds) {
        mixSeconds = Math.max(4, Math.min(20, seconds));
        persistState();
    }

    public synchronized void playPause() {
        if (playlist.isEmpty()) return;
        if (playing) {
            pause();
            return;
        }
        if (activePrepared && activePlayer != null) {
            if (!requestAudioFocus()) return;
            setOutputGain(1f);
            activePlayer.start();
            playing = true;
            ensureForeground();
            updateNotification();
        } else {
            playIndex(currentIndex >= 0 && currentIndex < playlist.size() ? currentIndex : 0);
        }
    }

    public synchronized void playIndex(int index) {
        if (index < 0 || index >= playlist.size()) return;
        if (!requestAudioFocus()) return;
        outputGain = 1f;
        generation++;
        releasePlayers();
        currentIndex = index;
        playing = false;
        activePrepared = false;
        crossing = false;
        final int expectedGeneration = generation;
        final MediaPlayer player;
        try {
            player = buildPlayer(playlist.get(index));
        } catch (RuntimeException unreadableTrack) {
            if (index + 1 < playlist.size()) playIndex(index + 1);
            else stopPlayback(false);
            return;
        }
        activePlayer = player;
        player.setOnPreparedListener(mp -> {
            synchronized (PlaybackService.this) {
                if (activePlayer != mp || generation != expectedGeneration) {
                    safeRelease(mp);
                    return;
                }
                activePrepared = true;
                mp.setVolume(outputGain, outputGain);
                mp.start();
                playing = true;
                ensureForeground();
                prepareNext();
                updateNotification();
            }
        });
        player.setOnCompletionListener(mp -> handleActiveCompletion(mp));
        player.setOnErrorListener((mp, what, extra) -> {
            synchronized (PlaybackService.this) {
                if (mp == activePlayer) advanceOrFinish();
            }
            return true;
        });
        player.prepareAsync();
    }

    public synchronized void next() {
        if (playlist.isEmpty()) return;
        int target = currentIndex < 0 ? 0 : currentIndex + 1;
        if (target < playlist.size()) playIndex(target);
    }

    public synchronized void previous() {
        if (activePrepared && activePlayer != null && safePosition(activePlayer) > 4000) {
            activePlayer.seekTo(0);
            return;
        }
        int target = currentIndex <= 0 ? 0 : currentIndex - 1;
        playIndex(target);
    }

    public synchronized void seekTo(int positionMs) {
        if (activePrepared && activePlayer != null) {
            if (crossing) abortCrossfade();
            int duration = safeDuration(activePlayer);
            activePlayer.seekTo(Math.max(0, Math.min(positionMs, duration)));
        }
    }

    public synchronized Bundle getSnapshot() {
        Bundle state = new Bundle();
        state.putInt("count", playlist.size());
        state.putInt("index", currentIndex);
        state.putBoolean("playing", playing);
        state.putBoolean("automix", autoMix);
        state.putBoolean("crossing", crossing);
        state.putBoolean("nextReady", nextPrepared);
        state.putInt("mixSeconds", mixSeconds);
        state.putFloat("mixProgress", crossfadeProgress);
        state.putInt("position", activePrepared && activePlayer != null ? safePosition(activePlayer) : 0);
        state.putInt("duration", activePrepared && activePlayer != null ? safeDuration(activePlayer) : 0);
        state.putString("title", currentIndex >= 0 && currentIndex < playlist.size()
                ? playlist.get(currentIndex).title : "No track selected");
        state.putString("nextTitle", currentIndex + 1 >= 0 && currentIndex + 1 < playlist.size()
                ? playlist.get(currentIndex + 1).title : "End of queue");
        return state;
    }

    private MediaPlayer buildPlayer(Track track) {
        MediaPlayer player = new MediaPlayer();
        player.setAudioAttributes(new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build());
        player.setWakeMode(getApplicationContext(), PowerManager.PARTIAL_WAKE_LOCK);
        try {
            player.setDataSource(getApplicationContext(), Uri.parse(track.uri));
        } catch (Exception error) {
            safeRelease(player);
            throw new IllegalStateException("Track cannot be opened: " + track.title, error);
        }
        return player;
    }

    private synchronized void prepareNext() {
        releaseNextPlayer();
        int nextIndex = currentIndex + 1;
        if (nextIndex < 0 || nextIndex >= playlist.size()) return;
        final int expectedGeneration = generation;
        final MediaPlayer player;
        try {
            player = buildPlayer(playlist.get(nextIndex));
        } catch (RuntimeException ignored) {
            return;
        }
        nextPlayer = player;
        nextPrepared = false;
        player.setVolume(0f, 0f);
        player.setOnPreparedListener(mp -> {
            synchronized (PlaybackService.this) {
                if (nextPlayer != mp || generation != expectedGeneration) {
                    safeRelease(mp);
                    return;
                }
                nextPrepared = true;
                updateNotification();
            }
        });
        player.setOnErrorListener((mp, what, extra) -> {
            synchronized (PlaybackService.this) {
                if (mp == nextPlayer) releaseNextPlayer();
            }
            return true;
        });
        player.prepareAsync();
    }

    private synchronized void tickMixEngine() {
        if (!playing || !autoMix || !activePrepared || activePlayer == null) return;
        int duration = safeDuration(activePlayer);
        int position = safePosition(activePlayer);
        int remaining = Math.max(0, duration - position);
        if (!crossing) {
            int mixMs = mixSeconds * 1000;
            if (duration > mixMs + 1000 && remaining <= mixMs && nextPrepared && nextPlayer != null) {
                try {
                    crossfadeWindowMs = Math.max(1000, Math.min(mixMs, remaining));
                    crossfadeProgress = 0f;
                    nextPlayer.setVolume(0f, 0f);
                    nextPlayer.start();
                    crossing = true;
                    updateNotification();
                } catch (IllegalStateException startFailed) {
                    releaseNextPlayer();
                    prepareNext();
                }
            }
        }
        if (crossing && nextPlayer != null) {
            // Anchor the fade to the outgoing deck's real playback position. A wall-clock
            // timer can drift from MediaPlayer startup on slower phones and causes a late
            // incoming deck or a sudden volume jump at the end of the song.
            float progress = 1f - (remaining / (float) Math.max(1, crossfadeWindowMs));
            applyCrossfadeProgress(progress);
            if (crossfadeProgress >= 1f) finishCrossfade();
        }
    }

    private void applyCrossfadeProgress(float requestedProgress) {
        float progress = Math.max(crossfadeProgress, Math.max(0f, Math.min(1f, requestedProgress)));
        crossfadeProgress = progress;
        float outgoing = (float) Math.cos(progress * Math.PI / 2f) * outputGain;
        float incoming = (float) Math.sin(progress * Math.PI / 2f) * outputGain;
        if (activePlayer != null) activePlayer.setVolume(outgoing, outgoing);
        if (nextPlayer != null) nextPlayer.setVolume(incoming, incoming);
    }

    private synchronized void handleActiveCompletion(MediaPlayer completed) {
        if (completed != activePlayer) return;
        if (crossing && nextPlayer != null) {
            applyCrossfadeProgress(1f);
            finishCrossfade();
        }
        else advanceOrFinish();
    }

    private synchronized void finishCrossfade() {
        if (!crossing || nextPlayer == null) return;
        MediaPlayer old = activePlayer;
        if (old != null) old.setOnCompletionListener(null);
        safeRelease(old);
        activePlayer = nextPlayer;
        activePrepared = true;
        nextPlayer = null;
        nextPrepared = false;
        crossing = false;
        crossfadeProgress = 0f;
        currentIndex++;
        activePlayer.setVolume(outputGain, outputGain);
        activePlayer.setOnCompletionListener(this::handleActiveCompletion);
        activePlayer.setOnErrorListener((mp, what, extra) -> {
            synchronized (PlaybackService.this) {
                if (mp == activePlayer) advanceOrFinish();
            }
            return true;
        });
        playing = activePlayer.isPlaying();
        prepareNext();
        updateNotification();
    }

    private synchronized void abortCrossfade() {
        crossing = false;
        crossfadeProgress = 0f;
        releaseNextPlayer();
        if (activePlayer != null) activePlayer.setVolume(outputGain, outputGain);
        prepareNext();
    }

    private synchronized void advanceOrFinish() {
        int target = currentIndex + 1;
        if (target >= playlist.size()) {
            stopPlayback(false);
            return;
        }
        if (nextPrepared && nextPlayer != null) {
            MediaPlayer old = activePlayer;
            safeRelease(old);
            activePlayer = nextPlayer;
            activePrepared = true;
            nextPlayer = null;
            nextPrepared = false;
            currentIndex = target;
            crossfadeProgress = 0f;
            activePlayer.setVolume(outputGain, outputGain);
            activePlayer.setOnCompletionListener(this::handleActiveCompletion);
            activePlayer.setOnErrorListener((mp, what, extra) -> {
                synchronized (PlaybackService.this) {
                    if (mp == activePlayer) advanceOrFinish();
                }
                return true;
            });
            try {
                activePlayer.start();
                playing = true;
                prepareNext();
                updateNotification();
                return;
            } catch (IllegalStateException ignored) {
                releasePlayers();
            }
        }
        playIndex(target);
    }

    private synchronized void pause() {
        if (crossing) abortCrossfade();
        if (activePrepared && activePlayer != null && activePlayer.isPlaying()) activePlayer.pause();
        playing = false;
        abandonAudioFocus();
        updateNotification();
    }

    private synchronized void stopPlayback(boolean resetIndex) {
        generation++;
        playing = false;
        crossing = false;
        crossfadeProgress = 0f;
        releasePlayers();
        if (resetIndex) currentIndex = -1;
        abandonAudioFocus();
        if (foreground) {
            stopForeground(true);
            foreground = false;
        }
    }

    private void releasePlayers() {
        safeRelease(activePlayer);
        activePlayer = null;
        activePrepared = false;
        releaseNextPlayer();
    }

    private void releaseNextPlayer() {
        safeRelease(nextPlayer);
        nextPlayer = null;
        nextPrepared = false;
    }

    private void safeRelease(MediaPlayer player) {
        if (player == null) return;
        try {
            player.setOnPreparedListener(null);
            player.setOnCompletionListener(null);
            player.setOnErrorListener(null);
            player.release();
        } catch (Exception ignored) {
        }
    }

    private int safePosition(MediaPlayer player) {
        try {
            return player.getCurrentPosition();
        } catch (Exception ignored) {
            return 0;
        }
    }

    private int safeDuration(MediaPlayer player) {
        try {
            return Math.max(0, player.getDuration());
        } catch (Exception ignored) {
            return 0;
        }
    }

    private boolean requestAudioFocus() {
        if (audioManager == null) return true;
        AudioManager.OnAudioFocusChangeListener listener = change -> {
            if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                pause();
            } else if (change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) {
                setOutputGain(0.25f);
            } else if (change == AudioManager.AUDIOFOCUS_GAIN) {
                setOutputGain(1f);
            }
        };
        audioFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build())
                .setOnAudioFocusChangeListener(listener)
                .build();
        return audioManager.requestAudioFocus(audioFocusRequest) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
    }

    private synchronized void setOutputGain(float gain) {
        outputGain = Math.max(0f, Math.min(1f, gain));
        if (crossing) {
            float progress = crossfadeProgress;
            crossfadeProgress = 0f;
            applyCrossfadeProgress(progress);
        } else if (activePlayer != null) {
            activePlayer.setVolume(outputGain, outputGain);
        }
    }

    private void abandonAudioFocus() {
        if (audioManager != null && audioFocusRequest != null) {
            audioManager.abandonAudioFocusRequest(audioFocusRequest);
        }
    }

    private void createNotificationChannel() {
        NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel),
                NotificationManager.IMPORTANCE_LOW
        );
        channel.setDescription(getString(R.string.notification_channel_description));
        channel.setSound(null, null);
        manager.createNotificationChannel(channel);
    }

    private Notification buildNotification() {
        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent open = PendingIntent.getActivity(this, 10, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        PendingIntent previous = servicePendingIntent(ACTION_PREVIOUS, 11);
        PendingIntent toggle = servicePendingIntent(ACTION_PLAY_PAUSE, 12);
        PendingIntent next = servicePendingIntent(ACTION_NEXT, 13);
        String title = currentIndex >= 0 && currentIndex < playlist.size()
                ? playlist.get(currentIndex).title : "ARDA MUSIC PLAYER";
        String mode = autoMix ? "AutoMix " + mixSeconds + "s · Order locked" : "Normal · Order locked";
        return new Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_music_note)
                .setContentTitle(title)
                .setContentText(mode)
                .setContentIntent(open)
                .setOngoing(playing)
                .setOnlyAlertOnce(true)
                .addAction(new Notification.Action.Builder(null, "Previous", previous).build())
                .addAction(new Notification.Action.Builder(null, playing ? "Pause" : "Play", toggle).build())
                .addAction(new Notification.Action.Builder(null, "Next", next).build())
                .setStyle(new Notification.MediaStyle().setShowActionsInCompactView(0, 1, 2))
                .build();
    }

    private PendingIntent servicePendingIntent(String action, int requestCode) {
        Intent intent = new Intent(this, PlaybackService.class).setAction(action);
        return PendingIntent.getService(this, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    private void ensureForeground() {
        Notification notification = buildNotification();
        if (!foreground) {
            startForeground(NOTIFICATION_ID, notification);
            foreground = true;
        } else {
            ((NotificationManager) getSystemService(NOTIFICATION_SERVICE)).notify(NOTIFICATION_ID, notification);
        }
    }

    private void updateNotification() {
        if (foreground) {
            ((NotificationManager) getSystemService(NOTIFICATION_SERVICE))
                    .notify(NOTIFICATION_ID, buildNotification());
        }
    }

    private void loadState() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        autoMix = prefs.getBoolean(PREF_AUTOMIX, true);
        mixSeconds = prefs.getInt(PREF_MIX_SECONDS, 8);
        String raw = prefs.getString(PREF_PLAYLIST, "[]");
        try {
            JSONArray items = new JSONArray(raw);
            for (int i = 0; i < items.length(); i++) {
                JSONObject item = items.getJSONObject(i);
                playlist.add(new Track(item.getString("uri"), item.optString("title", "Unknown track")));
            }
        } catch (Exception ignored) {
            playlist.clear();
        }
    }

    private void persistState() {
        JSONArray items = new JSONArray();
        try {
            for (Track track : playlist) {
                JSONObject item = new JSONObject();
                item.put("uri", track.uri);
                item.put("title", track.title);
                items.put(item);
            }
        } catch (Exception ignored) {
        }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
                .putString(PREF_PLAYLIST, items.toString())
                .putBoolean(PREF_AUTOMIX, autoMix)
                .putInt(PREF_MIX_SECONDS, mixSeconds)
                .apply();
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        try {
            unregisterReceiver(noisyReceiver);
        } catch (Exception ignored) {
        }
        stopPlayback(false);
        super.onDestroy();
    }
}

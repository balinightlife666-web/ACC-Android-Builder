package com.arda.musicplayer;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.provider.DocumentsContract;
import android.provider.OpenableColumns;
import android.text.InputType;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MainActivity extends Activity {
    private static final int REQUEST_FILES = 1101;
    private static final int REQUEST_FOLDER = 1102;
    private static final int REQUEST_NOTIFICATIONS = 1103;
    private static final String LINK_PREFS = "arda_playlist_reference";
    private static final String LINK_KEY = "playlist_url";
    private static final Pattern URL_PATTERN = Pattern.compile("https?://\\S+", Pattern.CASE_INSENSITIVE);

    private final Handler uiHandler = new Handler(Looper.getMainLooper());
    private PlaybackService playbackService;
    private boolean serviceBound;
    private boolean touchingPosition;
    private int renderedIndex = Integer.MIN_VALUE;
    private int renderedCount = Integer.MIN_VALUE;

    private TextView nowTitle;
    private TextView nowSubtitle;
    private TextView timeCurrent;
    private TextView timeTotal;
    private TextView mixValue;
    private TextView queueTitle;
    private TextView orderBadge;
    private TextView playlistLinkStatus;
    private TextView syncStatus;
    private TextView nextUpTitle;
    private TextView transitionStatus;
    private TextView modeHint;
    private Button modeNormal;
    private Button modeAutoMix;
    private Button playPause;
    private SeekBar positionSeek;
    private SeekBar mixSeek;
    private ListView queueList;
    private QueueAdapter queueAdapter;

    private final ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder binder) {
            playbackService = ((PlaybackService.LocalBinder) binder).getService();
            serviceBound = true;
            refreshQueue();
            renderState();
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            serviceBound = false;
            playbackService = null;
        }
    };

    private final Runnable uiTicker = new Runnable() {
        @Override
        public void run() {
            renderState();
            uiHandler.postDelayed(this, 400L);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        bindViews();
        bindActions();
        renderPlaylistLink();
        handleSharedPlaylistLink(getIntent());
        requestNotificationPermission();

        Intent serviceIntent = new Intent(this, PlaybackService.class);
        startService(serviceIntent);
        bindService(serviceIntent, connection, Context.BIND_AUTO_CREATE);
        uiHandler.post(uiTicker);
    }

    private void bindViews() {
        nowTitle = findViewById(R.id.nowTitle);
        nowSubtitle = findViewById(R.id.nowSubtitle);
        timeCurrent = findViewById(R.id.timeCurrent);
        timeTotal = findViewById(R.id.timeTotal);
        mixValue = findViewById(R.id.mixValue);
        queueTitle = findViewById(R.id.queueTitle);
        orderBadge = findViewById(R.id.orderBadge);
        playlistLinkStatus = findViewById(R.id.playlistLinkStatus);
        syncStatus = findViewById(R.id.syncStatus);
        nextUpTitle = findViewById(R.id.nextUpTitle);
        transitionStatus = findViewById(R.id.transitionStatus);
        modeHint = findViewById(R.id.modeHint);
        modeNormal = findViewById(R.id.modeNormal);
        modeAutoMix = findViewById(R.id.modeAutoMix);
        playPause = findViewById(R.id.playPause);
        positionSeek = findViewById(R.id.positionSeek);
        mixSeek = findViewById(R.id.mixSeek);
        queueList = findViewById(R.id.queueList);
        queueAdapter = new QueueAdapter(this);
        queueList.setAdapter(queueAdapter);
    }

    private void bindActions() {
        findViewById(R.id.addFiles).setOnClickListener(view -> openFilePicker());
        findViewById(R.id.addFolder).setOnClickListener(view -> openFolderPicker());
        playlistLinkStatus.setOnClickListener(view -> showPlaylistLinkDialog(null));
        findViewById(R.id.clearQueue).setOnClickListener(view -> confirmClearQueue());
        findViewById(R.id.previous).setOnClickListener(view -> {
            if (serviceBound) playbackService.previous();
        });
        findViewById(R.id.next).setOnClickListener(view -> {
            if (serviceBound) playbackService.next();
        });
        playPause.setOnClickListener(view -> {
            if (serviceBound) playbackService.playPause();
        });
        modeNormal.setOnClickListener(view -> {
            if (serviceBound) playbackService.setAutoMix(false);
            renderState();
        });
        modeAutoMix.setOnClickListener(view -> {
            if (serviceBound) playbackService.setAutoMix(true);
            renderState();
        });
        queueList.setOnItemClickListener((parent, view, position, id) -> {
            if (serviceBound) playbackService.playIndex(position);
        });

        mixSeek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                int seconds = progress + 4;
                mixValue.setText(seconds + " SEC");
                if (fromUser && serviceBound) playbackService.setMixSeconds(seconds);
            }

            @Override public void onStartTrackingTouch(SeekBar seekBar) { }
            @Override public void onStopTrackingTouch(SeekBar seekBar) { }
        });

        positionSeek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && serviceBound) {
                    Bundle state = playbackService.getSnapshot();
                    int duration = state.getInt("duration");
                    int target = (int) (duration * (progress / 1000f));
                    timeCurrent.setText(formatTime(target));
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                touchingPosition = true;
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                if (serviceBound) {
                    Bundle state = playbackService.getSnapshot();
                    int duration = state.getInt("duration");
                    playbackService.seekTo((int) (duration * (seekBar.getProgress() / 1000f)));
                }
                touchingPosition = false;
            }
        });
    }

    private void showPlaylistLinkDialog(String incomingLink) {
        SharedPreferences preferences = getSharedPreferences(LINK_PREFS, MODE_PRIVATE);
        String savedLink = preferences.getString(LINK_KEY, "");
        String initialLink = incomingLink;
        if (initialLink == null || initialLink.trim().isEmpty()) initialLink = savedLink;
        if (initialLink == null || initialLink.trim().isEmpty()) initialLink = supportedLinkFromClipboard();

        EditText input = new EditText(this);
        input.setHint("Paste Spotify / YouTube playlist link");
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        input.setSingleLine(false);
        input.setMaxLines(3);
        input.setText(initialLink == null ? "" : initialLink);
        input.setSelectAllOnFocus(true);

        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle(savedLink.isEmpty() ? "Save playlist link" : "Edit playlist link")
                .setMessage("This saves the original playlist reference. AutoMix plays the local audio files you add below.")
                .setView(input)
                .setNegativeButton("Cancel", null)
                .setPositiveButton("Save", null);
        if (!savedLink.isEmpty()) builder.setNeutralButton("Remove", null);

        AlertDialog dialog = builder.create();
        dialog.setOnShowListener(ignored -> {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(view -> {
                String candidate = extractFirstUrl(input.getText().toString());
                if (!isSupportedPlaylistUrl(candidate)) {
                    input.setError("Use a Spotify or YouTube playlist link");
                    return;
                }
                preferences.edit().putString(LINK_KEY, candidate).apply();
                renderPlaylistLink();
                Toast.makeText(this, "Playlist link saved", Toast.LENGTH_SHORT).show();
                dialog.dismiss();
            });
            if (!savedLink.isEmpty()) {
                dialog.getButton(AlertDialog.BUTTON_NEUTRAL).setOnClickListener(view -> {
                    preferences.edit().remove(LINK_KEY).apply();
                    renderPlaylistLink();
                    Toast.makeText(this, "Playlist link removed", Toast.LENGTH_SHORT).show();
                    dialog.dismiss();
                });
            }
        });
        dialog.show();
    }

    private String supportedLinkFromClipboard() {
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboard == null || !clipboard.hasPrimaryClip()) return "";
        ClipData clip = clipboard.getPrimaryClip();
        if (clip == null || clip.getItemCount() == 0) return "";
        CharSequence clipboardText = clip.getItemAt(0).coerceToText(this);
        String link = extractFirstUrl(clipboardText == null ? "" : clipboardText.toString());
        return isSupportedPlaylistUrl(link) ? link : "";
    }

    private void renderPlaylistLink() {
        String link = getSharedPreferences(LINK_PREFS, MODE_PRIVATE).getString(LINK_KEY, "");
        if (link == null || link.isEmpty()) {
            playlistLinkStatus.setText("ADD PLAYLIST REFERENCE\nSpotify or YouTube link");
            playlistLinkStatus.setTextColor(getColor(R.color.electric));
            return;
        }
        playlistLinkStatus.setText(playlistKind(link) + " REFERENCE SAVED\nTap to view or edit the playlist link");
        playlistLinkStatus.setTextColor(getColor(R.color.gold));
    }

    private void handleSharedPlaylistLink(Intent intent) {
        if (intent == null || !Intent.ACTION_SEND.equals(intent.getAction())) return;
        CharSequence sharedText = intent.getCharSequenceExtra(Intent.EXTRA_TEXT);
        String link = extractFirstUrl(sharedText == null ? "" : sharedText.toString());
        if (isSupportedPlaylistUrl(link)) {
            showPlaylistLinkDialog(link);
        } else {
            Toast.makeText(this, "Share a Spotify or YouTube playlist link", Toast.LENGTH_LONG).show();
        }
    }

    private String extractFirstUrl(String text) {
        if (text == null) return "";
        Matcher matcher = URL_PATTERN.matcher(text.trim());
        if (!matcher.find()) return "";
        String link = matcher.group();
        while (!link.isEmpty() && ").,;]".indexOf(link.charAt(link.length() - 1)) >= 0) {
            link = link.substring(0, link.length() - 1);
        }
        return link;
    }

    private boolean isSupportedPlaylistUrl(String link) {
        if (link == null || link.isEmpty()) return false;
        try {
            Uri uri = Uri.parse(link);
            String host = uri.getHost();
            String path = uri.getPath();
            if (host == null) return false;
            host = host.toLowerCase(Locale.ROOT);
            if (host.equals("spotify.link")) return true;
            if (hostMatches(host, "spotify.com")) return path != null && path.contains("/playlist/");
            if (hostMatches(host, "youtube.com") || host.equals("youtu.be")) {
                return uri.getQueryParameter("list") != null;
            }
        } catch (Exception ignored) {
        }
        return false;
    }

    private boolean hostMatches(String host, String domain) {
        return host.equals(domain) || host.endsWith("." + domain);
    }

    private String playlistKind(String link) {
        try {
            String host = Uri.parse(link).getHost();
            if (host != null && host.toLowerCase(Locale.ROOT).contains("spotify")) return "SPOTIFY";
        } catch (Exception ignored) {
        }
        return "YOUTUBE";
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleSharedPlaylistLink(intent);
    }

    private void openFilePicker() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("audio/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        startActivityForResult(intent, REQUEST_FILES);
    }

    private void openFolderPicker() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION
                | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
        startActivityForResult(intent, REQUEST_FOLDER);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode != RESULT_OK || data == null) return;
        if (requestCode == REQUEST_FILES) importSelectedFiles(data);
        else if (requestCode == REQUEST_FOLDER && data.getData() != null) importFolder(data.getData());
    }

    private void importSelectedFiles(Intent data) {
        ArrayList<Track> tracks = new ArrayList<>();
        if (data.getData() != null) addDocumentTrack(data.getData(), tracks);
        ClipData clipData = data.getClipData();
        if (clipData != null) {
            for (int i = 0; i < clipData.getItemCount(); i++) {
                addDocumentTrack(clipData.getItemAt(i).getUri(), tracks);
            }
        }
        if (serviceBound && !tracks.isEmpty()) {
            playbackService.addTracks(tracks);
            refreshQueue();
            Toast.makeText(this, tracks.size() + " track added · order locked", Toast.LENGTH_SHORT).show();
        }
    }

    private void addDocumentTrack(Uri uri, ArrayList<Track> destination) {
        if (uri == null) return;
        persistReadPermission(uri);
        destination.add(new Track(uri.toString(), displayName(uri)));
    }

    private void importFolder(Uri treeUri) {
        persistReadPermission(treeUri);
        Toast.makeText(this, "Scanning music folder…", Toast.LENGTH_SHORT).show();
        new Thread(() -> {
            ArrayList<Track> found = new ArrayList<>();
            try {
                String rootId = DocumentsContract.getTreeDocumentId(treeUri);
                collectAudioDocuments(treeUri, rootId, found, 0);
                Collections.sort(found, (left, right) -> naturalCompare(left.title, right.title));
            } catch (Exception ignored) {
            }
            runOnUiThread(() -> {
                if (!serviceBound) return;
                if (found.isEmpty()) {
                    Toast.makeText(this, "No supported audio found in this folder", Toast.LENGTH_LONG).show();
                    return;
                }
                playbackService.addTracks(found);
                refreshQueue();
                Toast.makeText(this, found.size() + " tracks ready · order locked", Toast.LENGTH_SHORT).show();
            });
        }, "arda-folder-scan").start();
    }

    private void collectAudioDocuments(Uri treeUri, String parentId, ArrayList<Track> found, int depth) {
        if (depth > 12) return;
        Uri childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId);
        String[] projection = {
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE
        };
        try (Cursor cursor = getContentResolver().query(childrenUri, projection, null, null, null)) {
            if (cursor == null) return;
            int idColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID);
            int nameColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME);
            int mimeColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE);
            while (cursor.moveToNext()) {
                String documentId = cursor.getString(idColumn);
                String name = cursor.getString(nameColumn);
                String mime = cursor.getString(mimeColumn);
                if (DocumentsContract.Document.MIME_TYPE_DIR.equals(mime)) {
                    collectAudioDocuments(treeUri, documentId, found, depth + 1);
                } else if (isAudio(name, mime)) {
                    Uri documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId);
                    found.add(new Track(documentUri.toString(), stripExtension(name)));
                }
            }
        } catch (Exception ignored) {
        }
    }

    private boolean isAudio(String name, String mime) {
        if (mime != null && mime.toLowerCase(Locale.ROOT).startsWith("audio/")) return true;
        String lower = name == null ? "" : name.toLowerCase(Locale.ROOT);
        return lower.endsWith(".mp3") || lower.endsWith(".m4a") || lower.endsWith(".aac")
                || lower.endsWith(".flac") || lower.endsWith(".wav") || lower.endsWith(".ogg")
                || lower.endsWith(".opus");
    }

    private void persistReadPermission(Uri uri) {
        try {
            getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
        } catch (Exception ignored) {
        }
    }

    private String displayName(Uri uri) {
        String name = null;
        try (Cursor cursor = getContentResolver().query(uri,
                new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) name = cursor.getString(0);
        } catch (Exception ignored) {
        }
        if (name == null || name.trim().isEmpty()) name = uri.getLastPathSegment();
        return stripExtension(name == null ? "Unknown track" : name);
    }

    private String stripExtension(String name) {
        int dot = name == null ? -1 : name.lastIndexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    private int naturalCompare(String left, String right) {
        int i = 0;
        int j = 0;
        while (i < left.length() && j < right.length()) {
            char a = Character.toLowerCase(left.charAt(i));
            char b = Character.toLowerCase(right.charAt(j));
            if (Character.isDigit(a) && Character.isDigit(b)) {
                long na = 0;
                long nb = 0;
                while (i < left.length() && Character.isDigit(left.charAt(i))) {
                    na = Math.min(999999999L, na * 10 + left.charAt(i++) - '0');
                }
                while (j < right.length() && Character.isDigit(right.charAt(j))) {
                    nb = Math.min(999999999L, nb * 10 + right.charAt(j++) - '0');
                }
                if (na != nb) return Long.compare(na, nb);
            } else {
                if (a != b) return Character.compare(a, b);
                i++;
                j++;
            }
        }
        return Integer.compare(left.length(), right.length());
    }

    private void confirmClearQueue() {
        if (!serviceBound || playbackService.getPlaylist().isEmpty()) return;
        new AlertDialog.Builder(this)
                .setTitle("Clear wedding queue?")
                .setMessage("Playback will stop and all tracks will be removed from this queue.")
                .setNegativeButton("Cancel", null)
                .setPositiveButton("Clear", (dialog, which) -> {
                    playbackService.clearPlaylist();
                    refreshQueue();
                    renderState();
                })
                .show();
    }

    private void refreshQueue() {
        if (!serviceBound) return;
        queueAdapter.setTracks(playbackService.getPlaylist());
        queueTitle.setText("WEDDING QUEUE · " + queueAdapter.getCount() + " TRACKS");
        orderBadge.setText(queueAdapter.getCount() + " · ORDER LOCKED");
        renderedCount = queueAdapter.getCount();
    }

    private void renderState() {
        if (!serviceBound || playbackService == null) return;
        Bundle state = playbackService.getSnapshot();
        int count = state.getInt("count");
        int index = state.getInt("index");
        int position = state.getInt("position");
        int duration = state.getInt("duration");
        int seconds = state.getInt("mixSeconds", 8);
        boolean playing = state.getBoolean("playing");
        boolean autoMix = state.getBoolean("automix");
        boolean crossing = state.getBoolean("crossing");
        boolean nextReady = state.getBoolean("nextReady");
        float mixProgress = state.getFloat("mixProgress", 0f);

        nowTitle.setText(state.getString("title", "No track selected"));
        if (index >= 0) {
            nowSubtitle.setText("Track " + (index + 1) + " of " + count
                    + (crossing ? " · Mixing next track" : autoMix ? " · AutoMix ready" : " · Normal playback"));
        } else {
            nowSubtitle.setText(count == 0 ? "Add music files to build your wedding queue" : "Queue ready · tap Play");
        }
        nextUpTitle.setText(state.getString("nextTitle", "End of queue"));
        if (!autoMix) {
            syncStatus.setText("MANUAL MODE");
            syncStatus.setTextColor(getColor(R.color.muted));
            transitionStatus.setText("AutoMix paused");
            modeHint.setText("Full tracks · no overlap");
        } else if (crossing) {
            syncStatus.setText("LIVE TRANSITION");
            syncStatus.setTextColor(getColor(R.color.gold));
            transitionStatus.setText(Math.round(mixProgress * 100f) + "% MIX");
            modeHint.setText("Equal-power · position synced");
        } else if (nextReady) {
            syncStatus.setText("SYNC LOCKED");
            syncStatus.setTextColor(getColor(R.color.electric));
            transitionStatus.setText("READY · " + seconds + " SEC");
            modeHint.setText("Next deck preloaded");
        } else {
            syncStatus.setText(index >= 0 ? "PREPARING" : "ENGINE READY");
            syncStatus.setTextColor(getColor(R.color.electric_soft));
            transitionStatus.setText(index >= 0 ? "Loading next deck" : "Waiting for playback");
            modeHint.setText("Position-aware AutoMix");
        }
        timeCurrent.setText(formatTime(position));
        timeTotal.setText(formatTime(duration));
        if (!touchingPosition) {
            positionSeek.setProgress(duration <= 0 ? 0 : Math.round(position * 1000f / duration));
        }
        playPause.setText(playing ? "PAUSE" : "PLAY");
        mixSeek.setProgress(seconds - 4);
        mixValue.setText(seconds + " SEC");
        styleModeButtons(autoMix);

        if (count != renderedCount) refreshQueue();
        if (index != renderedIndex) {
            renderedIndex = index;
            queueAdapter.setCurrentIndex(index);
            if (index >= 0) queueList.smoothScrollToPosition(index);
        }
    }

    private void styleModeButtons(boolean autoMix) {
        modeAutoMix.setBackgroundResource(autoMix ? R.drawable.bg_mode_active : R.drawable.bg_button_secondary);
        modeAutoMix.setTextColor(getColor(autoMix ? R.color.electric : R.color.white));
        modeAutoMix.setText(autoMix ? "AUTOMIX ON" : "AUTOMIX");
        modeNormal.setBackgroundResource(autoMix ? R.drawable.bg_button_secondary : R.drawable.bg_mode_active);
        modeNormal.setTextColor(getColor(autoMix ? R.color.white : R.color.electric));
        modeNormal.setText(autoMix ? "NORMAL" : "NORMAL ON");
    }

    private String formatTime(int milliseconds) {
        int totalSeconds = Math.max(0, milliseconds / 1000);
        return String.format(Locale.US, "%d:%02d", totalSeconds / 60, totalSeconds % 60);
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33
                && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, REQUEST_NOTIFICATIONS);
        }
    }

    @Override
    protected void onDestroy() {
        uiHandler.removeCallbacksAndMessages(null);
        if (serviceBound) unbindService(connection);
        serviceBound = false;
        super.onDestroy();
    }

    private final class QueueAdapter extends BaseAdapter {
        private final LayoutInflater inflater;
        private ArrayList<Track> tracks = new ArrayList<>();
        private int currentIndex = -1;

        QueueAdapter(Context context) {
            inflater = LayoutInflater.from(context);
        }

        void setTracks(ArrayList<Track> tracks) {
            this.tracks = tracks;
            notifyDataSetChanged();
        }

        void setCurrentIndex(int index) {
            currentIndex = index;
            notifyDataSetChanged();
        }

        @Override public int getCount() { return tracks.size(); }
        @Override public Track getItem(int position) { return tracks.get(position); }
        @Override public long getItemId(int position) { return position; }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            View row = convertView == null
                    ? inflater.inflate(R.layout.item_track, parent, false) : convertView;
            Track track = getItem(position);
            ((TextView) row.findViewById(R.id.trackNumber)).setText(String.format(Locale.US, "%02d", position + 1));
            ((TextView) row.findViewById(R.id.trackTitle)).setText(track.title);
            TextView meta = row.findViewById(R.id.trackMeta);
            TextView state = row.findViewById(R.id.trackState);
            boolean selected = position == currentIndex;
            meta.setText(selected ? "Now playing · deck A" : "Queued · exact order");
            meta.setTextColor(getColor(selected ? R.color.electric : R.color.muted));
            state.setText(selected ? "LIVE" : "");
            row.findViewById(R.id.trackRoot).setBackgroundResource(
                    selected ? R.drawable.bg_panel_selected : R.drawable.bg_panel);
            return row;
        }
    }
}

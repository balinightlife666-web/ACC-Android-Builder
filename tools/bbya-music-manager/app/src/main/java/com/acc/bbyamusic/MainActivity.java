package com.acc.bbyamusic;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;
import java.util.UUID;

public class MainActivity extends Activity {
    private static final String PREFS = "bbya_music_manager";
    private static final String CATALOG_KEY = "catalog_json";
    private static final int PICK_AUDIO_REQUEST = 4401;

    private SharedPreferences prefs;
    private LinearLayout page;
    private JSONArray zones = new JSONArray();
    private int revision = 1;
    private int pendingImportZoneIndex = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        loadCatalog();
        renderHome();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != PICK_AUDIO_REQUEST || resultCode != RESULT_OK || data == null) return;
        if (pendingImportZoneIndex < 0 || pendingImportZoneIndex >= zones.length()) return;

        int imported = 0;
        ClipData clip = data.getClipData();
        if (clip != null) {
            for (int i = 0; i < clip.getItemCount(); i++) {
                if (importAudioUri(pendingImportZoneIndex, clip.getItemAt(i).getUri())) imported++;
            }
        } else if (data.getData() != null) {
            if (importAudioUri(pendingImportZoneIndex, data.getData())) imported++;
        }

        if (imported > 0) {
            persist(true);
            toast(imported + " lagu masuk ke playlist");
        } else {
            toast("Tidak ada file audio yang berhasil diimport");
        }
        int zoneToRender = pendingImportZoneIndex;
        pendingImportZoneIndex = -1;
        renderZone(zoneToRender);
    }

    private void loadCatalog() {
        String raw = prefs.getString(CATALOG_KEY, null);
        if (raw == null || raw.isEmpty()) {
            zones = defaultZones();
            revision = 1;
            persist(false);
            return;
        }
        try {
            JSONObject catalog = new JSONObject(raw);
            revision = catalog.optInt("revision", 1);
            zones = catalog.optJSONArray("zones");
            if (zones == null) zones = defaultZones();
            migrateCatalog();
        } catch (JSONException e) {
            zones = defaultZones();
            revision = 1;
            persist(false);
        }
    }

    private void migrateCatalog() {
        for (int i = 0; i < zones.length(); i++) {
            JSONObject zone = zones.optJSONObject(i);
            if (zone == null) continue;
            JSONArray tracks = zone.optJSONArray("tracks");
            if (tracks == null) {
                try { zone.put("tracks", new JSONArray()); } catch (JSONException ignored) {}
                continue;
            }
            for (int j = 0; j < tracks.length(); j++) {
                JSONObject track = tracks.optJSONObject(j);
                if (track == null) continue;
                try {
                    if (!track.has("sourceUri")) track.put("sourceUri", "");
                    if (!track.has("sourceName")) track.put("sourceName", "");
                    if (!track.has("mimeType")) track.put("mimeType", "");
                    if (!track.has("sizeBytes")) track.put("sizeBytes", 0);
                    if (!track.has("uploadState")) {
                        String assetId = track.optString("robloxAssetId", "");
                        track.put("uploadState", assetId.isEmpty() ? "PENDING_UPLOAD" : "READY");
                    }
                    if (!track.has("syncState")) track.put("syncState", "LOCAL_ONLY");
                } catch (JSONException ignored) {}
            }
        }
    }

    private JSONArray defaultZones() {
        JSONArray result = new JSONArray();
        result.put(newZone("main-club", "Main Club", "Funkot / EDM"));
        result.put(newZone("underground", "Underground", "Underground / Club"));
        result.put(newZone("rooftop", "Rooftop", "Amapiano / Lounge"));
        result.put(newZone("mall", "Mall", "Chill / Pop"));
        result.put(newZone("pasar-malam", "Pasar Malam", "Dangdut / Remix"));
        result.put(newZone("lake", "Lake / Outdoor", "Ambient / Chill"));
        return result;
    }

    private JSONObject newZone(String id, String name, String genre) {
        JSONObject zone = new JSONObject();
        try {
            zone.put("id", id);
            zone.put("name", name);
            zone.put("genre", genre);
            zone.put("enabled", true);
            zone.put("tracks", new JSONArray());
        } catch (JSONException ignored) {}
        return zone;
    }

    private JSONObject buildCatalog() {
        JSONObject catalog = new JSONObject();
        try {
            catalog.put("schemaVersion", 2);
            catalog.put("revision", revision);
            catalog.put("zones", zones);
        } catch (JSONException ignored) {}
        return catalog;
    }

    private JSONObject buildMirrorCatalog() {
        JSONObject catalog = new JSONObject();
        JSONArray mirrorZones = new JSONArray();
        try {
            catalog.put("schemaVersion", 2);
            catalog.put("revision", revision);
            for (int i = 0; i < zones.length(); i++) {
                JSONObject sourceZone = zones.optJSONObject(i);
                if (sourceZone == null) continue;
                JSONObject zone = new JSONObject();
                zone.put("id", sourceZone.optString("id"));
                zone.put("name", sourceZone.optString("name"));
                zone.put("genre", sourceZone.optString("genre"));
                zone.put("enabled", sourceZone.optBoolean("enabled", true));
                JSONArray mirrorTracks = new JSONArray();
                JSONArray sourceTracks = sourceZone.optJSONArray("tracks");
                if (sourceTracks != null) {
                    for (int j = 0; j < sourceTracks.length(); j++) {
                        JSONObject sourceTrack = sourceTracks.optJSONObject(j);
                        if (sourceTrack == null) continue;
                        JSONObject track = new JSONObject();
                        track.put("id", sourceTrack.optString("id"));
                        track.put("title", sourceTrack.optString("title"));
                        track.put("artist", sourceTrack.optString("artist"));
                        track.put("enabled", sourceTrack.optBoolean("enabled", true));
                        track.put("order", sourceTrack.optInt("order", j + 1));
                        track.put("robloxAssetId", sourceTrack.optString("robloxAssetId", ""));
                        track.put("coverImage", sourceTrack.optString("coverImage", ""));
                        track.put("uploadState", sourceTrack.optString("uploadState", "PENDING_UPLOAD"));
                        mirrorTracks.put(track);
                    }
                }
                zone.put("tracks", mirrorTracks);
                mirrorZones.put(zone);
            }
            catalog.put("zones", mirrorZones);
        } catch (JSONException ignored) {}
        return catalog;
    }

    private void persist(boolean bumpRevision) {
        if (bumpRevision) revision++;
        prefs.edit().putString(CATALOG_KEY, buildCatalog().toString()).apply();
    }

    private void setupPage() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(Color.rgb(12, 13, 16));
        page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(dp(18), dp(18), dp(18), dp(36));
        scroll.addView(page, new ScrollView.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        setContentView(scroll);
    }

    private void renderHome() {
        setupPage();
        page.addView(title("BBYA MUSIC MANAGER", 26));
        page.addView(label("Import lagu dari Google Drive / file HP, lalu susun playlist per area. APK tidak memutar musik.", 14, Color.LTGRAY));
        page.addView(space(12));

        LinearLayout actions = row();
        Button addZone = primaryButton("+ AREA");
        Button export = secondaryButton("MIRROR JSON");
        actions.addView(addZone, weighted());
        actions.addView(spaceH(8));
        actions.addView(export, weighted());
        page.addView(actions);
        addZone.setOnClickListener(v -> showAddZoneDialog());
        export.setOnClickListener(v -> showExportDialog());

        page.addView(space(18));
        page.addView(label("AREA / CHANNEL", 12, Color.rgb(214, 174, 93)));
        page.addView(space(8));

        for (int i = 0; i < zones.length(); i++) {
            JSONObject zone = zones.optJSONObject(i);
            if (zone != null) page.addView(zoneCard(zone, i));
        }
        page.addView(space(14));
        page.addView(label("Revision " + revision + " • Import & playlist only • No Play / Pause", 12, Color.GRAY));
    }

    private View zoneCard(JSONObject zone, int index) {
        LinearLayout card = card();
        JSONArray tracks = zone.optJSONArray("tracks");
        int trackCount = tracks == null ? 0 : tracks.length();
        int pending = countPending(tracks);
        card.addView(title(zone.optString("name", "Area"), 20));
        card.addView(label(zone.optString("genre", "-"), 14, Color.LTGRAY));
        card.addView(space(5));
        card.addView(label(trackCount + " lagu • " + pending + " menunggu upload/sync", 12, Color.GRAY));
        card.addView(space(10));
        Button open = primaryButton("BUKA PLAYLIST");
        card.addView(open, matchWidth());
        open.setOnClickListener(v -> renderZone(index));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, 0, 0, dp(10));
        card.setLayoutParams(lp);
        return card;
    }

    private int countPending(JSONArray tracks) {
        if (tracks == null) return 0;
        int pending = 0;
        for (int i = 0; i < tracks.length(); i++) {
            JSONObject track = tracks.optJSONObject(i);
            if (track != null && track.optString("robloxAssetId", "").isEmpty()) pending++;
        }
        return pending;
    }

    private void renderZone(int zoneIndex) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) { renderHome(); return; }
        setupPage();

        Button back = secondaryButton("← SEMUA AREA");
        back.setOnClickListener(v -> renderHome());
        page.addView(back, wrapWidth());
        page.addView(space(14));
        page.addView(title(zone.optString("name", "Area"), 28));
        page.addView(label(zone.optString("genre", ""), 15, Color.rgb(214, 174, 93)));
        page.addView(label("Panel map membaca channel: " + zone.optString("id", "-"), 12, Color.GRAY));
        page.addView(space(12));

        CheckBox enabled = new CheckBox(this);
        enabled.setText("Aktif untuk panel musik area ini");
        enabled.setTextColor(Color.WHITE);
        enabled.setChecked(zone.optBoolean("enabled", true));
        enabled.setOnCheckedChangeListener((buttonView, isChecked) -> {
            try { zone.put("enabled", isChecked); } catch (JSONException ignored) {}
            persist(true);
        });
        page.addView(enabled);

        Button importButton = primaryButton("IMPORT LAGU DARI DRIVE / HP");
        page.addView(importButton, matchWidth());
        importButton.setOnClickListener(v -> openAudioPicker(zoneIndex));
        page.addView(space(8));

        Button edit = secondaryButton("EDIT NAMA / GENRE AREA");
        page.addView(edit, matchWidth());
        edit.setOnClickListener(v -> showEditZoneDialog(zoneIndex));

        page.addView(space(18));
        page.addView(label("PLAYLIST", 12, Color.rgb(214, 174, 93)));
        page.addView(space(8));

        JSONArray tracks = zone.optJSONArray("tracks");
        if (tracks == null) {
            tracks = new JSONArray();
            try { zone.put("tracks", tracks); } catch (JSONException ignored) {}
        }

        if (tracks.length() == 0) {
            LinearLayout empty = card();
            empty.addView(label("Belum ada lagu. Tekan IMPORT LAGU lalu pilih file dari Google Drive atau penyimpanan HP.", 14, Color.LTGRAY));
            page.addView(empty);
        } else {
            for (int i = 0; i < tracks.length(); i++) {
                JSONObject track = tracks.optJSONObject(i);
                if (track != null) page.addView(trackCard(zoneIndex, track, i, tracks.length()));
            }
        }

        page.addView(space(16));
        Button deleteZone = dangerButton("HAPUS AREA");
        page.addView(deleteZone, matchWidth());
        deleteZone.setOnClickListener(v -> confirmDeleteZone(zoneIndex));
    }

    private void openAudioPicker(int zoneIndex) {
        pendingImportZoneIndex = zoneIndex;
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("audio/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        startActivityForResult(Intent.createChooser(intent, "Pilih lagu dari Drive / HP"), PICK_AUDIO_REQUEST);
    }

    private boolean importAudioUri(int zoneIndex, Uri uri) {
        if (uri == null) return false;
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return false;
        JSONArray tracks = zone.optJSONArray("tracks");
        if (tracks == null) {
            tracks = new JSONArray();
            try { zone.put("tracks", tracks); } catch (JSONException ignored) {}
        }

        try {
            getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
        } catch (Exception ignored) {}

        String sourceName = getDisplayName(uri);
        String mimeType = getContentResolver().getType(uri);
        long sizeBytes = getSize(uri);
        String title = stripExtension(sourceName);
        if (title.isEmpty()) title = "Imported Track";

        JSONObject track = new JSONObject();
        try {
            track.put("id", "track-" + UUID.randomUUID());
            track.put("title", title);
            track.put("artist", "Unknown Artist");
            track.put("enabled", true);
            track.put("order", tracks.length() + 1);
            track.put("sourceUri", uri.toString());
            track.put("sourceName", sourceName);
            track.put("mimeType", mimeType == null ? "audio/*" : mimeType);
            track.put("sizeBytes", sizeBytes);
            track.put("robloxAssetId", "");
            track.put("coverImage", "");
            track.put("uploadState", "PENDING_UPLOAD");
            track.put("syncState", "LOCAL_ONLY");
            tracks.put(track);
            normalizeOrders(tracks);
            return true;
        } catch (JSONException e) {
            return false;
        }
    }

    private String getDisplayName(Uri uri) {
        String name = "audio-file";
        Cursor cursor = null;
        try {
            cursor = getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                int index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if (index >= 0) name = cursor.getString(index);
            }
        } catch (Exception ignored) {
        } finally {
            if (cursor != null) cursor.close();
        }
        return name == null ? "audio-file" : name;
    }

    private long getSize(Uri uri) {
        Cursor cursor = null;
        try {
            cursor = getContentResolver().query(uri, new String[]{OpenableColumns.SIZE}, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                int index = cursor.getColumnIndex(OpenableColumns.SIZE);
                if (index >= 0 && !cursor.isNull(index)) return cursor.getLong(index);
            }
        } catch (Exception ignored) {
        } finally {
            if (cursor != null) cursor.close();
        }
        return 0;
    }

    private String stripExtension(String name) {
        if (name == null) return "";
        int dot = name.lastIndexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    private View trackCard(int zoneIndex, JSONObject track, int trackIndex, int total) {
        LinearLayout card = card();
        card.addView(label(String.format(Locale.US, "%02d", trackIndex + 1), 12, Color.rgb(214, 174, 93)));
        card.addView(title(track.optString("title", "Untitled"), 18));
        card.addView(label(track.optString("artist", "Unknown Artist"), 14, Color.LTGRAY));
        String sourceName = track.optString("sourceName", "");
        if (!sourceName.isEmpty()) card.addView(label("File: " + sourceName, 12, Color.GRAY));
        String assetId = track.optString("robloxAssetId", "");
        String state = assetId.isEmpty() ? "MENUNGGU UPLOAD / SYNC" : "SIAP DIBACA ROBLOX";
        card.addView(label(state, 12, assetId.isEmpty() ? Color.rgb(225, 185, 94) : Color.rgb(130, 210, 160)));

        CheckBox active = new CheckBox(this);
        active.setText("Aktif di playlist area");
        active.setTextColor(Color.WHITE);
        active.setChecked(track.optBoolean("enabled", true));
        active.setOnCheckedChangeListener((buttonView, isChecked) -> {
            try { track.put("enabled", isChecked); } catch (JSONException ignored) {}
            persist(true);
        });
        card.addView(active);

        LinearLayout controls = row();
        Button up = secondaryButton("↑");
        Button down = secondaryButton("↓");
        Button edit = secondaryButton("EDIT");
        Button remove = dangerButton("HAPUS");
        controls.addView(up, weighted());
        controls.addView(spaceH(5));
        controls.addView(down, weighted());
        controls.addView(spaceH(5));
        controls.addView(edit, weighted());
        controls.addView(spaceH(5));
        controls.addView(remove, weighted());
        card.addView(controls);

        up.setEnabled(trackIndex > 0);
        down.setEnabled(trackIndex < total - 1);
        up.setOnClickListener(v -> moveTrack(zoneIndex, trackIndex, trackIndex - 1));
        down.setOnClickListener(v -> moveTrack(zoneIndex, trackIndex, trackIndex + 1));
        edit.setOnClickListener(v -> showEditTrackDialog(zoneIndex, trackIndex));
        remove.setOnClickListener(v -> confirmDeleteTrack(zoneIndex, trackIndex));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, 0, 0, dp(10));
        card.setLayoutParams(lp);
        return card;
    }

    private void showEditTrackDialog(int zoneIndex, int trackIndex) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return;
        JSONArray tracks = zone.optJSONArray("tracks");
        if (tracks == null) return;
        JSONObject track = tracks.optJSONObject(trackIndex);
        if (track == null) return;

        LinearLayout form = form();
        EditText title = input("Judul lagu");
        EditText artist = input("Artist");
        title.setText(track.optString("title", ""));
        artist.setText(track.optString("artist", ""));
        form.addView(title);
        form.addView(artist);

        new AlertDialog.Builder(this)
                .setTitle("Edit Metadata Lagu")
                .setView(form)
                .setNegativeButton("Batal", null)
                .setPositiveButton("Simpan", (dialog, which) -> {
                    try {
                        track.put("title", title.getText().toString().trim());
                        String artistText = artist.getText().toString().trim();
                        track.put("artist", artistText.isEmpty() ? "Unknown Artist" : artistText);
                    } catch (JSONException ignored) {}
                    persist(true);
                    renderZone(zoneIndex);
                }).show();
    }

    private void showAddZoneDialog() {
        LinearLayout form = form();
        EditText name = input("Nama area, contoh: Beach Club");
        EditText genre = input("Genre, contoh: House / Disco");
        form.addView(name);
        form.addView(genre);
        new AlertDialog.Builder(this)
                .setTitle("Tambah Area Musik")
                .setView(form)
                .setNegativeButton("Batal", null)
                .setPositiveButton("Tambah", (dialog, which) -> {
                    String zoneName = name.getText().toString().trim();
                    if (zoneName.isEmpty()) { toast("Nama area wajib diisi"); return; }
                    String id = slug(zoneName);
                    if (id.isEmpty()) id = "zone-" + UUID.randomUUID().toString().substring(0, 8);
                    zones.put(newZone(uniqueZoneId(id), zoneName, genre.getText().toString().trim()));
                    persist(true);
                    renderHome();
                }).show();
    }

    private void showEditZoneDialog(int zoneIndex) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return;
        LinearLayout form = form();
        EditText name = input("Nama area");
        EditText genre = input("Genre");
        name.setText(zone.optString("name", ""));
        genre.setText(zone.optString("genre", ""));
        form.addView(name);
        form.addView(genre);
        new AlertDialog.Builder(this)
                .setTitle("Edit Area")
                .setView(form)
                .setNegativeButton("Batal", null)
                .setPositiveButton("Simpan", (dialog, which) -> {
                    try {
                        zone.put("name", name.getText().toString().trim());
                        zone.put("genre", genre.getText().toString().trim());
                    } catch (JSONException ignored) {}
                    persist(true);
                    renderZone(zoneIndex);
                }).show();
    }

    private void moveTrack(int zoneIndex, int from, int to) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return;
        JSONArray tracks = zone.optJSONArray("tracks");
        if (tracks == null || from < 0 || to < 0 || from >= tracks.length() || to >= tracks.length()) return;
        JSONArray reordered = new JSONArray();
        for (int i = 0; i < tracks.length(); i++) {
            if (i == to) reordered.put(tracks.optJSONObject(from));
            if (i != from) reordered.put(tracks.optJSONObject(i));
        }
        normalizeOrders(reordered);
        try { zone.put("tracks", reordered); } catch (JSONException ignored) {}
        persist(true);
        renderZone(zoneIndex);
    }

    private void normalizeOrders(JSONArray tracks) {
        for (int i = 0; i < tracks.length(); i++) {
            JSONObject track = tracks.optJSONObject(i);
            if (track != null) try { track.put("order", i + 1); } catch (JSONException ignored) {}
        }
    }

    private void confirmDeleteTrack(int zoneIndex, int trackIndex) {
        new AlertDialog.Builder(this)
                .setTitle("Hapus lagu?")
                .setMessage("Lagu akan dihapus dari playlist area ini. File asli di Drive / HP tidak dihapus.")
                .setNegativeButton("Batal", null)
                .setPositiveButton("Hapus", (d, w) -> {
                    JSONObject zone = zones.optJSONObject(zoneIndex);
                    if (zone == null) return;
                    JSONArray tracks = zone.optJSONArray("tracks");
                    if (tracks == null) return;
                    JSONArray next = new JSONArray();
                    for (int i = 0; i < tracks.length(); i++) if (i != trackIndex) next.put(tracks.optJSONObject(i));
                    normalizeOrders(next);
                    try { zone.put("tracks", next); } catch (JSONException ignored) {}
                    persist(true);
                    renderZone(zoneIndex);
                }).show();
    }

    private void confirmDeleteZone(int zoneIndex) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return;
        new AlertDialog.Builder(this)
                .setTitle("Hapus area?")
                .setMessage("Area " + zone.optString("name") + " dan playlist lokalnya akan dihapus dari APK.")
                .setNegativeButton("Batal", null)
                .setPositiveButton("Hapus", (d, w) -> {
                    JSONArray next = new JSONArray();
                    for (int i = 0; i < zones.length(); i++) if (i != zoneIndex) next.put(zones.optJSONObject(i));
                    zones = next;
                    persist(true);
                    renderHome();
                }).show();
    }

    private void showExportDialog() {
        String json = buildMirrorCatalog().toString();
        TextView text = label(json, 12, Color.LTGRAY);
        text.setTextIsSelectable(true);
        ScrollView scroll = new ScrollView(this);
        scroll.setPadding(dp(12), dp(12), dp(12), dp(12));
        scroll.addView(text);
        new AlertDialog.Builder(this)
                .setTitle("Mirror JSON")
                .setMessage("Debug contract untuk backend/panel Roblox. URI file Drive/HP tidak diekspor.")
                .setView(scroll)
                .setNegativeButton("Tutup", null)
                .setPositiveButton("Copy", (d, w) -> {
                    ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                    clipboard.setPrimaryClip(ClipData.newPlainText("BBYA Music Mirror JSON", json));
                    toast("Mirror JSON disalin");
                }).show();
    }

    private String slug(String value) {
        return value.toLowerCase(Locale.US).trim().replaceAll("[^a-z0-9]+", "-").replaceAll("^-|-$", "");
    }

    private String uniqueZoneId(String candidate) {
        String id = candidate;
        int suffix = 2;
        while (zoneIdExists(id)) id = candidate + "-" + suffix++;
        return id;
    }

    private boolean zoneIdExists(String id) {
        for (int i = 0; i < zones.length(); i++) {
            JSONObject zone = zones.optJSONObject(i);
            if (zone != null && id.equals(zone.optString("id"))) return true;
        }
        return false;
    }

    private LinearLayout card() {
        LinearLayout view = new LinearLayout(this);
        view.setOrientation(LinearLayout.VERTICAL);
        view.setPadding(dp(15), dp(15), dp(15), dp(15));
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.rgb(24, 26, 31));
        bg.setCornerRadius(dp(14));
        bg.setStroke(dp(1), Color.rgb(47, 50, 58));
        view.setBackground(bg);
        return view;
    }

    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        return row;
    }

    private LinearLayout form() {
        LinearLayout form = new LinearLayout(this);
        form.setOrientation(LinearLayout.VERTICAL);
        form.setPadding(dp(18), dp(6), dp(18), 0);
        return form;
    }

    private TextView title(String value, int sp) {
        TextView text = label(value, sp, Color.WHITE);
        text.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return text;
    }

    private TextView label(String value, int sp, int color) {
        TextView text = new TextView(this);
        text.setText(value);
        text.setTextSize(sp);
        text.setTextColor(color);
        text.setLineSpacing(0, 1.08f);
        return text;
    }

    private EditText input(String hint) {
        EditText edit = new EditText(this);
        edit.setHint(hint);
        edit.setSingleLine(true);
        edit.setPadding(dp(10), dp(10), dp(10), dp(10));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, 0, 0, dp(8));
        edit.setLayoutParams(lp);
        return edit;
    }

    private Button primaryButton(String text) { return button(text, Color.rgb(196, 151, 63), Color.BLACK); }
    private Button secondaryButton(String text) { return button(text, Color.rgb(45, 48, 57), Color.WHITE); }
    private Button dangerButton(String text) { return button(text, Color.rgb(112, 42, 47), Color.WHITE); }

    private Button button(String text, int bgColor, int textColor) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextColor(textColor);
        button.setTextSize(12);
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(bgColor);
        bg.setCornerRadius(dp(11));
        button.setBackground(bg);
        button.setPadding(dp(10), dp(10), dp(10), dp(10));
        return button;
    }

    private View space(int height) { View v = new View(this); v.setLayoutParams(new LinearLayout.LayoutParams(1, dp(height))); return v; }
    private View spaceH(int width) { View v = new View(this); v.setLayoutParams(new LinearLayout.LayoutParams(dp(width), 1)); return v; }
    private LinearLayout.LayoutParams weighted() { return new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f); }
    private LinearLayout.LayoutParams matchWidth() { return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT); }
    private LinearLayout.LayoutParams wrapWidth() { return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT); }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
    private void toast(String message) { Toast.makeText(this, message, Toast.LENGTH_SHORT).show(); }
}
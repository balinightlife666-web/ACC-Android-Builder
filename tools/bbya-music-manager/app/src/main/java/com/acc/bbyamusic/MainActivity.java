package com.acc.bbyamusic;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.text.InputType;
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

    private SharedPreferences prefs;
    private LinearLayout page;
    private JSONArray zones = new JSONArray();
    private int revision = 1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        loadCatalog();
        renderHome();
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
        } catch (JSONException e) {
            zones = defaultZones();
            revision = 1;
            persist(false);
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
            catalog.put("schemaVersion", 1);
            catalog.put("revision", revision);
            catalog.put("zones", zones);
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
        scroll.addView(page, new ScrollView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        ));
        setContentView(scroll);
    }

    private void renderHome() {
        setupPage();

        TextView brand = title("BBYA MUSIC MANAGER", 26);
        page.addView(brand);
        page.addView(label("Playlist pusat untuk semua area BBYA Social Hub. APK ini hanya mengatur data playlist — musik tetap otomatis dimainkan oleh sistem di map.", 14, Color.LTGRAY));
        page.addView(space(12));

        LinearLayout actions = row();
        Button addZone = primaryButton("+ AREA");
        Button export = secondaryButton("EXPORT JSON");
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
            final int zoneIndex = i;
            JSONObject zone = zones.optJSONObject(i);
            if (zone != null) page.addView(zoneCard(zone, zoneIndex));
        }

        page.addView(space(14));
        page.addView(label("Revision " + revision + " • Tidak ada Play / Pause / Next di APK", 12, Color.GRAY));
    }

    private View zoneCard(JSONObject zone, int index) {
        LinearLayout card = card();
        String name = zone.optString("name", "Area");
        String genre = zone.optString("genre", "-");
        JSONArray tracks = zone.optJSONArray("tracks");
        int trackCount = tracks == null ? 0 : tracks.length();

        card.addView(title(name, 20));
        card.addView(label(genre, 14, Color.LTGRAY));
        card.addView(space(5));
        card.addView(label(trackCount + " track • channel: " + zone.optString("id", "-"), 12, Color.GRAY));
        card.addView(space(10));

        Button open = primaryButton("BUKA PLAYLIST");
        card.addView(open, matchWidth());
        open.setOnClickListener(v -> renderZone(index));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(0, 0, 0, dp(10));
        card.setLayoutParams(lp);
        return card;
    }

    private void renderZone(int zoneIndex) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) {
            renderHome();
            return;
        }

        setupPage();

        Button back = secondaryButton("← SEMUA AREA");
        back.setOnClickListener(v -> renderHome());
        page.addView(back, wrapWidth());
        page.addView(space(14));

        page.addView(title(zone.optString("name", "Area"), 28));
        page.addView(label(zone.optString("genre", ""), 15, Color.rgb(214, 174, 93)));
        page.addView(label("Channel ID: " + zone.optString("id", "-"), 12, Color.GRAY));
        page.addView(space(12));

        CheckBox enabled = new CheckBox(this);
        enabled.setText("Aktif untuk sistem musik map");
        enabled.setTextColor(Color.WHITE);
        enabled.setChecked(zone.optBoolean("enabled", true));
        enabled.setOnCheckedChangeListener((buttonView, isChecked) -> {
            try { zone.put("enabled", isChecked); } catch (JSONException ignored) {}
            persist(true);
        });
        page.addView(enabled);

        LinearLayout actions = row();
        Button add = primaryButton("+ TRACK");
        Button edit = secondaryButton("EDIT AREA");
        actions.addView(add, weighted());
        actions.addView(spaceH(8));
        actions.addView(edit, weighted());
        page.addView(actions);

        add.setOnClickListener(v -> showAddTrackDialog(zoneIndex));
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
            empty.addView(label("Belum ada lagu. Tambahkan track dan isi Roblox Audio Asset ID.", 14, Color.LTGRAY));
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

    private View trackCard(int zoneIndex, JSONObject track, int trackIndex, int total) {
        LinearLayout card = card();
        card.addView(label(String.format(Locale.US, "%02d", trackIndex + 1), 12, Color.rgb(214, 174, 93)));
        card.addView(title(track.optString("title", "Untitled"), 18));
        card.addView(label(track.optString("artist", "Unknown artist"), 14, Color.LTGRAY));
        card.addView(space(5));
        card.addView(label("Audio ID: " + track.optString("robloxAssetId", "-"), 12, Color.GRAY));
        String cover = track.optString("coverImage", "");
        if (!cover.isEmpty()) card.addView(label("Cover: " + cover, 12, Color.GRAY));

        CheckBox active = new CheckBox(this);
        active.setText("Aktif");
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

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(0, 0, 0, dp(10));
        card.setLayoutParams(lp);
        return card;
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
                    if (zoneName.isEmpty()) {
                        toast("Nama area wajib diisi");
                        return;
                    }
                    String id = slug(zoneName);
                    if (id.isEmpty()) id = "zone-" + UUID.randomUUID().toString().substring(0, 8);
                    id = uniqueZoneId(id);
                    zones.put(newZone(id, zoneName, genre.getText().toString().trim()));
                    persist(true);
                    renderHome();
                })
                .show();
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
                })
                .show();
    }

    private void showAddTrackDialog(int zoneIndex) {
        showTrackDialog(zoneIndex, -1);
    }

    private void showEditTrackDialog(int zoneIndex, int trackIndex) {
        showTrackDialog(zoneIndex, trackIndex);
    }

    private void showTrackDialog(int zoneIndex, int trackIndex) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return;
        JSONArray tracks = zone.optJSONArray("tracks");
        if (tracks == null) {
            tracks = new JSONArray();
            try { zone.put("tracks", tracks); } catch (JSONException ignored) {}
        }

        JSONObject editing = trackIndex >= 0 ? tracks.optJSONObject(trackIndex) : null;
        LinearLayout form = form();
        EditText title = input("Judul lagu");
        EditText artist = input("Artist");
        EditText asset = input("Roblox Audio Asset ID");
        asset.setInputType(InputType.TYPE_CLASS_NUMBER);
        EditText cover = input("Cover Asset ID (opsional)");

        if (editing != null) {
            title.setText(editing.optString("title", ""));
            artist.setText(editing.optString("artist", ""));
            asset.setText(editing.optString("robloxAssetId", ""));
            String currentCover = editing.optString("coverImage", "");
            cover.setText(currentCover.replace("rbxassetid://", ""));
        }

        form.addView(title);
        form.addView(artist);
        form.addView(asset);
        form.addView(cover);

        final JSONArray finalTracks = tracks;
        final JSONObject finalEditing = editing;
        new AlertDialog.Builder(this)
                .setTitle(editing == null ? "Tambah Track" : "Edit Track")
                .setView(form)
                .setNegativeButton("Batal", null)
                .setPositiveButton("Simpan", (dialog, which) -> {
                    String t = title.getText().toString().trim();
                    String a = artist.getText().toString().trim();
                    String assetId = asset.getText().toString().trim();
                    String coverId = cover.getText().toString().trim();

                    if (t.isEmpty() || assetId.isEmpty()) {
                        toast("Judul dan Roblox Audio Asset ID wajib diisi");
                        return;
                    }

                    JSONObject target = finalEditing == null ? new JSONObject() : finalEditing;
                    try {
                        if (finalEditing == null) target.put("id", "track-" + UUID.randomUUID().toString());
                        target.put("title", t);
                        target.put("artist", a.isEmpty() ? "Unknown Artist" : a);
                        target.put("robloxAssetId", assetId);
                        target.put("coverImage", coverId.isEmpty() ? "" : "rbxassetid://" + coverId);
                        if (finalEditing == null) target.put("enabled", true);
                        if (finalEditing == null) finalTracks.put(target);
                    } catch (JSONException ignored) {}

                    normalizeOrders(finalTracks);
                    persist(true);
                    renderZone(zoneIndex);
                })
                .show();
    }

    private void moveTrack(int zoneIndex, int from, int to) {
        JSONObject zone = zones.optJSONObject(zoneIndex);
        if (zone == null) return;
        JSONArray tracks = zone.optJSONArray("tracks");
        if (tracks == null || from < 0 || to < 0 || from >= tracks.length() || to >= tracks.length()) return;

        Object a = tracks.opt(from);
        Object b = tracks.opt(to);
        try {
            tracks.put(from, b);
            tracks.put(to, a);
        } catch (JSONException ignored) {}
        normalizeOrders(tracks);
        persist(true);
        renderZone(zoneIndex);
    }

    private void normalizeOrders(JSONArray tracks) {
        for (int i = 0; i < tracks.length(); i++) {
            JSONObject track = tracks.optJSONObject(i);
            if (track != null) {
                try { track.put("order", i + 1); } catch (JSONException ignored) {}
            }
        }
    }

    private void confirmDeleteTrack(int zoneIndex, int trackIndex) {
        new AlertDialog.Builder(this)
                .setTitle("Hapus track?")
                .setMessage("Track dihapus dari playlist APK. Ini tidak menghapus asset audio dari Roblox.")
                .setNegativeButton("Batal", null)
                .setPositiveButton("Hapus", (dialog, which) -> {
                    JSONObject zone = zones.optJSONObject(zoneIndex);
                    JSONArray tracks = zone == null ? null : zone.optJSONArray("tracks");
                    if (tracks != null) {
                        tracks.remove(trackIndex);
                        normalizeOrders(tracks);
                        persist(true);
                    }
                    renderZone(zoneIndex);
                })
                .show();
    }

    private void confirmDeleteZone(int zoneIndex) {
        new AlertDialog.Builder(this)
                .setTitle("Hapus area?")
                .setMessage("Area dan daftar track-nya akan dihapus dari APK.")
                .setNegativeButton("Batal", null)
                .setPositiveButton("Hapus", (dialog, which) -> {
                    zones.remove(zoneIndex);
                    persist(true);
                    renderHome();
                })
                .show();
    }

    private void showExportDialog() {
        String pretty;
        try {
            pretty = buildCatalog().toString(2);
        } catch (JSONException e) {
            pretty = buildCatalog().toString();
        }

        TextView text = new TextView(this);
        text.setText(pretty);
        text.setTextIsSelectable(true);
        text.setTextColor(Color.WHITE);
        text.setTextSize(12);
        text.setPadding(dp(14), dp(14), dp(14), dp(14));

        ScrollView scroller = new ScrollView(this);
        scroller.setBackgroundColor(Color.rgb(20, 21, 25));
        scroller.addView(text);

        final String finalPretty = pretty;
        new AlertDialog.Builder(this)
                .setTitle("Playlist JSON")
                .setView(scroller)
                .setNegativeButton("Tutup", null)
                .setPositiveButton("Copy", (dialog, which) -> {
                    ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                    clipboard.setPrimaryClip(ClipData.newPlainText("BBYA Music Catalog", finalPretty));
                    toast("JSON disalin");
                })
                .show();
    }

    private String uniqueZoneId(String base) {
        String candidate = base;
        int suffix = 2;
        while (zoneIdExists(candidate)) candidate = base + "-" + suffix++;
        return candidate;
    }

    private boolean zoneIdExists(String id) {
        for (int i = 0; i < zones.length(); i++) {
            JSONObject zone = zones.optJSONObject(i);
            if (zone != null && id.equals(zone.optString("id"))) return true;
        }
        return false;
    }

    private String slug(String value) {
        String slug = value.toLowerCase(Locale.US)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");
        return slug;
    }

    private LinearLayout form() {
        LinearLayout form = new LinearLayout(this);
        form.setOrientation(LinearLayout.VERTICAL);
        int p = dp(18);
        form.setPadding(p, dp(6), p, 0);
        return form;
    }

    private EditText input(String hint) {
        EditText input = new EditText(this);
        input.setHint(hint);
        input.setSingleLine(true);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(0, 0, 0, dp(8));
        input.setLayoutParams(lp);
        return input;
    }

    private LinearLayout card() {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(15), dp(14), dp(15), dp(14));
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.rgb(27, 29, 34));
        bg.setCornerRadius(dp(14));
        bg.setStroke(dp(1), Color.rgb(49, 52, 60));
        card.setBackground(bg);
        return card;
    }

    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        return row;
    }

    private TextView title(String text, int size) {
        TextView tv = label(text, size, Color.WHITE);
        tv.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return tv;
    }

    private TextView label(String text, int size, int color) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(size);
        tv.setTextColor(color);
        tv.setLineSpacing(0, 1.08f);
        return tv;
    }

    private Button primaryButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextColor(Color.BLACK);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.rgb(214, 174, 93));
        bg.setCornerRadius(dp(10));
        b.setBackground(bg);
        return b;
    }

    private Button secondaryButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextColor(Color.WHITE);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.rgb(43, 46, 53));
        bg.setCornerRadius(dp(10));
        b.setBackground(bg);
        return b;
    }

    private Button dangerButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextColor(Color.WHITE);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.rgb(104, 41, 46));
        bg.setCornerRadius(dp(10));
        b.setBackground(bg);
        return b;
    }

    private View space(int heightDp) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(1, dp(heightDp)));
        return v;
    }

    private View spaceH(int widthDp) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(dp(widthDp), 1));
        return v;
    }

    private LinearLayout.LayoutParams weighted() {
        return new LinearLayout.LayoutParams(0, dp(48), 1f);
    }

    private LinearLayout.LayoutParams matchWidth() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
    }

    private LinearLayout.LayoutParams wrapWidth() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(44));
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private void toast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }
}

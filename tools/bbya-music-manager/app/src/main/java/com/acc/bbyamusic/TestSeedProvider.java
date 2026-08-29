package com.acc.bbyamusic;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.net.Uri;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/**
 * Test-only bootstrap for the BBYA Music Manager pilot branch.
 *
 * It injects the Roblox audio IDs collected from the 2026-08-29 screenshot into
 * the Underground playlist without requiring local audio files. Existing tracks
 * are preserved and duplicate Asset IDs are skipped.
 */
public class TestSeedProvider extends ContentProvider {
    private static final String PREFS = "bbya_music_manager";
    private static final String CATALOG_KEY = "catalog_json";

    private static final String[][] TEST_TRACKS = new String[][]{
            {"86006580589828", "Screenshot ID 01 (judul tertutup / belum terverifikasi)"},
            {"125820152354579", "DJ Paradise X Velocity Baby Don't Go feat IMA Audio"},
            {"133947654553749", "DJ TJAP Morgan V4"},
            {"95691778643767", "DJ Ayang Ayang"},
            {"130313438027284", "Funk Do Bounce"},
            {"75712054983357", "Hadroh Ya Thoybha | Ar Production"},
            {"88943191512256", "DJ Banteng Lestari"},
            {"91809948844354", "DJ Gangsta MP"},
            {"108578144206183", "DJ Kandas HKS"},
            {"89763491889927", "DJ Battle HKS"},
            {"96924419000406", "DJ Trap Love Of War"},
            {"132460784559824", "DJ Cinta Yang Sempurna"},
            {"122720606049274", "DJ Bocah Bocah Cilik Sholawat"},
            {"70777592375726", "DJ Mahabarata"},
            {"98308711398889", "DJ Bila Nanti"},
            {"95839337053281", "DJ Punk Rock Jalanan"},
            {"135587255285184", "DJ TJAP Morgan Trompet - By Klepon Remix"},
            {"104136707299013", "DJ Gedhang Klutuk by DJ Tanti"},
            {"131597067752690", "Garam Cina"},
            {"73502975968958", "DJ Sin Pijama by Alvin Revolution"},
            {"101289385838814", "DJ Trompet Brazil"},
            {"102043858565172", "DJ Viral Tik Tok Pal Pal Di Kepas"},
            {"79235704240751", "DJ Twenty One Pilots Nova - Tambal Elang"},
            {"103710801320668", "DJ Prank Karnaval Viral Booyah"},
            {"102227106442067", "DJ We Found Love (ID screenshot belum 100% terverifikasi)"}
    };

    @Override
    public boolean onCreate() {
        Context context = getContext();
        if (context == null) return false;

        try {
            SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
            String raw = prefs.getString(CATALOG_KEY, "");
            JSONObject catalog = raw == null || raw.isEmpty() ? defaultCatalog() : new JSONObject(raw);
            JSONArray zones = catalog.optJSONArray("zones");
            if (zones == null) {
                catalog = defaultCatalog();
                zones = catalog.getJSONArray("zones");
            }

            JSONObject underground = findZone(zones, "underground");
            if (underground == null) {
                underground = newZone("underground", "Underground", "Underground / Club");
                zones.put(underground);
            }

            JSONArray tracks = underground.optJSONArray("tracks");
            if (tracks == null) {
                tracks = new JSONArray();
                underground.put("tracks", tracks);
            }

            Set<String> existingAssetIds = new HashSet<>();
            int maxOrder = 0;
            for (int i = 0; i < tracks.length(); i++) {
                JSONObject track = tracks.optJSONObject(i);
                if (track == null) continue;
                String assetId = track.optString("robloxAssetId", "");
                if (!assetId.isEmpty()) existingAssetIds.add(assetId);
                maxOrder = Math.max(maxOrder, track.optInt("order", i + 1));
            }

            int added = 0;
            for (int i = 0; i < TEST_TRACKS.length; i++) {
                String assetId = TEST_TRACKS[i][0];
                String title = TEST_TRACKS[i][1];
                if (existingAssetIds.contains(assetId)) continue;

                JSONObject track = new JSONObject();
                track.put("id", String.format(Locale.US, "test-shot-20260829-%02d", i + 1));
                track.put("title", title);
                track.put("artist", "Screenshot Roblox ID Test");
                track.put("enabled", true);
                track.put("order", ++maxOrder);
                track.put("sourceUri", "");
                track.put("sourceName", "");
                track.put("localPath", "");
                track.put("mimeType", "");
                track.put("sizeBytes", 0);
                track.put("robloxAssetId", assetId);
                track.put("coverImage", "");
                track.put("uploadState", "READY");
                track.put("syncState", "LOCAL_ONLY");
                track.put("testSource", "screenshot-2026-08-29");
                tracks.put(track);
                existingAssetIds.add(assetId);
                added++;
            }

            if (added > 0) {
                catalog.put("schemaVersion", 2);
                catalog.put("revision", Math.max(1, catalog.optInt("revision", 1)) + 1);
                prefs.edit()
                        .putString(CATALOG_KEY, catalog.toString())
                        .putInt("bbya_test_seed_20260829_added", added)
                        .putString("oauth_last_status", "Test ID siap: " + added + " track disuntik ke Underground")
                        .apply();
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private JSONObject defaultCatalog() throws Exception {
        JSONObject catalog = new JSONObject();
        JSONArray zones = new JSONArray();
        zones.put(newZone("main-club", "Main Club", "Funkot / EDM"));
        zones.put(newZone("underground", "Underground", "Underground / Club"));
        zones.put(newZone("rooftop", "Rooftop", "Amapiano / Lounge"));
        zones.put(newZone("mall", "Mall", "Chill / Pop"));
        zones.put(newZone("pasar-malam", "Pasar Malam", "Dangdut / Remix"));
        zones.put(newZone("lake", "Lake / Outdoor", "Ambient / Chill"));
        catalog.put("schemaVersion", 2);
        catalog.put("revision", 1);
        catalog.put("zones", zones);
        return catalog;
    }

    private JSONObject newZone(String id, String name, String genre) throws Exception {
        JSONObject zone = new JSONObject();
        zone.put("id", id);
        zone.put("name", name);
        zone.put("genre", genre);
        zone.put("enabled", true);
        zone.put("tracks", new JSONArray());
        return zone;
    }

    private JSONObject findZone(JSONArray zones, String id) {
        if (zones == null) return null;
        for (int i = 0; i < zones.length(); i++) {
            JSONObject zone = zones.optJSONObject(i);
            if (zone != null && id.equals(zone.optString("id", ""))) return zone;
        }
        return null;
    }

    @Override public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) { return null; }
    @Override public String getType(Uri uri) { return null; }
    @Override public Uri insert(Uri uri, ContentValues values) { return null; }
    @Override public int delete(Uri uri, String selection, String[] selectionArgs) { return 0; }
    @Override public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) { return 0; }
}

package com.acc.bbyamusic;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.util.Base64;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Locale;
import java.util.Set;

public class OAuthSyncActivity extends Activity {
    private static final String PREFS = "bbya_music_manager";
    private static final String CATALOG_KEY = "catalog_json";
    private static final String CLIENT_ID = "7780879532316955113";
    private static final String REDIRECT_URI = "bbyamusic://oauth/callback";
    private static final String SCOPES = "openid profile asset:read asset:write universe-messaging-service:publish";
    private static final String AUTHORIZE_URL = "https://apis.roblox.com/oauth/v1/authorize";
    private static final String TOKEN_URL = "https://apis.roblox.com/oauth/v1/token";
    private static final String USERINFO_URL = "https://apis.roblox.com/oauth/v1/userinfo";
    private static final String ASSET_CREATE_URL = "https://apis.roblox.com/assets/v1/assets";
    private static final String ASSET_OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/";
    private static final String UNIVERSE_ID = "8116636513";
    private static final String MESSAGE_URL = "https://apis.roblox.com/cloud/v2/universes/" + UNIVERSE_ID + ":publishMessage";
    private static final String TOPIC = "BBYA_MUSIC_UNDERGROUND_V1";
    private static final long MAX_AUDIO_BYTES = 20L * 1024L * 1024L;

    private SharedPreferences prefs;
    private TextView accountText;
    private TextView statusText;
    private Button loginButton;
    private Button syncButton;
    private Button libraryButton;
    private volatile boolean busy = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        render();
        handleOAuthIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleOAuthIntent(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (!busy) refreshUi();
    }

    private void render() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(Color.rgb(12, 13, 16));
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(dp(18), dp(22), dp(18), dp(36));
        scroll.addView(page, new ScrollView.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        page.addView(title("BBYA MUSIC SYNC", 27));
        page.addView(label("UNDERGROUND PILOT", 13, Color.rgb(214, 174, 93)));
        page.addView(space(10));
        page.addView(label("APK tetap hanya library playlist. Login Roblox dipakai untuk meng-upload lagu dan mengirim perubahan playlist Underground ke BBYA Social Hub.", 14, Color.LTGRAY));
        page.addView(space(18));

        LinearLayout card = card();
        accountText = label("Roblox: belum terhubung", 15, Color.WHITE);
        statusText = label("Status: siap", 13, Color.GRAY);
        card.addView(accountText);
        card.addView(space(7));
        card.addView(statusText);
        page.addView(card);
        page.addView(space(12));

        loginButton = primaryButton("LOGIN ROBLOX");
        syncButton = primaryButton("SYNC UNDERGROUND");
        libraryButton = secondaryButton("BUKA LIBRARY PLAYLIST");
        page.addView(loginButton, matchWidth());
        page.addView(space(8));
        page.addView(syncButton, matchWidth());
        page.addView(space(8));
        page.addView(libraryButton, matchWidth());
        page.addView(space(16));
        page.addView(label("Tidak ada Client Secret atau API key yang disimpan di APK. OAuth menggunakan PKCE.", 12, Color.GRAY));

        loginButton.setOnClickListener(v -> startOAuth());
        syncButton.setOnClickListener(v -> syncUnderground());
        libraryButton.setOnClickListener(v -> startActivity(new Intent(this, MainActivity.class)));
        setContentView(scroll);
        refreshUi();
    }

    private void refreshUi() {
        String username = prefs.getString("oauth_username", "");
        long expiresAt = prefs.getLong("oauth_expires_at", 0L);
        boolean valid = !prefs.getString("oauth_access_token", "").isEmpty() && System.currentTimeMillis() < expiresAt;
        accountText.setText(valid ? "Roblox: " + (username.isEmpty() ? "terhubung" : username) : "Roblox: belum terhubung / sesi habis");
        loginButton.setText(valid ? "LOGIN ULANG / GANTI AKUN" : "LOGIN ROBLOX");
        syncButton.setEnabled(valid && !busy);
        loginButton.setEnabled(!busy);
        libraryButton.setEnabled(!busy);
        if (!busy) statusText.setText("Status: " + prefs.getString("oauth_last_status", valid ? "siap sync" : "login diperlukan"));
    }

    private void startOAuth() {
        try {
            String verifier = randomUrlSafe(48);
            String challenge = base64Url(MessageDigest.getInstance("SHA-256").digest(verifier.getBytes(StandardCharsets.US_ASCII)));
            String state = randomUrlSafe(24);
            String nonce = randomUrlSafe(24);
            prefs.edit().putString("oauth_pkce_verifier", verifier).putString("oauth_state", state).apply();
            Uri uri = Uri.parse(AUTHORIZE_URL).buildUpon()
                    .appendQueryParameter("client_id", CLIENT_ID)
                    .appendQueryParameter("redirect_uri", REDIRECT_URI)
                    .appendQueryParameter("scope", SCOPES)
                    .appendQueryParameter("response_type", "code")
                    .appendQueryParameter("prompt", "login consent")
                    .appendQueryParameter("state", state)
                    .appendQueryParameter("nonce", nonce)
                    .appendQueryParameter("code_challenge", challenge)
                    .appendQueryParameter("code_challenge_method", "S256")
                    .build();
            startActivity(new Intent(Intent.ACTION_VIEW, uri));
        } catch (Exception e) {
            setStatus("OAuth gagal dimulai: " + e.getMessage());
        }
    }

    private void handleOAuthIntent(Intent intent) {
        if (intent == null || intent.getData() == null) return;
        Uri data = intent.getData();
        if (!"bbyamusic".equalsIgnoreCase(data.getScheme()) || !"oauth".equalsIgnoreCase(data.getHost())) return;
        String error = data.getQueryParameter("error");
        if (error != null && !error.isEmpty()) {
            setStatus("Login dibatalkan/gagal: " + error);
            return;
        }
        String code = data.getQueryParameter("code");
        String state = data.getQueryParameter("state");
        String expected = prefs.getString("oauth_state", "");
        if (code == null || code.isEmpty() || expected.isEmpty() || !expected.equals(state)) {
            setStatus("Callback OAuth tidak valid.");
            return;
        }
        exchangeCode(code);
    }

    private void exchangeCode(String code) {
        if (busy) return;
        setBusy(true, "Menukar kode OAuth...");
        new Thread(() -> {
            try {
                String verifier = prefs.getString("oauth_pkce_verifier", "");
                String form = formEncode(new String[][]{
                        {"grant_type", "authorization_code"},
                        {"client_id", CLIENT_ID},
                        {"code", code},
                        {"code_verifier", verifier},
                        {"redirect_uri", REDIRECT_URI}
                });
                HttpResponse response = request("POST", TOKEN_URL, null, "application/x-www-form-urlencoded", form.getBytes(StandardCharsets.UTF_8));
                if (response.code < 200 || response.code >= 300) throw new Exception("Token HTTP " + response.code + ": " + compact(response.body));
                JSONObject json = new JSONObject(response.body);
                String access = json.optString("access_token", "");
                if (access.isEmpty()) throw new Exception("access_token kosong");
                int expires = Math.max(60, json.optInt("expires_in", 899));
                prefs.edit()
                        .putString("oauth_access_token", access)
                        .putLong("oauth_expires_at", System.currentTimeMillis() + expires * 1000L - 30000L)
                        .remove("oauth_pkce_verifier")
                        .remove("oauth_state")
                        .apply();
                loadUserInfo(access);
                setStatusFromThread("Login berhasil. Sekarang buka library atau SYNC UNDERGROUND.");
            } catch (Exception e) {
                prefs.edit().remove("oauth_access_token").remove("oauth_expires_at").apply();
                setStatusFromThread("Login OAuth gagal: " + e.getMessage());
            } finally {
                setBusyFromThread(false, null);
            }
        }).start();
    }

    private void loadUserInfo(String accessToken) throws Exception {
        HttpResponse response = request("GET", USERINFO_URL, accessToken, null, null);
        if (response.code < 200 || response.code >= 300) throw new Exception("UserInfo HTTP " + response.code);
        JSONObject json = new JSONObject(response.body);
        String userId = json.optString("sub", "");
        String username = json.optString("preferred_username", json.optString("name", "Roblox User"));
        if (userId.isEmpty()) throw new Exception("Roblox user ID tidak ditemukan");
        prefs.edit().putString("oauth_user_id", userId).putString("oauth_username", username).apply();
    }

    private void syncUnderground() {
        if (busy) return;
        String access = prefs.getString("oauth_access_token", "");
        long expiresAt = prefs.getLong("oauth_expires_at", 0L);
        String userId = prefs.getString("oauth_user_id", "");
        if (access.isEmpty() || userId.isEmpty() || System.currentTimeMillis() >= expiresAt) {
            prefs.edit().remove("oauth_access_token").remove("oauth_expires_at").apply();
            refreshUi();
            toast("Login Roblox dulu");
            return;
        }

        setBusy(true, "Membaca playlist Underground...");
        new Thread(() -> {
            try {
                String raw = prefs.getString(CATALOG_KEY, "");
                if (raw.isEmpty()) throw new Exception("Library APK kosong");
                JSONObject catalog = new JSONObject(raw);
                int revision = Math.max(1, catalog.optInt("revision", 1));
                JSONObject zone = findZone(catalog.optJSONArray("zones"), "underground");
                if (zone == null) throw new Exception("Area Underground tidak ditemukan");
                JSONArray tracks = zone.optJSONArray("tracks");
                if (tracks == null || tracks.length() == 0) throw new Exception("Playlist Underground masih kosong");

                Set<String> currentTrackIds = new HashSet<>();
                int synced = 0;
                int pending = 0;
                for (int i = 0; i < tracks.length(); i++) {
                    JSONObject track = tracks.optJSONObject(i);
                    if (track == null) continue;
                    String trackId = track.optString("id", "");
                    if (trackId.isEmpty()) continue;
                    currentTrackIds.add(trackId);
                    setStatusFromThread("Underground " + (i + 1) + "/" + tracks.length() + ": " + track.optString("title", "Track"));

                    String assetId = track.optString("robloxAssetId", "");
                    if (assetId.isEmpty()) {
                        UploadResult upload = uploadAudio(access, userId, track);
                        if (!upload.approved || upload.assetId.isEmpty()) {
                            track.put("uploadState", upload.moderation.isEmpty() ? "UPLOAD_FAILED" : upload.moderation);
                            track.put("syncState", "WAITING_ROBLOX");
                            pending++;
                            persistCatalog(catalog);
                            continue;
                        }
                        assetId = upload.assetId;
                        track.put("robloxAssetId", assetId);
                        track.put("uploadState", "READY");
                        persistCatalog(catalog);
                    }

                    JSONObject delta = new JSONObject();
                    delta.put("v", 1);
                    delta.put("z", "underground");
                    delta.put("op", "upsert");
                    delta.put("rev", revision);
                    delta.put("trackId", trackId);
                    delta.put("assetId", assetId);
                    delta.put("title", track.optString("title", "Imported Track"));
                    delta.put("artist", track.optString("artist", "Unknown Artist"));
                    delta.put("order", track.optInt("order", i + 1));
                    delta.put("enabled", track.optBoolean("enabled", true));
                    publishDelta(access, delta);
                    track.put("syncState", "SYNCED");
                    synced++;
                    persistCatalog(catalog);
                }

                Set<String> previous = readSyncedIds();
                for (String oldTrackId : previous) {
                    if (!currentTrackIds.contains(oldTrackId)) {
                        JSONObject delta = new JSONObject();
                        delta.put("v", 1);
                        delta.put("z", "underground");
                        delta.put("op", "delete");
                        delta.put("rev", revision);
                        delta.put("trackId", oldTrackId);
                        publishDelta(access, delta);
                    }
                }
                writeSyncedIds(currentTrackIds);
                persistCatalog(catalog);
                String msg = pending == 0
                        ? "SYNCED ✓ " + synced + " lagu Underground dikirim ke Roblox."
                        : "Sync sebagian: " + synced + " siap, " + pending + " masih menunggu Roblox/moderasi.";
                prefs.edit().putString("oauth_last_status", msg).apply();
                setStatusFromThread(msg);
            } catch (Exception e) {
                String msg = "Sync gagal: " + e.getMessage();
                prefs.edit().putString("oauth_last_status", msg).apply();
                setStatusFromThread(msg);
            } finally {
                setBusyFromThread(false, null);
            }
        }).start();
    }

    private UploadResult uploadAudio(String accessToken, String userId, JSONObject track) throws Exception {
        String path = track.optString("localPath", "");
        File file = path.isEmpty() ? null : new File(path);
        if (file == null || !file.exists() || file.length() <= 0) throw new Exception("File lokal tidak ditemukan: " + track.optString("sourceName", "track"));
        if (file.length() >= MAX_AUDIO_BYTES) throw new Exception("File terlalu besar (>20 MB)");
        String mime = track.optString("mimeType", "audio/mpeg");
        if (mime.isEmpty()) mime = "audio/mpeg";
        String title = cleanName(track.optString("title", "BBYA Underground Track"), 50);

        JSONObject requestJson = new JSONObject();
        requestJson.put("assetType", "Audio");
        requestJson.put("displayName", title);
        requestJson.put("description", "BBYA Music • Underground");
        JSONObject creator = new JSONObject();
        creator.put("userId", userId);
        JSONObject context = new JSONObject();
        context.put("creator", creator);
        requestJson.put("creationContext", context);

        String boundary = "----BBYAMusic" + System.currentTimeMillis();
        ByteArrayOutputStream body = new ByteArrayOutputStream();
        writeString(body, "--" + boundary + "\r\n");
        writeString(body, "Content-Disposition: form-data; name=\"request\"\r\n");
        writeString(body, "Content-Type: application/json; charset=UTF-8\r\n\r\n");
        writeString(body, requestJson.toString());
        writeString(body, "\r\n--" + boundary + "\r\n");
        writeString(body, "Content-Disposition: form-data; name=\"fileContent\"; filename=\"" + safeFilename(track.optString("sourceName", file.getName())) + "\"\r\n");
        writeString(body, "Content-Type: " + mime + "\r\n\r\n");
        try (FileInputStream in = new FileInputStream(file)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = in.read(buffer)) != -1) body.write(buffer, 0, read);
        }
        writeString(body, "\r\n--" + boundary + "--\r\n");

        HttpResponse create = request("POST", ASSET_CREATE_URL, accessToken, "multipart/form-data; boundary=" + boundary, body.toByteArray());
        if (create.code < 200 || create.code >= 300) throw new Exception("Upload HTTP " + create.code + ": " + compact(create.body));
        JSONObject created = new JSONObject(create.body);
        String operationPath = created.optString("path", "");
        if (!operationPath.startsWith("operations/")) throw new Exception("Operation upload tidak ditemukan");
        String operationId = operationPath.substring("operations/".length());

        for (int attempt = 1; attempt <= 36; attempt++) {
            Thread.sleep(5000L);
            HttpResponse poll = request("GET", ASSET_OPERATION_URL + urlEncode(operationId), accessToken, null, null);
            if (poll.code < 200 || poll.code >= 300) throw new Exception("Operation HTTP " + poll.code);
            JSONObject op = new JSONObject(poll.body);
            if (!op.optBoolean("done", false)) continue;
            if (op.has("error")) throw new Exception("Roblox upload error: " + compact(op.optJSONObject("error") == null ? op.optString("error") : op.optJSONObject("error").toString()));
            JSONObject response = op.optJSONObject("response");
            if (response == null) throw new Exception("Operation selesai tanpa response");
            String assetId = response.optString("assetId", "");
            JSONObject moderationResult = response.optJSONObject("moderationResult");
            String moderation = moderationResult == null ? "UNKNOWN" : moderationResult.optString("moderationState", "UNKNOWN");
            boolean approved = "MODERATION_STATE_APPROVED".equals(moderation) || "APPROVED".equals(moderation);
            return new UploadResult(assetId, moderation, approved);
        }
        throw new Exception("Timeout menunggu Roblox upload");
    }

    private void publishDelta(String accessToken, JSONObject delta) throws Exception {
        JSONObject body = new JSONObject();
        body.put("topic", TOPIC);
        body.put("message", delta.toString());
        HttpResponse response = request("POST", MESSAGE_URL, accessToken, "application/json", body.toString().getBytes(StandardCharsets.UTF_8));
        if (response.code < 200 || response.code >= 300) throw new Exception("Messaging HTTP " + response.code + ": " + compact(response.body));
    }

    private JSONObject findZone(JSONArray zones, String id) {
        if (zones == null) return null;
        for (int i = 0; i < zones.length(); i++) {
            JSONObject zone = zones.optJSONObject(i);
            if (zone != null && id.equals(zone.optString("id", ""))) return zone;
        }
        return null;
    }

    private synchronized void persistCatalog(JSONObject catalog) {
        prefs.edit().putString(CATALOG_KEY, catalog.toString()).apply();
    }

    private Set<String> readSyncedIds() {
        Set<String> out = new HashSet<>();
        try {
            JSONArray json = new JSONArray(prefs.getString("underground_synced_ids", "[]"));
            for (int i = 0; i < json.length(); i++) {
                String id = json.optString(i, "");
                if (!id.isEmpty()) out.add(id);
            }
        } catch (Exception ignored) {}
        return out;
    }

    private void writeSyncedIds(Set<String> ids) {
        JSONArray array = new JSONArray();
        for (String id : ids) array.put(id);
        prefs.edit().putString("underground_synced_ids", array.toString()).apply();
    }

    private HttpResponse request(String method, String url, String bearer, String contentType, byte[] body) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(20000);
        connection.setReadTimeout(45000);
        connection.setUseCaches(false);
        connection.setRequestProperty("Accept", "application/json");
        if (bearer != null && !bearer.isEmpty()) connection.setRequestProperty("Authorization", "Bearer " + bearer);
        if (body != null) {
            connection.setDoOutput(true);
            if (contentType != null) connection.setRequestProperty("Content-Type", contentType);
            connection.setFixedLengthStreamingMode(body.length);
            try (OutputStream out = connection.getOutputStream()) {
                out.write(body);
                out.flush();
            }
        }
        int code = connection.getResponseCode();
        InputStream stream = code >= 200 && code < 400 ? connection.getInputStream() : connection.getErrorStream();
        String text = readAll(stream);
        connection.disconnect();
        return new HttpResponse(code, text);
    }

    private String readAll(InputStream input) throws Exception {
        if (input == null) return "";
        StringBuilder out = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) out.append(line);
        }
        return out.toString();
    }

    private String formEncode(String[][] values) throws Exception {
        StringBuilder out = new StringBuilder();
        for (String[] pair : values) {
            if (out.length() > 0) out.append('&');
            out.append(URLEncoder.encode(pair[0], "UTF-8"));
            out.append('=');
            out.append(URLEncoder.encode(pair[1], "UTF-8"));
        }
        return out.toString();
    }

    private String randomUrlSafe(int bytes) {
        byte[] data = new byte[bytes];
        new SecureRandom().nextBytes(data);
        return base64Url(data);
    }

    private String base64Url(byte[] data) {
        return Base64.encodeToString(data, Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
    }

    private String urlEncode(String value) throws Exception {
        return URLEncoder.encode(value, "UTF-8").replace("+", "%20");
    }

    private void writeString(OutputStream out, String text) throws Exception {
        out.write(text.getBytes(StandardCharsets.UTF_8));
    }

    private String safeFilename(String name) {
        if (name == null || name.isEmpty()) return "track.mp3";
        return name.replaceAll("[\\r\\n\\\"\\\\]", "_");
    }

    private String cleanName(String value, int max) {
        String text = value == null ? "" : value.replaceAll("[\\r\\n\\t]+", " ").trim();
        if (text.isEmpty()) text = "BBYA Underground Track";
        return text.length() <= max ? text : text.substring(0, max);
    }

    private String compact(String text) {
        if (text == null) return "";
        String one = text.replaceAll("\\s+", " ").trim();
        return one.length() <= 220 ? one : one.substring(0, 220) + "...";
    }

    private void setBusy(boolean value, String status) {
        busy = value;
        if (status != null) statusText.setText("Status: " + status);
        refreshUi();
    }

    private void setBusyFromThread(boolean value, String status) {
        runOnUiThread(() -> setBusy(value, status));
    }

    private void setStatus(String status) {
        prefs.edit().putString("oauth_last_status", status).apply();
        statusText.setText("Status: " + status);
    }

    private void setStatusFromThread(String status) {
        prefs.edit().putString("oauth_last_status", status).apply();
        runOnUiThread(() -> statusText.setText("Status: " + status));
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

    private Button primaryButton(String text) { return button(text, Color.rgb(196, 151, 63), Color.BLACK); }
    private Button secondaryButton(String text) { return button(text, Color.rgb(45, 48, 57), Color.WHITE); }

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

    private View space(int height) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(1, dp(height)));
        return v;
    }

    private LinearLayout.LayoutParams matchWidth() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private void toast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    private static class HttpResponse {
        final int code;
        final String body;
        HttpResponse(int code, String body) { this.code = code; this.body = body == null ? "" : body; }
    }

    private static class UploadResult {
        final String assetId;
        final String moderation;
        final boolean approved;
        UploadResult(String assetId, String moderation, boolean approved) {
            this.assetId = assetId == null ? "" : assetId;
            this.moderation = moderation == null ? "" : moderation;
            this.approved = approved;
        }
    }
}

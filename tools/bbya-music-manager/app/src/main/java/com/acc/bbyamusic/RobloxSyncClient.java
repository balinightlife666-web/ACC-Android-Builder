package com.acc.bbyamusic;

import android.net.Uri;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Locale;

/**
 * Direct Roblox Open Cloud client for BBYA Music Manager.
 *
 * Security contract:
 * - Mobile/public OAuth client only.
 * - PKCE is required.
 * - No Roblox API key or client secret is stored in the APK.
 * - Asset IDs remain internal integration data.
 */
public final class RobloxSyncClient {
    public static final String AUTHORIZE_URL = "https://apis.roblox.com/oauth/v1/authorize";
    public static final String TOKEN_URL = "https://apis.roblox.com/oauth/v1/token";
    public static final String ASSET_CREATE_URL = "https://apis.roblox.com/assets/v1/assets";
    public static final String OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/";
    public static final String UNIVERSE_MESSAGE_URL = "https://apis.roblox.com/cloud/v2/universes/%s:publishMessage";
    public static final String REQUIRED_SCOPES = "openid profile asset:read asset:write universe-messaging-service:publish";
    public static final String UNDERGROUND_TOPIC = "BBYA_MUSIC_UNDERGROUND_V1";

    public static final class Pkce {
        public final String verifier;
        public final String challenge;
        public final String state;

        private Pkce(String verifier, String challenge, String state) {
            this.verifier = verifier;
            this.challenge = challenge;
            this.state = state;
        }
    }

    public static final class Tokens {
        public final String accessToken;
        public final String refreshToken;
        public final long expiresInSeconds;

        private Tokens(String accessToken, String refreshToken, long expiresInSeconds) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
            this.expiresInSeconds = expiresInSeconds;
        }
    }

    public static final class AssetResult {
        public final String assetId;
        public final String moderationState;

        private AssetResult(String assetId, String moderationState) {
            this.assetId = assetId;
            this.moderationState = moderationState;
        }
    }

    public static Pkce newPkce() throws Exception {
        SecureRandom random = new SecureRandom();
        byte[] verifierBytes = new byte[48];
        byte[] stateBytes = new byte[24];
        random.nextBytes(verifierBytes);
        random.nextBytes(stateBytes);
        String verifier = base64Url(verifierBytes);
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        String challenge = base64Url(digest.digest(verifier.getBytes(StandardCharsets.US_ASCII)));
        String state = base64Url(stateBytes);
        return new Pkce(verifier, challenge, state);
    }

    public static Uri buildAuthorizeUri(String clientId, String redirectUri, Pkce pkce) {
        if (blank(clientId)) throw new IllegalArgumentException("OAuth client ID belum dikonfigurasi");
        return Uri.parse(AUTHORIZE_URL).buildUpon()
                .appendQueryParameter("client_id", clientId)
                .appendQueryParameter("redirect_uri", redirectUri)
                .appendQueryParameter("scope", REQUIRED_SCOPES)
                .appendQueryParameter("response_type", "code")
                .appendQueryParameter("prompt", "login consent")
                .appendQueryParameter("code_challenge", pkce.challenge)
                .appendQueryParameter("code_challenge_method", "S256")
                .appendQueryParameter("state", pkce.state)
                .build();
    }

    public static Tokens exchangeCode(String clientId, String redirectUri, String code, String verifier) throws Exception {
        String body = form("grant_type", "authorization_code") + "&" +
                form("client_id", clientId) + "&" +
                form("code", code) + "&" +
                form("code_verifier", verifier) + "&" +
                form("redirect_uri", redirectUri);
        JSONObject json = requestJson("POST", TOKEN_URL, null,
                "application/x-www-form-urlencoded", body.getBytes(StandardCharsets.UTF_8));
        String access = json.optString("access_token", "");
        if (blank(access)) throw new IllegalStateException("Roblox OAuth tidak mengembalikan access token");
        return new Tokens(access, json.optString("refresh_token", ""), json.optLong("expires_in", 899));
    }

    public static Tokens refresh(String clientId, String refreshToken) throws Exception {
        String body = form("grant_type", "refresh_token") + "&" +
                form("client_id", clientId) + "&" +
                form("refresh_token", refreshToken);
        JSONObject json = requestJson("POST", TOKEN_URL, null,
                "application/x-www-form-urlencoded", body.getBytes(StandardCharsets.UTF_8));
        String access = json.optString("access_token", "");
        if (blank(access)) throw new IllegalStateException("Refresh token gagal");
        return new Tokens(access, json.optString("refresh_token", ""), json.optLong("expires_in", 899));
    }

    public static AssetResult uploadAudio(String accessToken, File audioFile, String mimeType,
                                          String title, String creatorType, String creatorId) throws Exception {
        if (audioFile == null || !audioFile.isFile()) throw new IllegalArgumentException("File audio tidak ditemukan");
        if (audioFile.length() <= 0 || audioFile.length() >= 20L * 1024L * 1024L) {
            throw new IllegalArgumentException("Ukuran audio harus di bawah 20 MB");
        }
        if (blank(creatorId) || !creatorId.matches("[0-9]+")) throw new IllegalArgumentException("Creator ID tidak valid");
        String creatorKey = "group".equalsIgnoreCase(creatorType) ? "groupId" : "userId";

        JSONObject creator = new JSONObject().put(creatorKey, creatorId);
        JSONObject request = new JSONObject()
                .put("assetType", "Audio")
                .put("displayName", safeTitle(title))
                .put("description", "BBYA Music")
                .put("creationContext", new JSONObject().put("creator", creator));

        String boundary = "----BBYAMusic" + System.nanoTime();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        writePart(out, boundary, "request", null, "application/json", request.toString().getBytes(StandardCharsets.UTF_8));
        byte[] audio = readAll(audioFile);
        writePart(out, boundary, "fileContent", audioFile.getName(), mimeType, audio);
        out.write(("--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8));

        JSONObject create = requestJson("POST", ASSET_CREATE_URL, accessToken,
                "multipart/form-data; boundary=" + boundary, out.toByteArray());
        String path = create.optString("path", "");
        if (!path.startsWith("operations/")) throw new IllegalStateException("Roblox tidak mengembalikan operation path");
        String operationId = path.substring("operations/".length());

        for (int i = 0; i < 36; i++) {
            JSONObject op = requestJson("GET", OPERATION_URL + operationId, accessToken, null, null);
            if (op.optBoolean("done", false)) {
                if (op.has("error")) throw new IllegalStateException("Roblox asset operation gagal: " + op.opt("error"));
                JSONObject response = op.optJSONObject("response");
                if (response == null) throw new IllegalStateException("Operation selesai tanpa response");
                String assetId = String.valueOf(response.optLong("assetId", 0));
                if ("0".equals(assetId)) throw new IllegalStateException("Operation selesai tanpa Asset ID");
                JSONObject moderation = response.optJSONObject("moderationResult");
                return new AssetResult(assetId, moderation == null ? "UNKNOWN" : moderation.optString("moderationState", "UNKNOWN"));
            }
            Thread.sleep(5000L);
        }
        throw new IllegalStateException("Timeout menunggu Roblox asset operation");
    }

    /** Publish one small delta; Roblox MessagingService has a 1 KiB message cap. */
    public static void publishUndergroundUpsert(String accessToken, String universeId,
                                                String trackId, String title, String artist,
                                                String assetId, int order, boolean enabled, int revision) throws Exception {
        JSONObject delta = new JSONObject()
                .put("v", 1)
                .put("z", "underground")
                .put("op", "upsert")
                .put("trackId", limit(trackId, 80))
                .put("title", limit(title, 160))
                .put("artist", limit(artist, 100))
                .put("assetId", assetId)
                .put("order", Math.max(1, order))
                .put("enabled", enabled)
                .put("rev", Math.max(1, revision));
        String message = delta.toString();
        if (message.getBytes(StandardCharsets.UTF_8).length > 1000) {
            throw new IllegalArgumentException("Delta playlist terlalu besar untuk Roblox MessagingService");
        }
        JSONObject envelope = new JSONObject().put("topic", UNDERGROUND_TOPIC).put("message", message);
        requestEmptyOk("POST", String.format(Locale.US, UNIVERSE_MESSAGE_URL, universeId), accessToken,
                "application/json", envelope.toString().getBytes(StandardCharsets.UTF_8));
    }

    public static void publishUndergroundDelete(String accessToken, String universeId,
                                                String trackId, int revision) throws Exception {
        JSONObject delta = new JSONObject()
                .put("v", 1).put("z", "underground").put("op", "delete")
                .put("trackId", limit(trackId, 80)).put("rev", Math.max(1, revision));
        JSONObject envelope = new JSONObject().put("topic", UNDERGROUND_TOPIC).put("message", delta.toString());
        requestEmptyOk("POST", String.format(Locale.US, UNIVERSE_MESSAGE_URL, universeId), accessToken,
                "application/json", envelope.toString().getBytes(StandardCharsets.UTF_8));
    }

    private static JSONObject requestJson(String method, String url, String accessToken,
                                          String contentType, byte[] body) throws Exception {
        HttpURLConnection conn = open(method, url, accessToken, contentType, body);
        int code = conn.getResponseCode();
        String response = readStream(code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream());
        conn.disconnect();
        if (code < 200 || code >= 300) throw new IllegalStateException("HTTP " + code + ": " + response);
        return blank(response) ? new JSONObject() : new JSONObject(response);
    }

    private static void requestEmptyOk(String method, String url, String accessToken,
                                       String contentType, byte[] body) throws Exception {
        HttpURLConnection conn = open(method, url, accessToken, contentType, body);
        int code = conn.getResponseCode();
        String response = readStream(code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream());
        conn.disconnect();
        if (code < 200 || code >= 300) throw new IllegalStateException("HTTP " + code + ": " + response);
    }

    private static HttpURLConnection open(String method, String url, String accessToken,
                                          String contentType, byte[] body) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod(method);
        conn.setConnectTimeout(15000);
        conn.setReadTimeout(30000);
        conn.setRequestProperty("Accept", "application/json");
        if (!blank(accessToken)) conn.setRequestProperty("Authorization", "Bearer " + accessToken);
        if (!blank(contentType)) conn.setRequestProperty("Content-Type", contentType);
        if (body != null) {
            conn.setDoOutput(true);
            conn.setFixedLengthStreamingMode(body.length);
            try (OutputStream os = conn.getOutputStream()) { os.write(body); }
        }
        return conn;
    }

    private static void writePart(ByteArrayOutputStream out, String boundary, String name,
                                  String filename, String contentType, byte[] data) throws Exception {
        out.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
        String disposition = "Content-Disposition: form-data; name=\"" + name + "\"";
        if (filename != null) disposition += "; filename=\"" + filename.replace("\"", "") + "\"";
        out.write((disposition + "\r\n").getBytes(StandardCharsets.UTF_8));
        out.write(("Content-Type: " + contentType + "\r\n\r\n").getBytes(StandardCharsets.UTF_8));
        out.write(data);
        out.write("\r\n".getBytes(StandardCharsets.UTF_8));
    }

    private static byte[] readAll(File file) throws Exception {
        try (InputStream in = new FileInputStream(file); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buf = new byte[64 * 1024];
            int n;
            while ((n = in.read(buf)) != -1) out.write(buf, 0, n);
            return out.toByteArray();
        }
    }

    private static String readStream(InputStream in) throws Exception {
        if (in == null) return "";
        StringBuilder sb = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
        }
        return sb.toString();
    }

    private static String form(String key, String value) throws Exception {
        return java.net.URLEncoder.encode(key, "UTF-8") + "=" + java.net.URLEncoder.encode(value == null ? "" : value, "UTF-8");
    }

    private static String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String safeTitle(String title) {
        String t = blank(title) ? "BBYA Music Track" : title.trim();
        return limit(t, 100);
    }

    private static String limit(String value, int max) {
        if (value == null) return "";
        return value.length() <= max ? value : value.substring(0, max);
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }

    private RobloxSyncClient() {}
}

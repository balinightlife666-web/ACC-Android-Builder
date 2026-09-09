package com.amstudio.distribution.network;

import android.content.ContentResolver;
import android.net.Uri;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public final class ApiClient {
    private final ContentResolver resolver;
    private final String baseUrl;
    private final String bearerToken;

    public ApiClient(ContentResolver resolver, String baseUrl, String bearerToken) {
        this.resolver = resolver;
        this.baseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
        this.bearerToken = bearerToken == null ? "" : bearerToken.trim();
        if (this.baseUrl.isEmpty()) throw new IllegalArgumentException("AM STUDIO API is not configured");
        if (this.bearerToken.isEmpty()) throw new IllegalArgumentException("AM STUDIO session token is missing");
    }

    public JSONObject getMe() throws Exception {
        return requestJson("GET", "/v1/me", null);
    }

    public JSONObject createRelease(JSONObject release) throws Exception {
        return requestJson("POST", "/v1/releases", release == null ? new JSONObject() : release);
    }

    public JSONObject patchRelease(String releaseId, JSONObject patch) throws Exception {
        return requestJson("PATCH", "/v1/releases/" + pathSegment(releaseId), patch == null ? new JSONObject() : patch);
    }

    public JSONObject createUploadSession(String kind, String fileName, String mime, long sizeBytes, String checksum) throws Exception {
        JSONObject body = new JSONObject();
        body.put("kind", kind);
        body.put("fileName", fileName);
        body.put("mime", mime);
        body.put("sizeBytes", sizeBytes);
        body.put("checksum", checksum);
        return requestJson("POST", "/v1/uploads", body);
    }

    public JSONObject uploadContent(String targetPath, Uri uri, long sizeBytes) throws Exception {
        HttpURLConnection connection = open("PUT", targetPath);
        connection.setRequestProperty("Content-Type", "application/octet-stream");
        connection.setDoOutput(true);
        connection.setFixedLengthStreamingMode(sizeBytes);
        try (InputStream input = resolver.openInputStream(uri); OutputStream output = connection.getOutputStream()) {
            if (input == null) throw new IllegalStateException("Selected file cannot be opened");
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = input.read(buffer)) != -1) output.write(buffer, 0, read);
        }
        return readJson(connection);
    }

    public JSONObject completeUpload(String assetId, long durationMs, int width, int height) throws Exception {
        JSONObject body = new JSONObject();
        body.put("durationMs", durationMs);
        body.put("width", width);
        body.put("height", height);
        return requestJson("POST", "/v1/uploads/" + pathSegment(assetId) + "/complete", body);
    }

    public JSONObject preflight(String releaseId) throws Exception {
        return requestJson("POST", "/v1/releases/" + pathSegment(releaseId) + "/preflight", new JSONObject());
    }

    public JSONObject submitReview(String releaseId) throws Exception {
        return requestJson("POST", "/v1/releases/" + pathSegment(releaseId) + "/submit-review", new JSONObject());
    }

    private JSONObject requestJson(String method, String path, JSONObject body) throws Exception {
        HttpURLConnection connection = open(method, path);
        if (body != null) {
            byte[] data = body.toString().getBytes(StandardCharsets.UTF_8);
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            connection.setDoOutput(true);
            connection.setFixedLengthStreamingMode(data.length);
            try (OutputStream output = connection.getOutputStream()) {
                output.write(data);
            }
        }
        return readJson(connection);
    }

    private HttpURLConnection open(String method, String path) throws Exception {
        String normalizedPath = path.startsWith("/") ? path : "/" + path;
        HttpURLConnection connection = (HttpURLConnection) new URL(baseUrl + normalizedPath).openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(15_000);
        connection.setReadTimeout(60_000);
        connection.setUseCaches(false);
        connection.setRequestProperty("Accept", "application/json");
        connection.setRequestProperty("Authorization", "Bearer " + bearerToken);
        connection.setRequestProperty("X-AM-Client", "android");
        return connection;
    }

    private JSONObject readJson(HttpURLConnection connection) throws Exception {
        int status = connection.getResponseCode();
        InputStream stream = status >= 200 && status < 300 ? connection.getInputStream() : connection.getErrorStream();
        String text = stream == null ? "" : readAll(stream);
        JSONObject json = text.isEmpty() ? new JSONObject() : new JSONObject(text);
        if (status < 200 || status >= 300) {
            JSONObject error = json.optJSONObject("error");
            String code = error == null ? "HTTP_" + status : error.optString("code", "HTTP_" + status);
            String message = error == null ? "AM STUDIO API request failed" : error.optString("message", code);
            throw new ApiException(status, code, message);
        }
        return json;
    }

    private static String readAll(InputStream input) throws Exception {
        try (InputStream stream = input; ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[16 * 1024];
            int read;
            while ((read = stream.read(buffer)) != -1) output.write(buffer, 0, read);
            return output.toString(StandardCharsets.UTF_8.name());
        }
    }

    private static String pathSegment(String value) {
        String clean = value == null ? "" : value.trim();
        if (!clean.matches("[A-Za-z0-9_-]+")) throw new IllegalArgumentException("Invalid resource id");
        return clean;
    }

    public static final class ApiException extends Exception {
        public final int status;
        public final String code;

        public ApiException(int status, String code, String message) {
            super(message);
            this.status = status;
            this.code = code;
        }
    }
}

package com.acc.bbyamusic;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

final class CreatorResolver {
    private CreatorResolver() {}

    static JSONObject resolveUniverseCreator(String universeId, String fallbackUserId) throws Exception {
        String endpoint = "https://games.roblox.com/v1/games?universeIds=" + universeId;
        HttpURLConnection conn = (HttpURLConnection) new URL(endpoint).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(15000);
        conn.setReadTimeout(15000);
        conn.setRequestProperty("Accept", "application/json");

        int code = conn.getResponseCode();
        InputStream stream = code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream();
        StringBuilder body = new StringBuilder();
        if (stream != null) {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) body.append(line);
            }
        }
        conn.disconnect();
        if (code < 200 || code >= 300) {
            throw new Exception("Creator lookup HTTP " + code);
        }

        JSONObject root = new JSONObject(body.toString());
        JSONArray data = root.optJSONArray("data");
        if (data == null || data.length() == 0) throw new Exception("Creator BBYA tidak ditemukan");
        JSONObject game = data.getJSONObject(0);
        JSONObject owner = game.optJSONObject("creator");
        if (owner == null) throw new Exception("Creator BBYA kosong");

        String type = owner.optString("type", "");
        String id = String.valueOf(owner.optLong("id", 0L));
        if ("Group".equalsIgnoreCase(type) && !"0".equals(id)) {
            JSONObject creator = new JSONObject();
            creator.put("groupId", id);
            return creator;
        }

        if (fallbackUserId == null || fallbackUserId.isEmpty()) {
            throw new Exception("Fallback Roblox user ID kosong");
        }
        JSONObject creator = new JSONObject();
        creator.put("userId", fallbackUserId);
        return creator;
    }
}

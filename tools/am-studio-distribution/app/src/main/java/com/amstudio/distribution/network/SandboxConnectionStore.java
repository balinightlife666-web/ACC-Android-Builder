package com.amstudio.distribution.network;

import android.content.Context;
import android.content.SharedPreferences;

public final class SandboxConnectionStore {
    private static final String PREFS = "am_studio_sandbox_connection";
    private static final String KEY_BASE_URL = "base_url";

    private final SharedPreferences preferences;
    private volatile String sessionToken = "";

    public SandboxConnectionStore(Context context) {
        preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public String getBaseUrl() {
        return preferences.getString(KEY_BASE_URL, "");
    }

    public void setBaseUrl(String value) {
        String normalized = ApiConfig.normalizeBaseUrl(value);
        preferences.edit().putString(KEY_BASE_URL, normalized).apply();
    }

    public String getSessionToken() {
        return sessionToken;
    }

    public void setSessionToken(String value) {
        sessionToken = value == null ? "" : value.trim();
    }

    public void clearSession() {
        sessionToken = "";
    }

    public boolean isConfigured() {
        return !getBaseUrl().isEmpty() && !sessionToken.isEmpty();
    }
}

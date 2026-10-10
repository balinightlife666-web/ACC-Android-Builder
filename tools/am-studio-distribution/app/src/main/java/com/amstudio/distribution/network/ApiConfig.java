package com.amstudio.distribution.network;

import android.net.Uri;

public final class ApiConfig {
    private ApiConfig() {}

    public static String normalizeBaseUrl(String value) {
        String clean = value == null ? "" : value.trim();
        while (clean.endsWith("/")) clean = clean.substring(0, clean.length() - 1);
        if (clean.isEmpty()) return "";
        Uri uri = Uri.parse(clean);
        String scheme = uri.getScheme();
        String host = uri.getHost();
        if (scheme == null || host == null || host.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid AM STUDIO API URL");
        }
        if (!"https".equalsIgnoreCase(scheme)) {
            throw new IllegalArgumentException("AM STUDIO API requires HTTPS");
        }
        return clean;
    }
}

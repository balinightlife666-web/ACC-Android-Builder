package com.amstudio.distribution.network;

import android.content.ContentResolver;
import android.net.Uri;

import java.io.InputStream;
import java.security.MessageDigest;

public final class Hashing {
    private Hashing() {}

    public static String sha256(ContentResolver resolver, Uri uri) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream input = resolver.openInputStream(uri)) {
            if (input == null) throw new IllegalStateException("File cannot be opened");
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = input.read(buffer)) != -1) {
                digest.update(buffer, 0, read);
            }
        }
        byte[] bytes = digest.digest();
        StringBuilder hex = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) hex.append(String.format("%02x", b));
        return "sha256:" + hex;
    }
}

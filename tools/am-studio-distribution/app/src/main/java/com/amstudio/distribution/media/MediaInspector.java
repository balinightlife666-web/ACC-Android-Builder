package com.amstudio.distribution.media;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.provider.OpenableColumns;

import java.io.InputStream;

public final class MediaInspector {
    private MediaInspector() {}

    public static FileInfo inspectAudio(Context context, Uri uri) throws Exception {
        ContentResolver resolver = context.getContentResolver();
        Basic basic = basic(resolver, uri);
        long durationMs = 0L;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(context, uri);
            String duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
            if (duration != null && !duration.isEmpty()) durationMs = Long.parseLong(duration);
        } finally {
            try { retriever.release(); } catch (Exception ignored) {}
        }
        return new FileInfo(uri.toString(), basic.name, basic.mime, basic.sizeBytes, durationMs, 0, 0);
    }

    public static FileInfo inspectArtwork(Context context, Uri uri) throws Exception {
        ContentResolver resolver = context.getContentResolver();
        Basic basic = basic(resolver, uri);
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        try (InputStream input = resolver.openInputStream(uri)) {
            if (input == null) throw new IllegalStateException("Artwork tidak dapat dibaca");
            BitmapFactory.decodeStream(input, null, options);
        }
        return new FileInfo(uri.toString(), basic.name, basic.mime, basic.sizeBytes, 0L,
                Math.max(0, options.outWidth), Math.max(0, options.outHeight));
    }

    private static Basic basic(ContentResolver resolver, Uri uri) {
        String name = "";
        long size = 0L;
        try (Cursor cursor = resolver.query(uri, new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE}, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) {
                int nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                int sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE);
                if (nameIndex >= 0) name = cursor.getString(nameIndex);
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex);
            }
        } catch (Exception ignored) {}
        String mime = resolver.getType(uri);
        return new Basic(name == null ? "" : name, mime == null ? "" : mime, Math.max(0L, size));
    }

    public static final class FileInfo {
        public final String uri;
        public final String name;
        public final String mime;
        public final long sizeBytes;
        public final long durationMs;
        public final int width;
        public final int height;

        public FileInfo(String uri, String name, String mime, long sizeBytes, long durationMs, int width, int height) {
            this.uri = uri == null ? "" : uri;
            this.name = name == null ? "" : name;
            this.mime = mime == null ? "" : mime;
            this.sizeBytes = Math.max(0L, sizeBytes);
            this.durationMs = Math.max(0L, durationMs);
            this.width = Math.max(0, width);
            this.height = Math.max(0, height);
        }
    }

    private static final class Basic {
        final String name;
        final String mime;
        final long sizeBytes;
        Basic(String name, String mime, long sizeBytes) {
            this.name = name;
            this.mime = mime;
            this.sizeBytes = sizeBytes;
        }
    }
}

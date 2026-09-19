package com.arda.musicplayer;

import java.util.Objects;

public final class Track {
    public final String uri;
    public final String title;

    public Track(String uri, String title) {
        this.uri = uri;
        this.title = title == null || title.trim().isEmpty() ? "Unknown track" : title.trim();
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) return true;
        if (!(other instanceof Track)) return false;
        Track track = (Track) other;
        return Objects.equals(uri, track.uri);
    }

    @Override
    public int hashCode() {
        return Objects.hash(uri);
    }
}

package com.amstudio.distribution.domain;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public final class ReleaseDraft {
    private String id;
    private String backendReleaseId;
    private String title;
    private String artistName;
    private String labelName;
    private String releaseType;
    private String genre;
    private String releaseDate;
    private String songwriter;
    private String composer;
    private String copyrightOwner;
    private String audioUri;
    private String audioName;
    private String audioMime;
    private long audioSizeBytes;
    private long audioDurationMs;
    private String artworkUri;
    private String artworkName;
    private String artworkMime;
    private long artworkSizeBytes;
    private int artworkWidth;
    private int artworkHeight;
    private boolean explicitContent;
    private boolean rightsConfirmed;
    private ReleaseStatus status;
    private long updatedAt;
    private final List<String> destinations;

    public ReleaseDraft() {
        this.id = "rel_" + UUID.randomUUID().toString().replace("-", "");
        this.backendReleaseId = "";
        this.title = "";
        this.artistName = "";
        this.labelName = "AM STUDIO";
        this.releaseType = "Single";
        this.genre = "";
        this.releaseDate = "";
        this.songwriter = "";
        this.composer = "";
        this.copyrightOwner = "";
        this.audioUri = "";
        this.audioName = "";
        this.audioMime = "";
        this.artworkUri = "";
        this.artworkName = "";
        this.artworkMime = "";
        this.status = ReleaseStatus.DRAFT;
        this.updatedAt = System.currentTimeMillis();
        this.destinations = new ArrayList<>();
    }

    public String getId() { return id; }
    public String getBackendReleaseId() { return backendReleaseId; }
    public String getTitle() { return title; }
    public String getArtistName() { return artistName; }
    public String getLabelName() { return labelName; }
    public String getReleaseType() { return releaseType; }
    public String getGenre() { return genre; }
    public String getReleaseDate() { return releaseDate; }
    public String getSongwriter() { return songwriter; }
    public String getComposer() { return composer; }
    public String getCopyrightOwner() { return copyrightOwner; }
    public String getAudioUri() { return audioUri; }
    public String getAudioName() { return audioName; }
    public String getAudioMime() { return audioMime; }
    public long getAudioSizeBytes() { return audioSizeBytes; }
    public long getAudioDurationMs() { return audioDurationMs; }
    public String getArtworkUri() { return artworkUri; }
    public String getArtworkName() { return artworkName; }
    public String getArtworkMime() { return artworkMime; }
    public long getArtworkSizeBytes() { return artworkSizeBytes; }
    public int getArtworkWidth() { return artworkWidth; }
    public int getArtworkHeight() { return artworkHeight; }
    public boolean isExplicitContent() { return explicitContent; }
    public boolean isRightsConfirmed() { return rightsConfirmed; }
    public ReleaseStatus getStatus() { return status; }
    public long getUpdatedAt() { return updatedAt; }
    public List<String> getDestinations() { return new ArrayList<>(destinations); }

    public void setBackendReleaseId(String value) { backendReleaseId = clean(value); touch(); }
    public void setTitle(String value) { title = clean(value); touch(); }
    public void setArtistName(String value) { artistName = clean(value); touch(); }
    public void setLabelName(String value) { labelName = clean(value); touch(); }
    public void setReleaseType(String value) { releaseType = clean(value); touch(); }
    public void setGenre(String value) { genre = clean(value); touch(); }
    public void setReleaseDate(String value) { releaseDate = clean(value); touch(); }
    public void setSongwriter(String value) { songwriter = clean(value); touch(); }
    public void setComposer(String value) { composer = clean(value); touch(); }
    public void setCopyrightOwner(String value) { copyrightOwner = clean(value); touch(); }
    public void setExplicitContent(boolean value) { explicitContent = value; touch(); }
    public void setRightsConfirmed(boolean value) { rightsConfirmed = value; touch(); }
    public void setStatus(ReleaseStatus value) { status = value == null ? ReleaseStatus.DRAFT : value; touch(); }

    public void setAudio(String uri, String name, String mime, long sizeBytes, long durationMs) {
        audioUri = clean(uri);
        audioName = clean(name);
        audioMime = clean(mime);
        audioSizeBytes = Math.max(0L, sizeBytes);
        audioDurationMs = Math.max(0L, durationMs);
        touch();
    }

    public void setArtwork(String uri, String name, String mime, long sizeBytes, int width, int height) {
        artworkUri = clean(uri);
        artworkName = clean(name);
        artworkMime = clean(mime);
        artworkSizeBytes = Math.max(0L, sizeBytes);
        artworkWidth = Math.max(0, width);
        artworkHeight = Math.max(0, height);
        touch();
    }

    public void setDestinations(List<String> values) {
        destinations.clear();
        if (values != null) {
            for (String value : values) {
                String clean = clean(value);
                if (!clean.isEmpty() && !destinations.contains(clean)) destinations.add(clean);
            }
        }
        touch();
    }

    public JSONObject toJson() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("id", id);
        json.put("backendReleaseId", backendReleaseId);
        json.put("title", title);
        json.put("artistName", artistName);
        json.put("labelName", labelName);
        json.put("releaseType", releaseType);
        json.put("genre", genre);
        json.put("releaseDate", releaseDate);
        json.put("songwriter", songwriter);
        json.put("composer", composer);
        json.put("copyrightOwner", copyrightOwner);
        json.put("audioUri", audioUri);
        json.put("audioName", audioName);
        json.put("audioMime", audioMime);
        json.put("audioSizeBytes", audioSizeBytes);
        json.put("audioDurationMs", audioDurationMs);
        json.put("artworkUri", artworkUri);
        json.put("artworkName", artworkName);
        json.put("artworkMime", artworkMime);
        json.put("artworkSizeBytes", artworkSizeBytes);
        json.put("artworkWidth", artworkWidth);
        json.put("artworkHeight", artworkHeight);
        json.put("explicitContent", explicitContent);
        json.put("rightsConfirmed", rightsConfirmed);
        json.put("status", status.name());
        json.put("updatedAt", updatedAt);
        JSONArray stores = new JSONArray();
        for (String destination : destinations) stores.put(destination);
        json.put("destinations", stores);
        return json;
    }

    public static ReleaseDraft fromJson(JSONObject json) {
        ReleaseDraft draft = new ReleaseDraft();
        if (json == null) return draft;
        draft.id = json.optString("id", draft.id);
        draft.backendReleaseId = json.optString("backendReleaseId", "");
        draft.title = json.optString("title", "");
        draft.artistName = json.optString("artistName", "");
        draft.labelName = json.optString("labelName", "AM STUDIO");
        draft.releaseType = json.optString("releaseType", "Single");
        draft.genre = json.optString("genre", "");
        draft.releaseDate = json.optString("releaseDate", "");
        draft.songwriter = json.optString("songwriter", "");
        draft.composer = json.optString("composer", "");
        draft.copyrightOwner = json.optString("copyrightOwner", "");
        draft.audioUri = json.optString("audioUri", "");
        draft.audioName = json.optString("audioName", "");
        draft.audioMime = json.optString("audioMime", "");
        draft.audioSizeBytes = json.optLong("audioSizeBytes", 0L);
        draft.audioDurationMs = json.optLong("audioDurationMs", 0L);
        draft.artworkUri = json.optString("artworkUri", "");
        draft.artworkName = json.optString("artworkName", "");
        draft.artworkMime = json.optString("artworkMime", "");
        draft.artworkSizeBytes = json.optLong("artworkSizeBytes", 0L);
        draft.artworkWidth = json.optInt("artworkWidth", 0);
        draft.artworkHeight = json.optInt("artworkHeight", 0);
        draft.explicitContent = json.optBoolean("explicitContent", false);
        draft.rightsConfirmed = json.optBoolean("rightsConfirmed", false);
        draft.status = ReleaseStatus.safeValueOf(json.optString("status", "DRAFT"));
        draft.updatedAt = json.optLong("updatedAt", System.currentTimeMillis());
        draft.destinations.clear();
        JSONArray stores = json.optJSONArray("destinations");
        if (stores != null) {
            for (int i = 0; i < stores.length(); i++) {
                String value = clean(stores.optString(i, ""));
                if (!value.isEmpty()) draft.destinations.add(value);
            }
        }
        return draft;
    }

    private void touch() { updatedAt = System.currentTimeMillis(); }
    private static String clean(String value) { return value == null ? "" : value.trim(); }
}

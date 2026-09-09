package com.amstudio.distribution.domain;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public final class ReleaseDraft {
    private String id;
    private String title;
    private String artistName;
    private String labelName;
    private String releaseType;
    private ReleaseStatus status;
    private long updatedAt;
    private final List<String> destinations;

    public ReleaseDraft() {
        this.id = "rel_" + UUID.randomUUID().toString().replace("-", "");
        this.title = "";
        this.artistName = "";
        this.labelName = "AM STUDIO";
        this.releaseType = "Single";
        this.status = ReleaseStatus.DRAFT;
        this.updatedAt = System.currentTimeMillis();
        this.destinations = new ArrayList<>();
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
    public String getArtistName() { return artistName; }
    public String getLabelName() { return labelName; }
    public String getReleaseType() { return releaseType; }
    public ReleaseStatus getStatus() { return status; }
    public long getUpdatedAt() { return updatedAt; }
    public List<String> getDestinations() { return new ArrayList<>(destinations); }

    public void setTitle(String value) { title = clean(value); touch(); }
    public void setArtistName(String value) { artistName = clean(value); touch(); }
    public void setLabelName(String value) { labelName = clean(value); touch(); }
    public void setReleaseType(String value) { releaseType = clean(value); touch(); }
    public void setStatus(ReleaseStatus value) { status = value == null ? ReleaseStatus.DRAFT : value; touch(); }

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
        json.put("title", title);
        json.put("artistName", artistName);
        json.put("labelName", labelName);
        json.put("releaseType", releaseType);
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
        draft.title = json.optString("title", "");
        draft.artistName = json.optString("artistName", "");
        draft.labelName = json.optString("labelName", "AM STUDIO");
        draft.releaseType = json.optString("releaseType", "Single");
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

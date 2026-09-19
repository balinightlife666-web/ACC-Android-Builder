package com.amstudio.distribution.network;

import android.content.ContentResolver;
import android.net.Uri;

import com.amstudio.distribution.domain.ReleaseDraft;

import org.json.JSONArray;
import org.json.JSONObject;

public final class BackendReleaseOrchestrator {
    private final ContentResolver resolver;
    private final ApiClient api;

    public BackendReleaseOrchestrator(ContentResolver resolver, ApiClient api) {
        this.resolver = resolver;
        this.api = api;
    }

    public Result submit(ReleaseDraft draft) throws Exception {
        if (draft == null) throw new IllegalArgumentException("Release draft is required");
        if (draft.getAudioUri().isEmpty() || draft.getArtworkUri().isEmpty()) {
            throw new IllegalArgumentException("Audio master and artwork are required");
        }

        JSONObject created = api.createRelease(toCanonicalPayload(draft, "", ""));
        JSONObject release = created.optJSONObject("release");
        String releaseId = release == null ? "" : release.optString("id", "");
        if (releaseId.isEmpty()) throw new IllegalStateException("Backend did not return releaseId");

        String audioAssetId = uploadAsset(
                "AUDIO_MASTER",
                draft.getAudioName(),
                draft.getAudioMime(),
                Uri.parse(draft.getAudioUri()),
                draft.getAudioDurationMs(), 0, 0
        );

        String artworkAssetId = uploadAsset(
                "ARTWORK",
                draft.getArtworkName(),
                draft.getArtworkMime(),
                Uri.parse(draft.getArtworkUri()),
                0L, draft.getArtworkWidth(), draft.getArtworkHeight()
        );

        api.patchRelease(releaseId, toCanonicalPayload(draft, audioAssetId, artworkAssetId));
        JSONObject preflight = api.preflight(releaseId);
        if (!preflight.optBoolean("ok", false)) {
            return new Result(releaseId, preflight.optString("status", "PREFLIGHT_REQUIRED"), false, preflight);
        }

        JSONObject submitted = api.submitReview(releaseId);
        JSONObject submittedRelease = submitted.optJSONObject("release");
        String status = submittedRelease == null ? "IN_REVIEW" : submittedRelease.optString("status", "IN_REVIEW");
        return new Result(releaseId, status, true, submitted);
    }

    private String uploadAsset(String kind, String fileName, String mime, Uri uri,
                               long durationMs, int width, int height) throws Exception {
        Hashing.Fingerprint fingerprint = Hashing.fingerprint(resolver, uri);
        if (fingerprint.sizeBytes <= 0L) throw new IllegalStateException("Selected file is empty");

        JSONObject session = api.createUploadSession(kind, fileName, mime, fingerprint.sizeBytes, fingerprint.checksum);
        String assetId = session.optString("assetId", "");
        JSONObject upload = session.optJSONObject("upload");
        String target = upload == null ? "" : upload.optString("target", "");
        if (assetId.isEmpty() || target.isEmpty()) throw new IllegalStateException("Backend upload session is incomplete");

        api.uploadContent(target, uri, fingerprint.sizeBytes);
        api.completeUpload(assetId, durationMs, width, height);
        return assetId;
    }

    private JSONObject toCanonicalPayload(ReleaseDraft draft, String audioAssetId, String artworkAssetId) throws Exception {
        JSONObject payload = new JSONObject();
        payload.put("title", draft.getTitle());
        payload.put("artistName", draft.getArtistName());
        payload.put("labelName", draft.getLabelName());
        payload.put("genre", draft.getGenre());
        payload.put("releaseDate", draft.getReleaseDate());
        payload.put("songwriter", draft.getSongwriter());
        payload.put("composer", draft.getComposer());
        payload.put("copyrightOwner", draft.getCopyrightOwner());
        payload.put("explicitContent", draft.isExplicitContent());
        payload.put("rightsConfirmed", draft.isRightsConfirmed());
        if (audioAssetId != null && !audioAssetId.isEmpty()) payload.put("audioAssetId", audioAssetId);
        if (artworkAssetId != null && !artworkAssetId.isEmpty()) payload.put("artworkAssetId", artworkAssetId);
        JSONArray destinations = new JSONArray();
        for (String destination : draft.getDestinations()) destinations.put(destination);
        payload.put("destinations", destinations);
        return payload;
    }

    public static final class Result {
        public final String releaseId;
        public final String status;
        public final boolean submittedForReview;
        public final JSONObject raw;

        public Result(String releaseId, String status, boolean submittedForReview, JSONObject raw) {
            this.releaseId = releaseId == null ? "" : releaseId;
            this.status = status == null ? "" : status;
            this.submittedForReview = submittedForReview;
            this.raw = raw == null ? new JSONObject() : raw;
        }
    }
}

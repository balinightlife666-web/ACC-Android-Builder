package com.amstudio.distribution.distribution;

import com.amstudio.distribution.domain.ReleaseDraft;
import com.amstudio.distribution.domain.ReleaseStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public final class SandboxDistributionGateway implements DistributionGateway {
    @Override
    public ValidationResult validateRelease(ReleaseDraft draft) {
        List<String> issues = new ArrayList<>();
        if (draft == null) {
            issues.add("Release tidak tersedia.");
            return new ValidationResult(false, issues);
        }
        if (draft.getTitle().trim().isEmpty()) issues.add("Judul release wajib diisi.");
        if (draft.getArtistName().trim().isEmpty()) issues.add("Primary artist wajib diisi.");
        if (draft.getGenre().trim().isEmpty()) issues.add("Genre wajib diisi.");
        if (draft.getReleaseDate().trim().isEmpty()) issues.add("Tanggal rilis wajib diisi.");
        if (draft.getCopyrightOwner().trim().isEmpty()) issues.add("Pemilik copyright wajib diisi.");
        if (draft.getDestinations().isEmpty()) issues.add("Pilih minimal satu platform tujuan.");

        if (draft.getAudioUri().isEmpty()) {
            issues.add("Master audio wajib dipilih.");
        } else {
            String audioName = draft.getAudioName().toLowerCase(Locale.US);
            String audioMime = draft.getAudioMime().toLowerCase(Locale.US);
            boolean lossless = audioName.endsWith(".wav") || audioName.endsWith(".flac")
                    || audioMime.contains("wav") || audioMime.contains("flac");
            if (!lossless) issues.add("Master audio harus WAV atau FLAC.");
            if (draft.getAudioSizeBytes() <= 0L) issues.add("Ukuran master audio tidak valid.");
            if (draft.getAudioDurationMs() <= 0L) issues.add("Durasi master audio tidak terbaca.");
        }

        if (draft.getArtworkUri().isEmpty()) {
            issues.add("Cover artwork wajib dipilih.");
        } else {
            String artworkName = draft.getArtworkName().toLowerCase(Locale.US);
            String artworkMime = draft.getArtworkMime().toLowerCase(Locale.US);
            boolean imageType = artworkName.endsWith(".jpg") || artworkName.endsWith(".jpeg") || artworkName.endsWith(".png")
                    || artworkMime.contains("jpeg") || artworkMime.contains("png");
            if (!imageType) issues.add("Cover harus JPG atau PNG.");
            if (draft.getArtworkWidth() != draft.getArtworkHeight()) issues.add("Cover harus persegi 1:1.");
            if (draft.getArtworkWidth() < 3000 || draft.getArtworkHeight() < 3000) issues.add("Cover minimal 3000×3000 px.");
        }

        if (!draft.isRightsConfirmed()) issues.add("Deklarasi kepemilikan/lisensi hak wajib disetujui.");
        return new ValidationResult(issues.isEmpty(), issues);
    }

    @Override
    public SubmissionResult submitRelease(ReleaseDraft draft) {
        ValidationResult validation = validateRelease(draft);
        if (!validation.isValid()) {
            return new SubmissionResult(false, "", ReleaseStatus.PREFLIGHT_REQUIRED,
                    "Preflight belum lolos: " + String.join(" ", validation.getIssues()));
        }
        String suffix = draft.getId().replace("rel_", "");
        if (suffix.length() > 10) suffix = suffix.substring(0, 10);
        return new SubmissionResult(true,
                "AMS-SBX-" + suffix.toUpperCase(Locale.US),
                ReleaseStatus.IN_REVIEW,
                "Sandbox menerima release package. Belum dikirim ke DSP produksi.");
    }
}

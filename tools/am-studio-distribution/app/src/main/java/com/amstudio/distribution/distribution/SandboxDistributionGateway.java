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
        if (draft.getDestinations().isEmpty()) issues.add("Pilih minimal satu platform tujuan.");
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
                "Sandbox menerima release. Belum dikirim ke DSP produksi.");
    }
}

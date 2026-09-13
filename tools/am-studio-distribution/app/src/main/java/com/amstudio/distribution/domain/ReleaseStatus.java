package com.amstudio.distribution.domain;

public enum ReleaseStatus {
    DRAFT,
    PREFLIGHT_REQUIRED,
    READY_FOR_REVIEW,
    IN_REVIEW,
    NEEDS_CHANGES,
    APPROVED,
    SCHEDULED,
    DELIVERING,
    PARTIALLY_LIVE,
    LIVE,
    PROVIDER_REJECTED,
    DSP_REJECTED,
    RIGHTS_HOLD,
    FRAUD_HOLD,
    TAKEDOWN_REQUESTED,
    TAKING_DOWN,
    TAKEN_DOWN,
    CANCELLED;

    public static ReleaseStatus safeValueOf(String raw) {
        if (raw == null || raw.trim().isEmpty()) return DRAFT;
        try {
            return valueOf(raw);
        } catch (IllegalArgumentException ignored) {
            return DRAFT;
        }
    }
}

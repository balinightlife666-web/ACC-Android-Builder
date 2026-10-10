package com.amstudio.distribution.distribution;

import com.amstudio.distribution.domain.ReleaseDraft;
import com.amstudio.distribution.domain.ReleaseStatus;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public interface DistributionGateway {
    ValidationResult validateRelease(ReleaseDraft draft);
    SubmissionResult submitRelease(ReleaseDraft draft);

    final class ValidationResult {
        private final boolean valid;
        private final List<String> issues;

        public ValidationResult(boolean valid, List<String> issues) {
            this.valid = valid;
            this.issues = issues == null ? Collections.emptyList() : new ArrayList<>(issues);
        }

        public boolean isValid() { return valid; }
        public List<String> getIssues() { return new ArrayList<>(issues); }
    }

    final class SubmissionResult {
        private final boolean accepted;
        private final String internalSubmissionId;
        private final ReleaseStatus status;
        private final String message;

        public SubmissionResult(boolean accepted, String internalSubmissionId, ReleaseStatus status, String message) {
            this.accepted = accepted;
            this.internalSubmissionId = internalSubmissionId == null ? "" : internalSubmissionId;
            this.status = status == null ? ReleaseStatus.DRAFT : status;
            this.message = message == null ? "" : message;
        }

        public boolean isAccepted() { return accepted; }
        public String getInternalSubmissionId() { return internalSubmissionId; }
        public ReleaseStatus getStatus() { return status; }
        public String getMessage() { return message; }
    }
}

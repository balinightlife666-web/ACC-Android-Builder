import { canonicalRelease, applyEditablePatch, newId, nowIso, runPreflight, ReleaseStatus } from './domain.js';

export class MemoryStore {
  constructor() {
    this.releases = new Map();
    this.assets = new Map();
    this.audit = [];
  }

  createRelease(input, actor = 'dev-user') {
    const release = canonicalRelease(input);
    this.releases.set(release.id, release);
    this.record(actor, 'RELEASE_CREATED', release.id, null, release.status);
    return structuredClone(release);
  }

  listReleases() {
    return [...this.releases.values()].sort((a, b) => b.updatedAt.localeCompare(a.updatedAt)).map(structuredClone);
  }

  getRelease(id) {
    const release = this.releases.get(id);
    return release ? structuredClone(release) : null;
  }

  patchRelease(id, patch, actor = 'dev-user') {
    const release = this.requireRelease(id);
    const prior = release.status;
    applyEditablePatch(release, patch);
    this.record(actor, 'RELEASE_UPDATED', id, prior, release.status);
    return structuredClone(release);
  }

  createUploadSession(input, actor = 'dev-user') {
    const kind = input?.kind === 'ARTWORK' ? 'ARTWORK' : input?.kind === 'AUDIO_MASTER' ? 'AUDIO_MASTER' : '';
    if (!kind) throw coded('UPLOAD_KIND_INVALID', 'kind must be AUDIO_MASTER or ARTWORK');
    const fileName = text(input?.fileName);
    const mime = text(input?.mime);
    const sizeBytes = Number(input?.sizeBytes || 0);
    const checksum = text(input?.checksum);
    if (!fileName || !mime || !Number.isFinite(sizeBytes) || sizeBytes <= 0 || !checksum) {
      throw coded('UPLOAD_METADATA_INVALID', 'fileName, mime, sizeBytes and checksum are required');
    }
    const asset = {
      id: newId('ast'), kind, fileName, mime, sizeBytes, checksum,
      status: 'PENDING_UPLOAD', width: 0, height: 0, durationMs: 0,
      createdAt: nowIso(), updatedAt: nowIso()
    };
    this.assets.set(asset.id, asset);
    this.record(actor, 'UPLOAD_SESSION_CREATED', asset.id, null, asset.status);
    return {
      assetId: asset.id,
      status: asset.status,
      upload: {
        mode: 'DEV_SANDBOX_NO_OBJECT_STORAGE',
        target: `/v1/uploads/${asset.id}/complete`,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString()
      }
    };
  }

  completeUpload(id, input = {}, actor = 'dev-user') {
    const asset = this.assets.get(id);
    if (!asset) throw coded('ASSET_NOT_FOUND', 'Asset not found', 404);
    if (asset.status === 'VERIFIED') return structuredClone(asset);
    const providedChecksum = text(input.checksum);
    if (!providedChecksum || providedChecksum !== asset.checksum) {
      asset.status = 'REJECTED';
      asset.updatedAt = nowIso();
      this.record(actor, 'UPLOAD_REJECTED', id, 'PENDING_UPLOAD', asset.status);
      throw coded('CHECKSUM_MISMATCH', 'Checksum mismatch');
    }
    asset.width = Math.max(0, Number(input.width || 0));
    asset.height = Math.max(0, Number(input.height || 0));
    asset.durationMs = Math.max(0, Number(input.durationMs || 0));
    asset.status = 'VERIFIED';
    asset.updatedAt = nowIso();
    this.record(actor, 'UPLOAD_VERIFIED', id, 'PENDING_UPLOAD', asset.status);
    return structuredClone(asset);
  }

  preflightRelease(id, actor = 'dev-user') {
    const release = this.requireRelease(id);
    const prior = release.status;
    const result = runPreflight(release, assetId => this.assets.get(assetId));
    this.record(actor, 'RELEASE_PREFLIGHT', id, prior, release.status, { issues: result.issues });
    return { release: structuredClone(release), ...structuredClone(result) };
  }

  submitReview(id, actor = 'dev-user') {
    const release = this.requireRelease(id);
    if (release.status !== ReleaseStatus.READY_FOR_REVIEW) {
      throw coded('RELEASE_NOT_READY_FOR_REVIEW', 'Run a passing preflight first');
    }
    const prior = release.status;
    release.status = ReleaseStatus.IN_REVIEW;
    release.updatedAt = nowIso();
    this.record(actor, 'RELEASE_SUBMITTED_FOR_REVIEW', id, prior, release.status);
    return structuredClone(release);
  }

  getAudit() { return this.audit.map(structuredClone); }

  requireRelease(id) {
    const release = this.releases.get(id);
    if (!release) throw coded('RELEASE_NOT_FOUND', 'Release not found', 404);
    return release;
  }

  record(actor, action, entityId, priorState, nextState, meta = {}) {
    this.audit.push({
      id: newId('aud'), actor, action, entityId, priorState, nextState,
      meta, at: nowIso()
    });
  }
}

export function coded(code, message, status = 400) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  return error;
}

function text(value) { return typeof value === 'string' ? value.trim() : ''; }

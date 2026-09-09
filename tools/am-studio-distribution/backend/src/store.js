import { canonicalRelease, applyEditablePatch, newId, nowIso, runPreflight, ReleaseStatus } from './domain.js';
import { NullPersistence } from './persistence.js';

export class MemoryStore {
  constructor(options = {}) {
    this.persistence = options.persistence || new NullPersistence();
    this.releases = new Map();
    this.assets = new Map();
    this.audit = [];
    this.restore(this.persistence.load());
  }

  createRelease(input, actor = 'dev-user') {
    const release = canonicalRelease(input);
    this.releases.set(release.id, release);
    this.record(actor, 'RELEASE_CREATED', release.id, null, release.status);
    this.persist();
    return structuredClone(release);
  }

  listReleases() {
    return [...this.releases.values()]
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
      .map(value => structuredClone(value));
  }

  getRelease(id) {
    const release = this.releases.get(id);
    return release ? structuredClone(release) : null;
  }

  getAsset(id) {
    const asset = this.assets.get(id);
    return asset ? structuredClone(asset) : null;
  }

  patchRelease(id, patch, actor = 'dev-user') {
    const release = this.requireRelease(id);
    const prior = release.status;
    applyEditablePatch(release, patch);
    this.record(actor, 'RELEASE_UPDATED', id, prior, release.status);
    this.persist();
    return structuredClone(release);
  }

  createUploadSession(input, actor = 'dev-user') {
    const kind = input?.kind === 'ARTWORK' ? 'ARTWORK' : input?.kind === 'AUDIO_MASTER' ? 'AUDIO_MASTER' : '';
    if (!kind) throw coded('UPLOAD_KIND_INVALID', 'kind must be AUDIO_MASTER or ARTWORK');
    const fileName = text(input?.fileName);
    const mime = text(input?.mime);
    const sizeBytes = Number(input?.sizeBytes || 0);
    const checksum = normalizeChecksum(input?.checksum);
    if (!fileName || !mime || !Number.isFinite(sizeBytes) || sizeBytes <= 0 || !checksum) {
      throw coded('UPLOAD_METADATA_INVALID', 'fileName, mime, sizeBytes and sha256 checksum are required');
    }
    const asset = {
      id: newId('ast'), kind, fileName, mime, sizeBytes, checksum,
      status: 'PENDING_UPLOAD', storageKey: '', verifiedChecksum: '',
      width: 0, height: 0, durationMs: 0,
      createdAt: nowIso(), updatedAt: nowIso()
    };
    this.assets.set(asset.id, asset);
    this.record(actor, 'UPLOAD_SESSION_CREATED', asset.id, null, asset.status);
    this.persist();
    return {
      assetId: asset.id,
      status: asset.status,
      upload: {
        method: 'PUT',
        mode: 'DEV_LOCAL_STREAM',
        target: `/v1/uploads/${asset.id}/content`,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString()
      }
    };
  }

  markUploaded(id, result, actor = 'dev-user') {
    const asset = this.requireAsset(id);
    if (asset.status === 'VERIFIED' || asset.status === 'UPLOADED') return structuredClone(asset);
    if (asset.status !== 'PENDING_UPLOAD') throw coded('UPLOAD_STATE_INVALID', `Cannot upload asset from ${asset.status}`);
    const actualChecksum = normalizeChecksum(result?.checksum);
    const actualSize = Number(result?.sizeBytes || 0);
    if (!actualChecksum || actualChecksum !== asset.checksum) {
      const prior = asset.status;
      asset.status = 'REJECTED';
      asset.verifiedChecksum = actualChecksum;
      asset.updatedAt = nowIso();
      this.record(actor, 'UPLOAD_REJECTED', id, prior, asset.status, { reason: 'CHECKSUM_MISMATCH' });
      this.persist();
      throw coded('CHECKSUM_MISMATCH', 'Server-computed checksum does not match declared checksum');
    }
    if (actualSize !== asset.sizeBytes) {
      throw coded('UPLOAD_SIZE_MISMATCH', 'Uploaded size does not match declared size');
    }
    const prior = asset.status;
    asset.status = 'UPLOADED';
    asset.storageKey = text(result?.storageKey);
    asset.verifiedChecksum = actualChecksum;
    asset.updatedAt = nowIso();
    this.record(actor, 'UPLOAD_BYTES_VERIFIED', id, prior, asset.status);
    this.persist();
    return structuredClone(asset);
  }

  completeUpload(id, input = {}, actor = 'dev-user') {
    const asset = this.requireAsset(id);
    if (asset.status === 'VERIFIED') return structuredClone(asset);
    if (asset.status !== 'UPLOADED') throw coded('UPLOAD_BYTES_REQUIRED', 'Upload bytes and checksum verification must complete first');

    asset.width = Math.max(0, Number(input.width || 0));
    asset.height = Math.max(0, Number(input.height || 0));
    asset.durationMs = Math.max(0, Number(input.durationMs || 0));
    if (asset.kind === 'AUDIO_MASTER' && asset.durationMs <= 0) {
      throw coded('AUDIO_METADATA_REQUIRED', 'Audio duration is required after upload');
    }
    if (asset.kind === 'ARTWORK' && (asset.width <= 0 || asset.height <= 0)) {
      throw coded('ARTWORK_METADATA_REQUIRED', 'Artwork dimensions are required after upload');
    }

    const prior = asset.status;
    asset.status = 'VERIFIED';
    asset.updatedAt = nowIso();
    this.record(actor, 'UPLOAD_VERIFIED', id, prior, asset.status);
    this.persist();
    return structuredClone(asset);
  }

  preflightRelease(id, actor = 'dev-user') {
    const release = this.requireRelease(id);
    const prior = release.status;
    const result = runPreflight(release, assetId => this.assets.get(assetId));
    this.record(actor, 'RELEASE_PREFLIGHT', id, prior, release.status, { issues: result.issues });
    this.persist();
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
    this.persist();
    return structuredClone(release);
  }

  getAudit() {
    return this.audit.map(value => structuredClone(value));
  }

  requireRelease(id) {
    const release = this.releases.get(id);
    if (!release) throw coded('RELEASE_NOT_FOUND', 'Release not found', 404);
    return release;
  }

  requireAsset(id) {
    const asset = this.assets.get(id);
    if (!asset) throw coded('ASSET_NOT_FOUND', 'Asset not found', 404);
    return asset;
  }

  record(actor, action, entityId, priorState, nextState, meta = {}) {
    this.audit.push({
      id: newId('aud'), actor, action, entityId, priorState, nextState,
      meta, at: nowIso()
    });
  }

  snapshot() {
    return {
      schemaVersion: 1,
      releases: [...this.releases.values()],
      assets: [...this.assets.values()],
      audit: this.audit
    };
  }

  restore(snapshot) {
    if (!snapshot || Number(snapshot.schemaVersion || 1) !== 1) return;
    for (const release of Array.isArray(snapshot.releases) ? snapshot.releases : []) {
      if (release?.id) this.releases.set(release.id, release);
    }
    for (const asset of Array.isArray(snapshot.assets) ? snapshot.assets : []) {
      if (asset?.id) this.assets.set(asset.id, asset);
    }
    this.audit = Array.isArray(snapshot.audit) ? snapshot.audit : [];
  }

  persist() {
    this.persistence.save(this.snapshot());
  }
}

export function coded(code, message, status = 400) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  return error;
}

function text(value) { return typeof value === 'string' ? value.trim() : ''; }

function normalizeChecksum(value) {
  const raw = text(value).toLowerCase();
  if (!raw) return '';
  const digest = raw.startsWith('sha256:') ? raw.slice(7) : raw;
  return /^[a-f0-9]{64}$/.test(digest) ? `sha256:${digest}` : '';
}

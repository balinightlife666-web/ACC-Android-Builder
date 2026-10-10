import crypto from 'node:crypto';

export const ReleaseStatus = Object.freeze({
  DRAFT: 'DRAFT',
  PREFLIGHT_REQUIRED: 'PREFLIGHT_REQUIRED',
  READY_FOR_REVIEW: 'READY_FOR_REVIEW',
  IN_REVIEW: 'IN_REVIEW',
  NEEDS_CHANGES: 'NEEDS_CHANGES',
  RIGHTS_HOLD: 'RIGHTS_HOLD',
  APPROVED: 'APPROVED',
  DISTRIBUTING: 'DISTRIBUTING',
  PARTIALLY_LIVE: 'PARTIALLY_LIVE',
  LIVE: 'LIVE',
  TAKEDOWN_PENDING: 'TAKEDOWN_PENDING',
  TAKEN_DOWN: 'TAKEN_DOWN'
});

const editableStatuses = new Set([
  ReleaseStatus.DRAFT,
  ReleaseStatus.PREFLIGHT_REQUIRED,
  ReleaseStatus.NEEDS_CHANGES
]);

export function newId(prefix) {
  return `${prefix}_${crypto.randomUUID().replaceAll('-', '')}`;
}

export function nowIso() {
  return new Date().toISOString();
}

export function canEdit(status) {
  return editableStatuses.has(status);
}

export function canonicalRelease(input = {}) {
  const timestamp = nowIso();
  return {
    id: newId('rel'),
    status: ReleaseStatus.DRAFT,
    title: clean(input.title),
    artistName: clean(input.artistName),
    labelName: clean(input.labelName) || 'AM STUDIO',
    genre: clean(input.genre),
    releaseDate: clean(input.releaseDate),
    songwriter: clean(input.songwriter),
    composer: clean(input.composer),
    copyrightOwner: clean(input.copyrightOwner),
    explicitContent: Boolean(input.explicitContent),
    rightsConfirmed: Boolean(input.rightsConfirmed),
    audioAssetId: clean(input.audioAssetId),
    artworkAssetId: clean(input.artworkAssetId),
    destinations: uniqueStrings(input.destinations),
    createdAt: timestamp,
    updatedAt: timestamp,
    revision: 1
  };
}

export function applyEditablePatch(release, patch = {}) {
  if (!canEdit(release.status)) {
    const error = new Error(`Release cannot be edited while status=${release.status}`);
    error.code = 'RELEASE_STATE_NOT_EDITABLE';
    throw error;
  }
  const stringFields = ['title','artistName','labelName','genre','releaseDate','songwriter','composer','copyrightOwner','audioAssetId','artworkAssetId'];
  for (const field of stringFields) {
    if (Object.prototype.hasOwnProperty.call(patch, field)) release[field] = clean(patch[field]);
  }
  if (Object.prototype.hasOwnProperty.call(patch, 'explicitContent')) release.explicitContent = Boolean(patch.explicitContent);
  if (Object.prototype.hasOwnProperty.call(patch, 'rightsConfirmed')) release.rightsConfirmed = Boolean(patch.rightsConfirmed);
  if (Object.prototype.hasOwnProperty.call(patch, 'destinations')) release.destinations = uniqueStrings(patch.destinations);
  release.updatedAt = nowIso();
  release.revision += 1;
  return release;
}

export function runPreflight(release, assetLookup) {
  const issues = [];
  required(release.title, 'title', 'TITLE_REQUIRED', issues);
  required(release.artistName, 'artistName', 'PRIMARY_ARTIST_REQUIRED', issues);
  required(release.genre, 'genre', 'GENRE_REQUIRED', issues);
  required(release.releaseDate, 'releaseDate', 'RELEASE_DATE_REQUIRED', issues);
  required(release.copyrightOwner, 'copyrightOwner', 'COPYRIGHT_OWNER_REQUIRED', issues);
  if (!release.rightsConfirmed) issues.push(issue('rightsConfirmed', 'RIGHTS_DECLARATION_REQUIRED'));
  if (!release.destinations?.length) issues.push(issue('destinations', 'DESTINATION_REQUIRED'));

  const audio = release.audioAssetId ? assetLookup(release.audioAssetId) : null;
  const artwork = release.artworkAssetId ? assetLookup(release.artworkAssetId) : null;
  if (!audio || audio.kind !== 'AUDIO_MASTER' || audio.status !== 'VERIFIED') {
    issues.push(issue('audioAssetId', 'VERIFIED_AUDIO_MASTER_REQUIRED'));
  } else {
    const audioMime = (audio.mime || '').toLowerCase();
    const audioName = (audio.fileName || '').toLowerCase();
    if (!(audioMime.includes('wav') || audioMime.includes('flac') || audioName.endsWith('.wav') || audioName.endsWith('.flac'))) {
      issues.push(issue('audioAssetId', 'AUDIO_FORMAT_WAV_OR_FLAC_REQUIRED'));
    }
  }
  if (!artwork || artwork.kind !== 'ARTWORK' || artwork.status !== 'VERIFIED') {
    issues.push(issue('artworkAssetId', 'VERIFIED_ARTWORK_REQUIRED'));
  } else if (artwork.width < 3000 || artwork.height < 3000 || artwork.width !== artwork.height) {
    issues.push(issue('artworkAssetId', 'ARTWORK_SQUARE_3000_REQUIRED'));
  }

  const ok = issues.length === 0;
  release.status = ok ? ReleaseStatus.READY_FOR_REVIEW : ReleaseStatus.PREFLIGHT_REQUIRED;
  release.updatedAt = nowIso();
  return { ok, status: release.status, issues };
}

function issue(field, code) { return { field, code }; }
function required(value, field, code, issues) { if (!clean(value)) issues.push(issue(field, code)); }
function clean(value) { return typeof value === 'string' ? value.trim() : ''; }
function uniqueStrings(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map(clean).filter(Boolean))];
}

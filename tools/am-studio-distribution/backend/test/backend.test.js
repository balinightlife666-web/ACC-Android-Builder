import test from 'node:test';
import assert from 'node:assert/strict';
import { MemoryStore } from '../src/store.js';

function validReleasePatch(audioAssetId, artworkAssetId) {
  return {
    title: 'Foundation Test Single',
    artistName: 'AM STUDIO Test Artist',
    labelName: 'AM STUDIO',
    genre: 'Electronic',
    releaseDate: '2026-10-01',
    songwriter: 'Test Writer',
    composer: 'Test Composer',
    copyrightOwner: 'AM STUDIO Test Rights',
    rightsConfirmed: true,
    audioAssetId,
    artworkAssetId,
    destinations: ['Spotify', 'TikTok']
  };
}

function verifyAsset(store, kind, fileName, mime, extra = {}) {
  const session = store.createUploadSession({
    kind, fileName, mime, sizeBytes: 1000, checksum: `sha256-${kind}`
  });
  const asset = store.completeUpload(session.assetId, {
    checksum: `sha256-${kind}`,
    ...extra
  });
  return asset.id;
}

test('preflight blocks incomplete release', () => {
  const store = new MemoryStore();
  const release = store.createRelease({ title: 'Incomplete' });
  const result = store.preflightRelease(release.id);
  assert.equal(result.ok, false);
  assert.equal(result.release.status, 'PREFLIGHT_REQUIRED');
  assert.ok(result.issues.length >= 5);
});

test('verified WAV + 3000 square art can reach review', () => {
  const store = new MemoryStore();
  const audioAssetId = verifyAsset(store, 'AUDIO_MASTER', 'master.wav', 'audio/wav', { durationMs: 180000 });
  const artworkAssetId = verifyAsset(store, 'ARTWORK', 'cover.png', 'image/png', { width: 3000, height: 3000 });
  const release = store.createRelease({});
  store.patchRelease(release.id, validReleasePatch(audioAssetId, artworkAssetId));
  const preflight = store.preflightRelease(release.id);
  assert.equal(preflight.ok, true);
  assert.equal(preflight.release.status, 'READY_FOR_REVIEW');
  const submitted = store.submitReview(release.id);
  assert.equal(submitted.status, 'IN_REVIEW');
});

test('checksum mismatch rejects asset', () => {
  const store = new MemoryStore();
  const session = store.createUploadSession({
    kind: 'AUDIO_MASTER', fileName: 'master.flac', mime: 'audio/flac', sizeBytes: 1234, checksum: 'expected'
  });
  assert.throws(() => store.completeUpload(session.assetId, { checksum: 'wrong' }), /Checksum mismatch/);
});

test('release cannot be edited after submission', () => {
  const store = new MemoryStore();
  const audioAssetId = verifyAsset(store, 'AUDIO_MASTER', 'master.flac', 'audio/flac');
  const artworkAssetId = verifyAsset(store, 'ARTWORK', 'cover.jpg', 'image/jpeg', { width: 4000, height: 4000 });
  const release = store.createRelease({});
  store.patchRelease(release.id, validReleasePatch(audioAssetId, artworkAssetId));
  store.preflightRelease(release.id);
  store.submitReview(release.id);
  assert.throws(() => store.patchRelease(release.id, { title: 'Illegal edit' }), /cannot be edited/);
});

test('audit trail records sensitive state changes', () => {
  const store = new MemoryStore();
  const release = store.createRelease({ title: 'Audit' }, 'owner');
  store.patchRelease(release.id, { artistName: 'Artist' }, 'owner');
  const events = store.getAudit();
  assert.equal(events[0].action, 'RELEASE_CREATED');
  assert.equal(events[1].action, 'RELEASE_UPDATED');
  assert.equal(events[0].actor, 'owner');
});
